# Pre-cache API data for vignettes
# Run this script manually: Rscript data-raw/vignette-data.R
# Output: R/sysdata.rda (internal package data)

library("rTrafa")

# --- Products ---
vd_products <- get_products()

# --- Measures for Bussar ---
vd_measures_bussar <- get_measures("t10011")

# --- Dimensions for Bussar (with hierarchy info) ---
vd_dims_bussar <- get_dimensions("t10011")

# --- Dimension values: year (shows filter shortcuts) ---
vd_ar_values <- dimension_values(vd_dims_bussar, "ar")

# --- Dimension values: fuel type ---
vd_drivm_values <- dimension_values(vd_dims_bussar, "drivm")

# --- Time series: buses in traffic, last 10 years ---
vd_data_bussar <- get_data("t10011", "itrfslut",
  ar = as.character(2016:2025)
)

# --- Breakdown by fuel type (latest year) ---
vd_data_drivm <- get_data("t10011", "itrfslut",
  ar = "senaste",
  drivm = c("101", "102", "103", "104", "105", "106", "107")
)

# --- Comparison: passenger cars in traffic, same period ---
vd_data_personbilar <- get_data("t10016", "itrfslut",
  ar = as.character(2016:2025)
)

usethis::use_data(
  vd_products,
  vd_measures_bussar,
  vd_dims_bussar,
  vd_ar_values,
  vd_drivm_values,
  vd_data_bussar,
  vd_data_drivm,
  vd_data_personbilar,
  overwrite = TRUE, internal = TRUE
)
