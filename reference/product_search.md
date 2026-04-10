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
#> # A tibble: 7 × 5
#>   name   label              description                           id active_from
#>   <chr>  <chr>              <chr>                              <int> <chr>      
#> 1 t10091 Bussar             "Bussar\n\nDefinitioner-> Busskla…   231 2019-04-29…
#> 2 t10092 Lastbilar          "Lastbilar\nDefinitioner->Karosse…   232 2019-04-29…
#> 3 t10094 Personbilar        "Personbilar\n\nDefinitioner->Ens…   234 2019-04-29…
#> 4 t06012 Fordon             ""                                   258 2019-08-23…
#> 5 t10029 Övriga fordonsslag ""                                   273 2020-05-08…
#> 6 t10039 Övriga fordonsslag ""                                   276 2020-05-08…
#> 7 t10010 Fordon på väg      ""                                   313 2025-12-15…
```
