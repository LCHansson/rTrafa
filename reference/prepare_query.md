# Prepare a data query with progressive validation

Fetches the product structure, validates that the requested measure and
dimensions are compatible, and returns a query object that can be passed
to
[`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).

## Usage

``` r
prepare_query(
  product,
  measure,
  ...,
  lang = NULL,
  validate = TRUE,
  verbose = FALSE
)

# S3 method for class 'trafa_query'
print(x, ...)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`).

- measure:

  Character: measure name (e.g. `"itrfslut"`).

- ...:

  Ignored.

- lang:

  Language code: `"SV"` or `"EN"`.

- validate:

  Logical. If `TRUE` (default), validates dimension compatibility
  against the API structure.

- verbose:

  Print request details.

- x:

  A `<trafa_query>` object.

## Value

A `<trafa_query>` object. Pass to
[`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md)
via `query`.

## Details

The Trafa API supports progressive structure discovery: adding a measure
to the structure query reveals which dimensions are valid for that
measure (via the `option` field). This function leverages that to warn
about invalid dimension combinations before data is requested.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  q <- prepare_query("t10011", "itrfslut", ar = "2024")
  q

  get_data(query = q)
}# }
#> # A tibble: 1 × 3
#>   ar    ar_label itrfslut
#>   <chr> <chr>       <dbl>
#> 1 2024  2024        14178
```
