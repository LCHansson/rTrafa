#' Check if the Trafa API is available
#'
#' Performs a lightweight HTTP check to verify that the Trafa API is
#' reachable. This is primarily useful for guarding examples and tests.
#'
#' @return `TRUE` if the API responds within 5 seconds, `FALSE` otherwise.
#'
#' @export
#' @examples
#' trafa_available()
trafa_available <- function() {
  tryCatch({
    resp <- httr2::request(paste0(trafa_base_url, "/api/structure")) |>
      httr2::req_timeout(5) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform()
    httr2::resp_status(resp) == 200
  }, error = function(e) FALSE)
}
