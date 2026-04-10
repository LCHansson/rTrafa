#' Fetch data from the Trafa API
#'
#' The core function for downloading statistical data. Dimension filters
#' are passed as named arguments via `...`, or via a prepared query object
#' from [prepare_query()].
#'
#' @param product Character: product code (e.g. `"t10011"`).
#'   Ignored when `query` is provided.
#' @param measure Character: measure name (e.g. `"itrfslut"`).
#'   Ignored when `query` is provided.
#' @param ... Dimension filters as named arguments. Each name is a dimension
#'   name, each value is a character vector of filter values.
#'   Unspecified dimensions return all values.
#'   Ignored when `query` is provided.
#' @param query A `<trafa_query>` object from [prepare_query()]. When provided,
#'   `product`, `measure`, and `...` are taken from the query object.
#' @param lang Language code: `"SV"` or `"EN"`.
#' @param simplify Add human-readable label columns alongside codes.
#' @param verbose Print request details.
#' @return A tibble of data. Dimension columns use the dimension name;
#'   when `simplify = TRUE`, additional `{name}_label` columns are added.
#'   Measure values are in a column named after the measure.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   # Direct fetch
#'   get_data("t10011", "itrfslut", ar = "2024")
#'
#'   # With filters
#'   get_data("t10011", "itrfslut",
#'     ar = c("2023", "2024"),
#'     drivm = c("102", "103"))
#'
#'   # From a prepared query
#'   q <- prepare_query("t10011", "itrfslut", ar = "2024")
#'   get_data(query = q)
#' }}
get_data <- function(product,
                     measure,
                     ...,
                     query = NULL,
                     lang = NULL,
                     simplify = TRUE,
                     verbose = FALSE) {
  if (inherits(query, "trafa_query")) {
    product <- query$product
    measure <- query$measure
    filters <- query$selections
    lang <- query$lang
  } else {
    if (missing(product) || missing(measure)) {
      abort("Both `product` and `measure` are required (or provide `query`).")
    }

    if (inherits(product, "trafa_query")) {
      abort(c(
        "A <trafa_query> object was passed as `product`.",
        i = "Use the named argument: `get_data(query = <your query>)`"
      ))
    }

    filters <- list(...)
  }

  lang <- resolve_lang(lang)

  query_str <- do.call(compose_data_query,
    c(list(product = product, measure = measure), filters)
  )
  url <- trafa_url("data", query = query_str, lang = lang)
  raw <- trafa_get(url, verbose = verbose)

  if (is.null(raw)) return(NULL)

  result <- parse_trafa_data(raw, simplify = simplify)

  if (is.null(result)) return(NULL)

  attr(result, "trafa_source") <- list(
    product = product,
    measure = measure,
    lang = lang,
    fetched = Sys.time()
  )

  result
}

#' Parse a Trafa data API response into a tibble
#'
#' @param raw Parsed JSON list from the data endpoint.
#' @param simplify Add label columns.
#' @return A tibble.
#' @noRd
parse_trafa_data <- function(raw, simplify = TRUE) {
  # The response has: Header (with Columns), Rows (with Cells), Notes
  columns <- raw$Header$Column %||% raw$Columns %||% list()
  data_rows <- raw$Rows %||% raw$Data %||% list()

  if (length(columns) == 0) {
    warn("No columns in Trafa API response.")
    return(NULL)
  }

  if (length(data_rows) == 0) {
    warn("No data rows in Trafa API response.")
    return(NULL)
  }

  # Parse column metadata
  col_names <- vapply(columns, function(c) c$Name %||% NA_character_, character(1))
  col_labels <- vapply(columns, function(c) c$Value %||% c$Label %||% NA_character_, character(1))
  col_types <- vapply(columns, function(c) c$Type %||% NA_character_, character(1))
  col_units <- vapply(columns, function(c) c$Unit %||% NA_character_, character(1))

  # Build column type lookup: name -> "D" or "M"
  col_type_lookup <- stats::setNames(col_types, col_names)

  # Parse each row
  parsed_rows <- lapply(data_rows, function(row) {
    cells <- row$Cell %||% row$Cells %||% list()

    values <- list()
    labels <- list()

    for (cell in cells) {
      # Column is a string name (e.g. "ar"), not an integer index
      cname <- cell$Column %||% NA_character_
      if (is.na(cname) || !cname %in% col_names) next

      ctype <- col_type_lookup[[cname]]
      is_measure <- isTRUE(cell$IsMeasure) || identical(ctype, "M")

      if (is_measure) {
        # Measure values: use Value (raw) or FormattedValue
        raw_val <- cell$Value %||% cell$FormattedValue %||% NA_character_
        # Handle Swedish decimal format (space as thousands sep, comma as decimal)
        raw_val <- gsub("\\s", "", as.character(raw_val))
        raw_val <- gsub(",", ".", raw_val)
        values[[cname]] <- suppressWarnings(as.numeric(raw_val))
      } else {
        # Dimension values: Name is the code, Value is the label
        values[[cname]] <- cell$Name %||% NA_character_
        labels[[cname]] <- cell$Value %||% NA_character_
      }
    }

    row_data <- list()
    for (i in seq_along(col_names)) {
      cname <- col_names[i]
      row_data[[cname]] <- values[[cname]] %||% NA

      if (simplify && !identical(col_types[i], "M") && !is.null(labels[[cname]])) {
        row_data[[paste0(cname, "_label")]] <- labels[[cname]]
      }
    }

    as.data.frame(row_data, stringsAsFactors = FALSE, check.names = FALSE)
  })

  result <- tryCatch(
    dplyr::bind_rows(parsed_rows),
    error = function(e) {
      warn(paste("Failed to combine data rows:", conditionMessage(e)))
      NULL
    }
  )

  if (is.null(result)) return(NULL)

  tibble::as_tibble(result)
}

