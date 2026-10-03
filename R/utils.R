project_path <- function(...) {
  file.path(normalizePath(".", winslash = "/", mustWork = TRUE), ...)
}

timestamp_utc <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

safe_id <- function(x) {
  gsub("[^A-Za-z0-9_-]+", "_", x)
}

hash_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  digest::digest(file = path, algo = "sha256")
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(path)
}

read_text_file <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

write_json_file <- function(x, path) {
  ensure_dir(dirname(path))
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(path)
}
