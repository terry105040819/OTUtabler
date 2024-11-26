library(optparse)
library(dplyr)
library(tidyr)
args = commandArgs(trailingOnly=TRUE)

option_list <- list(
  make_option(c("-l","--taxonomy_level"),type="character",default = FALSE,help = "OTU table taxonomy resolution(ex.Species,Genus,Family)",metavar="character"),
  make_option(c("-i","--input"),type ="character",default = FALSE,help = "taxonomy table directory",metavar="character"),
  make_option(c("-o","--output"),action = "store",type = 'character',default = FALSE,help="OTU table output directory",metavar="character")
)

opt_parser <- OptionParser(option_list = option_list,
                           add_help_option = TRUE,
                           prog = NULL)

opt <- parse_args(opt_parser)

if (is.null(opt$input)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

taxonomy_level <- opt$taxonomy_level
input <- opt$input
output <- opt$output


taxo_table <- read.csv(file = input,header = T,sep = ",")
  #col 10 species
  #col 9 genus
  #col 8 family
  #Species_level
otu <- taxo_table[,c(2,3,8,9,10,12)]
if (taxonomy_level %in% c("species","Species")) {
  otu <- otu %>% group_by(case_no,species) %>% summarize(hits=sum(num_hits))
  otu_table <- as.data.frame(pivot_wider(otu, names_from = species, values_from = hits))
  otu_table <- lapply(otu_table, unlist)
  otu_table <- data.frame(lapply(otu_table, `length<-`, max(lengths(otu_table))))
  otu_table[is.na(otu_table)] <- 0 
  write.csv(otu_table,file = paste(output,"csv",sep = "."),row.names = F)
}else if(taxonomy_level %in% c("genus","Genus")){
  otu <- otu %>% group_by(case_no,genus) %>% summarize(hits=sum(num_hits))
  otu_table <- as.data.frame(pivot_wider(otu, names_from = genus, values_from = hits))
  otu_table <- lapply(otu_table, unlist)
  otu_table <- data.frame(lapply(otu_table, `length<-`, max(lengths(otu_table))))
  otu_table[is.na(otu_table)] <- 0 
  write.csv(otu_table,file = paste(output,"csv",sep = "."),row.names = F)
}else if(taxonomy_level %in% c("family","Family")){
  otu <- otu %>% group_by(case_no,family) %>% summarize(hits=sum(num_hits))
  otu_table <- as.data.frame(pivot_wider(otu, names_from = family, values_from = hits))
  otu_table <- lapply(otu_table, unlist)
  otu_table <- data.frame(lapply(otu_table, `length<-`, max(lengths(otu_table))))
  otu_table[is.na(otu_table)] <- 0 
  write.csv(otu_table,file = paste(output,"csv",sep = "."),row.names = F)
}else print("please type right Taxonomic rank with family,genus,species ")
