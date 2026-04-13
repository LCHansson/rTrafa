# Get available products from the Trafa API

Fetches the list of all available statistical products (datasets) from
the Trafa API.

## Usage

``` r
get_products(
  lang = NULL,
  cache = FALSE,
  cache_location = trafa_cache_dir,
  verbose = FALSE
)
```

## Arguments

- lang:

  Language code: `"SV"` (Swedish, default) or `"EN"` (English). Defaults
  to `getOption("rTrafa.lang", "SV")`.

- cache:

  Logical, cache results locally.

- cache_location:

  Cache directory. Defaults to
  [`trafa_cache_dir()`](https://lchansson.github.io/rTrafa/reference/trafa_cache_dir.md).

- verbose:

  Print request details.

## Value

A tibble with columns: `name`, `label`, `description`, `id`,
`active_from`.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  products <- get_products()
  products |> product_search("buss")
}# }
#> # A tibble: 3 × 8
#>   name   label  description          id unique_id option parent_name active_from
#>   <chr>  <chr>  <chr>             <int> <chr>     <lgl>  <chr>       <chr>      
#> 1 t10011 Bussar ""                  203 T10011    TRUE   NA          2019-01-10…
#> 2 t10091 Bussar "Bussar\n\nDefin…   231 T10091    TRUE   NA          2019-04-29…
#> 3 t10021 Bussar ""                  270 T10021    TRUE   NA          2020-05-08…
```
