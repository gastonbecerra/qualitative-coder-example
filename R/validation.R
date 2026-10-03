parse_coding_response <- function(content) {
  tryCatch(
    jsonlite::fromJSON(content, simplifyVector = TRUE),
    error = function(e) {
      list(.parse_error = conditionMessage(e))
    }
  )
}

validate_single_label <- function(parsed, codebook) {
  if (!is.null(parsed$.parse_error)) {
    return(list(valid = FALSE, error = parsed$.parse_error))
  }

  if (is.null(parsed$code) || !nzchar(parsed$code)) {
    return(list(valid = FALSE, error = "La respuesta no contiene code."))
  }

  allowed <- purrr::map_chr(codebook$labels, "id")
  if (!parsed$code %in% allowed) {
    return(list(valid = FALSE, error = paste0("Código no permitido: ", parsed$code)))
  }

  if (is.null(parsed$evidence)) {
    parsed$evidence <- ""
  }

  list(valid = TRUE, error = NA_character_)
}
