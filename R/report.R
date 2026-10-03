format_report_table <- function(x) {
  if (is.null(x) || nrow(x) == 0) {
    return("_Sin datos._")
  }

  cols <- names(x)
  header <- paste(cols, collapse = " | ")
  separator <- paste(rep("---", length(cols)), collapse = " | ")
  rows <- apply(x, 1, function(row) paste(row, collapse = " | "))

  paste(c(header, separator, rows), collapse = "\n")
}

generate_run_report <- function(cfg, codings, metrics) {
  run_dir <- cfg$paths$run_dir
  ensure_dir(run_dir)

  status_summary <- codings |>
    dplyr::count(dimension, status, name = "n") |>
    dplyr::arrange(dimension, status)

  errors <- codings |>
    dplyr::filter(status != "ok") |>
    dplyr::select(document_id, dimension, code, error)

  coding_summary <- codings |>
    dplyr::filter(status == "ok") |>
    dplyr::count(dimension, code, name = "n") |>
    dplyr::arrange(dimension, code)

  lines <- c(
    paste0("# Run Report: ", cfg$run$id),
    "",
    "## Run",
    "",
    paste0("- Project: `", cfg$project$id, "`"),
    paste0("- Corpus: `", cfg$corpus$id, "`"),
    paste0("- Provider: `", cfg$run$provider, "`"),
    paste0("- Model: `", cfg$run$model, "`"),
    paste0("- Prompt strategy: `", cfg$run$prompt_strategy, "`"),
    paste0("- Generated at: `", timestamp_utc(), "`"),
    "",
    "## Codificaciones",
    "",
    paste0("- Total rows: `", nrow(codings), "`"),
    paste0("- OK: `", sum(codings$status == "ok"), "`"),
    paste0("- Errors: `", sum(codings$status != "ok"), "`"),
    "",
    "### Estado Por Dimensión",
    "",
    format_report_table(status_summary),
    "",
    "### Códigos Asignados",
    "",
    format_report_table(coding_summary),
    "",
    "## Errores",
    "",
    format_report_table(errors),
    "",
    "## Métricas",
    "",
    format_report_table(metrics),
    "",
    "## Archivos",
    "",
    paste0("- Codings: `", file.path(run_dir, "codings.csv"), "`"),
    paste0("- Metrics: `", file.path(run_dir, "metrics.csv"), "`"),
    paste0("- Manifest: `", file.path(run_dir, "manifest.yml"), "`"),
    paste0("- Raw responses: `", file.path(run_dir, "raw"), "`")
  )

  report_path <- file.path(run_dir, "report.md")
  writeLines(lines, report_path, useBytes = TRUE)
  report_path
}
