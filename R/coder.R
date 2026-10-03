build_codebook_text <- function(codebook) {
  labels <- purrr::map_chr(codebook$labels, function(label) {
    paste0("- ", label$id, ": ", label$description)
  })

  paste(c(
    paste0("DIMENSION: ", codebook$id),
    paste0("VERSION: ", codebook$version),
    paste0("PREGUNTA: ", codebook$question),
    "CODIGOS PERMITIDOS:",
    labels
  ), collapse = "\n")
}

build_examples_text <- function(codebook) {
  if (is.null(codebook$examples) || length(codebook$examples) == 0) {
    return("")
  }

  examples <- purrr::map_chr(codebook$examples, function(example) {
    paste0(
      "Texto: ", example$text, "\n",
      "Code: ", example$code, "\n",
      "Evidence: ", example$evidence
    )
  })

  paste(c("EJEMPLOS:", examples), collapse = "\n\n")
}

build_coder_messages <- function(document_text, codebook, cfg) {
  base_prompt <- read_text_file(cfg$paths$base_prompt)
  prompt_strategy <- cfg$run$prompt_strategy
  examples <- if (identical(prompt_strategy, "few_shot")) build_examples_text(codebook) else ""

  user_content <- paste(c(
    build_codebook_text(codebook),
    examples,
    "DOCUMENTO:",
    document_text
  ), collapse = "\n\n")

  list(
    list(role = "system", content = base_prompt),
    list(role = "user", content = user_content)
  )
}

code_document <- function(document, codebook, cfg) {
  started_at <- timestamp_utc()
  messages <- build_coder_messages(
    document_text = document[[cfg$corpus$text_column]],
    codebook = codebook,
    cfg = cfg
  )

  result <- tryCatch(
    llm_chat(
      provider = cfg$run$provider,
      model = cfg$run$model,
      messages = messages,
      temperature = cfg$run$temperature,
      max_tokens = cfg$run$max_tokens
    ),
    error = function(e) {
      list(
        content = NA_character_,
        raw = list(error = conditionMessage(e)),
        latency = NA_real_,
        usage = NULL,
        status = "error",
        error = conditionMessage(e)
      )
    }
  )

  parsed <- if (identical(result$status, "ok")) parse_coding_response(result$content) else list()
  validation <- if (identical(codebook$type, "single_label") && identical(result$status, "ok")) {
    validate_single_label(parsed, codebook)
  } else if (!identical(result$status, "ok")) {
    list(valid = FALSE, error = result$error)
  } else {
    list(valid = FALSE, error = paste0("Tipo de codebook no soportado: ", codebook$type))
  }

  status <- if (identical(result$status, "ok") && isTRUE(validation$valid)) "ok" else "error"
  usage <- result$usage %||% list()

  list(
    coding = tibble::tibble(
      project_id = cfg$project$id,
      corpus_id = cfg$corpus$id,
      run_id = cfg$run$id,
      document_id = document[[cfg$corpus$document_id_column]],
      dimension = codebook$id,
      code = if (!is.null(parsed$code)) parsed$code else NA_character_,
      evidence = if (!is.null(parsed$evidence)) parsed$evidence else NA_character_,
      explanation = if (!is.null(parsed$explanation)) parsed$explanation else NA_character_,
      model = cfg$run$model,
      provider = cfg$run$provider,
      prompt_strategy = cfg$run$prompt_strategy,
      codebook_version = codebook$version,
      timestamp = started_at,
      latency = result$latency,
      prompt_tokens = usage$prompt_tokens %||% NA_integer_,
      completion_tokens = usage$completion_tokens %||% NA_integer_,
      total_tokens = usage$total_tokens %||% NA_integer_,
      cost = NA_real_,
      status = status,
      error = validation$error %||% result$error
    ),
    raw = result$raw
  )
}
