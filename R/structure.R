# Internal: raw structure fetcher and parser
# Public API is via get_measures() and get_dimensions()

#' Fetch raw structure from the Trafa API
#'
#' @param product Character: product code.
#' @param ... Additional query parts (e.g. a measure name for validation).
#' @param lang Language code.
#' @param cache Logical.
#' @param cache_location Cache directory.
#' @param verbose Print details.
#' @return A list of parsed StructureItem objects, or NULL.
#' @noRd
get_structure_raw <- function(product,
                              ...,
                              lang = NULL,
                              cache = FALSE,
                              cache_location = trafa_cache_dir,
                              verbose = FALSE) {
  stopifnot(is.character(product), length(product) == 1)
  lang <- resolve_lang(lang)

  extra <- as.character(c(...))
  ch <- cache_handler("structure", cache, cache_location, key_params = list(
    product = product,
    extra = paste(extra, collapse = "|"),
    lang = lang
  ))
  if (ch("discover")) return(ch("load"))

  query_str <- compose_structure_query(product, ...)
  url <- trafa_url("structure", query = query_str, lang = lang)
  raw <- trafa_get(url, verbose = verbose)

  if (is.null(raw)) return(NULL)

  items <- raw$StructureItems %||% list()
  if (length(items) == 0) {
    warn(paste0("No structure returned for product '", product, "'."))
    return(NULL)
  }

  ch("store", items)
}

#' Classify top-level StructureItems by type
#'
#' The structure endpoint returns a flat list mixing P (other products),
#' D (dimensions), M (measures), and H (hierarchies). This helper
#' partitions them.
#'
#' @param items List of StructureItem objects.
#' @return A named list with elements `dimensions`, `measures`, `hierarchies`.
#' @noRd
classify_structure_items <- function(items) {
  types <- vapply(items, function(x) x$Type %||% "", character(1))
  list(
    dimensions = items[types == "D"],
    measures   = items[types == "M"],
    hierarchies = items[types == "H"]
  )
}

#' Parse dimension values (DV) and filter shortcuts (F) from a dimension item
#'
#' @param item A single StructureItem of type D.
#' @return A tibble with columns `name`, `label`, `type` ("value" or "filter").
#' @noRd
parse_dimension_values <- function(item) {
  children <- item$StructureItems %||% list()
  child_types <- vapply(children, function(x) x$Type %||% "", character(1))
  relevant <- children[child_types %in% c("DV", "F")]

  if (length(relevant) == 0) return(NULL)

  tibble::tibble(
    name  = vapply(relevant, function(x) x$Name %||% NA_character_, character(1)),
    label = vapply(relevant, function(x) x$Label %||% NA_character_, character(1)),
    type  = vapply(relevant, function(x) {
      if (identical(x$Type, "F")) "filter" else "value"
    }, character(1))
  )
}
