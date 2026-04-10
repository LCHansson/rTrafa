# Get measures (KPIs) for a product

Retrieves the available measures for a Trafa product. Each measure
represents a specific statistic (KPI) that can be queried with
[`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).
A product typically has several measures — for example, "Bussar"
(t10011) has measures for vehicles in traffic, deregistered, newly
registered, etc.

## Usage

``` r
get_measures(
  product,
  lang = NULL,
  cache = FALSE,
  cache_location = trafa_cache_dir,
  verbose = FALSE
)
```

## Arguments

- product:

  Character: product code (e.g. `"t10011"`).

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

A tibble with columns: `product`, `name`, `label`, `description`.

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_measures("t10011") |> measure_describe()
}# }
#> ── itrfslut (Antal i trafik) ──────────────────────────────────────────────────── 
#>   Product: t10011
#>   Description: Avser i slutet av perioden 
#> 
#> ── avstslut (Antal avställda) ─────────────────────────────────────────────────── 
#>   Product: t10011
#>   Description: Avser i slutet av perioden 
#> 
#> ── nyregunder (Antal nyregistreringar) ────────────────────────────────────────── 
#>   Product: t10011
#>   Description: Avser under perioden 
#> 
#> ── avregunder (Antal avregistreringar) ────────────────────────────────────────── 
#>   Product: t10011
#>   Description: Avser under perioden 
#> 
```
