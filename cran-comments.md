## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Windows 11 Enterprise, R 4.5.2
* GitHub Actions: ubuntu-latest (R release, R devel), macos-latest (R release), windows-latest (R release)

## Notes

This is the first CRAN submission of rTrafa.

The package wraps the Trafa API (https://api.trafa.se/) for Swedish
transport statistics. All examples and tests are guarded by
`trafa_available()` to degrade gracefully when the API is unreachable.

An optional enhanced caching feature (SQLite-backed shared cache) is
available via the nordstatExtras package
(https://github.com/LoveHansson/nordstatExtras), which is not on CRAN.
nordstatExtras is listed in Suggests. It is not yet on CRAN but is
available via GitHub (https://github.com/LoveHansson/nordstatExtras).
All integration points use `requireNamespace("nordstatExtras",
quietly = TRUE)` with a graceful fallback to standard `.rds` file
caching when it is not installed. No functionality is lost without it.
