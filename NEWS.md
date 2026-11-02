# rTrafa 0.1.0.9014 (development)

## Bug fixes

- **`get_allowed_structure()` reads the answer it has for a set of one or
  two dimensions.** Such a set was accepted without a check, so a measure
  that takes a dimension only without the year would have got a set the
  source rules out. The answer for the measure, the year and that
  dimension, already fetched to learn what can be chosen beside it, now
  decides; no request is added. Not seen in the four recorded products.

# rTrafa 0.1.0.9013 (development)

## New features

- **`get_allowed_structure()`: which dimensions can be chosen together, for
  a whole product at once.** The Trafa API publishes no list of allowed
  combinations: its structure endpoint answers one selection at a time
  (which items can still be added), and its data endpoint does not refuse a
  selection that cannot be combined (it answers with no rows, or with a
  lone total row). `get_allowed_structure(product)` returns, per measure,
  the largest sets of dimensions that can be chosen together (`sets`); a
  selection is allowed when it is part of one of them. It asks one request
  per measure and dimension and one per candidate set, where the exhaustive
  walk of `discover_allowed_combinations()` asks one per allowed set. It
  rests on one assumption, that a part of an allowed set is itself allowed;
  the tests compare the two on recorded products, where they agree. A
  failed structure request stops it with an error of class
  `rtrafa_structure_failed`. What the structure does not say: which
  *values* of a dimension hold data for a measure (it lists the same values
  for every measure), so an allowed selection can still be empty.
- **`check_combination()`: can this measure and these dimensions be
  combined?** With the answer of `get_allowed_structure()` it is answered
  without a request and names what is in the way; without it, one structure
  request gives the API's own verdict on exactly that selection.
- **A failed or empty `get_data()` says when the structure rules the
  selection out.** On the failure path only (one extra structure request),
  the error's reasons gain "Trafa's structure rules out measure ...
  together with ...". What `get_data()` returns or signals is otherwise
  unchanged.

## Tests

- Structure answers recorded from the public API for four products
  (`tests/testthat/fixtures/structure-*.json`: t10011, t10030, t0802,
  t06013), played back without network by `helper-recorded-structure.R`.

# rTrafa 0.1.0.9012 (development)

## Breaking changes

- **`get_data()` stops with an error when a fetch gives no data.** It used
  to return `NULL` with a warning, and a script that did not test for
  `NULL` went on and failed later on something unrelated. The error has
  class `rtrafa_fetch_failed` when the request failed (no connection, an
  HTTP error, an answer that cannot be read), and `rtrafa_no_data` as well
  when the API answered without rows, which is what a measure and dimension
  combination without data gives. Its message carries what used to be the
  warnings (the HTTP status, a filter value the dimension does not list)
  and the request; the same are in the condition's fields `reasons` and
  `url`. To probe for data, catch the class:
  `tryCatch(get_data(...), rtrafa_no_data = function(e) NULL)`.
  `trafa_get_data()` forwards and so does the same.
  `discover_allowed_combinations(verify = TRUE)` already treated an error
  as "no data" and is unchanged. The other fetching functions
  (`get_products()`, `get_structure()`, `get_dimensions()`,
  `get_measures()`) still return `NULL` with a warning.
- A warning that concerns data that did arrive (the hidden breakdown, the
  silent total) is a warning as before.

# rTrafa 0.1.0.9011 (development)

## New features

- **`trafa_get_data()`: `get_data()` under a name that cannot be masked.**
  pixieweb exports a `get_data()` too, so in a script that attaches both
  packages the one attached last masks the other. `trafa_get_data()`
  forwards to `get_data()` unchanged (pixieweb gains `px_get_data()`), and
  attaching rTrafa while pixieweb is attached prints a one-line note
  naming the two safe calls.

# rTrafa 0.1.0.9010 (development)

## Bug fixes

- **A filter value the dimension does not list is named.** The Trafa API
  answers HTTP 500 for an unknown filter value (a year after the last
  published one, say), and `get_data()` came back empty with a warning
  that said nothing about the filter; the failure then surfaced downstream
  as something unrelated. `prepare_query()` now checks the values, not
  only the dimension names, and warns with the offending values and the
  ones the dimension has. `get_data()` does the same lookup when, and only
  when, the answer came back empty (one extra structure request on that
  path), so the warning names the cause. What the functions return is
  unchanged.
- `prepare_query()` no longer warns "Dimension '' not found" for a bare
  (unnamed) dimension argument.

# rTrafa 0.1.0.9009 (development)

## New features

- **Silent-total guard**: when a *bare* dimension (a requested breakdown)
  comes back with a single value, `get_data()` now warns instead of
  returning valid-looking data in which every subgroup silently reads as
  zero. Discovered via t10030, where aggregated heavy trucks
  (`fslag_under = "62"`) return a lone `drivm = "t1"` row with no fuel
  breakdown (dev-backlog 2026-08-17). Named single-value filters do not
  trigger the guard; raw pipe-delimited queries are covered.

# rTrafa 0.1.0.9008 (development)

## New features

- **`discover_allowed_combinations(verify = TRUE)`**: probes each
  discovered combination against the *data* endpoint (latest year,
  dimensions bare) and adds a `has_data` column. The structure endpoint
  can advertise measure/dimension spaces holding no rows at all —
  `t06013` lists `ton` with `ar` alone, yet only combinations including
  `trafik` plus one more dimension return data (AE 2026-08-04). The
  docs now state plainly that structure is not data.

## Bug fixes

- **Hidden-breakdown ambiguity is now detected**: some queries (e.g.
  `get_data("t0802", "godsvikt", ar = "2024")`) make the Trafa API break
  rows down by a dimension it does not include in the response — many
  rows share identical dimension values and cannot be told apart.
  `get_data()` previously passed this through silently (corrupting any
  downstream aggregation); it now warns with the row/combination counts
  and points to `discover_allowed_combinations()` (AE dev-backlog
  2026-08-03).
- The "No data rows" warning now explains the likely cause (invalid
  measure/dimension combination) and references
  `discover_allowed_combinations()`.

# rTrafa 0.1.0.9007 (development)

## New features

- **Bare (unfiltered) dimensions**: unnamed character arguments to
  `get_data()` / `compose_data_query()` are included without a value
  filter, so the API returns all values —
  `get_data("t10094", "mkorstr", "reglan", ar = "2024")` yields every
  county. Previously inexpressible (AE dev-backlog 2026-07-20).
- **Raw query strings**: `get_data(query = "t10094|mkorstr|ar:2024|reglan")`
  accepts a pipe-delimited query directly, exposing the full Trafa query
  language.

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
