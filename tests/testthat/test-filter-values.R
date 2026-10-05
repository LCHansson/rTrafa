# dev-backlog 2026-09-12: a filter value the dimension does not list (a year
# after the last published one) made the API answer HTTP 500, and get_data()
# returned nothing with a warning that did not mention the filter.

dims_fixture <- function() {
  vals <- function(codes, type = "value") {
    tibble::tibble(code = codes, text = codes, name = codes, label = codes,
                   type = type)
  }
  tibble::tibble(
    name = c("ar", "drivm", "empty"),
    option = c(TRUE, TRUE, TRUE),
    values = list(
      rbind(vals(as.character(2001:2025)), vals("senaste", "filter")),
      vals(c("101", "102")),
      NULL
    )
  )
}

test_that("unknown_filter_values finds values a dimension does not list", {
  found <- unknown_filter_values(
    dims_fixture(),
    list(ar = c("2024", "2026", "2027"), drivm = "101", "reglan", nope = "x",
         empty = "1")
  )
  expect_equal(names(found), "ar")
  expect_equal(found$ar$unknown, c("2026", "2027"))
  # Filter shortcuts the API resolves are values too
  expect_length(unknown_filter_values(dims_fixture(), list(ar = "senaste")), 0)
  expect_length(unknown_filter_values(NULL, list(ar = "2026")), 0)
  expect_length(unknown_filter_values(dims_fixture(), list()), 0)
})

test_that("selection_dimensions reads named filters and bare dimensions", {
  expect_equal(selection_dimensions(list(ar = "2024", "reglan")), c("ar", "reglan"))
  expect_equal(selection_dimensions(list("reglan")), "reglan")
  expect_equal(selection_dimensions(list()), character())
})

test_that("prepare_query() names the unknown value, and accepts bare dimensions", {
  local_mocked_bindings(
    get_measures = function(...) tibble::tibble(name = "itrfslut", label = "x"),
    get_dimensions = function(...) dims_fixture()
  )
  expect_warning(
    q <- prepare_query("t1", "itrfslut", ar = c("2025", "2026")),
    "'2026' not found in dimension 'ar' of product 't1'"
  )
  expect_s3_class(q, "trafa_query")
  expect_equal(q$selections, list(ar = c("2025", "2026")))
  expect_no_warning(prepare_query("t1", "itrfslut", ar = "2025", "drivm"))
})

test_that("get_data() explains an empty answer by the unknown filter value", {
  local_mocked_bindings(
    trafa_get = function(...) NULL,
    get_dimensions = function(...) dims_fixture()
  )
  expect_warning(
    res <- get_data("t1", "itrfslut", ar = "2026"),
    "'2026' not found in dimension 'ar'"
  )
  expect_null(res)
  # Valid values: nothing to add, and the return value is as before
  expect_no_warning(res2 <- get_data("t1", "itrfslut", ar = "2025"))
  expect_null(res2)
})

test_that("a failed structure lookup does not turn into an error", {
  local_mocked_bindings(
    trafa_get = function(...) NULL,
    get_dimensions = function(...) stop("offline")
  )
  expect_no_error(res <- get_data("t1", "itrfslut", ar = "2026"))
  expect_null(res)
})

test_that("live: a year the product does not list is named", {
  skip_on_cran()
  skip_if_not(trafa_available(), "Trafa API not available")
  w <- character()
  res <- withCallingHandlers(
    get_data("t10011", "itrfslut", ar = "2099"),
    warning = function(cnd) {
      w <<- c(w, conditionMessage(cnd))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(is.null(res) || nrow(res) == 0)
  expect_true(any(grepl("'2099' not found in dimension 'ar'", w, fixed = TRUE)))
})
