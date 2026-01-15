# Internal OpenAI-compatible Chat Completions client

#' @keywords internal
dashscope_chat_completions <- function(messages,
                                       model = "qwen-plus",
                                       base_url = getOption("llm.base_url",
                                         getOption("dashscope.base_url",
                                           "https://dashscope.aliyuncs.com/compatible-mode/v1")),
                                       api_key = Sys.getenv("DASHSCOPE_API_KEY"),
                                       temperature = 0.2,
                                       top_p = 0.9,
                                       max_tokens = 1024,
                                       seed = NULL,
                                       extra = list(),
                                       timeout_s = 120,
                                       verbose = FALSE) {
  if (!nzchar(api_key)) {
    stop("Missing API key. Supply `api_key=` or set an environment variable and pass it in.", call. = FALSE)
  }
  if (missing(messages) || !is.list(messages)) {
    stop("`messages` must be a list of {role, content} items.", call. = FALSE)
  }

  base_url <- normalize_base_url(base_url)

  body <- c(list(
    model = model,
    messages = messages,
    temperature = temperature,
    top_p = top_p,
    max_tokens = max_tokens
  ), if (!is.null(seed)) list(seed = seed) else list(), extra)

  req <- httr2::request(paste0(base_url, "/chat/completions")) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(body, auto_unbox = TRUE, null = "null") |>
    httr2::req_timeout(timeout_s)

  if (isTRUE(verbose)) req <- httr2::req_verbose(req)

  resp <- httr2::req_perform(req)
  httr2::resp_check_status(resp)

  # IMPORTANT: simplifyVector=FALSE to avoid turning choices into a data.frame
  out <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  # Some vendors may return 200 with an embedded error object
  if (!is.null(out$error)) {
    msg <- out$error$message %||% "Unknown API error"
    stop(msg, call. = FALSE)
  }

  out
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

#' @keywords internal
dashscope_extract_text <- function(resp_json) {
  if (is.null(resp_json)) return("")

  # Common OpenAI-compatible: choices[[1]]$message$content
  choices <- resp_json$choices

  # If simplifyVector was TRUE upstream, choices might be data.frame; handle anyway
  if (is.data.frame(choices)) {
    if ("message.content" %in% names(choices)) return(as.character(choices[1, "message.content"]))
    if ("text" %in% names(choices)) return(as.character(choices[1, "text"]))
  }

  if (is.list(choices) && length(choices) >= 1) {
    c1 <- choices[[1]]
    # message.content
    if (!is.null(c1$message) && !is.null(c1$message$content)) return(as.character(c1$message$content))
    # some providers use "text"
    if (!is.null(c1$text)) return(as.character(c1$text))
    # streaming delta (if any)
    if (!is.null(c1$delta) && !is.null(c1$delta$content)) return(as.character(c1$delta$content))
  }

  ""
}
