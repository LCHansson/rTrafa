# Client-side search on a product tibble

Filter an already-fetched product tibble by regex.

## Usage

``` r
product_search(product_df, query, column = NULL)
```

## Arguments

- product_df:

  A tibble returned by
  [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md).

- query:

  Character vector of search terms (combined with OR).

- column:

  Column names to search. `NULL` searches all character columns.

## Value

A filtered tibble.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_products() |> product_search("fordon")
}# }
#> # A tibble: 7 × 8
#>   name   label        description    id unique_id option parent_name active_from
#>   <chr>  <chr>        <chr>       <int> <chr>     <lgl>  <chr>       <chr>      
#> 1 t10091 Bussar       "Bussar\n\…   231 T10091    TRUE   NA          2019-04-29…
#> 2 t10092 Lastbilar    "Lastbilar…   232 T10092    TRUE   NA          2019-04-29…
#> 3 t10094 Personbilar  "Personbil…   234 T10094    TRUE   NA          2019-04-29…
#> 4 t06012 Fordon       ""            258 T06012    TRUE   NA          2019-08-23…
#> 5 t10029 Övriga ford… ""            273 T10029    TRUE   NA          2020-05-08…
#> 6 t10039 Övriga ford… ""            276 T10039    TRUE   NA          2020-05-08…
#> 7 t10010 Fordon på v… ""            313 T10010    TRUE   NA          2025-12-15…
```
