#' @rdname get_data
#' @section A name that cannot be masked:
#' `trafa_get_data()` is `get_data()` under a name no sister package exports.
#' pixieweb also exports a `get_data()`, so in a script that attaches both,
#' the package attached last masks the other and its calls fail on the wrong
#' argument check. Use `trafa_get_data()` here and `pixieweb::px_get_data()`
#' there, or prefix every call with its package.
#' @export
trafa_get_data <- function(...) {
  get_data(...)
}
