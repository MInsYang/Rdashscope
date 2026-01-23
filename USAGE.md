# Rdashscope Usage

> Rdashscope：在 R 里调用大模型（OpenAI Chat Completions 兼容接口），支持 **singleAsk / multiAsk**、自动识别输入对象（data.frame/Seurat/矩阵等）并格式化、支持 **结构化返回**（代码/函数/markdown/data.frame/list），以及 **一键导出**到 `pptx/docx/xlsx`。

GitHub：<https://github.com/MInsYang/Rdashscope>

---

## 1. 安装

### 1.1 安装依赖
```r
install.packages(c("jsonlite", "httr2"), repos="https://cloud.r-project.org")
```

### 1.2 （可选）安装导出相关依赖
```r
install.packages(c("officer", "openxlsx"), repos="https://cloud.r-project.org")
# 如果你要传入本地图片（多模态/图像输入），建议安装：
install.packages("base64enc", repos="https://cloud.r-project.org")
```

### 1.3 安装 Rdashscope（本地 tar.gz）
```r
install.packages("Rdashscope_0.3.7.tar.gz", repos=NULL, type="source")
library(Rdashscope)
```

---

## 2. 配置 Provider（模型厂商 / Base URL）

Rdashscope 走 **OpenAI Chat Completions 兼容模式**，通过 `set_provider()` 切换厂商或自定义 base_url。

### 2.1 DashScope（Qwen）
```r
library(Rdashscope)
set_provider("dashscope")
Sys.setenv(DASHSCOPE_API_KEY="你的key")
```

### 2.2 DeepSeek
```r
set_provider("deepseek")
Sys.setenv(DASHSCOPE_API_KEY="你的_deepseek_key")
```

### 2.3 Gemini（OpenAI-compatible endpoint）
```r
set_provider("gemini")
Sys.setenv(DASHSCOPE_API_KEY="你的_gemini_key")
```

### 2.4 自定义（兼容 OpenAI Chat Completions 的服务）
```r
set_provider("custom", base_url="https://your-host/v1")
Sys.setenv(DASHSCOPE_API_KEY="你的key")
```

### 2.5 查看当前 base_url
```r
get_provider()
```

---

## 3. singleAsk：单轮调用

### 3.1 最简单：给一个对象 + 一个任务
```r
res <- singleAsk(
  x = head(iris, 5),
  task = "解释每一列代表什么，并给出两条适合的可视化建议。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "text"
)
cat(res)
```

### 3.2 传入不同 class 的对象（自动格式化）
支持：`data.frame`、`matrix`、`dgCMatrix`、`Seurat`、普通 list 等。

```r
res <- singleAsk(
  x = your_seurat_obj,
  task = "请给我这个对象的 QC 建议，并指出可能需要过滤的指标。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "markdown"
)
cat(res)
```

### 3.3 常用可调参数
```r
res <- singleAsk(
  x = head(iris, 5),
  task = "给我两个 ggplot2 可视化建议，并输出代码。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "code",
  temperature = 0.2,
  max_tokens = 1500
)
cat(res)
```

---

## 4. multiAsk：多轮对话（带上下文）

### 4.1 创建一个 chat session
```r
chat <- new_chat(
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  temperature = 0.2,
  max_tokens = 2000
)
```

> 注意：上面示例里环境变量名请用 `DASHSCOPE_API_KEY`（不要打错）。

### 4.2 Round 1：附带对象
```r
ans1 <- multiAsk(
  chat,
  user_text = "请解释每一列代表什么，并给出两个适合的可视化建议。",
  x = head(iris, 5),
  return = "text"
)
cat(ans1)
```

### 4.3 Round 2：继续追问（不带对象也行）
```r
ans2 <- multiAsk(
  chat,
  user_text = "把你建议的可视化用 ggplot2 给我可直接运行的代码。",
  return = "code"
)
cat(ans2)
```

### 4.4 查看/清空对话历史
```r
chat$history()
chat$reset()
```

---

## 5. return：结构化返回

- `"text"`：纯文本  
- `"markdown"`：Markdown  
- `"code"`：可运行代码（尽量去掉解释/围栏）  
- `"function"`：可直接定义的 R 函数代码  
- `"dataframe"`：返回 R data.frame（二次格式化为严格 JSON 再转换）  
- `"list"`：返回 R list（严格 JSON）  
- `"pptx"` / `"docx"` / `"xlsx"`：导出文件路径  
- `"auto"`：自动推断（默认）  
- `"raw"`：原始响应（调试）  

---

## 6. 一键导出：PPTX / DOCX / XLSX

### 6.1 16:9 PPTX（推荐用模板）
PowerPoint/WPS：Slide Size → Widescreen (16:9) → 保存为 `widescreen_template.pptx`

```r
set_pptx_template("./widescreen_template.pptx")

ppt_path <- singleAsk(
  x = head(iris, 5),
  task = "做一个3页PPT：数据概览、可视化建议、结论。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "pptx"
)

ppt_path
file.exists(ppt_path)
```

### 6.2 DOCX
```r
doc_path <- singleAsk(
  x = head(iris, 5),
  task = "写一个简短分析报告：数据说明、结论、可视化建议。",
  model = "qwen-plus",
  api_key = Sys.getenv("DASHSCOPE_API_KEY"),
  return = "docx"
)

doc_path
file.exists(doc_path)
```

### 6.3 正确保存到当前目录
✅ 正确写法：

```r
# 保存 docx
file.copy(doc_path, file.path(getwd(), "iris_report.docx"), overwrite = TRUE)

# 保存 pptx
file.copy(ppt_path, file.path(getwd(), "iris_slides.pptx"), overwrite = TRUE)
```

---

## 7. 常见报错

- `master "Office Theme" does not exist.`：模板 master/layout 名不同（尤其 WPS），v0.3.6+ 已自动适配。
- `lexical error: invalid character inside string`（docx）：旧版 formatter JSON 含裸换行导致解析失败，v0.3.7+ 已修复（用 paragraphs 数组）。

---
