#' The whole allowed structure of a product, in one call
#'
#' Says, for every measure of a product, which dimensions can be chosen
#' together. It is what a form needs to switch off the choices that cannot be
#' combined with what is already chosen, without asking the API on every
#' click.
#'
#' **What the Trafa API states, and how.** The structure endpoint answers one
#' selection at a time: given a product, a measure and some dimensions, every
#' item of the product comes back with an `Option` flag that says whether it
#' can still be added. It publishes no list of allowed combinations. A
#' selection that cannot be combined comes back with every flag `FALSE`, and
#' the *data* endpoint does not refuse it: it answers with no rows, or with a
#' lone total row for a dimension it cannot break down by. A dimension lists
#' the same values whatever the measure, so the structure says nothing about
#' which *values* hold data.
#'
#' **What is returned.** For each measure, its largest allowed sets of
#' dimensions (`sets`). A selection is allowed when it is part of one of
#' them. In practice a set is one of the tables the product is built from.
#'
#' **How this function asks.** One request for the product; per measure one
#' request for the dimensions it can take, one per such dimension for what
#' can be chosen beside it, and then one per candidate set (the largest
#' groups of dimensions that can all be paired with each other; a candidate
#' the API turns down is tried again with one dimension less). This rests on
#' one assumption: a part of an allowed set is itself allowed. The package's
#' tests compare the result with the exhaustive walk of
#' [discover_allowed_combinations()] on recorded products, where they agree.
#' The exhaustive walk needs one request per allowed set, for a large product
#' more than a thousand; this function needs a fraction of that.
#'
#' The time dimension `ar`, which every data request must carry, is part of
#' every request made here when the measure can take it, and of every set.
#'
#' **Structure is not data.** A combination the structure allows can still
#' hold no rows; see `verify` in [discover_allowed_combinations()].
#'
#' @param product character(1). Trafa product code (e.g. `"t10011"`).
#' @param measure character vector of measure codes, or `NULL` (default) for
#'   every measure of the product.
#' @param max_requests integer(1). Stop with an error rather than make more
#'   structure requests than this. Default 2000.
#' @param lang Language code, `"SV"` or `"EN"`.
#' @param cache,cache_location Passed to the structure requests.
#' @param verbose logical(1). Print one line per measure.
#' @return A list of class `trafa_allowed`:
#' * `product`: the product code.
#' * `measures`: tibble `name`, `label`.
#' * `dimensions`: tibble `name`, `label`, `hierarchy`, `n_values`.
#' * `sets`: tibble `measure`, `dimensions` (a list-column of character
#'   vectors): the largest allowed sets, one row each. A measure the
#'   structure gives no dimension at all has one row with an empty set.
#' * `requests`: how many structure requests were made.
#' * `fetched`: when.
#'
#' The function stops with an error of class `rtrafa_structure_failed` when a
#' structure request fails or `max_requests` is passed: half a structure
#' would switch off choices that exist.
#'
#' @examples
#' \dontrun{
#' s <- get_allowed_structure("t10011")
#' s$sets
#' check_combination("t10011", "itrfslut", c("drivm", "pass"), allowed = s)
#' }
#'
#' @seealso [check_combination()], [discover_allowed_combinations()]
#' @export
get_allowed_structure <- function(product,
                                  measure = NULL,
                                  max_requests = 2000L,
                                  lang = NULL,
                                  cache = FALSE,
                                  cache_location = trafa_cache_dir,
                                  verbose = FALSE) {
  stopifnot(is.character(product), length(product) == 1)
  requests <- 0L
  fail <- function(...) {
    abort(c(sprintf("The structure of product '%s' could not be read.", product), ...,
            i = "Nothing is returned: half a structure would rule out choices that exist."),
          class = "rtrafa_structure_failed", product = product)
  }
  ask <- function(parts = character(0)) {
    if (requests >= max_requests) {
      fail(x = sprintf("It takes more than %d structure requests (`max_requests`).", max_requests))
    }
    requests <<- requests + 1L
    items <- suppressWarnings(get_structure_raw(
      product, parts, lang = lang, cache = cache, cache_location = cache_location
    ))
    if (is.null(items)) {
      fail(x = paste0("No answer for the selection: ", paste(c(product, parts), collapse = "|")))
    }
    structure_options(items)
  }

  base <- ask()
  measures <- base[base$type == "M", c("name", "label")]
  dimensions <- base[base$type == "D", c("name", "label", "hierarchy", "n_values")]
  wanted <- if (is.null(measure)) measures$name else as.character(measure)
  unknown <- setdiff(wanted, measures$name)
  if (length(unknown) > 0) {
    abort(sprintf("Product '%s' has no measure named %s.", product,
                  paste0("'", unknown, "'", collapse = ", ")))
  }

  rows <- list()
  for (m in wanted) {
    before <- requests
    alone <- ask(m)
    own <- alone$name[alone$type == "D" & alone$option]
    always <- intersect("ar", own)
    free <- setdiff(own, always)

    # What can be chosen beside each dimension.
    beside <- lapply(free, function(d) {
      a <- ask(c(m, always, d))
      intersect(free, setdiff(a$name[a$type == "D" & a$option], d))
    })
    names(beside) <- free
    paired <- function(a, b) b %in% beside[[a]] && a %in% beside[[b]]

    # Candidates: the largest groups in which every pair can be combined.
    # One or two dimensions are known from the answers above; a larger
    # candidate is put to the API, and one it turns down is tried again
    # with each dimension left out, larger sets always before smaller.
    found <- list()
    inside <- function(s, sets) any(vapply(sets, function(k) all(s %in% k), logical(1)))
    level <- largest_groups(free, paired)
    while (length(level) > 0) {
      size <- max(lengths(level))
      now <- level[lengths(level) == size]
      level <- level[lengths(level) < size]
      for (s in now) {
        if (inside(s, found)) next
        ok <- length(s) <= 2 || selection_allowed(ask(c(m, always, s)), m, c(always, s))
        if (ok) {
          found[[length(found) + 1L]] <- s
        } else {
          smaller <- lapply(s, function(x) setdiff(s, x))
          level <- c(level, smaller)
        }
      }
      keys <- vapply(level, paste, character(1), collapse = "|")
      level <- level[!duplicated(keys)]
    }
    if (length(found) == 0) found <- list(character(0))
    if (verbose) {
      message("[allowed] ", product, " | ", m, ": ", length(found), " set(s), ",
              requests - before, " request(s)")
    }
    for (s in found) {
      rows[[length(rows) + 1L]] <- tibble::tibble(measure = m, dimensions = list(c(always, s)))
    }
  }

  structure(
    list(
      product = product,
      measures = tibble::as_tibble(measures),
      dimensions = tibble::as_tibble(dimensions),
      sets = dplyr::bind_rows(rows),
      requests = requests,
      fetched = Sys.time()
    ),
    class = "trafa_allowed"
  )
}

