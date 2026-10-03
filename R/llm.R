llm_chat <- function(provider, model, messages, temperature = 0, max_tokens = 1000) {
  if (identical(provider, "mock")) {
    return(mock_chat(messages = messages, model = model))
  }

  if (identical(provider, "openrouter")) {
    return(openrouter_chat(
      model = model,
      messages = messages,
      temperature = temperature,
      max_tokens = max_tokens
    ))
  }

  stop("Provider no soportado: ", provider, call. = FALSE)
}

openrouter_chat <- function(model, messages, temperature = 0, max_tokens = 1000) {
  load_env()
  api_key <- Sys.getenv("OPENROUTER_API_KEY", unset = "")
  if (identical(api_key, "")) {
    stop("Falta OPENROUTER_API_KEY. Configuralo en .env o en el entorno.", call. = FALSE)
  }

  started <- Sys.time()
  response <- httr2::request("https://openrouter.ai/api/v1/chat/completions") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json",
      `HTTP-Referer` = "https://github.com/qualitative-coder",
      `X-Title` = "QualitativeCoder"
    ) |>
    httr2::req_body_json(list(
      model = model,
      messages = messages,
      temperature = temperature,
      max_tokens = max_tokens
    ), auto_unbox = TRUE) |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = FALSE)

  latency <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  content <- response$choices[[1]]$message$content

  list(
    content = content,
    raw = response,
    latency = latency,
    usage = response$usage %||% NULL,
    status = "ok",
    error = NA_character_
  )
}

mock_chat <- function(messages, model) {
  started <- Sys.time()
  user_message <- messages[[length(messages)]]$content
  text <- sub("(?s).*DOCUMENTO:\\s*", "", user_message, perl = TRUE)
  text_lower <- tolower(text)
  dimension <- stringr::str_match(user_message, "DIMENSION: ([A-Za-z0-9_-]+)")[, 2]

  if (identical(dimension, "risk_mentioned")) {
    has_risk <- grepl("riesgo|preocup|privacidad|depend|automático|automatico|problema|reemplaz", text_lower)
    code <- if (has_risk) "yes" else "no"
    evidence <- if (has_risk) {
      stringr::str_extract(text, "(?i)(riesgo|preocup[^.]*|privacidad|depend[^.]*|autom[aá]tic[^.]*|problema[^.]*|reemplaz[^.]*)")
    } else {
      ""
    }
  } else if (grepl("pero|aunque|sin embargo", text_lower)) {
    code <- "mixed"
    evidence <- stringr::str_extract(text, "(?i)(pero|aunque|sin embargo).*")
  } else if (grepl("ayuda|mejora|ahorra|útil|util|confío|confio|positivo", text_lower)) {
    code <- "positive"
    evidence <- stringr::str_extract(text, "(?i)(ayuda|mejora|ahorra|[úu]til|conf[ií]o|positivo)[^.]*")
  } else if (grepl("preocupa|prefiero no|problema|negativo|dudo|miedo", text_lower)) {
    code <- "negative"
    evidence <- stringr::str_extract(text, "(?i)(preocupa|prefiero no|problema|negativo|dudo|miedo)[^.]*")
  } else {
    code <- "neutral"
    evidence <- ""
  }

  body <- list(
    code = code,
    evidence = evidence %||% "",
    explanation = "Respuesta determinística generada por provider mock para probar el pipeline."
  )

  list(
    content = jsonlite::toJSON(body, auto_unbox = TRUE),
    raw = list(provider = "mock", model = model, body = body),
    latency = as.numeric(difftime(Sys.time(), started, units = "secs")),
    usage = NULL,
    status = "ok",
    error = NA_character_
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
