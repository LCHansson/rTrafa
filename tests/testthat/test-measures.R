test_that("get_measures extracts M-type items from mocked structure", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year"),
    list(Type = "M", Name = "itrfslut", Label = "In traffic",
         Description = "End of period"),
    list(Type = "M", Name = "nyregunder", Label = "New registrations",
         Description = "")
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_measures("t10011")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("itrfslut", "nyregunder"))
  expect_equal(result$product, c("t10011", "t10011"))
})

test_that("measure_search filters measures", {
  df <- tibble::tibble(
    product = rep("t1", 3),
    name = c("itrfslut", "avstslut", "nyregunder"),
    label = c("In traffic", "Deregistered", "New registrations"),
    description = c("End of period", "", "During period")
  )

  result <- measure_search(df, "traffic")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "itrfslut")
})

test_that("measure_describe returns invisibly for piping", {
  df <- tibble::tibble(
    product = "t1", name = "itrfslut",
    label = "In traffic", description = "End of period"
  )
  output <- capture.output(result <- measure_describe(df))
  expect_identical(result, df)
  expect_true(any(grepl("itrfslut", output)))
})

test_that("measure_describe warns on empty input", {
  expect_warning(measure_describe(empty_measures_tibble()), "No measures")
})

test_that("measure_extract_names returns name column", {
  df <- tibble::tibble(
    product = rep("t1", 2),
    name = c("itrfslut", "avstslut"),
    label = c("A", "B"), description = c("", "")
  )
  expect_equal(measure_extract_names(df), c("itrfslut", "avstslut"))
})

test_that("measure_extract_names returns empty for NULL", {
  expect_equal(measure_extract_names(NULL), character())
})
