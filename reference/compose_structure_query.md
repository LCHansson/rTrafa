# Compose a structure query string

Builds the pipe-delimited query string used by the Trafa
`/api/structure` endpoint.

## Usage

``` r
compose_structure_query(product = NULL, ...)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`).

- ...:

  Additional dimension names to include in the query. These are bare
  names (not filtered), used for progressive structure discovery.

## Value

A character string (e.g. `"t10011|ar|drivm"`), or an empty string if
`product` is `NULL`.

## Examples

``` r
compose_structure_query("t10011")
#> [1] "t10011"
compose_structure_query("t10011", "itrfslut", "ar")
#> [1] "t10011|itrfslut|ar"
```
