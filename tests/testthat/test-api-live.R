skip_if_not(trafa_available(), "Trafa API not available")

test_that("get_products returns a non-empty tibble", {
  products <- get_products()
  expect_s3_class(products, "tbl_df")
  expect_gt(nrow(products), 0)
  expect_true(all(c("name", "label") %in% names(products)))
})

test_that("get_measures returns measures for a product", {
  measures <- get_measures("t10011")
  expect_s3_class(measures, "tbl_df")
  expect_gt(nrow(measures), 0)
  expect_true(all(c("name", "label", "product") %in% names(measures)))
})

test_that("get_dimensions returns dimensions with hierarchy info", {
  dims <- get_dimensions("t10011")
  expect_s3_class(dims, "tbl_df")
  expect_gt(nrow(dims), 0)
  expect_true("hierarchy" %in% names(dims))

  # Should include hierarchy children (e.g. agarkat under agare)
  has_hierarchy <- any(!is.na(dims$hierarchy))
  expect_true(has_hierarchy)
})

test_that("dimension_values includes filter shortcuts", {
  dims <- get_dimensions("t10011")
  ar_vals <- dimension_values(dims, "ar")
  expect_s3_class(ar_vals, "tbl_df")
  expect_true("type" %in% names(ar_vals))

  # Should have both filter and value types
  expect_true("filter" %in% ar_vals$type)
  expect_true("value" %in% ar_vals$type)
})

test_that("get_data returns data for a known product with filter", {
  measures <- get_measures("t10011")
  skip_if(is.null(measures) || nrow(measures) == 0, "No measures found")

  data <- get_data("t10011", measures$name[1], ar = "2024")
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
})

test_that("get_data works with filter shortcuts", {
  data <- get_data("t10011", "itrfslut", ar = "senaste")
  expect_s3_class(data, "tbl_df")
  expect_equal(nrow(data), 1)
})

test_that("product pipeline works end-to-end", {
  result <- get_products() |>
    product_search("t10") |>
    product_extract_ids()

  expect_type(result, "character")
})

test_that("get_dimensions with multi-measure returns intersection", {
  # itrfslut + nyregunder for Bussar should narrow to (mostly) just 'ar'
  multi <- get_dimensions("t10011", measure = c("itrfslut", "nyregunder"))
  single_a <- get_dimensions("t10011", measure = "itrfslut")
  single_b <- get_dimensions("t10011", measure = "nyregunder")

  # Multi result should be a subset of each single result
  expect_true(all(multi$name %in% single_a$name))
  expect_true(all(multi$name %in% single_b$name))
})

test_that("data_legend produces formatted caption with descriptions", {
  data <- get_data("t10011", "itrfslut", ar = "2024")
  legend <- data_legend(data)
  expect_match(legend, "K\u00e4lla: Trafa")
  expect_match(legend, "produkt:")
  expect_match(legend, "m\u00e5tt:")
  expect_match(legend, "t10011")
  expect_match(legend, "itrfslut")
})

test_that("data_legend respects omit_varname and omit_desc", {
  data <- get_data("t10011", "itrfslut", ar = "2024")

  no_codes <- data_legend(data, omit_varname = TRUE)
  expect_false(grepl("t10011", no_codes))
  expect_false(grepl("itrfslut", no_codes))

  no_labels <- data_legend(data, omit_desc = TRUE)
  expect_match(no_labels, "t10011")
  expect_match(no_labels, "itrfslut")
})

test_that("full discovery workflow: products -> measures -> dimensions -> data", {
  products <- get_products()
  pid <- product_extract_ids(product_search(products, "Bussar"))
  skip_if(length(pid) == 0, "No Bussar product found")

  measures <- get_measures(pid[1])
  mid <- measure_extract_names(measures)
  skip_if(length(mid) == 0, "No measures found")

  dims <- get_dimensions(pid[1], measure = mid[1])
  expect_gt(nrow(dims), 0)

  data <- get_data(pid[1], mid[1], ar = "senaste")
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
})