#' @export
print.trafa_allowed <- function(x, ...) {
  cat(sprintf("<trafa_allowed> %s: %d measure(s), %d dimension(s), %d request(s)\n",
              x$product, nrow(x$measures), nrow(x$dimensions), x$requests))
  for (i in seq_len(nrow(x$sets))) {
    cat("  ", x$sets$measure[i], ": {", paste(x$sets$dimensions[[i]], collapse = ", "), "}\n", sep = "")
  }
  invisible(x)
}

#' Can this measure and these dimensions be combined?
#'
#' With `allowed` (the answer of [get_allowed_structure()]) the question is
#' answered from it, without a request, and the answer names what stands in
#' the way. Without it, one structure request is made for exactly this
#' selection and the API's own verdict is returned: a selection that cannot
#' be combined comes back with the chosen items flagged as not selectable.
#'
#' The data endpoint does not refuse a selection the structure rules out (it
#' answers with no rows or with a lone total row), so this is the check to
#' make before a fetch.
#'
#' @param product character(1). Product code.
#' @param measure character(1). Measure code.
#' @param dimensions character vector of dimension codes (without values).
#' @param allowed A `trafa_allowed` object, or `NULL` to ask the API.
#' @param lang,cache,cache_location Passed to the structure request.
#' @return A list: `allowed` (`TRUE`, `FALSE`, or `NA` when the API could not
#'   be asked), `source` (`"structure"` or `"api"`), and, filled only when
#'   `allowed` was given, `not_for_measure` (the dimensions the measure
#'   cannot take at all) and `fits` (the largest part of the remaining
#'   dimensions that one allowed set holds).
#' @examples
#' \dontrun{
#' check_combination("t10011", "itrfslut", c("drivm", "pass"))
#' }
#' @seealso [get_allowed_structure()]
#' @export
check_combination <- function(product, measure, dimensions = character(0),
                              allowed = NULL, lang = NULL, cache = FALSE,
                              cache_location = trafa_cache_dir) {
  stopifnot(is.character(product), length(product) == 1,
            is.character(measure), length(measure) == 1)
  dimensions <- unique(as.character(dimensions))

  if (!is.null(allowed)) {
    if (!inherits(allowed, "trafa_allowed")) abort("`allowed` must come from `get_allowed_structure()`.")
    if (!identical(allowed$product, product)) {
      abort(sprintf("`allowed` describes product '%s', not '%s'.", allowed$product, product))
    }
    sets <- allowed$sets$dimensions[allowed$sets$measure == measure]
    if (length(sets) == 0) {
      abort(sprintf("`allowed` holds no measure named '%s' for product '%s'.", measure, product))
    }
    not_for_measure <- setdiff(dimensions, unlist(sets))
    left <- setdiff(dimensions, not_for_measure)
    held <- vapply(sets, function(s) sum(left %in% s), integer(1))
    best <- sets[[which.max(held)]]
    return(list(
      allowed = length(not_for_measure) == 0 && max(held) == length(left),
      source = "structure",
      not_for_measure = not_for_measure,
      fits = intersect(left, best)
    ))
  }

  items <- tryCatch(
    suppressWarnings(get_structure_raw(product, c(measure, dimensions), lang = lang,
                                       cache = cache, cache_location = cache_location)),
    error = function(e) NULL
  )
  verdict <- if (is.null(items)) NA else selection_allowed(structure_options(items), measure, dimensions)
  list(allowed = verdict, source = "api", not_for_measure = character(0), fits = character(0))
}

