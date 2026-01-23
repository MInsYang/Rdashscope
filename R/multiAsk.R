new_chat <- function(model = "qwen-plus",
                     api_key = Sys.getenv("DASHSCOPE_API_KEY"),
                     base_url = getOption("llm.base_url", getOption("dashscope.base_url","https://dashscope.aliyuncs.com/compatible-mode/v1")),
                     system_prompt = "You are a senior data analysis assistant.",
                     max_turns = 20,
                     ...) {
  history <- list(list(role="system", content=system_prompt))
  extra_args <- list(...)
  extra_args$api_key <- api_key
  extra_args$base_url <- base_url

  ask <- function(user_text, x=NULL, images=NULL) {
    if (!is.null(x)) user_text <- paste0(user_text, "\n\n### Attached R object (auto-formatted)\n", format_input(x))
    content <- build_content(user_text, images=images)
    history <<- c(history, list(list(role="user", content=content)))
    if (length(history) > 1 + max_turns*2) history <<- c(history[1], utils::tail(history, max_turns*2))
    resp <- do.call(llm_chat_completions, c(list(messages=history, model=model), extra_args))
    answer <- llm_extract_text(resp)
    history <<- c(history, list(list(role="assistant", content=answer)))
    answer
  }

  structure(list(ask=ask,
                 history=function() history,
                 reset=function(){history <<- list(list(role="system", content=system_prompt)); invisible(TRUE)},
                 model=model, api_key=api_key, base_url=base_url),
            class="llm_chat_session")
}

multiAsk <- function(session,
                     user_text,
                     x=NULL,
                     images=NULL,
                     return = c("auto","text","code","function","markdown","dataframe","list","pptx","docx","xlsx","both"),
                     formatter_model = NULL,
                     pptx_template = NULL) {
  return <- match.arg(return)
  if (is.null(session) || !is.list(session) || is.null(session$ask)) stop("`session` must be created by new_chat().", call.=FALSE)
  txt <- session$ask(user_text, x=x, images=images)
  if (is.null(formatter_model) || !nzchar(formatter_model)) formatter_model <- session$model
  postprocess_reply(txt, return=return, formatter_model=formatter_model, api_key=session$api_key, base_url=session$base_url, pptx_template=pptx_template)
}
