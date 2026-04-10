#' Prepare a data query with progressive validation
#'
#' Fetches the product structure, validates that the requested measure and
#' dimensions are compatible, and returns a query object that can be passed
#' to [get_data()].
#'
#' The Trafa API supports progressive structure discovery: adding a measure
#' to the structure query reveals which dimensions are valid for that measure
#' (via the `option` field). This function leverages that to warn about
#' invalid dimension combinations before data is requested.
#'
#' @param product Character: product code (e.g. `"t10011"`).
#' @param measure Character: measure name (e.g. `"itrfslut"`).
#' @param ... Dimension filters as named arguments (same syntax as
#'   [get_data()]).
#' @param lang Language code: `"SV"` or `"EN"`.
#' @param validate Logical. If `TRUE` (default), validates dimension
#'   compatibility against the API structure.
#' @param verbose Print request details.
#' @return A `<trafa_query>` object. Pass to [get_data()] via `query`.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   q <- prepare_query("t10011", "itrfslut", ar = "2024")
#'   q
#'
#'   get_data(query = q)
#' }}
prepare_query <- function(product,
                          measure,
                          ...,
                          lang = NULL,
                          validate = TRUE,
                          verbose = FALSE) {
  stopifnot(is.character(product), length(product) == 1)
  stopifnot(is.character(measure), length(measure) == 1)
  lang <- resolve_lang(lang)

  # Validate measure exists
  measures <- get_measures(product, lang = lang, verbose = verbose)
  if (is.null(measures) || nrow(measures) == 0) {
    abort(paste0("Could not retrieve measures for product '", product, "'."))
  }
  if (!measure %in% measures$name) {
    available <- paste0("'", measures$name, "'", collapse = ", ")
    abort(c(
      paste0("Measure '", measure, "' not found in product '", product, "'."),
      i = paste0("Available measures: ", available)
    ))
  }

  # Fetch dimensions, optionally validated against the measure
  if (validate) {
    dims <- get_dimensions(product, measure = measure, only_valid = FALSE,
                           lang = lang, verbose = verbose)
  } else {
    dims <- get_dimensions(product, lang = lang, verbose = verbose)
  }

  user_selections <- list(...)

  # Check user-supplied dimensions against valid ones
  if (!is.null(dims) && nrow(dims) > 0 && length(user_selections) > 0) {
    valid_names <- dims$name[is.na(dims$option) | dims$option == TRUE]
    for (dim_name in names(user_selections)) {
      if (!dim_name %in% dims$name) {
        all_dim_names <- paste0("'", dims$name, "'", collapse = ", ")
        warn(c(
          paste0("Dimension '", dim_name, "' not found in product '", product, "'."),
          i = paste0("Available dimensions: ", all_dim_names)
        ))
      } else if (!dim_name %in% valid_names) {
        warn(c(
          paste0("Dimension '", dim_name, "' may not be valid for measure '",
                 measure, "' in product '", product, "'."),
          i = "The API reports Option = FALSE for this dimension."
        ))
      }
    }
  }

  query <- structure(
    list(
      product = product,
      measure = measure,
      selections = user_selections,
      dimensions = dims,
      lang = lang
    ),
    class = "trafa_query"
  )

  query
}

#' @rdname prepare_query
#' @param x A `<trafa_query>` object.
#' @param ... Ignored.
#' @export
print.trafa_query <- function(x, ...) {
  cat(format_heading(
    paste0("Trafa query: ", x$product, " | ", x$measure),
    level = 2, format = "inline"
  ), "\n")

  cat("  Product: ", x$product, "\n", sep = "")
  cat("  Measure: ", x$measure, "\n", sep = "")
  cat("  Language: ", x$lang, "\n", sep = "")

  if (length(x$selections) > 0) {
    cat("\n  Dimension filters:\n")
    for (dim_name in names(x$selections)) {
      vals <- x$selections[[dim_name]]
      if (length(vals) <= 5) {
        val_str <- paste0('"', vals, '"', collapse = ", ")
      } else {
        val_str <- paste0(
          paste0('"', utils::head(vals, 3), '"', collapse = ", "),
          ", ... +", length(vals) - 3, " more"
        )
      }
      cat("    ", dim_name, " = c(", val_str, ")\n", sep = "")
    }
  } else {
    cat("\n  No dimension filters (all values will be returned).\n")
  }

  if (!is.null(x$dimensions) && nrow(x$dimensions) > 0) {
    valid <- x$dimensions[is.na(x$dimensions$option) |
                            x$dimensions$option == TRUE, ]
    unused <- setdiff(valid$name, names(x$selections))
    if (length(unused) > 0) {
      cat("\n  Available (unfiltered) dimensions: ",
          paste(unused, collapse = ", "), "\n", sep = "")
    }
  }

  invisible(x)
}
