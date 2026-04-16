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
  key <- list(
    product = product,
    extra = paste(extra, collapse = "|"),
    lang = lang
  )

  # SQLite-backed metadata cache via nordstatExtras. The payload here is a
  # *list* of StructureItems (not a tibble) — base::serialize handles it.
  nxt_ch <- NULL
  ch <- NULL
  if (isTRUE(cache) && !is.null(cache_location) &&
      requireNamespace("nordstatExtras", quietly = TRUE) &&
      nordstatExtras::nxt_is_backend(cache_location)) {
    nxt_ch <- nordstatExtras::nxt_cache_handler(
      source = "trafa", entity = "structure", cache = TRUE,
      cache_location = cache_location,
      kind = "metadata",
      key_params = key
    )
    if (nxt_ch("discover")) return(nxt_ch("load"))
  } else {
    ch <- cache_handler("structure", cache, cache_location, key_params = key)
    if (ch("discover")) return(ch("load"))
  }

  query_str <- compose_structure_query(product, ...)
  url <- trafa_url("structure", query = query_str, lang = lang)
  raw <- trafa_get(url, verbose = verbose)

  if (is.null(raw)) return(NULL)

  items <- raw$StructureItems %||% list()
  if (length(items) == 0) {
    warn(paste0("No structure returned for product '", product, "'."))
    return(NULL)
  }

  if (!is.null(nxt_ch)) {
    nxt_ch("store", items)
    return(items)
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
    products    = items[types == "P"],
    dimensions  = items[types == "D"],
    measures    = items[types == "M"],
    hierarchies = items[types == "H"]
  )
}

#' Parse dimension values (DV) and filter shortcuts (F) from a dimension item
#'
#' @param item A single StructureItem of type D.
#' @return A tibble with columns `code`, `text`, `name`, `label`, `type`
#'   ("value" or "filter"). `code`/`text` mirror the names used by
#'   `pixieweb::get_variables()` and `rKolada` for consistency across the
#'   nordstat family; `name`/`label` are retained as aliases.
#' @noRd
parse_dimension_values <- function(item) {
  children <- item$StructureItems %||% list()
  child_types <- vapply(children, function(x) x$Type %||% "", character(1))
  relevant <- children[child_types %in% c("DV", "F")]

  if (length(relevant) == 0) return(NULL)

  codes  <- vapply(relevant, function(x) x$Name %||% NA_character_, character(1))
  texts  <- vapply(relevant, function(x) x$Label %||% NA_character_, character(1))
  types  <- vapply(relevant, function(x) {
    if (identical(x$Type, "F")) "filter" else "value"
  }, character(1))

  tibble::tibble(
    code  = codes,
    text  = texts,
    name  = codes,   # backwards-compatible alias — will be deprecated in 0.2.0
    label = texts,   # backwards-compatible alias — will be deprecated in 0.2.0
    type  = types
  )
}
