suppressPackageStartupMessages(library(devtools))

cat("=== document() ===\n")
devtools::document(".")

cat("\n=== load_all() ===\n")
devtools::load_all(".")

cat("\n=== Test 1: discover_allowed_combinations(t10011, itrfslut) ===\n")
r1 <- discover_allowed_combinations("t10011", "itrfslut", verbose = TRUE)
print(r1, n = Inf)
cat("\nUnique dim-sets:", nrow(r1), "\n")

cat("\n=== Test 2: discover_allowed_combinations(t10011) [all measures] ===\n")
r2 <- discover_allowed_combinations("t10011", verbose = FALSE)
cat("rows:", nrow(r2), "\n")
cat("measures:", paste(unique(r2$measure), collapse = ", "), "\n")

cat("\n=== Test 3: assertions ===\n")
stopifnot(
  is.data.frame(r1),
  nrow(r1) >= 6,
  all(r1$product == "t10011"),
  all(r1$measure == "itrfslut"),
  "ar" %in% unlist(r1$dimensions)
)
# Verify the expected dim-sets are present
keys <- vapply(r1$dimensions, function(s) paste(sort(s), collapse = ","),
               character(1))
expected_subsets <- c(
  "ar",
  "ar,bussklass",
  "ar,drivm",
  "ar,leasing",
  "ar,bussklass,leasing"
)
missing <- setdiff(expected_subsets, keys)
if (length(missing) > 0) {
  cat("MISSING expected combinations:\n")
  print(missing)
  stop("Expected dim-sets not found.")
} else {
  cat("All expected dim-sets present.\n")
}
