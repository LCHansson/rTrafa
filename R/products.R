#' Get available products from the Trafa API
#'
#' Fetches the list of all available statistical products (datasets) from the
#' Trafa API.
#'
#' @param lang Language code: `"SV"` (Swedish, default) or `"EN"` (English).
#'   Defaults to `getOption("rTrafa.lang", "SV")`.
#' @param cache Logical, cache results locally.
#' @param cache_location Cache directory. Defaults to [trafa_cache_dir()].
#' @param verbose Print request details.
#' @return A tibble with columns: `name`, `label`, `description`, `id`,
#'   `active_from`.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   products <- get_products()
#'   products |> product_search("buss")
#' }}
get_products <- function(lang = NULL,
                         cache = FALSE,
                         cache_location = trafa_cache_dir,
                         verbose = FALSE) {
  lang <- resolve_lang(lang)

  # SQLite-backed metadata cache via nordstatExtras. Opt-in when the caller
  # passes a sqlite cache_location; otherwise falls through to the .rds path.
  nxt_ch <- NULL
  ch <- NULL
  if (isTRUE(cache) && !is.null(cache_location) &&
      requireNamespace("nordstatExtras", quietly = TRUE) &&
      nordstatExtras::nxt_is_backend(cache_location)) {
    nxt_ch <- nordstatExtras::nxt_cache_handler(
      source = "trafa", entity = "products", cache = TRUE,
      cache_location = cache_location,
      kind = "metadata",
      key_params = list(lang = lang)
    )
    if (nxt_ch("discover")) return(nxt_ch("load"))
  } else {
    ch <- cache_handler("products", cache, cache_location, key_params = list(
      lang = lang
    ))
    if (ch("discover")) return(ch("load"))
  }

  url <- trafa_url("structure", lang = lang)
  raw <- trafa_get(url, verbose = verbose)

  if (is.null(raw)) return(NULL)

  items <- raw$StructureItems %||% list()
  if (length(items) == 0) {
    warn("No products returned by the Trafa API.")
    return(empty_products_tibble())
  }

  rows <- lapply(items, parse_product_item)

  result <- dplyr::bind_rows(rows)
  if (!is.null(nxt_ch)) {
    nxt_ch("store", result)
    return(result)
  }
  ch("store", result)
}

# Parse a single StructureItem of type "P" into a product row. Used by both
# get_products() and product_children() so the column set is identical.
#' @noRd
parse_product_item <- function(item) {
  tibble::tibble(
    name        = item$Name %||% NA_character_,
    label       = item$Label %||% NA_character_,
    description = item$Description %||% NA_character_,
    id          = as.integer(item$Id %||% NA_integer_),
    unique_id   = item$UniqueId %||% NA_character_,
    option      = item$Option %||% NA,
    parent_name = item$ParentName %||% NA_character_,
    active_from = item$ActiveFrom %||% NA_character_
  )
}

#' @noRd
empty_products_tibble <- function() {
  tibble::tibble(
    name = character(),
    label = character(),
    description = character(),
    id = integer(),
    unique_id = character(),
    option = logical(),
    parent_name = character(),
    active_from = character()
  )
}

