# Extract values for a specific dimension

Returns the available values for a dimension, including both regular
values and filter shortcuts (like `"senaste"` = latest). The `type`
column distinguishes them: `"value"` for regular values, `"filter"` for
shortcuts that the API resolves dynamically.

## Usage

``` r
dimension_values(dim_df, dimension_name)
```

## Arguments

- dim_df:

  A tibble returned by
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md).

- dimension_name:

  Dimension name (character).

## Value

A tibble with columns `name`, `label`, `type`.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  dims <- get_dimensions("t10011")
  dims |> dimension_values("ar")
  dims |> dimension_values("drivm")
}# }
#> # A tibble: 10 × 3
#>    name  label      type 
#>    <chr> <chr>      <chr>
#>  1 101   Bensin     value
#>  2 102   Diesel     value
#>  3 103   El         value
#>  4 104   Elhybrid   value
#>  5 105   Laddhybrid value
#>  6 106   Etanol     value
#>  7 107   Gas        value
#>  8 108   Biodiesel  value
#>  9 109   Övriga     value
#> 10 t1    Totalt     value
```
