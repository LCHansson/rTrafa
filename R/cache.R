#' Get the persistent rTrafa cache directory
#'
#' Returns the path to the user-level cache directory for rTrafa, creating it
#' if it does not exist. Uses [tools::R_user_dir()] so the cache survives
#' across R sessions.
#'
#' @return A single character string (directory path).
#' @export
#' @examples
#' trafa_cache_dir()
trafa_cache_dir <- function() {
  dir <- tools::R_user_dir("rTrafa", "cache")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  dir
}

#' Build a cache filename from entity + key_params
#' @noRd
cache_filename <- function(entity, key_params) {
  sorted_keys <- key_params[order(names(key_params))]
  hash_input <- paste(
    names(sorted_keys),
    vapply(sorted_keys, function(x) paste(x, collapse = ","), character(1)),
    sep = "=", collapse = ";"
  )
  hash_full <- rlang::hash(hash_input)
  hash_short <- substr(hash_full, 1, 12)

  paste0("rtrafa_", entity, "_", hash_short, "_", Sys.Date(), ".rds")
}

#' Create a cache handler
#'
#' Returns a function that manages caching of API responses.
#'
#' @param entity Character entity name (e.g. "products", "structure").
#' @param cache Logical, whether to enable caching.
#' @param cache_location Directory for cache files. Defaults to `trafa_cache_dir`.
#' @param key_params A named list of values that form a unique cache key.
#' @return A function with signature `(method, df)` where method is
#'   "discover", "load", or "store".
#' @noRd
cache_handler <- function(entity, cache, cache_location, key_params = list()) {
  if (is.function(cache_location)) {
    cache_location <- cache_location()
  }

  storage <- if (isTRUE(cache)) {
    file.path(cache_location, cache_filename(entity, key_params))
  } else {
    ""
  }

  if (storage == "") {
    return(function(method, df = NULL) {
      if (method == "store") return(df)
      return(FALSE)
    })
  }

  function(method, df = NULL) {
    switch(method,
      discover = file.exists(storage),
      load = readRDS(storage),
      store = {
        saveRDS(df, file = storage)
        return(df)
      },
      NULL
    )
  }
}

#' Clear rTrafa cache files
#'
#' Removes cached API responses stored in the default or specified location.
#'
#' @param entity Character entity to clear (e.g. `"products"`, `"structure"`),
#'   or `NULL` (default) to clear all rTrafa cache files.
#' @param cache_location Directory to clear. Defaults to [trafa_cache_dir()].
#' @return `invisible(NULL)`
#' @export
#' @examples
#' \donttest{
#' if (trafa_available()) {
#'   trafa_clear_cache()
#'   trafa_clear_cache(entity = "products")
#' }}
trafa_clear_cache <- function(entity = NULL,
                              cache_location = trafa_cache_dir()) {
  entity_part <- if (!is.null(entity)) entity else "[^_]+"
  pattern <- paste0("^rtrafa_", entity_part, "_[a-f0-9]+_.*\\.rds$")

  files <- list.files(cache_location, pattern = pattern, full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    inform(paste("Removed", length(files), "cached file(s)."))
  } else {
    inform("No rTrafa cache files found.")
  }

  invisible(NULL)
}
