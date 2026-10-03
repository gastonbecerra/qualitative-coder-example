create_run_manifest <- function(cfg, codebooks) {
  list(
    project = cfg$project,
    corpus = cfg$corpus,
    run = cfg$run,
    coders = purrr::map(codebooks, function(codebook) {
      list(
        id = codebook$id,
        version = codebook$version,
        type = codebook$type,
        path = codebook$path,
        file_hash = codebook$file_hash
      )
    }),
    files = list(
      project_config = list(path = cfg$paths$config, hash = hash_file(cfg$paths$config)),
      corpus = list(path = cfg$paths$corpus, hash = hash_file(cfg$paths$corpus)),
      human_coding = list(path = cfg$paths$human_coding, hash = hash_file(cfg$paths$human_coding)),
      base_prompt = list(
        path = cfg$paths$base_prompt,
        hash = hash_file(cfg$paths$base_prompt)
      )
    ),
    created_at = timestamp_utc()
  )
}

run_coders <- function(cfg, corpus, codebooks, base_prompt_file = cfg$paths$base_prompt) {
  cfg$paths$base_prompt <- base_prompt_file
  rows <- purrr::pmap(corpus, function(...) tibble::tibble(...))
  results <- list()

  for (doc in rows) {
    for (codebook in codebooks) {
      key <- paste(doc[[cfg$corpus$document_id_column]], codebook$id, sep = "__")
      results[[key]] <- code_document(doc, codebook, cfg)
    }
  }

  results
}

collect_codings <- function(coding_results) {
  purrr::map_dfr(coding_results, "coding")
}

save_run_outputs <- function(cfg, manifest, coding_results, codings) {
  run_dir <- cfg$paths$run_dir
  raw_dir <- file.path(run_dir, "raw")
  ensure_dir(raw_dir)

  yaml::write_yaml(manifest, file.path(run_dir, "manifest.yml"))
  readr::write_csv(codings, file.path(run_dir, "codings.csv"))

  purrr::iwalk(coding_results, function(result, name) {
    write_json_file(result$raw, file.path(raw_dir, paste0(safe_id(name), ".json")))
  })

  file.path(run_dir, "codings.csv")
}

save_metrics <- function(cfg, metrics) {
  if (is.null(metrics) || nrow(metrics) == 0) {
    return(NA_character_)
  }

  path <- file.path(cfg$paths$run_dir, "metrics.csv")
  ensure_dir(dirname(path))
  readr::write_csv(metrics, path)
  path
}
