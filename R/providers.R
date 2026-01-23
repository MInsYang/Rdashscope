normalize_base_url <- function(x) {
  if (is.null(x) || !nzchar(x)) return(x)
  sub("/+$", "", x)
}

set_provider <- function(provider = c("dashscope", "deepseek", "gemini", "custom"),
                         base_url = NULL) {
  provider <- match.arg(provider)
  preset <- switch(
    provider,
    dashscope = "https://dashscope.aliyuncs.com/compatible-mode/v1",
    deepseek  = "https://api.deepseek.com",
    gemini    = "https://generativelanguage.googleapis.com/v1beta/openai",
    custom    = base_url
  )
  if (is.null(preset) || !nzchar(preset)) stop("When provider='custom', you must supply `base_url`.", call. = FALSE)
  preset <- normalize_base_url(preset)
  options(llm.base_url = preset)
  options(dashscope.base_url = preset)
  invisible(preset)
}

get_provider <- function() {
  normalize_base_url(getOption("llm.base_url", getOption("dashscope.base_url", "")))
}
