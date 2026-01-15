# Provider presets + base_url helpers

#' Normalize base_url to avoid double slashes
#' @keywords internal
normalize_base_url <- function(x) {
  if (is.null(x) || !nzchar(x)) return(x)
  sub("/+$", "", x)
}

#' Set a provider preset (base_url)
#'
#' @param provider One of: "dashscope", "deepseek", "gemini", "custom".
#' @param base_url If provider="custom", set your own base_url.
#' @return Invisibly returns the chosen base_url.
#' @export
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

  if (is.null(preset) || !nzchar(preset)) {
    stop("When provider='custom', you must supply `base_url`.", call. = FALSE)
  }

  preset <- normalize_base_url(preset)

  options(llm.base_url = preset)
  options(dashscope.base_url = preset) # backward compatible

  invisible(preset)
}

#' Get the current base_url
#'
#' @return The current base_url resolved from \code{options(llm.base_url)} (or legacy \code{dashscope.base_url}).
#' @export
get_provider <- function() {
  normalize_base_url(
    getOption("llm.base_url", getOption("dashscope.base_url", ""))
  )
}
