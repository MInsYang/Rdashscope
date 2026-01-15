# Rdashscope

⭐️ **Vendor-agnostic LLM client for R** (OpenAI-compatible **Chat Completions**) with **single-cell friendly auto-formatting** (e.g., compact **Seurat** summaries).

Highlights:

- `singleAsk()` — one-shot Q&A with class-aware input formatting
- `new_chat()` + `multiAsk()` — multi-turn session with history truncation
- `format_input()` — extensible S3 formatter (data.frame / matrix / dgCMatrix / Seurat / ...)
- `set_provider()` — one-line provider presets (dashscope / deepseek / gemini / custom)

---

## Installation

```r
install.packages("remotes")
remotes::install_github("MInsYang/Rdashscope") or
devtools::install_local("Rdashscope_0.2.3.zip")
```

---

## Quick start singleAsk

```r
library(Rdashscope)

set_provider("dashscope")
Sys.setenv(DASHSCOPE_API_KEY="sk-xxx")

res <- singleAsk(
  x = head(iris, 10),
  task = "Summarize the dataset and propose 2-3 plots.",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY")
)
cat(res)

# help
?singleAsk
```

---

## Debugging tips

If you ever get an empty string, inspect the raw response:

```r
raw <- singleAsk(head(iris,5), "Explain each column",
  model="qwen-plus",
  api_key=Sys.getenv("DASHSCOPE_API_KEY"),
  return="raw"
)
str(raw, max.level=3)
```

To print HTTP request/response details (advanced):

```r
# You can temporarily set verbose=TRUE by editing client.R to add req_verbose(),
# or call the internal client directly in a dev session.
```

---

## Quick start multiAsk

```r
library(Rdashscope)

# 0) Choose provider + set API key (recommended via env var)
set_provider("dashscope")
Sys.setenv(DASHSCOPE_API_KEY = "sk-xxxx")

# 1) Create a chat session
chat <- new_chat(
  model = "qwen-plus",  # qwen-flash
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  temperature = 0.2,
  max_tokens = 1200   # note: each vendor/model has a limit
)

# 2) Round 1 (attach an R object, auto formatted via format_input)
ans1 <- multiAsk(
  chat,
  user_text = "Explain what each column means and suggest 2 suitable plots.",
  x = head(iris, 5)
)
cat(ans1)

# 3) Round 2 (follow-up without attaching objects)
ans2 <- multiAsk(
  chat,
  user_text = "Provide executable ggplot2 code for the suggested plots."
)
cat(ans2)

# 4) Round 3+ (keep iterating)
ans3 <- multiAsk(
  chat,
  user_text = "Polish the plots (theme_bw + larger fonts) and save to a PDF."
)
cat(ans3)
```

---

## License

MIT
