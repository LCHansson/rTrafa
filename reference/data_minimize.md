# Remove monotonous columns from a data tibble

Remove monotonous columns from a data tibble

## Usage

``` r
data_minimize(data_df)
```

## Arguments

- data_df:

  A tibble returned by
  [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).

## Value

A tibble with monotonous columns removed.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  d <- get_data("t10011", "itrfslut", ar = "2024")
  d |> data_minimize()
}# }
#> # A tibble: 1 × 3
#>   ar    ar_label itrfslut
#>   <chr> <chr>       <dbl>
#> 1 2024  2024        14178
```
