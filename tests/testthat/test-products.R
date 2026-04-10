test_that("product_search filters product tibble", {
  products <- tibble::tibble(
    name = c("t10011", "t20022", "t30033"),
    label = c("Bussar i trafik", "Lastbilar", "Personbilar"),
    description = c("Antal bussar", "Antal lastbilar", "Antal personbilar"),
    id = 1:3,
    active_from = rep("2020-01-01", 3)
  )

  result <- product_search(products, "buss")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "t10011")
})

test_that("product_search is case-insensitive", {
  products <- tibble::tibble(
    name = c("t10011"), label = c("Bussar"),
    description = c(""), id = 1L, active_from = c("")
  )
  expect_equal(nrow(product_search(products, "BUSSAR")), 1)
})

test_that("product_describe returns invisibly for piping", {
  products <- tibble::tibble(
    name = c("t10011"), label = c("Bussar"),
    description = c("Antal bussar i trafik"), id = 1L,
    active_from = c("2020-01-01")
  )
  output <- capture.output(result <- product_describe(products))
  expect_identical(result, products)
  expect_true(any(grepl("t10011", output)))
  expect_true(any(grepl("Bussar", output)))
})

test_that("product_describe warns on empty input", {
  empty <- tibble::tibble(name = character(), label = character(),
                          description = character(), id = integer(),
                          active_from = character())
  expect_warning(product_describe(empty), "No products")
})

test_that("product_minimize removes monotonous columns", {
  products <- tibble::tibble(
    name = c("a", "b"), label = c("A", "B"),
    description = c("same", "same"), id = 1:2,
    active_from = c("2020", "2020")
  )
  result <- product_minimize(products)
  expect_true("name" %in% names(result))
  expect_false("description" %in% names(result))
})

test_that("product_extract_ids returns name column", {
  products <- tibble::tibble(
    name = c("t10011", "t20022"),
    label = c("A", "B"), description = c("", ""),
    id = 1:2, active_from = c("", "")
  )
  expect_equal(product_extract_ids(products), c("t10011", "t20022"))
})

test_that("product_extract_ids returns empty vector for empty input", {
  expect_equal(product_extract_ids(NULL), character())
  empty <- tibble::tibble(name = character())
  expect_equal(product_extract_ids(empty), character())
})
