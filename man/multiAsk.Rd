\name{multiAsk}
\alias{multiAsk}
\title{Continue a chat session (multi-turn)}
\description{
Send a user message to a session created by \code{new_chat()} and return the assistant reply.
}
\usage{
multiAsk(session, user_text, x = NULL)
}
\arguments{
  \item{session}{A session created by \code{new_chat()}.}
  \item{user_text}{User message text.}
  \item{x}{Optional R object to attach (auto formatted).}
}
\value{
Assistant reply as a character string.
}
\seealso{\code{\link{new_chat}}}
