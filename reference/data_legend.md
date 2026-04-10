# Generate a source caption for plots

Generate a source caption for plots

## Usage

``` r
data_legend(data_df, struct_df = NULL)
```

## Arguments

- data_df:

  A tibble returned by
  [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).

- struct_df:

  A tibble returned by
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md).
  Optional.

## Value

A character string suitable for plot captions.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  d <- get_data("t10011", "itrfslut", ar = "2024")
  data_legend(d)
}# }
#> [1] "Source: Trafa, product t10011, measure itrfslut"
```
