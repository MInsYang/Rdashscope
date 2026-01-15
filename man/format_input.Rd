\name{format_input}
\alias{format_input}
\title{Format an R object as LLM-friendly text}
\description{
S3 generic that converts R objects into compact, model-friendly text. Includes built-in methods for common
analysis objects (data.frame, matrix, dgCMatrix, Seurat).
}
\usage{
format_input(x, ...)
}
\arguments{
  \item{x}{Any R object.}
  \item{...}{Additional method-specific arguments (e.g., \code{head_n} for tables).}
}
\value{
A character string suitable to include in a chat prompt.
}
\examples{
format_input(head(iris, 3))
}
