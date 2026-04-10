test_that("compose_structure_query builds pipe-delimited string", {
  expect_equal(compose_structure_query("t10011"), "t10011")
  expect_equal(compose_structure_query("t10011", "itrfslut"), "t10011|itrfslut")
  expect_equal(
    compose_structure_query("t10011", "itrfslut", "ar"),
    "t10011|itrfslut|ar"
  )
})

test_that("compose_structure_query returns empty string for NULL product", {
  expect_equal(compose_structure_query(), "")
})

test_that("compose_data_query builds pipe-delimited string with filters", {
  expect_equal(
    compose_data_query("t10011", "itrfslut"),
    "t10011|itrfslut"
  )
  expect_equal(
    compose_data_query("t10011", "itrfslut", ar = "2024"),
    "t10011|itrfslut|ar:2024"
  )
  expect_equal(
    compose_data_query("t10011", "itrfslut", ar = c("2023", "2024")),
    "t10011|itrfslut|ar:2023,2024"
  )
})

test_that("compose_data_query handles multiple dimension filters", {
  result <- compose_data_query("t10011", "itrfslut",
    ar = c("2023", "2024"),
    drivm = c("102", "103")
  )
  expect_match(result, "^t10011\\|itrfslut\\|")
  expect_match(result, "ar:2023,2024")
  expect_match(result, "drivm:102,103")
})

test_that("compose_data_query requires product and measure", {
  expect_error(compose_data_query(), "product.*measure")
})

test_that("trafa_url builds correct URLs", {
  url <- trafa_url("structure")
  expect_equal(url, "https://api.trafa.se/api/structure")

  url <- trafa_url("data", query = "t10011|itrfslut", lang = "SV")
  expect_equal(url, "https://api.trafa.se/api/data?query=t10011|itrfslut&lang=SV")

  url <- trafa_url("structure", lang = "EN")
  expect_equal(url, "https://api.trafa.se/api/structure?lang=EN")
})
