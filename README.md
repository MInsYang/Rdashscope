# AI4R - Rdashscope

GitHub: https://github.com/MInsYang/Rdashscope

## TODO
add agent，SKILLS ， MCP server

## v0.3.7 fix: docx JSON parsing + WPS templates

- Fixed `return="docx"` lexical JSON parse errors by switching the formatter schema to **arrays of strings** (no raw newlines inside JSON strings).
- PPTX export still supports 16:9 via templates and now works with WPS/Kingsoft masters/layouts.

## Install (local .tar.gz)

```r
install.packages(c("jsonlite","httr2"), repos="https://cloud.r-project.org")
install.packages(c("officer","openxlsx"), repos="https://cloud.r-project.org")
install.packages("Rdashscope_0.3.7.tar.gz", repos=NULL, type="source")
```

## 16:9 PPTX (template)

PowerPoint/WPS → Slide Size → Widescreen (16:9) → Save as `widescreen_template.pptx`

```r
library(Rdashscope)
set_provider("dashscope")
Sys.setenv(DASHSCOPE_API_KEY="sk-xxxx")

set_pptx_template("./widescreen_template.pptx")

ppt <- singleAsk(
  x = head(iris, 5),
  task = "做一个3页PPT：数据概览、可视化建议、结论。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "pptx"
)

ppt
file.exists(ppt)
```

## DOCX

```r
doc <- singleAsk(
  x = head(iris, 5),
  task = "写一个简短分析报告：数据说明、结论、可视化建议。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "docx"
)

doc
file.exists(doc)
```
