test_that("get_dimensions extracts D-type items including hierarchy children", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year", DataType = "Time",
         Option = TRUE, Description = "",
         StructureItems = list(
           list(Type = "F", Name = "senaste", Label = "Latest"),
           list(Type = "DV", Name = "2023", Label = "2023"),
           list(Type = "DV", Name = "2024", Label = "2024")
         )),
    list(Type = "D", Name = "drivm", Label = "Fuel", DataType = "String",
         Option = TRUE, Description = "",
         StructureItems = list(
           list(Type = "DV", Name = "101", Label = "Petrol"),
           list(Type = "DV", Name = "102", Label = "Diesel")
         )),
    list(Type = "M", Name = "itrfslut", Label = "Count",
         Description = "", StructureItems = list()),
    list(Type = "H", Name = "agare", Label = "Owner", Option = TRUE,
         StructureItems = list(
           list(Type = "D", Name = "agarkat", Label = "Owner cat",
                DataType = "String", Option = TRUE, Description = "",
                StructureItems = list(
                  list(Type = "DV", Name = "10", Label = "Private"),
                  list(Type = "DV", Name = "20", Label = "Public")
                ))
         ))
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_dimensions("t10011")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(result$name, c("ar", "drivm", "agarkat"))

  # Hierarchy column
  expect_true(is.na(result$hierarchy[1]))
  expect_true(is.na(result$hierarchy[2]))
  expect_equal(result$hierarchy[3], "agare")
})

test_that("get_dimensions includes F-type filters in values", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year", DataType = "Time",
         Option = TRUE, Description = "",
         StructureItems = list(
           list(Type = "F", Name = "senaste", Label = "Latest"),
           list(Type = "DV", Name = "2024", Label = "2024")
         ))
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_dimensions("t10011")
  vals <- result$values[[1]]
  expect_equal(nrow(vals), 2)
  expect_equal(vals$type, c("filter", "value"))
  expect_equal(vals$name, c("senaste", "2024"))

  # n_values counts only regular values, not filters
  expect_equal(result$n_values[1], 1L)
})

test_that("get_dimensions accepts a vector of measures", {
  captured_extra <- NULL
  local_mocked_bindings(
    get_structure_raw = function(product, ..., lang = NULL, cache = FALSE,
                                 cache_location = NULL, verbose = FALSE) {
      captured_extra <<- as.character(c(...))
      list(
        list(Type = "D", Name = "ar", Label = "Year", DataType = "Time",
             Option = TRUE, Description = "", StructureItems = list())
      )
    }
  )

  result <- get_dimensions("t10011", measure = c("itrfslut", "nyregunder"))
  expect_equal(captured_extra, c("itrfslut", "nyregunder"))
  expect_equal(nrow(result), 1)
})

test_that("get_dimensions excludes invalid dims when only_valid = TRUE", {
  mock_items <- list(
    list(Type = "D", Name = "ar", Label = "Year", DataType = "Time",
         Option = TRUE, Description = "", StructureItems = list()),
    list(Type = "D", Name = "bad", Label = "Invalid", DataType = "String",
         Option = FALSE, Description = "", StructureItems = list())
  )

  local_mocked_bindings(
    get_structure_raw = function(...) mock_items
  )

  result <- get_dimensions("t10011", measure = "itrfslut", only_valid = TRUE)
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "ar")

  result_all <- get_dimensions("t10011", measure = "itrfslut", only_valid = FALSE)
  expect_equal(nrow(result_all), 2)
})

test_that("dimension_search filters by text", {
  df <- tibble::tibble(
    product = rep("t1", 3),
    name = c("ar", "drivm", "agarkat"),
    label = c("Year", "Fuel type", "Owner category"),
    data_type = rep("String", 3), option = rep(TRUE, 3),
    description = rep("", 3), hierarchy = c(NA, NA, "agare"),
    n_values = c(10L, 5L, 3L),
    values = list(NULL, NULL, NULL)
  )

  result <- dimension_search(df, "fuel")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "drivm")
})

test_that("dimension_values extracts values for a dimension", {
  vals_tbl <- tibble::tibble(
    name = c("senaste", "2023", "2024"),
    label = c("Latest", "2023", "2024"),
    type = c("filter", "value", "value")
  )
  df <- tibble::tibble(
    product = "t1", name = "ar", label = "Year",
    data_type = "Time", option = TRUE,
    description = "", hierarchy = NA_character_,
    n_values = 2L, values = list(vals_tbl)
  )

  result <- dimension_values(df, "ar")
  expect_equal(nrow(result), 3)
  expect_equal(result$type, c("filter", "value", "value"))
})

test_that("dimension_values warns on missing dimension", {
  df <- tibble::tibble(
    product = "t1", name = "ar", label = "Year",
    data_type = "Time", option = TRUE,
    description = "", hierarchy = NA_character_,
    n_values = 0L, values = list(NULL)
  )
  expect_warning(dimension_values(df, "missing"), "not found")
})

test_that("dimension_extract_names returns name column", {
  df <- tibble::tibble(
    product = rep("t1", 2),
    name = c("ar", "drivm"), label = c("Year", "Fuel"),
    data_type = rep("String", 2), option = rep(TRUE, 2),
    description = rep("", 2), hierarchy = rep(NA_character_, 2),
    n_values = c(10L, 5L), values = list(NULL, NULL)
  )
  expect_equal(dimension_extract_names(df), c("ar", "drivm"))
})

test_that("dimension_describe shows hierarchy tag", {
  df <- tibble::tibble(
    product = "t1", name = "agarkat", label = "Owner cat",
    data_type = "String", option = TRUE,
    description = "", hierarchy = "agare",
    n_values = 2L,
    values = list(tibble::tibble(
      name = c("10", "20"), label = c("Private", "Public"),
      type = c("value", "value")
    ))
  )
  output <- capture.output(dimension_describe(df))
  expect_true(any(grepl("agare", output)))
  expect_true(any(grepl("agarkat", output)))
})
