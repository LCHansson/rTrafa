test_that("data_minimize removes monotonous columns from data", {
  data_df <- tibble::tibble(
    ar = c("2023", "2024"),
    drivm = c("102", "102"),
    itrfslut = c(100, 200)
  )
  result <- data_minimize(data_df)
  expect_true("ar" %in% names(result))
  expect_true("itrfslut" %in% names(result))
  expect_false("drivm" %in% names(result))
})

test_that("data_legend returns source string", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  legend <- data_legend(data_df)
  expect_match(legend, "Trafa")
  expect_match(legend, "t10011")
  expect_match(legend, "itrfslut")
})

test_that("data_legend includes dimension info when struct provided", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  struct <- tibble::tibble(
    product = "t10011", name = c("ar", "drivm"),
    label = c("Year", "Fuel"), type = c("D", "D"),
    data_type = c("Tid", "String"), option = c(TRUE, TRUE),
    selected = c(FALSE, FALSE), description = c("", ""),
    n_values = c(10L, 5L), values = list(NULL, NULL),
    parent_name = c(NA, NA)
  )

  legend <- data_legend(data_df, struct)
  expect_match(legend, "Year")
  expect_match(legend, "Fuel")
})
