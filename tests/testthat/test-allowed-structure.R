# get_allowed_structure() and check_combination(), on structure answers
# recorded from the public API (helper-recorded-structure.R). No network.

sets_of <- function(s, measure) {
  lapply(s$sets$dimensions[s$sets$measure == measure], sort)
}
key <- function(x) paste(sort(x), collapse = ",")

# Every part of every set, as sorted keys (the time dimension left out).
parts_of <- function(sets) {
  out <- character(0)
  for (s in sets) {
    s <- setdiff(s, "ar")
    n <- length(s)
    for (i in 0:(2^n - 1)) out <- c(out, key(s[bitwAnd(i, 2^(seq_len(n) - 1)) > 0]))
  }
  unique(out)
}

test_that("t10011: the sets are the tables the product is built from", {
  asked <- new.env()
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011", asked))
  s <- get_allowed_structure("t10011")

  expect_s3_class(s, "trafa_allowed")
  expect_equal(s$product, "t10011")
  expect_equal(s$measures$name, c("itrfslut", "avstslut", "nyregunder", "avregunder"))
  expect_setequal(
    s$dimensions$name,
    c("ar", "avregform", "dimpo", "leasing", "bussklass", "drivm", "pass", "agarkat", "tillst")
  )
  # A dimension inside a hierarchy carries the hierarchy's name.
  expect_equal(s$dimensions$hierarchy[s$dimensions$name == "agarkat"], "agare")
  expect_true(is.na(s$dimensions$hierarchy[s$dimensions$name == "drivm"]))

  expect_setequal(
    vapply(sets_of(s, "itrfslut"), key, character(1)),
    c("ar,bussklass,leasing", "ar,leasing,pass", "agarkat,ar,tillst", "ar,drivm")
  )
  expect_equal(vapply(sets_of(s, "avstslut"), key, character(1)), "agarkat,ar,tillst")
  expect_equal(vapply(sets_of(s, "nyregunder"), key, character(1)), "ar,dimpo")
  expect_equal(vapply(sets_of(s, "avregunder"), key, character(1)), "ar,avregform")

  expect_equal(s$requests, asked$n)
  expect_equal(s$requests, 15L)
})

test_that("the sets hold exactly what the exhaustive walk finds", {
  cases <- list(
    t10011 = NULL,
    t10030 = NULL,
    # godsvikt: pairs alone would allow sets the API turns down
    t0802 = c("antalfar", "godsvikt")
  )
  for (product in names(cases)) {
    local_mocked_bindings(get_structure_raw = recorded_structure(product))
    measures <- cases[[product]] %||% unlist(recorded_fixture(product)$measures)
    s <- get_allowed_structure(product, measure = measures)
    walked <- 0L
    for (m in measures) {
      walk <- discover_allowed_combinations(product, m, cache = FALSE)
      found <- unique(vapply(walk$dimensions, function(d) key(setdiff(d, "ar")), character(1)))
      # A measure that takes no dimension, not even the year (t10030's
      # akumunyreg): the walk records nothing, here it is one empty set.
      if (length(found) == 0) found <- ""
      expect_setequal(parts_of(sets_of(s, m)), found)
      walked <- walked + length(found)
    }
    # ... in fewer requests than one per allowed set, where the product is large
    if (product == "t0802") expect_lt(s$requests, walked / 2)
  }
})

test_that("a measure that takes no dimension has one empty set", {
  local_mocked_bindings(get_structure_raw = recorded_structure("t10030"))
  s <- get_allowed_structure("t10030", measure = "akumunyreg")
  expect_equal(nrow(s$sets), 1L)
  expect_length(s$sets$dimensions[[1]], 0)
  expect_equal(s$requests, 2L)
})

test_that("a failed structure request stops everything", {
  # t0802's fixture holds four of its measures: the fifth is not answered
  local_mocked_bindings(get_structure_raw = recorded_structure("t0802"))
  err <- expect_error(get_allowed_structure("t0802", measure = "pax"), class = "rtrafa_structure_failed")
  expect_match(conditionMessage(err), "t0802|pax", fixed = TRUE)
  expect_equal(err$product, "t0802")

  expect_error(get_allowed_structure("t0802", measure = "godsvikt", max_requests = 20),
               class = "rtrafa_structure_failed")
  expect_error(get_allowed_structure("t0802", measure = "finns_inte"), "no measure named")
})

