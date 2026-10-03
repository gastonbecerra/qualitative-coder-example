old_warn <- getOption("warn")
options(warn = -1)
on.exit(options(warn = old_warn), add = TRUE)

suppressWarnings(targets::tar_make(callr_function = NULL))
