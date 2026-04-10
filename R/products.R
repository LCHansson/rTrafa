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

  ch <- cache_handler("products", cache, cache_location, key_params = list(
    lang = lang
  ))
  if (ch("discover")) return(ch("load"))

  url <- trafa_url("structure", lang = lang)
  raw <- trafa_get(url, verbose = verbose)

  if (is.null(raw)) return(NULL)

  items <- raw$StructureItems %||% list()
  if (length(items) == 0) {
    warn("No products returned by the Trafa API.")
    return(empty_products_tibble())
  }

  rows <- lapply(items, function(item) {
    tibble::tibble(
      name = item$Name %||% NA_character_,
      label = item$Label %||% NA_character_,
      description = item$Description %||% NA_character_,
      id = as.integer(item$Id %||% NA_integer_),
      active_from = item$ActiveFrom %||% NA_character_
    )
  })

  result <- dplyr::bind_rows(rows)
  ch("store", result)
}

#' @noRd
empty_products_tibble <- function() {
  tibble::tibble(
    name = character(),
    label = character(),
    description = character(),
    id = integer(),
    active_from = character()
  )
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