test_that("check_combination() answers from the structure and names what is in the way", {
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011"))
  s <- get_allowed_structure("t10011")
  local_mocked_bindings(get_structure_raw = function(...) stop("no request expected"))

  ok <- check_combination("t10011", "itrfslut", c("leasing", "pass"), allowed = s)
  expect_true(ok$allowed)
  expect_equal(ok$source, "structure")
  expect_true(check_combination("t10011", "itrfslut", allowed = s)$allowed)

  # a dimension the measure does not take at all
  no <- check_combination("t10011", "itrfslut", c("avregform", "drivm"), allowed = s)
  expect_false(no$allowed)
  expect_equal(no$not_for_measure, "avregform")
  expect_equal(no$fits, "drivm")

  # two dimensions the measure takes, but never together
  no <- check_combination("t10011", "itrfslut", c("drivm", "pass"), allowed = s)
  expect_false(no$allowed)
  expect_length(no$not_for_measure, 0)
  expect_length(no$fits, 1)

  expect_error(check_combination("t10030", "nyreg", allowed = s), "describes product")
  expect_error(check_combination("t10011", "finns_inte", allowed = s), "no measure named")
})

test_that("check_combination() without a structure asks the API once", {
  asked <- new.env()
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011", asked))
  yes <- check_combination("t10011", "itrfslut", c("leasing", "bussklass"))
  expect_true(yes$allowed)
  expect_equal(yes$source, "api")
  expect_false(check_combination("t10011", "itrfslut", "avregform")$allowed)
  expect_false(check_combination("t10011", "itrfslut", c("drivm", "pass"))$allowed)
  expect_equal(asked$n, 3L)
  # no answer: unknown, not "allowed"
  expect_true(is.na(check_combination("t10011", "itrfslut", c("tillst", "pass", "drivm"))$allowed))
})

test_that("printing a structure lists the sets", {
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011"))
  s <- get_allowed_structure("t10011", measure = "avstslut")
  expect_output(print(s), "avstslut: {ar, agarkat, tillst}", fixed = TRUE)
})

# AE order 20261020081922-uckmax: a set of one or two dimensions was accepted
# without reading the answer already fetched for it. Here the recorded answer
# for avregunder|ar|avregform is replaced by what the source gives for a
# selection it rules out (nothing flagged): the measure would take the
# dimension only without the year.
test_that("a set of one dimension the answer rules out is not accepted", {
  ruled_out <- list(`avregunder|ar|avregform` = list(m = list(), d = list()))
  asked <- new.env()
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011", asked, ruled_out))
  s <- get_allowed_structure("t10011", measure = "avregunder")
  expect_equal(vapply(sets_of(s, "avregunder"), key, character(1)), "ar")
  # no request beyond the ones already made
  expect_equal(s$requests, asked$n)
  expect_equal(s$requests, 3L)

  # The recorded answer, untouched, still gives the set
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011"))
  s2 <- get_allowed_structure("t10011", measure = "avregunder")
  expect_equal(vapply(sets_of(s2, "avregunder"), key, character(1)), "ar,avregform")
})

test_that("a pair is accepted only when the answer for each member allows it", {
  # itrfslut|ar|drivm stays recorded; ruling out drivm alone with the year
  # leaves drivm in no set
  ruled_out <- list(`itrfslut|ar|drivm` = list(m = list(), d = list()))
  local_mocked_bindings(get_structure_raw = recorded_structure("t10011", answers = ruled_out))
  s <- get_allowed_structure("t10011", measure = "itrfslut")
  expect_false("drivm" %in% unlist(s$sets$dimensions))
  expect_setequal(
    vapply(sets_of(s, "itrfslut"), key, character(1)),
    c("ar,bussklass,leasing", "ar,leasing,pass", "agarkat,ar,tillst")
  )
})
