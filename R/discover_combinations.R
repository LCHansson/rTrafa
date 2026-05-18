#' Discover allowed variable combinations via the Trafa API
#'
#' Enumerates all `(measure, dim-set)`-combinations that the Trafa API
#' will accept for a given product, by recursively probing the structure
#' endpoint via [get_dimensions()] with a growing measure-and-dimension
#' vector. The stopping condition is when the API returns no new
#' addable dimensions beyond the implicit `"ar"` (year).
#'
#' This replaces the earlier HTML-scraping approach (which read Trafa's
#' documentation pages directly) with a proper API-driven enumeration.
#' Same enumeration semantics, but using the documented `/api/structure`
#' endpoint instead of brittle CMS markup.
#'
#' @param product character(1). Trafa product code (e.g. "t10011").
#' @param measure character vector. One or more measure codes. When
#'   `NULL` (default) or longer than one, the function iterates over
#'   each measure and concatenates the results.
#' @param cache logical(1). Cache `get_dimensions()` results via
#'   nordstatExtras. Default `TRUE` — discovery makes many API calls per
#'   product so caching is essential for reasonable runtime on re-runs.
#' @param cache_location nordstatExtras handle (or a `trafa_cache_dir`)
#'   passed to [get_dimensions()].
#' @param verbose logical(1). Print per-query diagnostics: product,
#'   measure, current dim-set, and addable dimensions found.
#' @return A tibble with columns:
#' * `product`: character. Same as input.
#' * `measure`: character. Measure code.
#' * `dimensions`: list-col of character vectors. Each entry is a valid
#'   dimension-set (always includes `"ar"`) for the given
#'   `(product, measure)`.
#'
#' One row per `(product, measure, dim-set)` combination.
#'
#' @examples
#' \dontrun{
#' discover_allowed_combinations("t10011", "itrfslut")
#' discover_allowed_combinations("t10011")  # all measures
#' }
#'
#' @seealso [discover_all_allowed_combinations()] for batch discovery
#'   across all products.
#'
#' @export
discover_allowed_combinations <- function(product,
                                          measure = NULL,
                                          cache = TRUE,
                                          cache_location = trafa_cache_dir,
                                          verbose = FALSE) {
  stopifnot(is.character(product), length(product) == 1)

  # If no measure given or multiple measures, iterate
  if (is.null(measure) || length(measure) > 1) {
    meas_codes <- if (is.null(measure)) {
      m <- tryCatch(
        get_measures(product, cache = cache, cache_location = cache_location),
        error = function(e) NULL
      )
      if (is.null(m) || nrow(m) == 0) return(.empty_combos_tibble())
      as.character(m$name)
    } else as.character(measure)

    parts <- lapply(meas_codes, function(m) {
      discover_allowed_combinations(product, m,
                                    cache = cache,
                                    cache_location = cache_location,
                                    verbose = verbose)
    })
    return(dplyr::bind_rows(parts))
  }

  # Single-measure recursive enumeration
  if (verbose) message("[discover] ", product, " | ", measure)

  visited <- new.env(parent = emptyenv())
  combos <- list()

  visit <- function(dim_set) {
    # Prefix prevents the empty-set case ("") from being an invalid env name
    key <- paste0("k:", paste(sort(dim_set), collapse = "|"))
    if (exists(key, envir = visited)) return(invisible())
    assign(key, TRUE, envir = visited)

    query <- c(measure, dim_set)
    dims <- tryCatch(
      get_dimensions(product, measure = query,
                     cache = cache,
                     cache_location = cache_location),
      error = function(e) NULL
    )
    if (is.null(dims) || nrow(dims) == 0) return(invisible())

    returned <- as.character(dims$name)
    # "ar" is always implicit (Trafa requires it on every data call) and
    # the dims we already locked in are not new addables.
    addable <- setdiff(setdiff(returned, "ar"), dim_set)

    # Record current dim_set as a valid combination, with "ar" prepended
    combos[[length(combos) + 1L]] <<- sort(unique(c("ar", dim_set)))

    if (verbose && length(addable) > 0) {
      message("[discover]   {", key %||% "", "} addable: ",
              paste(addable, collapse = ","))
    }

    for (d in addable) visit(c(dim_set, d))
  }
  visit(character(0))

  if (length(combos) == 0) return(.empty_combos_tibble())

  # Deduplicate by canonical string representation
  ckeys <- vapply(combos, paste, collapse = ",", FUN.VALUE = character(1))
  combos_unique <- combos[!duplicated(ckeys)]

  tibble::tibble(
    product = product,
    measure = measure,
    dimensions = combos_unique
  )
}

#' Discover allowed combinations for every Trafa product
#'
#' Loops [get_products()] and calls [discover_allowed_combinations()]
#' for each. Per-product failures are caught and surfaced via
#' [warning()] so the batch run completes even when individual products
#' fail.
#'
#' First-pass runtime: ~10-20 minutes for ~57 products (depending on
#' product complexity and Trafa API latency). Subsequent passes with
#' the same `cache_location` are near-instant — each `get_dimensions()`
#' call is cached individually.
#'
#' @param cache logical(1). Passed to [discover_allowed_combinations()].
#'   Default `TRUE`.
#' @param cache_location nordstatExtras handle passed through.
#' @param verbose logical(1). Print per-product progress.
#' @return Combined tibble with the same columns as
#'   [discover_allowed_combinations()].
#'
#' @examples
#' \dontrun{
#' handle <- nordstatExtras::nxt_open("su_cache.sqlite")
#' combos <- discover_all_allowed_combinations(cache_location = handle,
#'                                             verbose = TRUE)
#' nordstatExtras::nxt_close(handle)
#' }
#'
#' @export
discover_all_allowed_combinations <- function(cache = TRUE,
                                              cache_location = NULL,
                                              verbose = FALSE) {
  prods <- get_products(cache = !is.null(cache_location),
                        cache_location = cache_location)
  if (is.null(prods) || nrow(prods) == 0) return(.empty_combos_tibble())
  if (verbose) message("[discover_all] products to process: ", nrow(prods))

  parts <- lapply(seq_len(nrow(prods)), function(i) {
    p <- prods$name[i]
    if (verbose) message("[discover_all] (", i, "/", nrow(prods), ") ", p)
    tryCatch(
      discover_allowed_combinations(p,
                                    cache = cache,
                                    cache_location = cache_location,
                                    verbose = verbose),
      error = function(e) {
        warning(sprintf("Discovery failed for product '%s': %s",
                        p, conditionMessage(e)))
        NULL
      }
    )
  })

  out <- dplyr::bind_rows(parts)
  if (verbose) {
    message("[discover_all] total rows: ", nrow(out),
            " | products with data: ", length(unique(out$product)))
  }
  if (nrow(out) == 0) return(.empty_combos_tibble())
  out
}

# Internal: empty tibble with the canonical column shape
.empty_combos_tibble <- function() {
  tibble::tibble(
    product = character(0),
    measure = character(0),
    dimensions = list()
  )
}
