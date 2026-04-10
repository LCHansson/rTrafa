# Remove monotonous columns from a product tibble

Remove monotonous columns from a product tibble

## Usage

``` r
product_minimize(product_df)
```

## Arguments

- product_df:

  A tibble returned by
  [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md).

## Value

A tibble with monotonous columns removed.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_products() |> product_minimize()
}# }
#> # A tibble: 56 × 5
#>    name   label             description                           id active_from
#>    <chr>  <chr>             <chr>                              <int> <chr>      
#>  1 t10011 "Bussar"          ""                                   203 2019-01-10…
#>  2 t10014 "Motorcyklar"     ""                                   206 2019-01-10…
#>  3 t10015 "Mopeder klass I" ""                                   207 2019-01-10…
#>  4 t10017 "Släpvagnar"      ""                                   209 2019-01-10…
#>  5 t10018 "Traktorer"       ""                                   210 2019-01-10…
#>  6 t10019 "Terrängskotrar " ""                                   211 2019-01-10…
#>  7 t0401  "Trafikarbete "   ""                                   222 2019-01-10…
#>  8 t10012 "Körkort"         ""                                   227 2019-01-14…
#>  9 t10091 "Bussar"          "Bussar\n\nDefinitioner-> Busskla…   231 2019-04-29…
#> 10 t10092 "Lastbilar"       "Lastbilar\nDefinitioner->Karosse…   232 2019-04-29…
#> # ℹ 46 more rows
```
