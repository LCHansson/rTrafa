# Search measures by text

Search measures by text

## Usage

``` r
measure_search(measure_df, query, column = NULL)
```

## Arguments

- measure_df:

  A tibble returned by
  [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md).

- query:

  Character vector of search terms (combined with OR).

- column:

  Column names to search. `NULL` searches `name`, `label`, and
  `description`.

## Value

A filtered tibble.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_measures("t10011") |> measure_search("trafik")
}# }
#> # A tibble: 1 × 4
#>   product name     label          description               
#>   <chr>   <chr>    <chr>          <chr>                     
#> 1 t10011  itrfslut Antal i trafik Avser i slutet av perioden
```
