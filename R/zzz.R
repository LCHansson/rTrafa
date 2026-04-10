.onLoad <- function(libname, pkgname) {
  op <- options()
  op_rtrafa <- list(
    rTrafa.lang = "SV"
  )
  toset <- !(names(op_rtrafa) %in% names(op))
  if (any(toset)) options(op_rtrafa[toset])
  invisible()
}
