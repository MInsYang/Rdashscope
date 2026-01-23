format_input <- function(x, ...) UseMethod("format_input")

format_input.default <- function(x, ...) {
  summary_txt <- paste(capture.output(utils::str(x, max.level = 2, give.attr = FALSE)), collapse = "\n")
  json_txt <- tryCatch(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", pretty = TRUE), error = function(e) NULL)
  if (!is.null(json_txt)) paste0("## R str()\n", summary_txt, "\n\n## JSON\n", json_txt) else paste0("## R str()\n", summary_txt)
}

format_input.character <- function(x, ...) paste(x, collapse = "\n")

format_input.data.frame <- function(x, head_n = 30, ...) {
  x2 <- utils::head(x, head_n)
  paste0("## data.frame\n- nrow: ", nrow(x), ", ncol: ", ncol(x),
         "\n- colnames: ", paste(colnames(x), collapse = ", "),
         "\n\n## head(", head_n, ")\n",
         paste(capture.output(print(x2, row.names = FALSE)), collapse = "\n"))
}

format_input.matrix <- function(x, head_n = 10, ...) {
  x2 <- x[seq_len(min(nrow(x), head_n)), seq_len(min(ncol(x), head_n)), drop = FALSE]
  paste0("## matrix\n- dim: ", paste(dim(x), collapse=" x "), "\n- type: ", typeof(x),
         "\n\n## top-left corner\n", paste(capture.output(print(x2)), collapse="\n"))
}

format_input.dgCMatrix <- function(x, ...) {
  nnz <- tryCatch(length(x@x), error=function(e) NA_integer_)
  paste0("## dgCMatrix (sparse)\n- dim: ", paste(dim(x), collapse=" x "),
         "\n- nnz: ", nnz,
         "\n- density: ", if (!is.na(nnz)) round(nnz/(prod(dim(x))+1e-9), 6) else "NA", "\n")
}

format_input.Seurat <- function(x, meta_cols = c("orig.ident","seurat_clusters"), assays = NULL, ...) {
  if (!requireNamespace("Seurat", quietly = TRUE)) return(format_input.default(x))
  md <- x@meta.data
  keep <- intersect(meta_cols, colnames(md))
  md2 <- if (length(keep)) md[, keep, drop=FALSE] else md
  meta_glimpse <- paste(capture.output(utils::str(md2, max.level = 1)), collapse = "\n")
  assay_names <- tryCatch(names(x@assays), error=function(e) character())
  if (!is.null(assays)) assay_names <- intersect(assay_names, assays)
  dims_txt <- tryCatch({
    a <- Seurat::DefaultAssay(x); d <- dim(x[[a]])
    paste0("- DefaultAssay: ", a, "\n- Dim(DefaultAssay): ", paste(d, collapse=" x "))
  }, error=function(e) "")
  paste0("## Seurat object summary\n- Cells: ", ncol(x), "\n- Features: ", nrow(x),
         "\n- Assays: ", paste(assay_names, collapse=", "), "\n", dims_txt,
         "\n\n## meta.data (selected)\n", meta_glimpse)
}
