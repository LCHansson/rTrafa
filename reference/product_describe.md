# Print human-readable product summaries

Print human-readable product summaries

## Usage

``` r
product_describe(product_df, max_n = 5, format = "inline", heading_level = 2)
```

## Arguments

- product_df:

  A tibble returned by
  [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md).

- max_n:

  Maximum number of products to describe.

- format:

  Output format: `"inline"` (console) or `"md"` (markdown).

- heading_level:

  Heading level for output.

## Value

`product_df` invisibly (for piping).

## Examples

``` r
# \donttest{
if (trafa_available()) {
  get_products() |> product_search("buss") |> product_describe()
}# }
#> ── t10011: Bussar ─────────────────────────────────────────────────────────────── 
#>   Active from: 2019-01-10T10:17:00 
#> 
#> ── t10091: Bussar ─────────────────────────────────────────────────────────────── 
#>   Description: Bussar
#> 
#> Definitioner-> Bussklass: För fordon som är inrättade för befordran av fler än 22 passagerare utöver föraren finns följande fordonsklasser: Klass I – Fordon som tillverkats med utrymmen för ståplatspassagerare för att medge frekventa förflyttningar av passagerare. Klass II – Fordon som huvudsakligen tillverkats för befordran av sittplatspassagerare och som är utformade för att medge befordran av ståplatspassagerare i mittgången och/eller i ett utrymme som inte är större än att det utrymme som upptas för två dubbelsäten. Klass III – Fordon som uteslutande tillverkats för befordran av sittplatspassagerare. För fordon som är inrättande för befordran av högst 22 passagerare utöver föraren finns följande fordonsklasser: Klass A – Fordon utformade för befordran av ståplatspassagerare. Ett fordon i denna klass är utrustat med säten och ska ha utrymme för ståplatspassagerare. Klass B – Fordon som inte är utformade för befordran av ståplatspassagerare. Ett fordon i denna klass saknar utrymme för ståplatspassagerare.
#>   Active from: 2019-04-29T11:00:00 
#> 
#> ── t10021: Bussar ─────────────────────────────────────────────────────────────── 
#>   Active from: 2020-05-08T12:59:00 
#> 
```
