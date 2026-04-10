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

test_that("data_legend formats SV caption with descriptions and codes", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  local_mocked_bindings(
    lookup_product_label = function(...) "Bussar",
    lookup_measure_label = function(...) "Antal i trafik"
  )

  legend <- data_legend(data_df, lang = "SV")
  expect_match(legend, "K\u00e4lla: Trafa")
  expect_match(legend, "produkt: Bussar \\(t10011\\)")
  expect_match(legend, "m\u00e5tt: Antal i trafik \\(itrfslut\\)")
})

test_that("data_legend formats EN caption", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "EN",
    fetched = Sys.time()
  )

  local_mocked_bindings(
    lookup_product_label = function(...) "Buses",
    lookup_measure_label = function(...) "In traffic"
  )

  legend <- data_legend(data_df, lang = "EN")
  expect_match(legend, "Source: Trafa")
  expect_match(legend, "product: Buses \\(t10011\\)")
  expect_match(legend, "measure: In traffic \\(itrfslut\\)")
})

test_that("data_legend omit_varname drops the codes", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  local_mocked_bindings(
    lookup_product_label = function(...) "Bussar",
    lookup_measure_label = function(...) "Antal i trafik"
  )

  legend <- data_legend(data_df, omit_varname = TRUE)
  expect_match(legend, "produkt: Bussar")
  expect_false(grepl("t10011", legend))
  expect_false(grepl("itrfslut", legend))
})

test_that("data_legend omit_desc drops the labels", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  local_mocked_bindings(
    lookup_product_label = function(...) "Bussar",
    lookup_measure_label = function(...) "Antal i trafik"
  )

  legend <- data_legend(data_df, omit_desc = TRUE)
  expect_match(legend, "produkt: t10011")
  expect_match(legend, "m\u00e5tt: itrfslut")
  expect_false(grepl("Bussar", legend))
  expect_false(grepl("Antal i trafik", legend))
})

test_that("data_legend falls back to code when label lookup fails", {
  data_df <- tibble::tibble(ar = "2024", val = 100)
  attr(data_df, "trafa_source") <- list(
    product = "t10011", measure = "itrfslut", lang = "SV",
    fetched = Sys.time()
  )

  local_mocked_bindings(
    lookup_product_label = function(...) NA_character_,
    lookup_measure_label = function(...) NA_character_
  )

  legend <- data_legend(data_df)
  expect_match(legend, "produkt: t10011")
  expect_match(legend, "m\u00e5tt: itrfslut")
})

test_that("data_legend returns empty string when no source attribute", {
  data_df <- tibble::tibble(x = 1)
  expect_equal(data_legend(data_df), "")
})

test_that("format_legend_field handles all combinations", {
  expect_equal(format_legend_field("Bussar", "t10011", FALSE, FALSE),
               "Bussar (t10011)")
  expect_equal(format_legend_field("Bussar", "t10011", TRUE, FALSE),
               "Bussar")
  expect_equal(format_legend_field("Bussar", "t10011", FALSE, TRUE),
               "t10011")
  expect_equal(format_legend_field(NA, "t10011", FALSE, FALSE),
               "t10011")
  expect_equal(format_legend_field("", "t10011", FALSE, FALSE),
               "t10011")
})
