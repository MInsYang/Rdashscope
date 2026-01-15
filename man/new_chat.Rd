\name{new_chat}
\alias{new_chat}
\title{Create a multi-turn chat session}
\description{
Creates a lightweight session object that keeps conversation history and automatically truncates
older turns to control context length.
}
\usage{
new_chat(model = "qwen-plus",
  system_prompt = "You are a senior single-cell bioinformatics assistant.",
  max_turns = 20, ...)
}
\arguments{
  \item{model}{Model name (vendor-specific).}
  \item{system_prompt}{System instruction.}
  \item{max_turns}{Maximum number of recent user+assistant turns to keep (system message is always kept).}
  \item{...}{Forwarded to the HTTP client (e.g., \code{api_key}, \code{base_url}, \code{temperature}, \code{max_tokens}, \code{timeout_s}).}
}
\value{
A session object (list) with methods: \code{$ask()}, \code{$history()}, \code{$reset()}.
}
\seealso{\code{\link{multiAsk}}, \code{\link{singleAsk}}}
