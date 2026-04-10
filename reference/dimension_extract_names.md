# Extract dimension names

Extract dimension names

## Usage

``` r
dimension_extract_names(dim_df)
```

## Arguments

- dim_df:

  A tibble returned by
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md).

## Value

A character vector of dimension names.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_dimensions("t10011") |> dimension_extract_names()
}# }
#> [1] "ar"        "avregform" "dimpo"     "leasing"   "bussklass" "drivm"    
#> [7] "pass"      "agarkat"   "tillst"   
```
