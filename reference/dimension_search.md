# Search dimensions by text

Search dimensions by text

## Usage

``` r
dimension_search(dim_df, query, column = NULL)
```

## Arguments

- dim_df:

  A tibble returned by
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md).

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
  get_dimensions("t10011") |> dimension_search("driv")
}# }
#> # A tibble: 1 × 13
#>   product name  label   data_type option description hierarchy n_values values  
#>   <chr>   <chr> <chr>   <chr>     <lgl>  <chr>       <chr>        <int> <list>  
#> 1 t10011  drivm Drivme… String    TRUE   ""          NA              10 <tibble>
#> # ℹ 4 more variables: id <int>, unique_id <chr>, parent_name <chr>,
#> #   active_from <chr>
```
