# Recorded structure answers (tests/testthat/fixtures/structure-<product>.json),
# taken once from the public API on the date each file states. A file holds the
# product's items (`base`, values left out, their count kept) and, per selection
# that was asked, the names the API flagged as still selectable (`answers`:
# "<measure>|<dimensions>" -> measures `m`, dimensions `d`).
#
# recorded_structure(product) returns a stand-in for get_structure_raw() that
# answers from the file and returns NULL for a selection that was not recorded.

recorded_key <- function(parts) {
  parts <- as.character(parts)
  if (length(parts) == 0) return("")
  paste(c(parts[1], sort(parts[-1], method = "radix")), collapse = "|")
}

recorded_fixture <- function(product) {
  fx <- jsonlite::fromJSON(
    testthat::test_path("fixtures", paste0("structure-", product, ".json")),
    simplifyVector = FALSE
  )
  names(fx$answers) <- vapply(
    strsplit(names(fx$answers), "|", fixed = TRUE), recorded_key, character(1)
  )
  fx
}

recorded_structure <- function(product, asked = NULL, answers = list()) {
  fx <- recorded_fixture(product)
  # `answers` replaces recorded answers (same "<measure>|<dims>" keys)
  for (k in names(answers)) fx$answers[[recorded_key(strsplit(k, "|", fixed = TRUE)[[1]])]] <- answers[[k]]
  flag <- function(item, on) {
    item$Option <- on(item)
    item$StructureItems <- lapply(item$StructureItems %||% list(), flag, on = on)
    item
  }
  function(product, ..., lang = NULL, cache = FALSE, cache_location = NULL, verbose = FALSE) {
    parts <- as.character(c(...))
    if (!is.null(asked)) asked$n <- (asked$n %||% 0L) + 1L
    if (!identical(product, fx$product)) return(NULL)
    if (length(parts) == 0) return(lapply(fx$base, flag, on = function(item) TRUE))
    a <- fx$answers[[recorded_key(parts)]]
    if (is.null(a)) return(NULL)
    m <- unlist(a$m); d <- unlist(a$d)
    lapply(fx$base, flag, on = function(item) {
      if (identical(item$Type, "M")) item$Name %in% m
      else if (identical(item$Type, "D")) item$Name %in% d
      else FALSE
    })
  }
}
