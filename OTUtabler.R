#!/usr/bin/env Rscript
# OTUtabler V3
# Convert a taxonomy table (e.g. from Kraken2) into an OTU-style table
# (rows = samples, columns = taxa) at family / genus / species resolution.
#
# Required packages: optparse, data.table
#   install.packages(c("optparse", "data.table"))

# ---- dependencies (no silent auto-install: keeps pipelines reproducible) ----
missing_pkgs <- c("optparse", "data.table")[
  !vapply(c("optparse", "data.table"), requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_pkgs) > 0) {
  stop("Missing R package(s): ", paste(missing_pkgs, collapse = ", "),
       "\nInstall with: install.packages(c(",
       paste0("\"", missing_pkgs, "\"", collapse = ", "), "))", call. = FALSE)
}
suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
})

SUPPORTED_LEVELS <- c("species", "genus", "family")

# ---- command line ----
option_list <- list(
  make_option(c("-l", "--taxonomy_level"), type = "character", metavar = "character",
              help = "OTU table taxonomy resolution: species, genus or family (case-insensitive)"),
  make_option(c("-i", "--input"), type = "character", metavar = "character",
              help = "Taxonomy table (.csv or .tsv, separator is auto-detected)"),
  make_option(c("-o", "--output"), type = "character", metavar = "character",
              help = paste("OTU table output path. '.csv' is appended unless the name already ends",
                           "in .csv or .tsv (.tsv writes tab-separated).",
                           "Default: <input name>_<level>_OTU.csv")),
  make_option(c("-r", "--relative"), action = "store_true", default = FALSE,
              help = "Output relative abundance (each sample sums to 1) instead of raw hits"),
  make_option(c("-m", "--min_hits"), type = "double", default = 0, metavar = "number",
              help = "Drop taxa whose total hits across all samples is below this value [default %default]"),
  make_option(c("-d", "--drop_unclassified"), action = "store_true", default = FALSE,
              help = "Drop rows with an empty/NA taxon instead of grouping them as 'Unclassified'"),
  make_option("--sample_col", type = "character", default = "case_no", metavar = "character",
              help = "Name of the sample ID column [default %default]"),
  make_option("--hits_col", type = "character", default = "num_hits", metavar = "character",
              help = "Name of the hit-count column [default %default]")
)
opt_parser <- OptionParser(option_list = option_list,
                           description = "Convert a taxonomy table into an OTU-style table.")
opt <- parse_args(opt_parser)

fail <- function(...) {
  stop(paste0(...), call. = FALSE)
}

# ---- argument validation ----
if (is.null(opt$input)) {
  print_help(opt_parser)
  fail("Input file is required. Use -i or --input.")
}
if (!file.exists(opt$input)) {
  fail("Input file not found: ", opt$input)
}
if (is.null(opt$taxonomy_level)) {
  print_help(opt_parser)
  fail("Taxonomy level is required. Use -l or --taxonomy_level (species, genus or family).")
}
level <- tolower(trimws(opt$taxonomy_level))
if (!level %in% SUPPORTED_LEVELS) {
  fail("Unsupported taxonomy level '", opt$taxonomy_level, "'. Choose one of: ",
       paste(SUPPORTED_LEVELS, collapse = ", "), ".")
}
if (is.na(opt$min_hits) || opt$min_hits < 0) {
  fail("--min_hits must be a non-negative number.")
}
sample_col <- tolower(trimws(opt$sample_col))
hits_col   <- tolower(trimws(opt$hits_col))

# ---- read input (fread auto-detects csv / tsv) ----
taxo <- tryCatch(
  fread(opt$input, data.table = TRUE, colClasses = "character", na.strings = c("NA", "")),
  error = function(e) fail("Could not read '", opt$input, "': ", conditionMessage(e))
)
if (nrow(taxo) == 0) fail("Input table has no rows.")
setnames(taxo, tolower(trimws(names(taxo))))

needed  <- c(sample_col, level, hits_col)
absent  <- setdiff(needed, names(taxo))
if (length(absent) > 0) {
  fail("Column(s) not found in input: ", paste(absent, collapse = ", "),
       "\nColumns present: ", paste(names(taxo), collapse = ", "))
}

dt <- data.table(
  sample_id = trimws(taxo[[sample_col]]),
  taxon     = trimws(taxo[[level]]),
  hits      = suppressWarnings(as.numeric(taxo[[hits_col]]))
)
rm(taxo)

# rows without a sample ID cannot be placed in the table
n_no_sample <- sum(is.na(dt$sample_id) | dt$sample_id == "")
if (n_no_sample > 0) {
  warning(n_no_sample, " row(s) without a sample ID were dropped.", call. = FALSE)
  dt <- dt[!(is.na(sample_id) | sample_id == "")]
}

# rows whose hit count is missing or not numeric
n_bad_hits <- sum(is.na(dt$hits))
if (n_bad_hits > 0) {
  warning(n_bad_hits, " row(s) with a missing or non-numeric '", hits_col, "' were dropped.",
          call. = FALSE)
  dt <- dt[!is.na(hits)]
}

# unclassified taxa
unclassified <- is.na(dt$taxon) | dt$taxon == ""
if (any(unclassified)) {
  if (opt$drop_unclassified) {
    message("Dropped ", sum(unclassified), " row(s) with no ", level, " assignment.")
    dt <- dt[!unclassified]
  } else {
    dt[unclassified, taxon := "Unclassified"]
  }
}
if (nrow(dt) == 0) fail("No usable rows left after cleaning the input.")

# ---- aggregate and pivot ----
agg <- dt[, .(hits = sum(hits)), by = .(sample_id, taxon)]

if (opt$min_hits > 0) {
  totals <- agg[, .(total = sum(hits)), by = taxon]
  keep   <- totals[total >= opt$min_hits, taxon]
  message("Kept ", length(keep), " of ", nrow(totals), " taxa (total hits >= ", opt$min_hits, ").")
  agg <- agg[taxon %in% keep]
  if (nrow(agg) == 0) fail("No taxa pass --min_hits ", opt$min_hits, ".")
}

otu <- dcast(agg, sample_id ~ taxon, value.var = "hits", fill = 0)

if (opt$relative) {
  m  <- as.matrix(otu[, -1, with = FALSE])
  rs <- rowSums(m)
  m  <- m / ifelse(rs > 0, rs, 1)          # samples with zero total stay at 0
  otu <- cbind(otu[, 1, with = FALSE], as.data.table(m))
}
setnames(otu, 1, sample_col)

# ---- write ----
out <- opt$output
if (is.null(out)) {
  out <- paste0(tools::file_path_sans_ext(opt$input), "_", level, "_OTU")
}
sep <- ","
if (grepl("\\.tsv$", out, ignore.case = TRUE)) {
  sep <- "\t"
} else if (!grepl("\\.csv$", out, ignore.case = TRUE)) {
  out <- paste0(out, ".csv")
}
if (file.exists(out)) message("Overwriting existing file: ", out)
fwrite(otu, file = out, sep = sep)

message("Done: ", nrow(otu), " sample(s) x ", ncol(otu) - 1, " ", level, "-level taxa -> ", out)
