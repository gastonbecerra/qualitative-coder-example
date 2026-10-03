calculate_accuracy <- function(codings, human_coding) {
  if (is.null(human_coding) || nrow(human_coding) == 0) {
    return(tibble::tibble())
  }

  required_cols <- c("document_id", "dimension", "gold_code")
  missing_cols <- setdiff(required_cols, names(human_coding))
  if (length(missing_cols) > 0) {
    stop("Faltan columnas en human coding: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  codings |>
    dplyr::filter(status == "ok") |>
    dplyr::select(document_id, dimension, code) |>
    dplyr::inner_join(human_coding, by = c("document_id", "dimension")) |>
    dplyr::mutate(correct = code == gold_code) |>
    dplyr::group_by(dimension) |>
    dplyr::summarise(
      metric = "accuracy",
      value = mean(correct),
      n = dplyr::n(),
      .groups = "drop"
    )
}
