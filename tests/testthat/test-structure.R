test_that("classify_structure_items separates D, M, H types", {
  items <- list(
    list(Type = "P", Name = "other_product"),
    list(Type = "D", Name = "ar", Label = "Year"),
    list(Type = "M", Name = "itrfslut", Label = "Count"),
    list(Type = "H", Name = "agare", Label = "Owner",
         StructureItems = list(
           list(Type = "D", Name = "agarkat", Label = "Owner cat")
         ))
  )

  result <- classify_structure_items(items)
  expect_length(result$dimensions, 1)
  expect_length(result$measures, 1)
  expect_length(result$hierarchies, 1)
  expect_equal(result$dimensions[[1]]$Name, "ar")
  expect_equal(result$measures[[1]]$Name, "itrfslut")
  expect_equal(result$hierarchies[[1]]$Name, "agare")
})

test_that("parse_dimension_values extracts DV and F items", {
  item <- list(
    Name = "ar", Type = "D",
    StructureItems = list(
      list(Type = "F", Name = "senaste", Label = "Senaste"),
      list(Type = "F", Name = "forra", Label = "Previous"),
      list(Type = "DV", Name = "2023", Label = "2023"),
      list(Type = "DV", Name = "2024", Label = "2024")
    )
  )

  vals <- parse_dimension_values(item)
  expect_s3_class(vals, "tbl_df")
  expect_equal(nrow(vals), 4)
  expect_equal(sum(vals$type == "filter"), 2)
  expect_equal(sum(vals$type == "value"), 2)
  expect_equal(vals$name[vals$type == "filter"], c("senaste", "forra"))
})

test_that("parse_dimension_values returns NULL for no children", {
  item <- list(Name = "m", Type = "M", StructureItems = list())
  expect_null(parse_dimension_values(item))
})
