# Love, 2026-10-06: get_data() stops with an error on a failed fetch. It used
# to return NULL with a warning, and a script that did not test for NULL went
# on and failed later on something unrelated.

data_answer <- function(rows) {
  list(
    Header = list(Column = list(
      list(Name = "ar", Value = "År", Type = "D"),
      list(Name = "itrfslut", Value = "Antal i trafik", Type = "M")
    )),
    Rows = rows
  )
}
one_row <- list(list(Cell = list(
  list(Column = "ar", Name = "2024", Value = "2024"),
  list(Column = "itrfslut", Value = "1000", IsMeasure = TRUE)
)))

test_that("a request that fails is an error of class rtrafa_fetch_failed", {
  local_mocked_bindings(
    trafa_get = function(url, ...) {
      rlang::warn(paste0("Trafa API returned HTTP 500 for: ", url))
      NULL
    },
    get_dimensions = function(...) NULL
  )
  expect_no_warning(
    err <- expect_error(get_data("t1", "itrfslut", ar = "2024"), class = "rtrafa_fetch_failed")
  )
  expect_false(inherits(err, "rtrafa_no_data"))
  expect_match(conditionMessage(err), "The fetch of product 't1', measure 'itrfslut'", fixed = TRUE)
  expect_match(conditionMessage(err), "HTTP 500", fixed = TRUE)
  expect_match(conditionMessage(err), "Request: https://api.trafa.se", fixed = TRUE)
  expect_equal(err$product, "t1")
  expect_equal(err$measure, "itrfslut")
  expect_match(err$url, "t1|itrfslut|ar:2024", fixed = TRUE)
  expect_length(err$reasons, 1)
})

test_that("an answer without rows is rtrafa_no_data, and also rtrafa_fetch_failed", {
  local_mocked_bindings(
    trafa_get = function(...) data_answer(list()),
    get_dimensions = function(...) NULL
  )
  expect_no_warning(
    err <- expect_error(get_data("t1", "itrfslut", ar = "2024"), class = "rtrafa_no_data")
  )
  expect_s3_class(err, "rtrafa_fetch_failed")
  expect_match(conditionMessage(err), "returned no data for product 't1'", fixed = TRUE)
  expect_match(conditionMessage(err), "No data rows in Trafa API response", fixed = TRUE)
  # The probe a caller writes
  expect_null(tryCatch(get_data("t1", "itrfslut", ar = "2024"), rtrafa_no_data = function(e) NULL))
})

test_that("an answer without columns is rtrafa_no_data", {
  local_mocked_bindings(
    trafa_get = function(...) list(Rows = list()),
    get_dimensions = function(...) NULL
  )
  expect_error(get_data("t1", "itrfslut", ar = "2024"), class = "rtrafa_no_data")
})

test_that("a raw query string that gives nothing is an error too", {
  local_mocked_bindings(trafa_get = function(...) NULL)
  expect_error(get_data(query = "t1|itrfslut|ar:2024"), class = "rtrafa_fetch_failed")
})

test_that("trafa_get_data() stops the same way", {
  local_mocked_bindings(trafa_get = function(...) NULL, get_dimensions = function(...) NULL)
  expect_error(trafa_get_data("t1", "itrfslut", ar = "2024"), class = "rtrafa_fetch_failed")
})

test_that("data that arrives is returned, and its warnings are warnings as before", {
  local_mocked_bindings(trafa_get = function(...) data_answer(one_row))
  expect_no_warning(res <- get_data("t1", "itrfslut", ar = "2024"))
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1)

  # Two rows that cannot be told apart: the hidden-breakdown warning, and the data
  local_mocked_bindings(trafa_get = function(...) data_answer(c(one_row, one_row)))
  expect_warning(res2 <- get_data("t1", "itrfslut", ar = "2024"), "hidden breakdown")
  expect_equal(nrow(res2), 2)
})