#' The API's verdict on the selection an answer was asked for
#'
#' @param opt Answer of `structure_options()`.
#' @param measure,dimensions What was selected.
#' @return `TRUE` when the measure and every selected dimension are in the
#'   answer and flagged as options.
#' @noRd
selection_allowed <- function(opt, measure, dimensions) {
  m <- opt[opt$type == "M" & opt$name == measure, ]
  d <- opt[opt$type == "D" & opt$name %in% dimensions, ]
  nrow(m) == 1 && all(dimensions %in% d$name) && all(m$option) && all(d$option)
}

#' The largest groups in which every pair passes `paired`
#'
#' @param items character vector.
#' @param paired function(a, b) returning one logical.
#' @return A list of character vectors (each in the order of `items`); the
#'   single empty group when `items` is empty.
#' @noRd
largest_groups <- function(items, paired) {
  out <- list()
  grow <- function(group, candidates, done) {
    if (length(candidates) == 0 && length(done) == 0) {
      out[[length(out) + 1L]] <<- items[items %in% group]
      return(invisible())
    }
    for (v in candidates) {
      near <- function(xs) xs[vapply(xs, function(x) paired(v, x), logical(1))]
      grow(c(group, v), near(setdiff(candidates, v)), near(done))
      candidates <- setdiff(candidates, v)
      done <- c(done, v)
    }
  }
  grow(character(0), items, character(0))
  out
}

#' Flatten a structure answer to one row per measure and dimension
#'
#' Dimensions inside a hierarchy are listed with the hierarchy's name; their
#' own `Option` flag is what counts (the hierarchy's flag is `FALSE` also for
#' measures its dimensions can be combined with).
#'
#' @param items List of StructureItems, as `get_structure_raw()` returns.
#' @return A tibble: `type` ("M" or "D"), `name`, `label`, `option`,
#'   `hierarchy`, `n_values`.
#' @noRd
structure_options <- function(items) {
  out <- list()
  add <- function(item, hierarchy) {
    kids <- item$StructureItems %||% list()
    kinds <- vapply(kids, function(x) x$Type %||% "", character(1))
    # A recorded answer may carry the count instead of the values themselves.
    n_values <- item$nValues %||% sum(kinds == "DV")
    out[[length(out) + 1L]] <<- tibble::tibble(
      type = item$Type %||% NA_character_,
      name = item$Name %||% NA_character_,
      label = item$Label %||% NA_character_,
      option = isTRUE(item$Option),
      hierarchy = hierarchy,
      n_values = as.integer(n_values)
    )
  }
  for (item in items) {
    type <- item$Type %||% ""
    if (type %in% c("M", "D")) {
      add(item, NA_character_)
    } else if (type == "H") {
      for (child in item$StructureItems %||% list()) {
        if (identical(child$Type, "D")) add(child, item$Name %||% NA_character_)
      }
    }
  }
  if (length(out) == 0) {
    return(tibble::tibble(type = character(), name = character(), label = character(),
                          option = logical(), hierarchy = character(), n_values = integer()))
  }
  dplyr::bind_rows(out)
}
