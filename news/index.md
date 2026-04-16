# Changelog

## rTrafa 0.1.0.9001 (development)

### Minor changes

- The nested `values` tibble inside
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md)
  now exposes `code` and `text` columns in addition to the legacy `name`
  and `label` columns. `code`/`text` mirror the convention used by
  `pixieweb::get_variables()` and the sibling Kolada package, making it
  easier to write code that works against all three sources. The legacy
  aliases remain for backward compatibility and will be deprecated in a
  later release.

### Bug fixes

- [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md)
  now warns when called with no dimension filters. The Trafa API returns
  an empty response in this case, which previously surfaced only as a
  cryptic “No data rows in Trafa API response.” warning. The new message
  points the user to
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md)
  and suggests starting with an `ar = "..."` filter.

## rTrafa 0.1.0.9000 (development)

### Bug fixes

- [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md)
  now writes its result to nordstatExtras under `entity = "measures"`
  when a `nxt_handle`-backed `cache_location` is supplied. Previously
  the function only triggered the `entity = "structure"` cache (via
  `get_structure_raw()`), which is deliberately omitted from the search
  index — measures were therefore never searchable via
  [`nxt_search()`](https://rdrr.io/pkg/nordstatExtras/man/nxt_search.html).
  With this fix, measures appear in the search index.

## rTrafa 0.1.0

Initial CRAN release.

### Features

- **API connection**:
  [`trafa_available()`](https://lchansson.github.io/rTrafa/reference/trafa_available.md)
  performs a lightweight connectivity check, used to guard examples and
  tests.
- **Product discovery**:
  [`get_products()`](https://lchansson.github.io/rTrafa/reference/get_products.md)
  lists all statistical products (datasets) available on the Trafa API.
- **Structure inspection**:
  [`get_measures()`](https://lchansson.github.io/rTrafa/reference/get_measures.md)
  and
  [`get_dimensions()`](https://lchansson.github.io/rTrafa/reference/get_dimensions.md)
  retrieve the measures (KPIs) and filterable dimensions for a given
  product, including hierarchy metadata and dimension validation.
- **Data retrieval**:
  [`get_data()`](https://lchansson.github.io/rTrafa/reference/get_data.md)
  downloads data using pipe-delimited query syntax, with automatic
  parsing and optional simplification (human-readable `_label` columns
  alongside raw codes).
- **Query workflow**:
  [`prepare_query()`](https://lchansson.github.io/rTrafa/reference/prepare_query.md)
  validates selections against the structure endpoint before hitting the
  data endpoint;
  [`compose_structure_query()`](https://lchansson.github.io/rTrafa/reference/compose_structure_query.md)
  and
  [`compose_data_query()`](https://lchansson.github.io/rTrafa/reference/compose_data_query.md)
  expose programmatic access to the raw URL builders.
- **Entity operations**: each entity type (`product`, `measure`,
  `dimension`) supports a consistent family of `*_search()`,
  `*_describe()`, `*_extract_ids()` / `*_extract_names()` and
  `*_minimize()` helpers for piped exploration.
- **Filter shortcuts**:
  [`dimension_values()`](https://lchansson.github.io/rTrafa/reference/dimension_values.md)
  surfaces Trafa’s server-side shortcuts (`senaste`, `forra`) alongside
  regular values, so queries can always reach the latest period without
  hardcoding years.
- **Data helpers**:
  [`data_minimize()`](https://lchansson.github.io/rTrafa/reference/data_minimize.md)
  drops monotonous columns;
  [`data_legend()`](https://lchansson.github.io/rTrafa/reference/data_legend.md)
  generates a source caption suitable for
  `ggplot2::labs(caption = ...)`, with `lang`, `omit_varname` and
  `omit_desc` arguments for fine-grained control over what to show.
- **Persistent caching**:
  [`trafa_cache_dir()`](https://lchansson.github.io/rTrafa/reference/trafa_cache_dir.md)
  and
  [`trafa_clear_cache()`](https://lchansson.github.io/rTrafa/reference/trafa_clear_cache.md)
  manage cached API responses via
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).
- **HTTP resilience**: automatic retry with exponential backoff for
  transient errors.
- **Offline-safe**: all examples and vignettes are guarded by
  [`trafa_available()`](https://lchansson.github.io/rTrafa/reference/trafa_available.md)
  and draw on pre-cached API data stored in `R/sysdata.rda`, so package
  builds and tests do not require network access.

### Documentation

- **Quick start vignette** (`a-quickstart-rtrafa`): five-step
  walk-through from product discovery to a plotted time series.
- **Introduction vignette** (`introduction-to-rtrafa`): covers the
  four-level data model (product → measure → dimension → value),
  hierarchies, filter shortcuts, dimension validation, prepared queries,
  and three worked ggplot2 examples.
- Vignette plots convert the `ar` (year) column to `Date` before
  plotting and use
  [`scale_x_date()`](https://ggplot2.tidyverse.org/reference/scale_date.html)
  so axis breaks land on whole years — a pattern the sibling packages
  `rKolada` and `pixieweb` share.
- README and vignettes cross-link to the sibling packages `rKolada`
  (Swedish municipal and regional KPIs) and `pixieweb` (PX-Web APIs for
  Nordic statistics agencies).
