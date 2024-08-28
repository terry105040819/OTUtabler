control_rmoutlier <-  Control[Control$case_no %in% control_otu_rmoutlier$case_no,]
control_rmoutlier_otu <- control_rmoutlier[,c(2,3,10,12)]
control_rmoutlier_otu <- control_rmoutlier_otu %>% group_by(case_no,species) %>% summarize(hits=sum(num_hits))
control_rmoutlier_table <- as.data.frame(pivot_wider(control_rmoutlier_otu, names_from = species, values_from = hits))
control_rmoutlier_table<- lapply(control_rmoutlier_table, unlist)
control_rmoutlier_table <- data.frame(lapply(control_rmoutlier_table, `length<-`, max(lengths(control_rmoutlier_table))))
control_rmoutlier_table[is.na(control_rmoutlier_table)] <- 0 

control_rmoutlier_otu <- as.data.frame(control_rmoutlier_otu)
control_rmoutlier_otu <- control_rmoutlier_otu |>
  dplyr::mutate(shannon_index = vegan::diversity(hits), .by = case_no)
control_rmoutlier_otu <- control_rmoutlier_otu[!control_rmoutlier_otu$shannon_index %in% boxplot.stats(control_rmoutlier_otu$shannon_index)$out,]
control_rmoutlier_otu$group <- "健康族群"
