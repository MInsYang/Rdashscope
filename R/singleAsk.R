singleAsk <- function(x,
                      task,
                      model = "qwen-plus",
                      api_key = Sys.getenv("DASHSCOPE_API_KEY"),
                      base_url = getOption("llm.base_url", getOption("dashscope.base_url","https://dashscope.aliyuncs.com/compatible-mode/v1")),
                      images = NULL,
                      return = c("auto","text","code","function","markdown","dataframe","list","pptx","docx","xlsx","both","raw"),
                      formatter_model = model,
                      system_prompt = "You are a senior data analysis assistant. Be concise and give executable R code when helpful.",
                      pptx_template = NULL,
                      ...) {
  return <- match.arg(return)

  payload <- format_input(x)
  user_text <- paste0("### Task\n", task, "\n\n### Input (auto-formatted)\n", payload)
  content <- build_content(user_text, images=images)

  messages <- list(list(role="system", content=system_prompt),
                   list(role="user", content=content))

  resp <- llm_chat_completions(messages=messages, model=model, api_key=api_key, base_url=base_url, ...)
  if (return=="raw") return(resp)
  txt <- llm_extract_text(resp)

  postprocess_reply(txt, return=return, formatter_model=formatter_model, api_key=api_key, base_url=base_url, pptx_template=pptx_template)
}
