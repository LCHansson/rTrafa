.onLoad <- function(libname, pkgname) {
  op <- options()
  op_rtrafa <- list(
    rTrafa.lang = "SV"
  )
  toset <- !(names(op_rtrafa) %in% names(op))
  if (any(toset)) options(op_rtrafa[toset])
  invisible()
}

.onAttach <- function(libname, pkgname) {
  msg <- masking_note(search())
  if (!is.null(msg)) packageStartupMessage(msg)
}

#' The note shown when a sister package with its own get_data() is attached
#' @param attached Character vector as returned by `search()`.
#' @return A string, or NULL when there is nothing to say.
#' @noRd
masking_note <- function(attached) {
  if (!"package:pixieweb" %in% attached) return(NULL)
  paste0(
    "rTrafa and pixieweb both export get_data(); the one attached last wins.
",
    "In a script that uses both, call trafa_get_data() and px_get_data() ",
    "(or rTrafa::get_data() and pixieweb::get_data())."
  )
}
