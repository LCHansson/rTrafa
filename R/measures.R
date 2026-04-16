#' Get measures (KPIs) for a product
#'
#' Retrieves the available measures for a Trafa product. Each measure
#' represents a specific statistic (KPI) that can be queried with
#' [get_data()]. A product typically has several measures — for example,
#' "Bussar" (t10011) has measures for vehicles in traffic, deregistered,
#' newly registered, etc.
#'
#' @param product Character: product code (e.g. `"t10011"`).
#' @param lang Language code: `"SV"` or `"EN"`.
#' @param cache Logical, cache results locally.
#' @param cache_location Cache directory. Defaults to [trafa_cache_dir()].
#' @param verbose Print request details.
#' @return A tibble with columns: `product`, `name`, `label`, `description`,
#'   `id`, `unique_id`, `option`, `active_from`, `data_type`, `parent_name`.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_measures("t10011") |> measure_describe()
#' }}
get_measures <- function(product,
                         lang = NULL,
                         cache = FALSE,
                         cache_location = trafa_cache_dir,
                         verbose = FALSE) {
  # Measures-specific nordstatExtras cache. Without this, the search index
  # extractor (trafa/measures in nordstatExtras::search.R) never fires,
  # because get_structure_raw stores under entity="structure" which is
  # deliberately omitted from the search index.
  nxt_ch <- NULL
  if (isTRUE(cache) && !is.null(cache_location) &&
      requireNamespace("nordstatExtras", quietly = TRUE) &&
      nordstatExtras::nxt_is_backend(cache_location)) {
    nxt_ch <- nordstatExtras::nxt_cache_handler(
      source = "trafa", entity = "measures", cache = TRUE,
      cache_location = cache_location,
      kind = "metadata",
      key_params = list(product = product, lang = lang)
    )
    if (nxt_ch("discover")) return(nxt_ch("load"))
  }

  items <- get_structure_raw(product, lang = lang, cache = cache,
                             cache_location = cache_location, verbose = verbose)
  if (is.null(items)) return(NULL)

  classified <- classify_structure_items(items)
  m_items <- classified$measures

  if (length(m_items) == 0) {
    warn(paste0("No measures found for product '", product, "'."))
    result <- empty_measures_tibble()
    if (!is.null(nxt_ch)) nxt_ch("store", result)
    return(result)
  }

  result <- tibble::tibble(
    product     = product,
    name        = vapply(m_items, function(x) x$Name %||% NA_character_, character(1)),
    label       = vapply(m_items, function(x) x$Label %||% NA_character_, character(1)),
    description = vapply(m_items, function(x) x$Description %||% NA_character_, character(1)),
    id          = vapply(m_items, function(x) as.integer(x$Id %||% NA_integer_), integer(1)),
    unique_id   = vapply(m_items, function(x) x$UniqueId %||% NA_character_, character(1)),
    option      = vapply(m_items, function(x) x$Option %||% NA, logical(1)),
    active_from = vapply(m_items, function(x) x$ActiveFrom %||% NA_character_, character(1)),
    data_type   = vapply(m_items, function(x) x$DataType %||% NA_character_, character(1)),
    parent_name = vapply(m_items, function(x) x$ParentName %||% NA_character_, character(1))
  )

  if (!is.null(nxt_ch)) nxt_ch("store", result)
  result
}

#' @noRd
empty_measures_tibble <- function() {
  tibble::tibble(
    product = character(), name = character(),
    label = character(), description = character(),
    id = integer(), unique_id = character(),
    option = logical(), active_from = character(),
    data_type = character(), parent_name = character()
  )
}

#' Search measures by text
#'
#' @param measure_df A tibble returned by [get_measures()].
#' @param query Character vector of search terms (combined with OR).
#' @param column Column names to search. `NULL` searches `name`, `label`,
#'   and `description`.
#' @return A filtered tibble.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_measures("t10011") |> measure_search("trafik")
#' }}
measure_search <- function(measure_df, query, column = NULL) {
  column <- column %||% c("name", "label", "description")
  entity_search(measure_df, query, column, caller = "measure_search")
}

#' Print human-readable measure summaries
#'
#' @param measure_df A tibble returned by [get_measures()].
#' @param max_n Maximum number of measures to describe.
#' @param format Output format: `"inline"` or `"md"`.
#' @param heading_level Heading level.
#' @return `measure_df` invisibly (for piping).
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_measures("t10011") |> measure_describe()
#' }}
measure_describe <- function(measure_df, max_n = 10, format = "inline",
                             heading_level = 2) {
  if (is.null(measure_df) || nrow(measure_df) == 0) {
    warn("No measures to describe.")
    return(invisible(measure_df))
  }

  n <- min(max_n, nrow(measure_df))

  for (i in seq_len(n)) {
    row <- measure_df[i, ]
    cat(format_heading(
      paste0(row$name, " (", row$label, ")"),
      level = heading_level,
      format = format
    ), "\n")

    fields <- list(
      format_field("Product", row$product),
      format_field("Description",
        if (!is.na(row$description) && row$description != "") row$description else NULL)
    )
    fields <- fields[!vapply(fields, is.null, logical(1))]
    if (length(fields) > 0) cat(paste(fields, collapse = "\n"), "\n")
    cat("\n")
  }

  if (nrow(measure_df) > max_n) {
    cat(paste0("... and ", nrow(measure_df) - max_n, " more measure(s).\n"))
  }

  invisible(measure_df)
}

#' Extract measure names
#'
#' @param measure_df A tibble returned by [get_measures()].
#' @return A character vector of measure names.
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   get_measures("t10011") |> measure_extract_names()
#' }}
measure_extract_names <- function(measure_df) {
  if (is.null(measure_df) || nrow(measure_df) == 0) return(character())
  measure_df$name
}
