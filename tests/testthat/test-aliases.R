# dev-backlog 2026-09-12: rTrafa and pixieweb both export get_data().

test_that("trafa_get_data() is get_data() under an unmaskable name", {
  seen <- NULL
  local_mocked_bindings(get_data = function(...) {
    seen <<- list(...)
    "forwarded"
  })
  expect_equal(trafa_get_data("t10011", "itrfslut", ar = "2024"), "forwarded")
  expect_equal(seen, list("t10011", "itrfslut", ar = "2024"))
})

test_that("the masking note appears only beside pixieweb", {
  expect_null(masking_note(c(".GlobalEnv", "package:rTrafa", "package:stats")))
  note <- masking_note(c(".GlobalEnv", "package:rTrafa", "package:pixieweb"))
  expect_match(note, "px_get_data()", fixed = TRUE)
  expect_match(note, "trafa_get_data()", fixed = TRUE)
})
