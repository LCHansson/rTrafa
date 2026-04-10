# rTrafa <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/lchansson/rTrafa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lchansson/rTrafa/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

[`rTrafa`](https://lchansson.github.io/rTrafa/index.html) is an R package for *discovering*, *inspecting* and *downloading* Swedish transport statistics from the [Trafa API](https://api.trafa.se/) — the open database maintained by Trafikanalys, Sweden's agency for transport analysis. It covers road, rail, sea and air transport; vehicles in traffic; new registrations; passenger and freight volumes; and more.

To learn more about using `rTrafa`, it is recommended you use the following resources in order:

## Getting started with rTrafa

1.  To get up and running quickly with rTrafa, please see the vignette [A quick start guide to rTrafa](https://lchansson.github.io/rTrafa/articles/a-quickstart-rtrafa.html).
2.  For an introduction to rTrafa and the design principles of functions included, please see [Introduction to rTrafa](https://lchansson.github.io/rTrafa/articles/introduction-to-rtrafa.html).
3.  See the [Reference section of the package homepage](https://lchansson.github.io/rTrafa/reference/index.html) to learn about the full set of functionality included with the package.

`rTrafa` is open source licensed under the Affero Gnu Public License version 3. This means you are free to download the source, modify and redistribute it as you please, but any copies or modifications must retain the original license. Please see the file LICENSE.md for further information.

## Installation

rTrafa is on CRAN. To install it, run the following code in R:

``` r
install.packages("rTrafa")
```

To install the latest development version from GitHub, use the `remotes` package:

``` r
library("remotes")
remotes::install_github("LCHansson/rTrafa")
```

## Quick start

```r
library(rTrafa)

# List the available statistical products
products <- get_products()

# Inspect the measures available for "Buses" (product t10011)
measures <- get_measures("t10011")

# Download "Vehicles in traffic" for the last ten years
bus_data <- get_data("t10011", "itrfslut",
  ar = as.character(2016:2025)
)
```

## Features

- **Search-then-fetch workflow**: Discover products, inspect measures and dimensions, then download data
- **Three-level data model**: Products → measures → dimensions, mirrored by `get_products()`, `get_measures()` and `get_dimensions()`
- **Filter shortcuts**: Use `ar = "senaste"` for the latest period without hardcoding years
- **Dimension validation**: `prepare_query()` checks that your filters are compatible with the selected measure before hitting the data endpoint
- **Offline-safe examples**: `trafa_available()` guards all network calls so examples and tests degrade gracefully when the API is down

## Contributing

You are welcome to contribute to the further development of the rTrafa package in any of the following ways:

-   Open an [issue](https://github.com/LCHansson/rTrafa/issues)
-   Clone this repo, make modifications and create a pull request
-   Spread the word!

## Related packages

`rTrafa` is part of a family of R packages for Swedish and Nordic open statistics that share the same design philosophy — tibble-based, pipe-friendly, and offline-safe:

- [rKolada](https://lchansson.github.io/rKolada/) — R client for the [Kolada](https://kolada.se/) database of Swedish municipal and regional Key Performance Indicators
- [pixieweb](https://lchansson.github.io/pixieweb/) — R client for PX-Web APIs (Statistics Sweden, Statistics Norway, Statistics Finland, and more)

### Code of Conduct

Please note that the rTrafa project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.
