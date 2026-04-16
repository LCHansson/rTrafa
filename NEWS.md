# rTrafa 0.1.0.9001 (development)

## Minor changes

* The nested `values` tibble inside `get_dimensions()` now exposes
  `code` and `text` columns in addition to the legacy `name` and
  `label` columns. `code`/`text` mirror the convention used by
  `pixieweb::get_variables()` and the sibling Kolada package, making
  it easier to write code that works against all three sources. The
  legacy aliases remain for backward compatibility and will be
  deprecated in a later release.

## Bug fixes

* `get_data()` now warns when called with no dimension filters. The Trafa
  API returns an empty response in this case, which previously surfaced only
  as a cryptic "No data rows in Trafa API response." warning. The new
  message points the user to `get_dimensions()` and suggests starting with
  an `ar = "..."` filter.

# rTrafa 0.1.0.9000 (development)

## Bug fixes

* `get_measures()` now writes its result to nordstatExtras under
  `entity = "measures"` when a `nxt_handle`-backed `cache_location` is
  supplied. Previously the function only triggered the `entity = "structure"`
  cache (via `get_structure_raw()`), which is deliberately omitted from
  the search index — measures were therefore never searchable via
  `nxt_search()`. With this fix, measures appear in the search index.

# rTrafa 0.1.0

Initial CRAN release.

## Features

* **API connection**: `trafa_available()` performs a lightweight
  connectivity check, used to guard examples and tests.
* **Product discovery**: `get_products()` lists all statistical
  products (datasets) available on the Trafa API.
* **Structure inspection**: `get_measures()` and `get_dimensions()`
  retrieve the measures (KPIs) and filterable dimensions for a given
  product, including hierarchy metadata and dimension validation.
* **Data retrieval**: `get_data()` downloads data using pipe-delimited
  query syntax, with automatic parsing and optional simplification
  (human-readable `_label` columns alongside raw codes).
* **Query workflow**: `prepare_query()` validates selections against
  the structure endpoint before hitting the data endpoint;
  `compose_structure_query()` and `compose_data_query()` expose
  programmatic access to the raw URL builders.
* **Entity operations**: each entity type (`product`, `measure`,
  `dimension`) supports a consistent family of `*_search()`,
  `*_describe()`, `*_extract_ids()` / `*_extract_names()` and
  `*_minimize()` helpers for piped exploration.
* **Filter shortcuts**: `dimension_values()` surfaces Trafa's
  server-side shortcuts (`senaste`, `forra`) alongside regular values,
  so queries can always reach the latest period without hardcoding
  years.
* **Data helpers**: `data_minimize()` drops monotonous columns;
  `data_legend()` generates a source caption suitable for
  `ggplot2::labs(caption = ...)`, with `lang`, `omit_varname` and
  `omit_desc` arguments for fine-grained control over what to show.
* **Persistent caching**: `trafa_cache_dir()` and `trafa_clear_cache()`
  manage cached API responses via `tools::R_user_dir()`.
* **HTTP resilience**: automatic retry with exponential backoff for
  transient errors.
* **Offline-safe**: all examples and vignettes are guarded by
  `trafa_available()` and draw on pre-cached API data stored in
  `R/sysdata.rda`, so package builds and tests do not require network
  access.

## Documentation

* **Quick start vignette** (`a-quickstart-rtrafa`): five-step walk-through
  from product discovery to a plotted time series.
* **Introduction vignette** (`introduction-to-rtrafa`): covers the
  four-level data model (product → measure → dimension → value),
  hierarchies, filter shortcuts, dimension validation, prepared
  queries, and three worked ggplot2 examples.
* Vignette plots convert the `ar` (year) column to `Date` before
  plotting and use `scale_x_date()` so axis breaks land on whole years
  — a pattern the sibling packages `rKolada` and `pixieweb` share.
* README and vignettes cross-link to the sibling packages `rKolada`
  (Swedish municipal and regional KPIs) and `pixieweb` (PX-Web APIs
  for Nordic statistics agencies).
