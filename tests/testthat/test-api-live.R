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
