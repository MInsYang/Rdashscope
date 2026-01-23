set_pptx_template <- function(path) {
  if (!is.character(path) || length(path) != 1 || !nzchar(path)) stop("`path` must be a single string.", call.=FALSE)
  if (!file.exists(path)) stop("Template file not found: ", path, call.=FALSE)
  options(Rdashscope.pptx_template = normalizePath(path, winslash = "/", mustWork = TRUE))
  invisible(getOption("Rdashscope.pptx_template"))
}

get_pptx_template <- function() {
  getOption("Rdashscope.pptx_template", NULL)
}
