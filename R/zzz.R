.onLoad <- function(libname, pkgname) {
  if (is.null(getOption("llm.base_url")) && is.null(getOption("dashscope.base_url"))) {
    options(llm.base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1")
    options(dashscope.base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1") # compat
  }
}
