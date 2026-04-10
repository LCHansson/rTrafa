#' Compose a structure query string
#'
#' Builds the pipe-delimited query string used by the Trafa `/api/structure`
#' endpoint.
#'
#' @param product Character: product code (e.g. `"t10011"`).
#' @param ... Additional dimension names to include in the query.
#'   These are bare names (not filtered), used for progressive structure
#'   discovery.
#' @return A character string (e.g. `"t10011|ar|drivm"`), or an empty string
#'   if `product` is `NULL`.
#' @export
#' @examples
#' compose_structure_query("t10011")
#' compose_structure_query("t10011", "itrfslut", "ar")
compose_structure_query <- function(product = NULL, ...) {
  parts <- c(product, as.character(c(...)))
  parts <- parts[nzchar(parts)]
  paste(parts, collapse = "|")
}

#' Compose a data query string
#'
#' Builds the pipe-delimited query string used by the Trafa `/api/data`
#' endpoint.
#'
#' @param product Character: product code (e.g. `"t10011"`).
#' @param measure Character: measure name (e.g. `"itrfslut"`).
#' @param ... Named arguments where the name is a dimension and the value is
#'   a character vector of filter values (e.g. `ar = c("2023", "2024")`).
#' @return A character string (e.g. `"t10011|itrfslut|ar:2023,2024"`).
#' @export
#' @examples
#' compose_data_query("t10011", "itrfslut")
#' compose_data_query("t10011", "itrfslut", ar = "2024")
#' compose_data_query("t10011", "itrfslut", ar = c("2023", "2024"),
#'                    drivm = c("102", "103"))
compose_data_query <- function(product, measure, ...) {
  if (missing(product) || missing(measure)) {
    abort("Both product and measure are required.")
  }

  filters <- list(...)
  parts <- c(product, measure)

  for (dim_name in names(filters)) {
    values <- paste(as.character(filters[[dim_name]]), collapse = ",")
    parts <- c(parts, paste0(dim_name, ":", values))
  }

  paste(parts, collapse = "|")
}

#' Build a full Trafa API URL
#' @param endpoint "structure" or "data".
#' @param query The pipe-delimited query string.
#' @param lang Language code ("SV" or "EN").
#' @return Character URL.
#' @noRd
trafa_url <- function(endpoint, query = NULL, lang = NULL) {
  url <- paste0(trafa_base_url, "/api/", endpoint)

  params <- list()
  if (!is.null(query) && nzchar(query)) params$query <- query
  if (!is.null(lang)) params$lang <- lang

  if (length(params) == 0) return(url)

  query_str <- paste(
    names(params),
    vapply(params, as.character, character(1)),
    sep = "="
  )
  paste0(url, "?", paste(query_str, collapse = "&"))
}
