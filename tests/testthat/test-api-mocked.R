test_that("get_products parses mocked structure response", {
  mock_response <- list(
    StructureItems = list(
      list(Name = "t10011", Label = "Bussar", Description = "Antal bussar",
           Id = 1, ActiveFrom = "2020-01-01"),
      list(Name = "t20022", Label = "Lastbilar", Description = "",
           Id = 2, ActiveFrom = "2021-06-01")
    )
  )

  local_mocked_bindings(
    trafa_get = function(...) mock_response
  )

  result <- get_products(lang = "SV")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("t10011", "t20022"))
  expect_equal(result$label, c("Bussar", "Lastbilar"))
})

test_that("get_products returns NULL on API failure", {
  local_mocked_bindings(
    trafa_get = function(...) NULL
  )

  expect_null(get_products())
})

test_that("get_measures parses mocked response", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year"),
    list(Type = "M", Name = "itrfslut", Label = "In traffic",
         Description = "End of period"),
    list(Type = "M", Name = "avstslut", Label = "Deregistered",
         Description = "")
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_measures("t10011")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("itrfslut", "avstslut"))
})

test_that("get_dimensions parses mocked response with hierarchy", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year", DataType = "Time",
         Option = TRUE, Description = "",
         StructureItems = list(
           list(Type = "DV", Name = "2024", Label = "2024")
         )),
    list(Type = "M", Name = "itrfslut", Label = "Count",
         Description = "", StructureItems = list()),
    list(Type = "H", Name = "agare", Label = "Owner", Option = TRUE,
         StructureItems = list(
           list(Type = "D", Name = "agarkat", Label = "Owner category",
                DataType = "String", Option = TRUE, Description = "",
                StructureItems = list(
                  list(Type = "DV", Name = "10", Label = "Private")
                ))
         ))
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_dimensions("t10011")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("ar", "agarkat"))
  expect_true(is.na(result$hierarchy[1]))
  expect_equal(result$hierarchy[2], "agare")
})

test_that("get_data parses mocked data response", {
  mock_response <- list(
    Header = list(
      Column = list(
        list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
        list(Name = "itrfslut", Value = "Count", Type = "M", DataType = "String", Unit = "antal")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "itrfslut", Value = "1000", FormattedValue = "1 000", IsMeasure = TRUE)
      ))
    )
  )

  local_mocked_bindings(
    trafa_get = function(...) mock_response
  )

  result <- get_data("t10011", "itrfslut", ar = "2024")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$ar, "2024")
  expect_equal(result$itrfslut, 1000)
})

test_that("get_data returns NULL on API failure", {
  local_mocked_bindings(
    trafa_get = function(...) NULL
  )

  # get_data with no dimension filters now emits a helpful warning up-front;
  # the underlying API-failure path must still return NULL.
  expect_null(suppressWarnings(get_data("t10011", "itrfslut")))
})

test_that("get_data warns when called with no dimension filters", {
  # Stub the HTTP layer so the warning test doesn't fall through to the
  # "No data rows" warning emitted by parse_trafa_data.
  local_mocked_bindings(trafa_get = function(...) NULL)
  expect_warning(
    get_data("t10011", "itrfslut", query = NULL),
    "No dimension filters"
  )
})

test_that("trafa_available returns TRUE for successful response", {
  local_mocked_bindings(
    .package = "httr2",
    req_perform = function(...) {
      structure(list(status_code = 200L), class = "httr2_response")
    },
    resp_status = function(...) 200L
  )

  expect_true(trafa_available())
})
