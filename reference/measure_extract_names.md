# Extract measure names

Extract measure names

## Usage

``` r
measure_extract_names(measure_df)
```

## Arguments

- measure_df:

  A tibble returned by
  [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md).

## Value

A character vector of measure names.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_measures("t10011") |> measure_extract_names()
}# }
#> [1] "itrfslut"   "avstslut"   "nyregunder" "avregunder"
```
