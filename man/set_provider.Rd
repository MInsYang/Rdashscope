\name{set_provider}
\alias{set_provider}
\title{Set provider preset (base_url)}
\description{
Convenience helper to set \code{options(llm.base_url=...)} using common OpenAI-compatible providers
(dashscope, deepseek, gemini) or a custom base_url.
}
\usage{
set_provider(provider = c("dashscope", "deepseek", "gemini", "custom"), base_url = NULL)
}
\arguments{
  \item{provider}{One of \code{"dashscope"}, \code{"deepseek"}, \code{"gemini"}, or \code{"custom"}.}
  \item{base_url}{If provider is \code{"custom"}, supply the base URL.}
}
\value{
Invisibly returns the chosen base_url.
}
\seealso{\code{\link{get_provider}}}
