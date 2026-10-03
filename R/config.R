load_env <- function(path = ".env") {
  if (file.exists(path)) {
    dotenv::load_dot_env(path)
  }
  invisible(TRUE)
}

load_project_config <- function(config_path = "projects/example_project/project.yml") {
  project_dir <- dirname(config_path)
  if (!file.exists(config_path)) {
    stop("No existe project.yml: ", config_path, call. = FALSE)
  }

  cfg <- yaml::read_yaml(config_path)
  cfg$paths <- list(
    project_dir = project_dir,
    config = config_path,
    corpus = file.path(project_dir, cfg$corpus$path),
    human_coding = file.path(project_dir, cfg$human_coding$path),
    outputs = file.path(project_dir, cfg$outputs$path),
    run_dir = file.path(project_dir, cfg$outputs$path, "runs", cfg$run$id),
    base_prompt = project_path("resources", "prompts", "base_coder.md")
  )
  cfg
}

get_codebook_paths <- function(cfg) {
  active_coders <- purrr::keep(cfg$coders, function(coder) isTRUE(coder$active))
  purrr::map_chr(active_coders, function(coder) file.path(cfg$paths$project_dir, coder$codebook))
}

read_corpus <- function(cfg, corpus_file = cfg$paths$corpus) {
  readr::read_csv(corpus_file, show_col_types = FALSE)
}

read_codebooks <- function(cfg, codebook_files = get_codebook_paths(cfg)) {
  active_coders <- purrr::keep(cfg$coders, function(coder) isTRUE(coder$active))

  purrr::map2(active_coders, codebook_files, function(coder, codebook_path) {
    codebook <- yaml::read_yaml(codebook_path)
    codebook$path <- codebook_path
    codebook$file_hash <- hash_file(codebook_path)
    codebook
  }) |>
    rlang::set_names(purrr::map_chr(active_coders, "id"))
}

read_human_coding <- function(cfg, human_coding_file = cfg$paths$human_coding) {
  required <- isTRUE(cfg$human_coding$required)

  if (is.na(human_coding_file) || !file.exists(human_coding_file)) {
    if (required) {
      stop("No existe el gold standard requerido: ", human_coding_file, call. = FALSE)
    }
    return(tibble::tibble())
  }

  readr::read_csv(human_coding_file, show_col_types = FALSE)
}

optional_human_coding_file <- function(cfg) {
  if (file.exists(cfg$paths$human_coding)) {
    return(cfg$paths$human_coding)
  }

  NA_character_
}
