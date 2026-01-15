#' Create a multi-turn chat session
#'
#' @param model Model name (vendor-specific).
#' @param system_prompt System instruction.
#' @param max_turns Keep at most this many recent turns (user+assistant pairs).
#' @param ... Passed to the HTTP client (temperature, max_tokens, api_key, base_url, etc).
#' @return A session object (list) with $ask(), $history(), $reset().
#' @export
new_chat <- function(model = "qwen-plus",
                     system_prompt = "You are a senior single-cell bioinformatics assistant.",
                     max_turns = 20,
                     ...) {
  history <- list(list(role = "system", content = system_prompt))
  extra_args <- list(...)

  ask <- function(user_text, x = NULL) {
    if (!is.null(x)) {
      user_text <- paste0(
        user_text, "\n\n### Attached R object (auto-formatted)\n",
        format_input(x)
      )
    }

    history <<- c(history, list(list(role = "user", content = user_text)))

    if (length(history) > 1 + max_turns * 2) {
      history <<- c(history[1], utils::tail(history, max_turns * 2))
    }

    resp <- do.call(dashscope_chat_completions, c(list(messages = history, model = model), extra_args))
    answer <- dashscope_extract_text(resp)
    history <<- c(history, list(list(role = "assistant", content = answer)))
    answer
  }

  get_history <- function() history
  reset <- function() { history <<- list(list(role = "system", content = system_prompt)); invisible(TRUE) }

  structure(list(ask = ask, history = get_history, reset = reset),
            class = "qwen_chat_session")
}

#' Continue a chat session (multi-turn)
#'
#' @param session A session created by new_chat().
#' @param user_text User message text.
#' @param x Optional R object to attach (auto formatted).
#' @return Assistant reply as a character string.
#' @export
multiAsk <- function(session, user_text, x = NULL) {
  if (is.null(session) || !is.list(session) || is.null(session$ask)) {
    stop("`session` must be created by new_chat().", call. = FALSE)
  }
  session$ask(user_text, x = x)
}
