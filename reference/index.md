# Package index

## Discover products

Browse and search Trafa’s statistical products.

- [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md)
  : Get available products from the Trafa API
- [`product_search()`](https://lchansson.github.io/rTrafa/reference/product_search.md)
  : Client-side search on a product tibble
- [`product_describe()`](https://lchansson.github.io/rTrafa/reference/product_describe.md)
  : Print human-readable product summaries
- [`product_minimize()`](https://lchansson.github.io/rTrafa/reference/product_minimize.md)
  : Remove monotonous columns from a product tibble
- [`product_extract_ids()`](https://lchansson.github.io/rTrafa/reference/product_extract_ids.md)
  : Extract product codes from a product tibble
- [`product_has_data()`](https://lchansson.github.io/rTrafa/reference/product_has_data.md)
  : Check if a product is a data-bearing leaf or an empty container

## Explore measures

Each product contains one or more measures (KPIs).

- [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md)
  : Get measures (KPIs) for a product
- [`measure_search()`](https://lchansson.github.io/rTrafa/reference/measure_search.md)
  : Search measures by text
- [`measure_describe()`](https://lchansson.github.io/rTrafa/reference/measure_describe.md)
  : Print human-readable measure summaries
- [`measure_extract_names()`](https://lchansson.github.io/rTrafa/reference/measure_extract_names.md)
  : Extract measure names

## Explore dimensions

Dimensions are the filter variables available for a product.

- [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md)
  : Get dimensions (filter variables) for a product
- [`dimension_search()`](https://lchansson.github.io/rTrafa/reference/dimension_search.md)
  : Search dimensions by text
- [`dimension_describe()`](https://lchansson.github.io/rTrafa/reference/dimension_describe.md)
  : Print human-readable dimension summaries
- [`dimension_values()`](https://lchansson.github.io/rTrafa/reference/dimension_values.md)
  : Extract values for a specific dimension
- [`dimension_extract_names()`](https://lchansson.github.io/rTrafa/reference/dimension_extract_names.md)
  : Extract dimension names

## Prepare and fetch data

Build queries and download data.

- [`prepare_query()`](https://lchansson.github.io/rTrafa/reference/prepare_query.md)
  [`print(`*`<trafa_query>`*`)`](https://lchansson.github.io/rTrafa/reference/prepare_query.md)
  : Prepare a data query with progressive validation
- [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md)
  : Fetch data from the Trafa API

## Data utilities

Post-processing helpers for downloaded data.

- [`data_minimize()`](https://lchansson.github.io/rTrafa/reference/data_minimize.md)
  : Remove monotonous columns from a data tibble
- [`data_legend()`](https://lchansson.github.io/rTrafa/reference/data_legend.md)
  : Generate a source caption for plots

## Query composition

Low-level functions for building pipe-delimited API queries.

- [`compose_structure_query()`](https://lchansson.github.io/rTrafa/reference/compose_structure_query.md)
  : Compose a structure query string
- [`compose_data_query()`](https://lchansson.github.io/rTrafa/reference/compose_data_query.md)
  : Compose a data query string

## Utilities

API availability and cache management.

- [`trafa_available()`](https://lchansson.github.io/rTrafa/reference/trafa_available.md)
  : Check if the Trafa API is available
- [`trafa_cache_dir()`](https://lchansson.github.io/rTrafa/reference/trafa_cache_dir.md)
  : Get the persistent rTrafa cache directory
- [`trafa_clear_cache()`](https://lchansson.github.io/rTrafa/reference/trafa_clear_cache.md)
  : Clear rTrafa cache files
