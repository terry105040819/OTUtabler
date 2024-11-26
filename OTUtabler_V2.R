option_list <- list(
  make_option(c("-l", "--taxonomy_level"), type = "character", help = "Taxonomy resolution (Species, Genus, Family)", metavar = "character"),
  make_option(c("-i", "--input"), type = "character", help = "Input taxonomy table file path", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", help = "Output OTU table file path", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# 参数验证
if (is.null(opt$input) || opt$input == FALSE) {
  print_help(opt_parser)
  stop("Input file is required. Use -i or --input to specify the file.", call.=FALSE)
}

if (is.null(opt$taxonomy_level) || opt$taxonomy_level == FALSE) {
  stop("Taxonomy level is required. Use -l or --taxonomy_level to specify it (e.g., Species, Genus, Family).", call.=FALSE)
}

taxonomy_level <- opt$taxonomy_level
input <- opt$input
output <- opt$output
taxo_table <- read.csv(file = input, header = TRUE, sep = ",")
colnames(taxo_table) <- tolower(colnames(taxo_table))


# 选择分类等级并计算 OTU 表
taxonomy_column <- match.arg(tolower(taxonomy_level), c("species", "genus", "family"))

otu <- taxo_table %>%
  select(case_no, species, genus, family, num_hits) %>%
  group_by(case_no, .data[[taxonomy_column]]) %>%
  summarize(hits = sum(num_hits), .groups = "drop")

otu_table <- pivot_wider(otu, names_from = .data[[taxonomy_column]], values_from = hits) %>%
  replace(is.na(.), 0)

# 写入输出文件
write.csv(otu_table, file = paste0(output, ".csv"), row.names = FALSE)
