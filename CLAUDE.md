# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rTrafa is an R package that wraps the Trafa API (https://api.trafa.se/) — Swedish Transport Analysis agency's statistical database. It provides tidy, pipeable interfaces for downloading and processing transport statistics data.

## Build & Development Commands

```bash
# Check package (equivalent to CRAN check)
R CMD check .

# Build package
R CMD build .

# Install locally
R CMD INSTALL .

# Run tests
Rscript -e "testthat::test_local()"

# Regenerate documentation (roxygen2)
Rscript -e "devtools::document()"
```

From an R session with devtools:
```r
devtools::check()       # Full package check
devtools::test()        # Run tests only
devtools::document()    # Rebuild docs from roxygen2 comments
devtools::load_all()    # Load package for interactive development
devtools::install()     # Install from source
```

## Architecture

### API Layer (`R/utils.R`, `R/query.R`)

The Trafa API has two endpoints:
- `/api/structure` — discovery and metadata (products, dimensions, measures, values)
- `/api/data` — actual statistical data

Both use pipe-delimited query syntax: `product|measure|dim:filter1,filter2`

Core HTTP function `trafa_get()` handles all API communication with retry logic. Query URLs are built by `compose_structure_query()` and `compose_data_query()`.

### Entity Wrappers

- `get_products()` — fetch all available products (datasets)
- `get_structure()` — fetch structure (dimensions, measures, values) for a product
- `get_data()` — fetch actual data with dimension filters

### Entity Operations (`R/products.R`, `R/structure.R`)

Each entity type follows a consistent pattern:
- `*_search()` — filter by text/regex
- `*_describe()` — print human-readable descriptions
- `*_extract_ids()` / `*_extract_names()` — extract ID/name vector
- `*_minimize()` — remove low-information columns

### Design Conventions

- All public functions return tibbles and are designed for `|>` chaining
- Naming: `entity_operation()` (e.g., `product_search`, `dimension_values`)
- API failures return NULL with warnings (no exceptions)
- `trafa_available()` guards all examples/vignettes for offline safety (required by CRAN policy)
- Uses `.data` pronoun from rlang for tidy evaluation; string column names in select/rename contexts
- Roxygen2 generates all man pages and NAMESPACE — never edit those by hand
- Sister packages: rKolada and pixieweb follow the same design philosophy

## Testing

Tests use testthat edition 3. Test files:
- `test-utils.R` — internal utilities (pure, no network)
- `test-products.R` — product operations with synthetic data (pure)
- `test-structure.R` — structure parsing, dimension/measure ops (pure)
- `test-query-composers.R` — pipe-delimited query construction (pure)
- `test-data-parsing.R` — data response parsing (pure)
- `test-data-helpers.R` — data_minimize, data_legend (pure)
- `test-prepare-query.R` — prepare_query with mocked validation
- `test-api-mocked.R` — API functions with mocked HTTP responses
- `test-api-live.R` — live integration tests (skipped when API unavailable)

The `trafa_available()` guard function should wrap any test or example that calls the API.

## CRAN Notes

All API-dependent code must be wrapped with `trafa_available()` checks and must fail gracefully when offline.
