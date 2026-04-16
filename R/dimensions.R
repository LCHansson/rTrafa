#' Get dimensions (filter variables) for a product
#'
#' Retrieves the available dimensions for a Trafa product. Dimensions are
#' the categorical variables you can filter on when fetching data with
#' [get_data()] — for example year, fuel type, or owner category.
#'
#' Dimensions that belong to a hierarchy (e.g. "Ägarkategori" under the
#' "Ägare" hierarchy) are included with their hierarchy noted in the
#' `hierarchy` column. Hierarchies themselves are not queryable — only
#' their child dimensions are.
#'
#' When `measure` is provided, the API validates which dimensions are
#' compatible with that measure. Invalid dimensions are excluded by default
#' (controlled by `only_valid`).
#'
#' `measure` can also be a **vector of several measure names**. In that
#' case, the API returns the intersection: only dimensions that are valid
#' for *all* the requested measures. This is useful when planning a query
#' that mixes several measures and you want to know which dimensions you
#' can safely filter on.
#'
#' @param product Character: product code (e.g. `"t10011"`).
#' @param measure Character vector of one or more measure names. When
#'   provided, only dimensions valid for the measure(s) are returned
#'   (unless `only_valid = FALSE`). Passing several measures restricts
#'   the result to dimensions valid for *all* of them.
#' @param only_valid Logical. When `measure` is provided and
#'   `only_valid = TRUE` (default), dimensions with `option = FALSE` are
#'   excluded. Set to `FALSE` to see all dimensions with their validity
#'   status.
#' @param lang Language code: `"SV"` or `"EN"`.
#' @param cache Logical, cache results locally.
#' @param cache_location Cache directory. Defaults to [trafa_cache_dir()].
#' @param verbose Print request details.
#' @return A tibble with columns: `product`, `name`, `label`, `data_type`,
#'   `option`, `description`, `hierarchy`, `n_values`, `values`.
#'
#'   The `values` column contains nested tibbles with columns `code`,
#'   `text`, `name`, `label` and `type`. `code`/`text` mirror the
#'   conventions used by `pixieweb::get_variables()` and the sibling
#'   Kolada package; `name`/`label` are legacy aliases kept for
#'   backward compatibility. `type` is `"value"` for regular dimension
#'   values and `"filter"` for API filter shortcuts like `"senaste"`
#'   (latest).
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   # All dimensions
#'   get_dimensions("t10011") |> dimension_describe()
#'
#'   # Validated against a specific measure
#'   get_dimensions("t10011", measure = "itrfslut")
#'
#'   # Validated against several measures (intersection)
#'   get_dimensions("t10011", measure = c("itrfslut", "nyregunder"))
#'
#'   # Inspect values for a dimension
#'   get_dimensions("t10011") |> dimension_values("drivm")
#' }}
get_dimensions <- function(product,
                           measure = NULL,
                           only_valid = TRUE,
                           lang = NULL,
                           cache = FALSE,
                           cache_location = trafa_cache_dir,
                           verbose = FALSE) {
  items <- get_structure_raw(product, measure,
                             lang = lang, cache = cache,
                             cache_location = cache_location,
                             verbose = verbose)
  if (is.null(items)) return(NULL)

  classified <- classify_structure_items(items)

  # Collect top-level dimensions (not inside a hierarchy)
  dim_rows <- lapply(classified$dimensions, function(item) {
    build_dimension_row(item, product, hierarchy = NA_character_)
  })

  # Collect dimensions nested inside hierarchies
  for (h_item in classified$hierarchies) {
    h_name <- h_item$Name %||% NA_character_
    h_children <- h_item$StructureItems %||% list()
    child_types <- vapply(h_children, function(x) x$Type %||% "", character(1))
    child_dims <- h_children[child_types == "D"]

    for (child in child_dims) {
      dim_rows <- c(dim_rows, list(
        build_dimension_row(child, product, hierarchy = h_name)
      ))
    }
  }

  if (length(dim_rows) == 0) {
    warn(paste0("No dimensions found for product '", product, "'."))
    return(empty_dimensions_tibble())
  }

  result <- dplyr::bind_rows(dim_rows)

  # Filter to valid dimensions if measure was provided
  if (!is.null(measure) && only_valid) {
    result <- result[is.na(result$option) | result$option == TRUE, ]
  }

  result
}

#' Build a single dimension row from a StructureItem
#' @noRd
build_dimension_row <- function(item, product, hierarchy) {
  vals <- parse_dimension_values(item)

  n_values <- if (!is.null(vals)) {
    # Count only actual values, not filter shortcuts
    sum(vals$type == "value")
  } else {
    NA_integer_
  }

  tibble::tibble(
    product     = product,
    name        = item$Name %||% NA_character_,
    label       = item$Label %||% NA_character_,
    data_type   = item$DataType %||% "String",
    option      = item$Option %||% NA,
    description = item$Description %||% NA_character_,
    hierarchy   = hierarchy,
    n_values    = as.integer(n_values),
    values      = list(vals),
    id          = as.integer(item$Id %||% NA_integer_),
    unique_id   = item$UniqueId %||% NA_character_,
    parent_name = item$ParentName %||% NA_character_,
    active_from = item$ActiveFrom %||% NA_character_
  )
}

