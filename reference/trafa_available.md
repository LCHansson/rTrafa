# Check if the Trafa API is available

Performs a lightweight HTTP check to verify that the Trafa API is
reachable. This is primarily useful for guarding examples and tests.

## Usage

``` r
trafa_available()
```

## Value

`TRUE` if the API responds within 5 seconds, `FALSE` otherwise.

## Examples

``` r
trafa_available()
#> [1] TRUE
```
