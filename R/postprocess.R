unescape_placeholders <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  x <- as.character(x)
  if (grepl("\\\\n", x, perl = TRUE) && !grepl("\n", x, fixed = TRUE)) {
    x <- gsub("\\\\r\\\\n", "\n", x, perl = TRUE)
    x <- gsub("\\\\n", "\n", x, perl = TRUE)
    x <- gsub("\\\\t", "\t", x, perl = TRUE)
  }
  x
}

extract_code <- function(text, fallback = FALSE) {
  text <- unescape_placeholders(text)
  m <- gregexpr("```[a-zA-Z0-9_-]*\\s*\\n([\\s\\S]*?)\\n```", text, perl = TRUE)
  hits <- regmatches(text, m)[[1]]
  if (length(hits) && hits[1] != "-1") {
    blocks <- vapply(hits, function(h) sub("^```[a-zA-Z0-9_-]*\\s*\\n([\\s\\S]*?)\\n```$", "\\1", h, perl=TRUE), character(1))
    return(paste(blocks, collapse="\n\n"))
  }
  if (isTRUE(fallback)) return(text)
  ""
}

as_r_function <- function(code, name = "llm_generated_fn", args = c("...")) {
  code <- unescape_placeholders(code)
  if (grepl("\\bfunction\\s*\\(", code)) return(code)
  arg_txt <- paste(args, collapse=", ")
  body <- paste0("  ", gsub("\n", "\n  ", code, fixed=TRUE))
  paste0(name, " <- function(", arg_txt, ") {\n", body, "\n}\n")
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

looks_like_md_table <- function(x) {
  x <- unescape_placeholders(x)
  grepl("\\|", x) && grepl("\\n\\s*\\|?\\s*[-:]+", x, perl=TRUE)
}

looks_like_json <- function(x) {
  x <- trimws(unescape_placeholders(x))
  grepl("^\\{", x) || grepl("^\\[", x)
}

looks_like_code <- function(x) {
  x <- unescape_placeholders(x)
  if (nzchar(extract_code(x, fallback=FALSE))) return(TRUE)
  patterns <- c("(<-|=)\\s*function\\s*\\(", "\\blibrary\\s*\\(", "\\brequire\\s*\\(", "\\bggplot\\s*\\(",
                "\\bfor\\s*\\(", "\\bif\\s*\\(", "%%", "::", "\\breturn\\s*\\(")
  sum(vapply(patterns, function(p) grepl(p, x, perl=TRUE), logical(1))) >= 2
}

looks_like_bullets <- function(x) {
  x <- unescape_placeholders(x)
  grepl("\\n\\s*[-*•]\\s+", x, perl=TRUE)
}

infer_return_type <- function(text) {
  x <- unescape_placeholders(text)
  x_trim <- trimws(x)
  if (grepl("\\bfunction\\s*\\(", x, perl=TRUE)) return("function")
  if (looks_like_code(x)) return("code")
  if (looks_like_md_table(x) || grepl("^\\s*#", x, perl=TRUE)) return("markdown")
  if (looks_like_json(x_trim)) {
    if (grepl("\"columns\"\\s*:", x_trim, perl=TRUE) && grepl("\"data\"\\s*:", x_trim, perl=TRUE)) return("dataframe")
    return("list")
  }
  if (looks_like_bullets(x)) return("markdown")
  "text"
}

format_output_with_llm <- function(text,
                                   target = c("code","function","markdown","dataframe","list","pptx","docx","xlsx"),
                                   model,
                                   api_key,
                                   base_url = getOption("llm.base_url", getOption("dashscope.base_url","https://dashscope.aliyuncs.com/compatible-mode/v1")),
                                   temperature = 0.0,
                                   max_tokens = 1800,
                                   verbose = FALSE) {
  target <- match.arg(target)
  text <- unescape_placeholders(text)

  system <- "You are a strict formatter. Return ONLY the requested format, no extra commentary."

  schema <- switch(
    target,
    dataframe  = 'Return STRICT JSON: {"type":"dataframe","columns":[...],"data":[[...],[...]]}. Strings must not contain raw newlines.',
    list       = 'Return STRICT JSON: {"type":"list","value": <any JSON value>}. Strings must not contain raw newlines.',
    pptx       = 'Return STRICT JSON: {"type":"pptx","slides":[{"title":"...","bullets":["...","..."]}]}. Each string must NOT contain raw newline characters.',
    docx       = 'Return STRICT JSON: {"type":"docx","title":"...","sections":[{"heading":"...","paragraphs":["...","..."]}]}. Each string must NOT contain raw newline characters.',
    xlsx       = 'Return STRICT JSON: {"type":"xlsx","sheets":[{"name":"Sheet1","table":{"columns":[...],"data":[[...]]}}]}. Each string must NOT contain raw newline characters.',
    markdown   = "Return clean Markdown only.",
    code       = "Return ONLY runnable code, no fences, no explanation.",
    `function` = "Return ONLY runnable R function code, no fences, no explanation."
  )

  user <- paste0("Target: ", target,
                 "\nRules: ", schema,
                 "\nIMPORTANT: Do NOT include ``` fences. Do NOT include any extra keys or text.\n\nInput:\n",
                 text)
  messages <- list(list(role="system", content=system), list(role="user", content=user))
  resp <- llm_chat_completions(messages=messages, model=model, api_key=api_key, base_url=base_url,
                               temperature=temperature, max_tokens=max_tokens, verbose=verbose)
  llm_extract_text(resp)
}

parse_dataframe_json <- function(json_txt) {
  obj <- jsonlite::fromJSON(json_txt, simplifyVector = FALSE)
  if (is.null(obj$type) || obj$type != "dataframe") stop("Formatter did not return dataframe JSON.", call.=FALSE)
  cols <- obj$columns; dat <- obj$data
  df <- as.data.frame(do.call(rbind, lapply(dat, function(r) {
    if (length(r) < length(cols)) r <- c(r, rep(NA, length(cols)-length(r)))
    r[seq_len(length(cols))]
  })), stringsAsFactors=FALSE)
  colnames(df) <- cols
  df
}

parse_list_json <- function(json_txt) {
  obj <- jsonlite::fromJSON(json_txt, simplifyVector = FALSE)
  if (!is.null(obj$type) && obj$type=="list") return(obj$value)
  obj
}

.pick_layout_with_title_body <- function(ppt) {
  ls <- officer::layout_summary(ppt)
  if (is.null(ls) || nrow(ls) == 0) stop("No layouts found in PPTX template.", call.=FALSE)

  title_like <- c("title", "ctrTitle")
  body_like  <- c("body", "obj")

  ok_row <- NA_integer_
  for (i in seq_len(nrow(ls))) {
    master <- ls$master[i]; layout <- ls$layout[i]
    lp <- tryCatch(officer::layout_properties(ppt, layout = layout, master = master), error=function(e) NULL)
    if (is.null(lp) || nrow(lp) == 0) next
    has_title <- any(lp$type %in% title_like)
    has_body  <- any(lp$type %in% body_like)
    if (has_title && has_body) { ok_row <- i; break }
  }
  if (is.na(ok_row)) ok_row <- 1L
  list(master = ls$master[ok_row], layout = ls$layout[ok_row])
}

.get_ph_label <- function(ppt, master, layout, want = c("title","body")) {
  want <- match.arg(want)
  lp <- officer::layout_properties(ppt, layout = layout, master = master)
  title_like <- c("title","ctrTitle")
  body_like  <- c("body","obj")

  if (want == "title") {
    idx <- which(lp$type %in% title_like)
    if (length(idx)) return(lp$ph_label[idx[1]])
  } else {
    idx <- which(lp$type %in% body_like)
    if (length(idx)) return(lp$ph_label[idx[1]])
  }
  if (nrow(lp) > 0) return(lp$ph_label[1])
  NULL
}

write_pptx_from_spec <- function(spec, path, template = getOption("Rdashscope.pptx_template", NULL)) {
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("To export PPTX, please install `officer`: install.packages('officer')", call.=FALSE)
  }
  if (!is.null(template) && nzchar(template)) {
    if (!file.exists(template)) stop("PPTX template not found: ", template, call.=FALSE)
    ppt <- officer::read_pptx(path = template)
  } else {
    ppt <- officer::read_pptx()
  }

  pick <- .pick_layout_with_title_body(ppt)
  master <- pick$master
  layout <- pick$layout
  title_label <- .get_ph_label(ppt, master, layout, "title")
  body_label  <- .get_ph_label(ppt, master, layout, "body")

  for (s in spec$slides %||% list()) {
    ppt <- officer::add_slide(ppt, layout = layout, master = master)
    if (!is.null(title_label)) {
      ppt <- officer::ph_with(ppt, value = (s$title %||% ""), location = officer::ph_location_label(title_label))
    }
    bullets <- s$bullets %||% list()
    body <- paste("\u2022", unlist(bullets), collapse = "\n")
    if (!is.null(body_label)) {
      ppt <- officer::ph_with(ppt, value = body, location = officer::ph_location_label(body_label))
    } else {
      ppt <- officer::ph_with(ppt, value = body, location = officer::ph_location_fullsize())
    }
  }
  print(ppt, target = path)
  path
}

