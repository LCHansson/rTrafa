# rTrafa 0.1.0.9006 (development)

## Breaking changes

* The `scrape_allowed_combinations()` / `scrape_all_allowed_combinations()`
  functions introduced in 0.1.0.9003 have been **removed**. They read
  Trafa's HTML documentation pages, which proved unreliable: the CMS
  serves two response variants for the same URL (one with the
  combinations list rendered, one without), and the page contents
  sometimes go entirely empty. The `rvest` and `xml2` dependencies are
  also removed.

## New features

* `discover_allowed_combinations(product, measure = NULL)` and
  `discover_all_allowed_combinations()` enumerate the same information
  via the Trafa **API** (the `/api/structure` endpoint, accessed
  through the existing `get_dimensions()`). The function recursively
  probes `get_dimensions(product, measure = c(measure, dim_set))` and
  expands the dim-set as long as the API reports new addable
  dimensions; it terminates when only `"ar"` (the implicit year axis)
  remains.

  This is the documented API contract — no scraping, no CMS quirks —
  and individual `get_dimensions()` calls are cached transparently via
  nordstatExtras. First-pass runtime is comparable to scraping
  (~15-20 min for all 57 products); re-runs hit the cache and complete
  in seconds. Return shape is identical to the removed scrape variants:
  `tibble(product, measure, dimensions)` with `dimensions` as a list-col.

# rTrafa 0.1.0.9005 (development)

## Bug fixes

* `scrape_allowed_combinations()` now retries with exponential backoff
  when Trafa serves the "skeleton" HTML variant. trafa.se has two
  back-end variants for the API documentation pages: a smaller skeleton
  without the rendered combinations list (~51 KB for product T10010) and
  the full version with `<ul class="api-combos">` populated (~95 KB).
  Both return HTTP 200 from the same URL, with roughly 50/50 distribution.
  Previous behaviour: scraping succeeded ~50 % of the time. New
  behaviour: up to `max_attempts` (default 5) tries with sleeps of
  0.3 s, 0.6 s, 1.2 s, 2.4 s between — gives ~97 % single-call success.
* The "no combinations found" error message now explains the skeleton-
  variant phenomenon and suggests raising `max_attempts` or checking the
  page in a browser.

# rTrafa 0.1.0.9004 (development)

## Minor changes

* `scrape_allowed_combinations()` and `scrape_all_allowed_combinations()`
  now accept a `verbose` argument. When `TRUE`, the functions print
  diagnostic messages — the URL fetched, the number of `<ul.api-combos>`
  and `<li>` elements found, the first three raw scraped strings, the
  number of measure codes resolved from the API, and the final result
  shape. Useful when scraping fails or returns unexpected results.
* The "no `<ul class='api-combos'>` found" error now suggests re-running
  with `verbose = TRUE` for diagnostics.

# rTrafa 0.1.0.9003 (development)

## New features

* `scrape_allowed_combinations(product)` and
  `scrape_all_allowed_combinations()` read the *valid variable
  combinations* for a Trafa product from the public HTML documentation
  at `trafa.se/sidor/api-dokumentation/?code=<product>`. This information
  is not exposed via the Trafa API but is essential for generating
  actionable error messages when the API returns "no data" for an invalid
  filter combination.

  **Architectural caveat:** Unlike all other functions in this package,
  these two **do not call the Trafa API**. They scrape the public
  documentation website, which is outside the API contract. Both
  functions print an informational message on each call (suppressible via
  `silent = TRUE`) to make this distinction obvious. The URL is
  configurable via the `TRAFA_DOCS_URL_TEMPLATE` environment variable to
  ease testing and to provide a quick override if Trafa restructures
  their CMS.

  Errors during scraping are surfaced via `warning()` so batch jobs
  (e.g. cron-driven cache priming) can keep running when an individual
  product page fails.

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
