# Check if a product is a data-bearing leaf or an empty container

The Trafa API does not model parent-child relationships between products
explicitly. However, some products (e.g. "Fordon på väg", t10010) have
dimensions and measures in their structure but return no data rows —
they act as organizational containers. This function checks whether a
product has actual data by inspecting its structure for
dimension/measure items whose `parent_name` matches the product code,
and then verifying whether the data endpoint returns rows.

## Usage

``` r
product_has_data(
  product,
  lang = NULL,
  cache = FALSE,
  cache_location = trafa_cache_dir,
  verbose = FALSE
)
```

## Arguments

- product:

  Character: product code.

- lang, cache, cache_location, verbose:

  Standard rTrafa args.

## Value

Logical: `TRUE` if the product's data endpoint returns rows, `FALSE` if
it appears to be an empty container.

## Details

**Note:** when a product is a container, the related "sub-products"
cannot be discovered programmatically via the API. Use
[`product_search()`](https://lchansson.github.io/rTrafa/reference/product_search.md)
on the product catalogue to find products with similar names (e.g.
`product_search(get_products(), "fordon")`).

## Examples

``` r
# \donttest{
if (trafa_available()) {
  product_has_data("t10011")   # TRUE — Bussar has data
  product_has_data("t10010")   # FALSE — container, no data rows
}# }
#> Warning: No data rows in Trafa API response.
#> [1] FALSE
```
