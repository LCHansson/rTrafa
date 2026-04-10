# Internal HTTP and utility functions

# API base URL (single, fixed endpoint)
trafa_base_url <- "https://api.trafa.se"

#' Perform an HTTP GET request to the Trafa API
#' @param url URL to request.
#' @param verbose Print request details.
#' @return Parsed JSON as list, or NULL on failure.
#' @noRd
trafa_get <- function(url, verbose = FALSE, .retry = 0L, .max_retries = 3L) {
  if (verbose) inform(paste("GET", url))

  res <- tryCatch(
    httr2::request(url) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform(),
    error = function(e) {
      warn(paste("Could not connect to Trafa API:", conditionMessage(e)))
      return(NULL)
    }
  )

  if (is.null(res)) return(NULL)

  status <- httr2::resp_status(res)
  if (status == 429) {
    if (.retry >= .max_retries) {
      warn(paste0("Rate limited by Trafa API after ", .max_retries, " retries: ", url))
      return(NULL)
    }
    delay <- 2^.retry
    if (verbose) inform(paste0("Rate limited (429). Retrying in ", delay, "s..."))
    Sys.sleep(delay)
    return(trafa_get(url, verbose = verbose, .retry = .retry + 1L,
                     .max_retries = .max_retries))
  }
  if (status >= 400) {
    warn(paste0("Trafa API returned HTTP ", status, " for: ", url))
    return(NULL)
  }

  parse_json_response(res)
}

#' Parse a JSON response
#' @param res An httr2 response object.
#' @return Parsed JSON as list, or NULL on failure.
#' @noRd
parse_json_response <- function(res) {
  result <- tryCatch(
    httr2::resp_body_json(res),
    error = function(e) NULL
  )

  if (!is.null(result)) return(result)

  tryCatch({
    raw_text <- httr2::resp_body_string(res)
    jsonlite::fromJSON(raw_text, simplifyVector = FALSE)
  }, error = function(e) {
    warn(paste("Failed to parse Trafa API response:", conditionMessage(e)))
    NULL
  })
}

#' Shared search helper
#' @param df Tibble to filter.
#' @param query Character vector of search terms (combined with OR).
#' @param column Column names to search. NULL = all character columns.
#' @param caller Name of calling function for warnings.
#' @return Filtered tibble.
#' @noRd
entity_search <- function(df, query, column = NULL, caller = "search") {
  if (is.null(df) || nrow(df) == 0) {
    warn(paste0("An empty object was used as input to ", caller, "()."))
    return(df)
  }

  if (is.null(column)) {
    chr_cols <- names(df)[vapply(df, is.character, logical(1))]
    list_cols <- names(df)[vapply(df, is.list, logical(1))]
    column <- c(chr_cols, list_cols)
  }

  pattern <- tolower(paste(query, collapse = "|"))

  chr_cols <- intersect(column, names(df)[vapply(df, is.character, logical(1))])
  list_cols <- intersect(column, names(df)[vapply(df, is.list, logical(1))])

  chr_match <- if (length(chr_cols) > 0) {
    mat <- vapply(chr_cols, function(col) {
      grepl(pattern, tolower(df[[col]]), perl = TRUE)
    }, logical(nrow(df)))
    # vapply returns a vector (not matrix) when nrow(df) == 1
    if (is.matrix(mat)) apply(mat, 1, any) else any(mat)
  } else {
    rep(FALSE, nrow(df))
  }

  list_match <- if (length(list_cols) > 0) {
    matches <- vapply(list_cols, function(col) {
      vapply(df[[col]], function(x) {
        any(grepl(pattern, tolower(as.character(x)), perl = TRUE))
      }, logical(1))
    }, logical(nrow(df)))
    if (is.matrix(matches)) apply(matches, 1, any) else matches
  } else {
    rep(FALSE, nrow(df))
  }

  df[chr_match | list_match, , drop = FALSE]
}

#' Remove monotonous columns from a tibble
#' @param df Tibble.
#' @return Tibble with monotonous columns removed.
#' @noRd
remove_monotonous <- function(df) {
  if (is.null(df) || nrow(df) <= 1) return(df)

  keep <- vapply(df, function(col) {
    length(unique(col)) > 1
  }, logical(1))

  df[, keep, drop = FALSE]
}

#' Resolve lang parameter, falling back to option
#' @param lang User-supplied lang or NULL.
#' @return Character: "SV" or "EN".
#' @noRd
resolve_lang <- function(lang = NULL) {
  lang <- lang %||% getOption("rTrafa.lang", "SV")
  lang <- toupper(lang)
  if (!lang %in% c("SV", "EN")) {
    abort("lang must be \"SV\" or \"EN\".")
  }
  lang
}
