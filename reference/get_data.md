# Fetch data from the Trafa API

The core function for downloading statistical data. Dimension filters
are passed as named arguments via `...`, or via a prepared query object
from
[`prepare_query()`](https://lchansson.github.io/rTrafa/reference/prepare_query.md).

## Usage

``` r
get_data(
  product,
  measure,
  ...,
  query = NULL,
  lang = NULL,
  simplify = TRUE,
  verbose = FALSE
)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`). Ignored when `query` is
  provided.

- measure:

  Character: measure name (e.g. `"itrfslut"`). Ignored when `query` is
  provided.

- ...:

  Dimension filters as named arguments. Each name is a dimension name,
  each value is a character vector of filter values. Unspecified
  dimensions return all values. Ignored when `query` is provided.

- query:

  A `<trafa_query>` object from
  [`prepare_query()`](https://lchansson.github.io/rTrafa/reference/prepare_query.md).
  When provided, `product`, `measure`, and `...` are taken from the
  query object.

- lang:

  Language code: `"SV"` or `"EN"`.

- simplify:

  Add human-readable label columns alongside codes.

- verbose:

  Print request details.

## Value

A tibble of data. Dimension columns use the dimension name; when
`simplify = TRUE`, additional `{name}_label` columns are added. Measure
values are in a column named after the measure.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  # Direct fetch
  get_data("t10011", "itrfslut", ar = "2024")

  # With filters
  get_data("t10011", "itrfslut",
    ar = c("2023", "2024"),
    drivm = c("102", "103"))

  # From a prepared query
  q <- prepare_query("t10011", "itrfslut", ar = "2024")
  get_data(query = q)
}# }
#> # A tibble: 1 × 3
#>   ar    ar_label itrfslut
#>   <chr> <chr>       <dbl>
#> 1 2024  2024        14178
```