#' @noRd
empty_dimensions_tibble <- function() {
  tibble::tibble(
    product = character(), name = character(), label = character(),
    data_type = character(), option = logical(),
    description = character(), hierarchy = character(),
    n_values = integer(), values = list()
  )
}

#' Search dimensions by text
#'
#' @param dim_df A tibble returned by [get_dimensions()].
#' @param query Character vector of search terms (combined with OR).
#' @param column Column names to search. `NULL` searches `name`, `label`,
#'   and `description`.
#' @return A filtered tibble.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_dimensions("t10011") |> dimension_search("driv")
#' }}
dimension_search <- function(dim_df, query, column = NULL) {
  column <- column %||% c("name", "label", "description")
  entity_search(dim_df, query, column, caller = "dimension_search")
}

#' Print human-readable dimension summaries
#'
#' @param dim_df A tibble returned by [get_dimensions()].
#' @param max_n Maximum number of dimensions to describe.
#' @param format Output format: `"inline"` or `"md"`.
#' @param heading_level Heading level.
#' @return `dim_df` invisibly (for piping).
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_dimensions("t10011") |> dimension_describe()
#' }}
dimension_describe <- function(dim_df, max_n = 15, format = "inline",
                               heading_level = 2) {
  if (is.null(dim_df) || nrow(dim_df) == 0) {
    warn("No dimensions to describe.")
    return(invisible(dim_df))
  }

  n <- min(max_n, nrow(dim_df))

  for (i in seq_len(n)) {
    row <- dim_df[i, ]

    title <- paste0(row$name, " (", row$label, ")")
    if (!is.na(row$hierarchy)) {
      title <- paste0(title, "  [", row$hierarchy, "]")
    }

    cat(format_heading(title, level = heading_level, format = format), "\n")

    fields <- list(
      format_field("Data type",
        if (row$data_type != "String") row$data_type else NULL),
      format_field("Description",
        if (!is.na(row$description) && row$description != "") row$description else NULL),
      format_field("Selectable",
        if (!is.na(row$option)) ifelse(row$option, "Yes", "No") else NULL)
    )
    fields <- fields[!vapply(fields, is.null, logical(1))]
    if (length(fields) > 0) cat(paste(fields, collapse = "\n"), "\n")

    # Show values
    vals <- row$values[[1]]
    if (!is.null(vals) && nrow(vals) > 0) {
      regular <- vals[vals$type == "value", ]
      filters <- vals[vals$type == "filter", ]

      if (nrow(regular) > 0) {
        val_display <- paste(regular$name, regular$label, sep = " = ")
        cat("  Values (", nrow(regular), "): ",
            truncate_list(val_display, 5), "\n", sep = "")
      }
      if (nrow(filters) > 0) {
        filt_display <- paste(filters$name, filters$label, sep = " = ")
        cat("  Filters: ", paste(filt_display, collapse = ", "), "\n", sep = "")
      }
    }
    cat("\n")
  }

  if (nrow(dim_df) > max_n) {
    cat(paste0("... and ", nrow(dim_df) - max_n, " more dimension(s).\n"))
  }

  invisible(dim_df)
}

#' Extract values for a specific dimension
#'
#' Returns the available values for a dimension, including both regular
#' values and filter shortcuts (like `"senaste"` = latest). The `type`
#' column distinguishes them: `"value"` for regular values, `"filter"`
#' for shortcuts that the API resolves dynamically.
#'
#' @param dim_df A tibble returned by [get_dimensions()].
#' @param dimension_name Dimension name (character).
#' @return A tibble with columns `code`, `text`, `name`, `label`, `type`.
#'   `code`/`text` mirror the nordstat-family convention; `name`/`label`
#'   are retained as legacy aliases.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   dims <- get_dimensions("t10011")
#'   dims |> dimension_values("ar")
#'   dims |> dimension_values("drivm")
#' }}
dimension_values <- function(dim_df, dimension_name) {
  row <- dim_df[dim_df$name == dimension_name, ]
  if (nrow(row) == 0) {
    warn(paste0("Dimension '", dimension_name, "' not found."))
    return(tibble::tibble(code = character(), text = character(),
                          name = character(), label = character(),
                          type = character()))
  }
  vals <- row$values[[1]]
  if (is.null(vals)) {
    return(tibble::tibble(code = character(), text = character(),
                          name = character(), label = character(),
                          type = character()))
  }
  vals
}

#' Extract dimension names
#'
#' @param dim_df A tibble returned by [get_dimensions()].
#' @return A character vector of dimension names.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_dimensions("t10011") |> dimension_extract_names()
#' }}
dimension_extract_names <- function(dim_df) {
  if (is.null(dim_df) || nrow(dim_df) == 0) return(character())
  dim_df$name
}
