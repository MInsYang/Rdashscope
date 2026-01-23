`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

build_content <- function(text, images = NULL) {
  if (is.null(images) || length(images) == 0) return(text)
  parts <- list(list(type = "text", text = text))
  for (img in images) {
    if (grepl("^https?://", img, ignore.case = TRUE)) {
      parts <- c(parts, list(list(type="image_url", image_url=list(url=img))))
    } else {
      if (!requireNamespace("base64enc", quietly = TRUE)) {
        stop("To pass local image files, please install the suggested package `base64enc`.", call. = FALSE)
      }
      if (!file.exists(img)) stop("Image file not found: ", img, call. = FALSE)
      ext <- tolower(tools::file_ext(img))
      mime <- switch(ext, png="image/png", jpg="image/jpeg", jpeg="image/jpeg", webp="image/webp",
                     stop("Unsupported image extension: ", ext, call. = FALSE))
      b64 <- base64enc::base64encode(img)
      url <- paste0("data:", mime, ";base64,", b64)
      parts <- c(parts, list(list(type="image_url", image_url=list(url=url))))
    }
  }
  parts
}

llm_chat_completions <- function(messages,
                                 model,
                                 base_url = getOption("llm.base_url",
                                   getOption("dashscope.base_url",
                                     "https://dashscope.aliyuncs.com/compatible-mode/v1")),
                                 api_key,
                                 temperature = 0.2,
                                 top_p = 0.9,
                                 max_tokens = 1024,
                                 seed = NULL,
                                 extra = list(),
                                 timeout_s = 120,
                                 verbose = FALSE) {
  if (!nzchar(api_key)) stop("Missing API key.", call. = FALSE)
  if (missing(messages) || !is.list(messages)) stop("`messages` must be a list of {role, content}.", call. = FALSE)
  base_url <- normalize_base_url(base_url)

  body <- c(list(model=model, messages=messages, temperature=temperature, top_p=top_p, max_tokens=max_tokens),
            if (!is.null(seed)) list(seed=seed) else list(), extra)

  req <- httr2::request(paste0(base_url, "/chat/completions")) |>
    httr2::req_method("POST") |>
    httr2::req_headers(Authorization = paste("Bearer", api_key), `Content-Type`="application/json") |>
    httr2::req_body_json(body, auto_unbox = TRUE, null = "null") |>
    httr2::req_timeout(timeout_s)

  if (isTRUE(verbose)) req <- httr2::req_verbose(req)
  resp <- httr2::req_perform(req)
  httr2::resp_check_status(resp)
  out <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  if (!is.null(out$error)) stop(out$error$message %||% "Unknown API error", call. = FALSE)
  out
}

llm_extract_text <- function(resp_json) {
  if (is.null(resp_json)) return("")
  choices <- resp_json$choices
  if (is.data.frame(choices)) {
    if ("message.content" %in% names(choices)) return(as.character(choices[1, "message.content"]))
    if ("text" %in% names(choices)) return(as.character(choices[1, "text"]))
  }
  if (is.list(choices) && length(choices) >= 1) {
    c1 <- choices[[1]]
    if (!is.null(c1$message) && !is.null(c1$message$content)) return(as.character(c1$message$content))
    if (!is.null(c1$text)) return(as.character(c1$text))
    if (!is.null(c1$delta) && !is.null(c1$delta$content)) return(as.character(c1$delta$content))
  }
  ""
}
