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
#> # A tibble: 56 × 6
#>    name   label             description                 id unique_id active_from
#>    <chr>  <chr>             <chr>                    <int> <chr>     <chr>      
#>  1 t10011 "Bussar"          ""                         203 T10011    2019-01-10…
#>  2 t10014 "Motorcyklar"     ""                         206 T10014    2019-01-10…
#>  3 t10015 "Mopeder klass I" ""                         207 T10015    2019-01-10…
#>  4 t10017 "Släpvagnar"      ""                         209 T10017    2019-01-10…
#>  5 t10018 "Traktorer"       ""                         210 T10018    2019-01-10…
#>  6 t10019 "Terrängskotrar " ""                         211 T10019    2019-01-10…
#>  7 t0401  "Trafikarbete "   ""                         222 T0401     2019-01-10…
#>  8 t10012 "Körkort"         ""                         227 T10012    2019-01-14…
#>  9 t10091 "Bussar"          "Bussar\n\nDefinitioner…   231 T10091    2019-04-29…
#> 10 t10092 "Lastbilar"       "Lastbilar\nDefinitione…   232 T10092    2019-04-29…
#> # ℹ 46 more rows
```
