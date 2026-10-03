suppressPackageStartupMessages(library(targets))

source("R/utils.R")
source("R/config.R")
source("R/llm.R")
source("R/validation.R")
source("R/coder.R")
source("R/orchestrator.R")
source("R/metrics.R")
source("R/report.R")

tar_option_set(
  packages = c("dplyr", "purrr", "readr", "tibble", "stringr", "httr2", "jsonlite", "yaml", "dotenv", "digest")
)

list(
  tar_target(
    project_config_file,
    Sys.getenv("QC_PROJECT_CONFIG", "projects/example_project/project.yml"),
    format = "file",
    cue = tar_cue(mode = "always")
  ),
  tar_target(config, load_project_config(project_config_file)),
  tar_target(corpus_file, config$paths$corpus, format = "file"),
  tar_target(corpus, read_corpus(config, corpus_file)),
  tar_target(codebook_files, get_codebook_paths(config), format = "file"),
  tar_target(codebooks, read_codebooks(config, codebook_files)),
  tar_target(base_prompt_file, config$paths$base_prompt, format = "file"),
  tar_target(run_manifest, create_run_manifest(config, codebooks)),
  tar_target(coding_results, run_coders(config, corpus, codebooks, base_prompt_file)),
  tar_target(codings, collect_codings(coding_results)),
  tar_target(saved_codings, save_run_outputs(config, run_manifest, coding_results, codings), format = "file"),
  tar_target(human_coding, read_human_coding(config), cue = tar_cue(mode = "always")),
  tar_target(metrics, calculate_accuracy(codings, human_coding)),
  tar_target(saved_metrics, save_metrics(config, metrics)),
  tar_target(
    report,
    generate_run_report(config, codings, metrics),
    format = "file",
    cue = tar_cue(mode = "always")
  )
)
