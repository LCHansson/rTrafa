test_that("entity_search filters by text in character columns", {
  df <- tibble::tibble(
    name = c("alpha", "beta", "gamma"),
    label = c("First", "Second", "Third")
  )

  result <- entity_search(df, "bet")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "beta")
})

test_that("entity_search is case-insensitive", {
  df <- tibble::tibble(name = c("Alpha", "beta"), label = c("one", "two"))
  expect_equal(nrow(entity_search(df, "ALPHA")), 1)
  expect_equal(nrow(entity_search(df, "alpha")), 1)
})

test_that("entity_search supports OR-combined queries", {
  df <- tibble::tibble(name = c("a", "b", "c"), label = c("x", "y", "z"))
  result <- entity_search(df, c("a", "c"))
  expect_equal(nrow(result), 2)
})

test_that("entity_search warns on empty input", {
  df <- tibble::tibble(name = character())
  expect_warning(entity_search(df, "test"), "empty")
})

test_that("entity_search can restrict to specific columns", {
  df <- tibble::tibble(name = c("match", "no"), label = c("no", "match"))
  result <- entity_search(df, "match", column = "name")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "match")
})

test_that("remove_monotonous removes columns with a single unique value", {
  df <- tibble::tibble(a = c(1, 1, 1), b = c(1, 2, 3), c = c("x", "x", "x"))
  result <- remove_monotonous(df)
  expect_true("b" %in% names(result))
  expect_false("a" %in% names(result))
  expect_false("c" %in% names(result))
})

test_that("remove_monotonous returns input when 1 or 0 rows", {
  df1 <- tibble::tibble(a = 1, b = 2)
  expect_equal(remove_monotonous(df1), df1)
  expect_null(remove_monotonous(NULL))
})

test_that("resolve_lang defaults to SV", {
  expect_equal(resolve_lang(NULL), "SV")
  expect_equal(resolve_lang("en"), "EN")
  expect_equal(resolve_lang("SV"), "SV")
})

test_that("resolve_lang errors on invalid lang", {
  expect_error(resolve_lang("FR"), "SV.*EN")
})
