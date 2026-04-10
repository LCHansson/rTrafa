# Compose a data query string

Builds the pipe-delimited query string used by the Trafa `/api/data`
endpoint.

## Usage

``` r
compose_data_query(product, measure, ...)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`).

- measure:

  Character: measure name (e.g. `"itrfslut"`).

- ...:

  Named arguments where the name is a dimension and the value is a
  character vector of filter values (e.g. `ar = c("2023", "2024")`).

## Value

A character string (e.g. `"t10011|itrfslut|ar:2023,2024"`).

## Examples

``` r
compose_data_query("t10011", "itrfslut")
#> [1] "t10011|itrfslut"
compose_data_query("t10011", "itrfslut", ar = "2024")
#> [1] "t10011|itrfslut|ar:2024"
compose_data_query("t10011", "itrfslut", ar = c("2023", "2024"),
                   drivm = c("102", "103"))
#> [1] "t10011|itrfslut|ar:2023,2024|drivm:102,103"
```
