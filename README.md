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
remotes::install_github("YOUR_GITHUB_ID/Rdashscope")
```

---

## Quick start

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

## License

MIT