#' Check if a product is a data-bearing leaf or an empty container
#'
#' The Trafa API does not model parent-child relationships between products
#' explicitly. However, some products (e.g. "Fordon på väg", t10010) have
#' dimensions and measures in their structure but return no data rows — they
#' act as organizational containers. This function checks whether a product
#' has actual data by inspecting its structure for dimension/measure items
#' whose `parent_name` matches the product code, and then verifying whether
#' the data endpoint returns rows.
#'
#' **Note:** when a product is a container, the related "sub-products"
#' cannot be discovered programmatically via the API. Use
#' [product_search()] on the product catalogue to find products with
#' similar names (e.g. `product_search(get_products(), "fordon")`).
#'
#' @param product Character: product code.
#' @param lang,cache,cache_location,verbose Standard rTrafa args.
#' @return Logical: `TRUE` if the product's data endpoint returns rows,
#'   `FALSE` if it appears to be an empty container.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   product_has_data("t10011")   # TRUE — Bussar has data
#'   product_has_data("t10010")   # FALSE — container, no data rows
#' }}
product_has_data <- function(product, lang = NULL, cache = FALSE,
                             cache_location = trafa_cache_dir,
                             verbose = FALSE) {
  # Get the structure to find at least one measure name
  items <- get_structure_raw(product, lang = lang, cache = cache,
                             cache_location = cache_location,
                             verbose = verbose)
  if (is.null(items)) return(FALSE)

  classified <- classify_structure_items(items)
  if (length(classified$measures) == 0) return(FALSE)

  first_measure <- classified$measures[[1]]$Name
  if (is.null(first_measure)) return(FALSE)

  # Build a minimal filter: pick the first dimension and request a single
  # value (e.g. ar = "2024"). The Trafa data endpoint requires at least
  # two of {product, measure, dimension} to be specified.
  dim_filter <- list()
  if (length(classified$dimensions) > 0) {
    first_dim <- classified$dimensions[[1]]
    dim_name <- first_dim$Name
    # Grab the first DV (dimension value) child to use as filter
    dim_vals <- parse_dimension_values(first_dim)
    if (!is.null(dim_vals) && nrow(dim_vals) > 0) {
      first_val <- dim_vals$name[dim_vals$type == "value"][1]
      if (!is.na(first_val)) {
        dim_filter <- stats::setNames(list(first_val), dim_name)
      }
    }
  }

  # Try a minimal data fetch via do.call so the dynamic dim_filter
  # expands cleanly into the ... argument of get_data().
  result <- tryCatch(
    do.call(get_data, c(
      list(product, first_measure, lang = lang, verbose = verbose),
      dim_filter
    )),
    error = function(e) NULL
  )
  !is.null(result) && nrow(result) > 0
}

#' Client-side search on a product tibble
#'
#' Filter an already-fetched product tibble by regex.
#'
#' @param product_df A tibble returned by [get_products()].
#' @param query Character vector of search terms (combined with OR).
#' @param column Column names to search. `NULL` searches all character columns.
#' @return A filtered tibble.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_products() |> product_search("fordon")
#' }}
product_search <- function(product_df, query, column = NULL) {
  entity_search(product_df, query, column, caller = "product_search")
}

#' Print human-readable product summaries
#'
#' @param product_df A tibble returned by [get_products()].
#' @param max_n Maximum number of products to describe.
#' @param format Output format: `"inline"` (console) or `"md"` (markdown).
#' @param heading_level Heading level for output.
#' @return `product_df` invisibly (for piping).
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_products() |> product_search("buss") |> product_describe()
#' }}
product_describe <- function(product_df, max_n = 5, format = "inline",
                             heading_level = 2) {
  if (is.null(product_df) || nrow(product_df) == 0) {
    warn("No products to describe.")
    return(invisible(product_df))
  }

  n <- min(max_n, nrow(product_df))

  for (i in seq_len(n)) {
    row <- product_df[i, ]
    cat(format_heading(
      paste0(row$name, ": ", row$label),
      level = heading_level,
      format = format
    ), "\n")

    fields <- list(
      format_field("Description", if (!is.na(row$description) && row$description != "") row$description else NULL),
      format_field("Active from", if ("active_from" %in% names(row) && !is.na(row$active_from)) row$active_from else NULL)
    )
    fields <- fields[!vapply(fields, is.null, logical(1))]
    if (length(fields) > 0) {
      cat(paste(fields, collapse = "\n"), "\n")
    }
    cat("\n")
  }

  if (nrow(product_df) > max_n) {
    cat(paste0("... and ", nrow(product_df) - max_n, " more product(s).\n"))
  }

  invisible(product_df)
}

#' Remove monotonous columns from a product tibble
#'
#' @param product_df A tibble returned by [get_products()].
#' @return A tibble with monotonous columns removed.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_products() |> product_minimize()
#' }}
product_minimize <- function(product_df) {
  remove_monotonous(product_df)
}

#' Extract product codes from a product tibble
#'
#' @param product_df A tibble returned by [get_products()].
#' @return A character vector of product codes (the `name` column).
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_products() |> product_search("buss") |> product_extract_ids()
#' }}
product_extract_ids <- function(product_df) {
  if (is.null(product_df) || nrow(product_df) == 0) return(character())
  product_df$name
}
