suppressPackageStartupMessages(library(devtools))
load_all(".")

cat("=== Step 1: get_dimensions(t10011, measure = itrfslut) ===\n")
r1 <- get_dimensions("t10011", measure = "itrfslut")
print(r1[, c("name", "label", "option")])

cat("\n=== Step 2: measure = c(itrfslut, leasing) ===\n")
r2 <- get_dimensions("t10011", measure = c("itrfslut", "leasing"))
print(r2[, c("name", "label", "option")])

cat("\n=== Step 3: measure = c(itrfslut, leasing, bussklass) ===\n")
r3 <- get_dimensions("t10011", measure = c("itrfslut", "leasing", "bussklass"))
print(r3[, c("name", "label", "option")])