write_docx_from_spec <- function(spec, path) {
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("To export DOCX, please install `officer`: install.packages('officer')", call.=FALSE)
  }
  doc <- officer::read_docx()
  if (!is.null(spec$title) && nzchar(spec$title)) doc <- officer::body_add_par(doc, spec$title, style = "heading 1")
  secs <- spec$sections %||% list()
  for (sec in secs) {
    if (!is.null(sec$heading) && nzchar(sec$heading)) doc <- officer::body_add_par(doc, sec$heading, style = "heading 2")
    paras <- sec$paragraphs %||% list()
    for (p in paras) {
      if (!is.null(p) && nzchar(as.character(p))) doc <- officer::body_add_par(doc, as.character(p), style = "Normal")
    }
  }
  print(doc, target = path)
  path
}

write_xlsx_from_spec <- function(spec, path) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("To export XLSX, please install `openxlsx`: install.packages('openxlsx')", call.=FALSE)
  }
  wb <- openxlsx::createWorkbook()
  for (sh in spec$sheets %||% list()) {
    nm <- sh$name %||% "Sheet1"
    openxlsx::addWorksheet(wb, nm)
    tbl <- sh$table
    if (!is.null(tbl)) {
      df <- as.data.frame(do.call(rbind, tbl$data %||% list()), stringsAsFactors = FALSE)
      if (!is.null(tbl$columns)) colnames(df) <- tbl$columns
      openxlsx::writeData(wb, nm, df)
    }
  }
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  path
}

