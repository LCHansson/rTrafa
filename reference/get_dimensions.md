# Get dimensions (filter variables) for a product

Retrieves the available dimensions for a Trafa product. Dimensions are
the categorical variables you can filter on when fetching data with
[`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md)
— for example year, fuel type, or owner category.

## Usage

``` r
get_dimensions(
  product,
  measure = NULL,
  only_valid = TRUE,
  lang = NULL,
  cache = FALSE,
  cache_location = trafa_cache_dir,
  verbose = FALSE
)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`).

- measure:

  Character vector of one or more measure names. When provided, only
  dimensions valid for the measure(s) are returned (unless
  `only_valid = FALSE`). Passing several measures restricts the result
  to dimensions valid for *all* of them.

- only_valid:

  Logical. When `measure` is provided and `only_valid = TRUE` (default),
  dimensions with `option = FALSE` are excluded. Set to `FALSE` to see
  all dimensions with their validity status.

- lang:

  Language code: `"SV"` or `"EN"`.

- cache:

  Logical, cache results locally.

- cache_location:

  Cache directory. Defaults to
  [`trafa_cache_dir()`](https://lchansson.github.io/rTrafa/reference/trafa_cache_dir.md).

- verbose:

  Print request details.

## Value

A tibble with columns: `product`, `name`, `label`, `data_type`,
`option`, `description`, `hierarchy`, `n_values`, `values`.

The `values` column contains nested tibbles with columns `name`,
`label`, and `type` (`"value"` for regular dimension values, `"filter"`
for API filter shortcuts like `"senaste"` / latest).

## Details

Dimensions that belong to a hierarchy (e.g. "Ägarkategori" under the
"Ägare" hierarchy) are included with their hierarchy noted in the
`hierarchy` column. Hierarchies themselves are not queryable — only
their child dimensions are.

When `measure` is provided, the API validates which dimensions are
compatible with that measure. Invalid dimensions are excluded by default
(controlled by `only_valid`).

`measure` can also be a **vector of several measure names**. In that
case, the API returns the intersection: only dimensions that are valid
for *all* the requested measures. This is useful when planning a query
that mixes several measures and you want to know which dimensions you
can safely filter on.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  # All dimensions
  get_dimensions("t10011") |> dimension_describe()

  # Validated against a specific measure
  get_dimensions("t10011", measure = "itrfslut")

  # Validated against several measures (intersection)
  get_dimensions("t10011", measure = c("itrfslut", "nyregunder"))

  # Inspect values for a dimension
  get_dimensions("t10011") |> dimension_values("drivm")
}# }
#> ── ar (År) ────────────────────────────────────────────────────────────────────── 
#>   Data type: Time
#>   Selectable: Yes 
#>   Values (25): 2001 = 2001, 2002 = 2002, 2003 = 2003, 2004 = 2004, 2005 = 2005 ... and 20 more
#>   Filters: senaste = Senaste, forra = Föregående
#> 
#> ── avregform (Avregistreringsorsak) ───────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (2): 20 = Utförda ur landet, t1 = Totalt
#> 
#> ── dimpo (Direkt import) ──────────────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (2): 10 = Direkt import, t1 = Totalt
#> 
#> ── leasing (Leasing) ──────────────────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (2): 30 = Leasade, t1 = Totalt
#> 
#> ── bussklass (Bussklass) ──────────────────────────────────────────────────────── 
#>   Description: Bussklasser enligt föreskrift nr 107 UNECE
#>   Selectable: Yes 
#>   Values (7): 1 = A, 2 = B, 3 = I, 4 = II, 5 = III ... and 2 more
#> 
#> ── drivm (Drivmedel) ──────────────────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (10): 101 = Bensin, 102 = Diesel, 103 = El, 104 = Elhybrid, 105 = Laddhybrid ... and 5 more
#> 
#> ── pass (Antal passagerare) ───────────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (12): 101 = – 20, 102 = 21 – 40, 103 = 41 – 50, 104 = 51 – 60, 105 = 61 – 70 ... and 7 more
#> 
#> ── agarkat (Ägarkategori)  [agare] ────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (3): 10 = Fysisk person, 20 = Juridisk person, t1 = Totalt
#> 
#> ── tillst (Tillstånd)  [agare] ────────────────────────────────────────────────── 
#>   Selectable: Yes 
#>   Values (3): 1 = Yrkesmässig trafik, 2 = Firmabilstrafik, t1 = Totalt
#> 
#> # A tibble: 10 × 3
#>    name  label      type 
#>    <chr> <chr>      <chr>
#>  1 101   Bensin     value
#>  2 102   Diesel     value
#>  3 103   El         value
#>  4 104   Elhybrid   value
#>  5 105   Laddhybrid value
#>  6 106   Etanol     value
#>  7 107   Gas        value
#>  8 108   Biodiesel  value
#>  9 109   Övriga     value
#> 10 t1    Totalt     value
```
