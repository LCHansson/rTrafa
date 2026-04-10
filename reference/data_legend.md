# Generate a source caption for plots

Builds a human-readable source attribution string from a data tibble
returned by
[`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).
The string includes the product and measure along with their
human-readable descriptions, and is suitable for use as a `caption` in
[`ggplot2::labs()`](https://ggplot2.tidyverse.org/reference/labs.html).

## Usage

``` r
data_legend(data_df, lang = NULL, omit_varname = FALSE, omit_desc = FALSE)
```

## Arguments

- data_df:

  A tibble returned by
  [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md).

- lang:

  Language for the caption text: `"SV"` (Swedish, default) or `"EN"`
  (English). Defaults to `getOption("rTrafa.lang", "SV")`. Note that the
  product/measure labels are returned by the API in their default
  language regardless of this setting.

- omit_varname:

  Logical. If `TRUE`, omit the variable codes (the parenthesised IDs
  like `t10011` and `itrfslut`).

- omit_desc:

  Logical. If `TRUE`, omit the human-readable descriptions and show only
  the codes.

## Value

A single character string suitable for plot captions.

## Details

By default the caption shows both the description and the code, e.g.
`"Källa: Trafa; produkt: Bussar (t10011); mått: Antal i trafik (itrfslut)"`.
Use `omit_varname` to drop the codes or `omit_desc` to drop the
descriptions.

Product and measure descriptions are looked up via
[`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md)
and
[`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md)
(cached on disk).

## Examples

``` r
# \donttest{
if (trafa_available()) {
  d <- get_data("t10011", "itrfslut", ar = "2024")
  data_legend(d)
  data_legend(d, lang = "EN")
  data_legend(d, omit_varname = TRUE)
  data_legend(d, omit_desc = TRUE)
}# }
#> [1] "Källa: Trafa; produkt: t10011; mått: itrfslut"
```
