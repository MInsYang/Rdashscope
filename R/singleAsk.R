#' Ask the model once (one-shot)
#'
#' @param x Any R object (data.frame, Seurat, character, list, ...).
#' @param task What you want the model to do.
#' @param model Model name (vendor-specific).
#' @param system_prompt System instruction.
#' @param return 'text' (default) or 'raw' (full JSON response).
#' @param ... Passed to the HTTP client (e.g., temperature, max_tokens, timeout_s, api_key, base_url).
#' @return A character string (or a raw response list if return="raw").
#' @export
singleAsk <- function(x,
                      task,
                      model = "qwen-plus",
                      system_prompt = "You are a senior single-cell bioinformatics assistant. Be concise, correct, and give executable R code when helpful.",
                      return = c("text", "raw"),
                      ...) {
  return <- match.arg(return)

  payload <- format_input(x)
  user_content <- paste0(
    "### Task\n", task, "\n\n",
    "### Input (auto-formatted)\n", payload
  )

  messages <- list(
    list(role = "system", content = system_prompt),
    list(role = "user", content = user_content)
  )

  resp <- dashscope_chat_completions(messages = messages, model = model, ...)
  if (return == "raw") return(resp)
  dashscope_extract_text(resp)
}
