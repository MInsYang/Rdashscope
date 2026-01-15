\name{singleAsk}
\alias{singleAsk}
\title{Ask the model once (one-shot)}
\description{
Formats an R object using \code{format_input()} and sends a single request to an OpenAI-compatible
\code{/chat/completions} endpoint.
}
\usage{
singleAsk(x, task, model = "qwen-plus",
  system_prompt = "You are a senior single-cell bioinformatics assistant. Be concise, correct, and give executable R code when helpful.",
  return = c("text", "raw"), ...)
}
\arguments{
  \item{x}{Any R object (e.g., data.frame, Seurat, character, list).}
  \item{task}{What you want the model to do.}
  \item{model}{Model name (vendor-specific).}
  \item{system_prompt}{System instruction.}
  \item{return}{Either \code{"text"} (default) or \code{"raw"} (full JSON response).}
  \item{...}{Forwarded to the HTTP client (e.g., \code{api_key}, \code{base_url}, \code{temperature}, \code{max_tokens}, \code{timeout_s}).}
}
\value{
A character string, or the raw response list if \code{return="raw"}.
}
\examples{
\dontrun{
library(Rdashscope)
set_provider("dashscope")
Sys.setenv(DASHSCOPE_API_KEY="sk-xxx")

singleAsk(head(iris, 5), "Explain each column.",
  model="qwen-plus", api_key=Sys.getenv("DASHSCOPE_API_KEY"))
}
}
\seealso{\code{\link{format_input}}, \code{\link{new_chat}}, \code{\link{set_provider}}}