#' Remove monotonous columns from a data tibble
#'
#' @param data_df A tibble returned by [get_data()].
#' @return A tibble with monotonous columns removed.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   d <- get_data("t10011", "itrfslut", ar = "2024")
#'   d |> data_minimize()
#' }}
data_minimize <- function(data_df) {
  remove_monotonous(data_df)
}

#' Generate a source caption for plots
#'
#' Builds a human-readable source attribution string from a data tibble
#' returned by [get_data()]. The string includes the product and measure
#' along with their human-readable descriptions, and is suitable for use
#' as a `caption` in `ggplot2::labs()`.
#'
#' By default the caption shows both the description and the code, e.g.
#' `"Källa: Trafa; produkt: Bussar (t10011); mått: Antal i trafik
#' (itrfslut)"`. Use `omit_varname` to drop the codes or `omit_desc` to
#' drop the descriptions.
#'
#' Product and measure descriptions are looked up via [get_products()]
#' and [get_measures()] (cached on disk).
#'
#' @param data_df A tibble returned by [get_data()].
#' @param lang Language for the caption text: `"SV"` (Swedish, default)
#'   or `"EN"` (English). Defaults to `getOption("rTrafa.lang", "SV")`.
#'   Note that the product/measure labels are returned by the API in
#'   their default language regardless of this setting.
#' @param omit_varname Logical. If `TRUE`, omit the variable codes (the
#'   parenthesised IDs like `t10011` and `itrfslut`).
#' @param omit_desc Logical. If `TRUE`, omit the human-readable
#'   descriptions and show only the codes.
#' @return A single character string suitable for plot captions.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   d <- get_data("t10011", "itrfslut", ar = "2024")
#'   data_legend(d)
#'   data_legend(d, lang = "EN")
#'   data_legend(d, omit_varname = TRUE)
#'   data_legend(d, omit_desc = TRUE)
#' }}
data_legend <- function(data_df,
                        lang = NULL,
                        omit_varname = FALSE,
                        omit_desc = FALSE) {
  source_info <- attr(data_df, "trafa_source")
  if (is.null(source_info)) return("")

  lang <- resolve_lang(lang)
  s <- legend_strings(lang)

  product_code <- source_info$product
  measure_code <- source_info$measure

  # Look up labels (cached)
  product_label <- lookup_product_label(product_code, lang = lang)
  measure_label <- lookup_measure_label(product_code, measure_code, lang = lang)

  product_str <- format_legend_field(product_label, product_code,
                                     omit_varname, omit_desc)
  measure_str <- format_legend_field(measure_label, measure_code,
                                     omit_varname, omit_desc)

  paste0(
    s$source, ": Trafa; ",
    s$product, ": ", product_str, "; ",
    s$measure, ": ", measure_str
  )
}

#' @noRd
legend_strings <- function(lang) {
  switch(lang,
    SV = list(source = "K\u00e4lla", product = "produkt", measure = "m\u00e5tt"),
    EN = list(source = "Source", product = "product", measure = "measure")
  )
}

#' Format one product or measure for the legend
#' @noRd
format_legend_field <- function(label, code, omit_varname, omit_desc) {
  has_label <- !is.null(label) && !is.na(label) && nzchar(label)

  if (omit_varname) return(if (has_label) label else code)
  if (omit_desc || !has_label) return(code)
  paste0(label, " (", code, ")")
}

#' Look up the human-readable label for a product code
#' @noRd
lookup_product_label <- function(product_code, lang = "SV") {
  products <- tryCatch(
    get_products(lang = lang, cache = TRUE),
    error = function(e) NULL
  )
  if (is.null(products) || nrow(products) == 0) return(NA_character_)

  row <- products[products$name == product_code, ]
  if (nrow(row) == 0) return(NA_character_)
  row$label[1]
}

#' Look up the human-readable label for a measure code
#' @noRd
lookup_measure_label <- function(product_code, measure_code, lang = "SV") {
  measures <- tryCatch(
    get_measures(product_code, lang = lang, cache = TRUE),
    error = function(e) NULL
  )
  if (is.null(measures) || nrow(measures) == 0) return(NA_character_)

  row <- measures[measures$name == measure_code, ]
  if (nrow(row) == 0) return(NA_character_)
  row$label[1]
}
