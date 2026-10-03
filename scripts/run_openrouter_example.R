Sys.setenv(QC_PROJECT_CONFIG = "projects/example_project/project_openrouter.yml")

old_warn <- getOption("warn")
options(warn = -1)
on.exit(options(warn = old_warn), add = TRUE)

targets::tar_make(callr_function = NULL)
