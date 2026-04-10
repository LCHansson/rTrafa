# Print human-readable measure summaries

Print human-readable measure summaries

## Usage

``` r
measure_describe(measure_df, max_n = 10, format = "inline", heading_level = 2)
```

## Arguments

- measure_df:

  A tibble returned by
  [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md).

- max_n:

  Maximum number of measures to describe.

- format:

  Output format: `"inline"` or `"md"`.

- heading_level:

  Heading level.

## Value

`measure_df` invisibly (for piping).

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
