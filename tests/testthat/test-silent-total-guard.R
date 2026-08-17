# Silent-total guard: a bare dimension (requested breakdown) that comes back
# with a single value must warn — dev-backlog 2026-08-17 (t10030 heavy trucks
# returned a lone drivm = "t1" row and read as 0 % electrification).

make_response <- function(drivm_codes, drivm_labels = drivm_codes) {
  rows <- lapply(seq_along(drivm_codes), function(i) {
    list(Cell = list(
      list(Column = "ar", Name = "2024", Value = "2024", IsMeasure = FALSE),
      list(Column = "drivm", Name = drivm_codes[i], Value = drivm_labels[i],
           IsMeasure = FALSE),
      list(Column = "nyreg", Value = as.character(1000 + i), IsMeasure = TRUE)
    ))
  })
  list(
    Header = list(Column = list(
      list(Name = "ar", Value = "Year", Type = "D", DataType = "Tid", Unit = ""),
      list(Name = "drivm", Value = "Drivmedel", Type = "D",
           DataType = "String", Unit = ""),
      list(Name = "nyreg", Value = "Nyregistreringar", Type = "M",
           DataType = "String", Unit = "antal")
    )),
    Rows = rows
  )
}

test_that("bare dimension collapsing to a single value warns", {
  local_mocked_bindings(
    trafa_get = function(...) make_response("t1", "Totalt")
  )
  expect_warning(
    get_data("t10030", "nyreg", ar = "2024", "drivm"),
    "requested as a breakdown but came back with a single value"
  )
})

test_that("bare dimension in a raw query string also warns", {
  local_mocked_bindings(
    trafa_get = function(...) make_response("t1", "Totalt")
  )
  expect_warning(
    get_data(query = "t10030|nyreg|ar:2024|drivm"),
    "requested as a breakdown but came back with a single value"
  )
})

test_that("bare dimension with a real breakdown does not warn", {
  local_mocked_bindings(
    trafa_get = function(...) make_response(c("101", "102", "103"),
                                            c("Bensin", "Diesel", "El"))
  )
  expect_no_warning(get_data("t10030", "nyreg", ar = "2024", "drivm"))
})

test_that("a NAMED single-value filter does not trigger the guard", {
  local_mocked_bindings(
    trafa_get = function(...) make_response("t1", "Totalt")
  )
  expect_no_warning(get_data("t10030", "nyreg", ar = "2024", drivm = "t1"))
})
