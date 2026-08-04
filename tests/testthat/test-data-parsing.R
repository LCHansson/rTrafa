test_that("parse_trafa_data handles typical API response", {
  raw <- list(
    Header = list(
      Column = list(
        list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
        list(Name = "drivm", Value = "Fuel type", Type = "D", DataType = "String", Unit = ""),
        list(Name = "itrfslut", Value = "In traffic", Type = "M", DataType = "String", Unit = "antal")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "drivm", Name = "102", Value = "Diesel", IsMeasure = FALSE),
        list(Column = "itrfslut", Value = "10086", FormattedValue = "10 086", IsMeasure = TRUE)
      )),
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "drivm", Name = "103", Value = "Petrol", IsMeasure = FALSE),
        list(Column = "itrfslut", Value = "5432", FormattedValue = "5 432", IsMeasure = TRUE)
      ))
    )
  )

  result <- parse_trafa_data(raw, simplify = TRUE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("ar" %in% names(result))
  expect_true("ar_label" %in% names(result))
  expect_true("drivm" %in% names(result))
  expect_true("drivm_label" %in% names(result))
  expect_true("itrfslut" %in% names(result))

  expect_equal(result$ar, c("2024", "2024"))
  expect_equal(result$drivm, c("102", "103"))
  expect_equal(result$drivm_label, c("Diesel", "Petrol"))
  expect_equal(result$itrfslut, c(10086, 5432))
})

test_that("parse_trafa_data without simplify omits label columns", {
  raw <- list(
    Header = list(
      Column = list(
        list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
        list(Name = "itrfslut", Value = "Count", Type = "M", DataType = "String", Unit = "")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "itrfslut", Value = "100", FormattedValue = "100", IsMeasure = TRUE)
      ))
    )
  )

  result <- parse_trafa_data(raw, simplify = FALSE)
  expect_true("ar" %in% names(result))
  expect_false("ar_label" %in% names(result))
})

test_that("parse_trafa_data handles Swedish decimal format", {
  raw <- list(
    Header = list(
      Column = list(
        list(Name = "val", Value = "Value", Type = "M", DataType = "String", Unit = "")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "val", Value = "1234,56", FormattedValue = "1 234,56", IsMeasure = TRUE)
      ))
    )
  )

  result <- parse_trafa_data(raw, simplify = FALSE)
  expect_equal(result$val, 1234.56)
})

test_that("parse_trafa_data warns on empty response", {
  raw_no_cols <- list(Header = list(Column = list()), Rows = list())
  expect_warning(parse_trafa_data(raw_no_cols), "No columns")

  raw_no_rows <- list(
    Header = list(Column = list(
      list(Name = "x", Value = "X", Type = "D", DataType = "String", Unit = "")
    )),
    Rows = list()
  )
  expect_warning(parse_trafa_data(raw_no_rows), "No data rows")
})

test_that("parse_trafa_data warns on hidden-breakdown ambiguity", {
  # Mimics t0802|godsvikt|ar:2024: the API returns many rows per year
  # without including the breaking-down dimension in the response.
  raw <- list(
    Header = list(
      Column = list(
        list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
        list(Name = "godsvikt", Value = "Goods", Type = "M", DataType = "String", Unit = "ton")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "godsvikt", Value = "163757", IsMeasure = TRUE)
      )),
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "godsvikt", Value = "66381", IsMeasure = TRUE)
      ))
    )
  )
  expect_warning(
    result <- parse_trafa_data(raw, simplify = TRUE),
    "unique dimension combination"
  )
  # Data still returned — the caller decides; the warning names the trap.
  expect_equal(nrow(result), 2)
})

test_that("parse_trafa_data does not warn when dimensions disambiguate", {
  raw <- list(
    Header = list(
      Column = list(
        list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
        list(Name = "svkust", Value = "Coast", Type = "D", DataType = "String", Unit = ""),
        list(Name = "godsvikt", Value = "Goods", Type = "M", DataType = "String", Unit = "ton")
      )
    ),
    Rows = list(
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "svkust", Name = "t1", Value = "Totalt", IsMeasure = FALSE),
        list(Column = "godsvikt", Value = "163757", IsMeasure = TRUE)
      )),
      list(Cell = list(
        list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
        list(Column = "svkust", Name = "01", Value = "Ostkusten", IsMeasure = FALSE),
        list(Column = "godsvikt", Value = "66381", IsMeasure = TRUE)
      ))
    )
  )
  expect_no_warning(parse_trafa_data(raw, simplify = TRUE))
})

test_that("empty response warning points at discover_allowed_combinations", {
  raw <- list(
    Header = list(Column = list(
      list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = "")
    )),
    Rows = list()
  )
  expect_warning(parse_trafa_data(raw), "discover_allowed_combinations")
})
