# Extract product codes from a product tibble

Extract product codes from a product tibble

## Usage

``` r
product_extract_ids(product_df)
```

## Arguments

- product_df:

  A tibble returned by
  [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md).

## Value

A character vector of product codes (the `name` column).

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_products() |> product_search("buss") |> product_extract_ids()
}# }
#> [1] "t10011" "t10091" "t10021"
```