postprocess_reply <- function(text,
                              return = c("auto","text","code","function","markdown","dataframe","list","pptx","docx","xlsx","both"),
                              formatter_model = NULL,
                              api_key = NULL,
                              base_url = getOption("llm.base_url", getOption("dashscope.base_url","https://dashscope.aliyuncs.com/compatible-mode/v1")),
                              verbose = FALSE,
                              pptx_template = NULL) {
  return <- match.arg(return)
  text <- unescape_placeholders(text)

  if (return=="auto") {
    inferred <- infer_return_type(text)
    if (inferred %in% c("dataframe","list","pptx","docx","xlsx") &&
        (is.null(formatter_model) || !nzchar(formatter_model) || is.null(api_key) || !nzchar(api_key))) {
      inferred <- if (looks_like_md_table(text)) "markdown" else "text"
    }
    return(postprocess_reply(text, return=inferred, formatter_model=formatter_model, api_key=api_key,
                             base_url=base_url, verbose=verbose, pptx_template=pptx_template))
  }

  if (return=="text") return(text)
  if (return=="code") return(extract_code(text, fallback=TRUE))

  if (return=="function") {
    code <- extract_code(text, fallback=FALSE); if (!nzchar(code)) code <- text
    if (grepl("\\bfunction\\s*\\(", code)) return(unescape_placeholders(code))
    if (!is.null(formatter_model) && nzchar(formatter_model) && !is.null(api_key) && nzchar(api_key)) {
      fmt <- format_output_with_llm(code, "function", model=formatter_model, api_key=api_key, base_url=base_url, verbose=verbose)
      return(unescape_placeholders(extract_code(fmt, fallback=TRUE)))
    }
    return(as_r_function(code))
  }

  if (return=="markdown") {
    if (looks_like_md_table(text) || grepl("^\\s*#", text)) return(text)
    if (is.null(formatter_model) || !nzchar(formatter_model) || is.null(api_key) || !nzchar(api_key)) return(text)
    fmt <- format_output_with_llm(text, "markdown", model=formatter_model, api_key=api_key, base_url=base_url, verbose=verbose)
    return(unescape_placeholders(fmt))
  }

  if (return=="both") return(list(text=text, code=extract_code(text, fallback=FALSE)))

  if (is.null(formatter_model) || !nzchar(formatter_model)) stop("Need formatter_model for structured return.", call.=FALSE)
  if (is.null(api_key) || !nzchar(api_key)) stop("Need api_key for structured return.", call.=FALSE)

  fmt_txt <- format_output_with_llm(text, target=return, model=formatter_model, api_key=api_key, base_url=base_url, verbose=verbose)
  fmt_txt <- unescape_placeholders(fmt_txt)

  if (return=="dataframe") return(parse_dataframe_json(fmt_txt))
  if (return=="list") return(parse_list_json(fmt_txt))

  spec <- tryCatch(jsonlite::fromJSON(fmt_txt, simplifyVector = FALSE),
                   error = function(e) {
                     stop("Failed to parse formatter JSON for return='", return, "'. Try setting formatter_model to a stronger model, or set return='text'/'markdown'.\nOriginal error: ", e$message, call.=FALSE)
                   })

  if (is.null(spec$type) || spec$type != return) stop("Formatter spec type mismatch.", call.=FALSE)

  out_path <- tempfile(fileext = paste0(".", return))
  if (return=="pptx") {
    tpl <- pptx_template %||% getOption("Rdashscope.pptx_template", NULL)
    return(write_pptx_from_spec(spec, out_path, template = tpl))
  }
  if (return=="docx") return(write_docx_from_spec(spec, out_path))
  if (return=="xlsx") return(write_xlsx_from_spec(spec, out_path))
  fmt_txt
}
