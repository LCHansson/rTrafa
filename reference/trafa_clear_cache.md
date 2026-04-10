# Clear rTrafa cache files

Removes cached API responses stored in the default or specified
location.

## Usage

``` r
trafa_clear_cache(entity = NULL, cache_location = trafa_cache_dir())
```

## Arguments

- entity:

  Character entity to clear (e.g. `"products"`, `"structure"`), or
  `NULL` (default) to clear all rTrafa cache files.

- cache_location:

  Directory to clear. Defaults to
  [`trafa_cache_dir()`](https://lchansson.github.io/rTrafa/reference/trafa_cache_dir.md).

## Value

`invisible(NULL)`

## Examples

``` r
# \donttest{
if (trafa_available()) {
  trafa_clear_cache()
  trafa_clear_cache(entity = "products")
}# }
#> No rTrafa cache files found.
#> No rTrafa cache files found.
```
