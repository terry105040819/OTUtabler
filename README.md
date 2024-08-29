# taxonomy-to-OTU-table
this R scripts for people who own an taxonomy table and transfer into OTU style table for downstream analysis
## Taxonomy table format
You can get a taxonomy table from some kinds of classification tool, this kind of table obtain full taxonomy result of each samples. but the original OTU style table is more convenient for downstream analysis(eg. PCA).

![OTU_table](https://github.com/user-attachments/assets/10afd681-9da2-4176-921c-9e641f42faf9)

## OTU table format

this table summarize all information from taxonomy table with user-defined classification resolution, the row showing the sample ID and the column showing the bacteria you mapped.

![OTU2](https://github.com/user-attachments/assets/28643ae7-d211-4c0f-b437-0c4d8aace8c1)

# USAGE
The taxonomy level only set to family,genus and species level,and the input format also limited.

```
rscript OTUtabler.R -h

Options:
	-l CHARACTER, --taxonomy_level=CHARACTER
		OTU table taxonomy resolution(ex.Species,Genus,Family)

	-i CHARACTER, --input=CHARACTER
		taxonomy table directory

	-o CHARACTER, --output=CHARACTER
		OTU table output directory

	-h, --help
		Show this help message and exit
```


``` shell
rscript OTUtabler.R -l genus -i taxonomy table -o OTU table output
```
# Output
## example from 16s rRNA full length Gut microbiota 
<img width="992" alt="截圖 2024-08-29 下午4 03 59" src="https://github.com/user-attachments/assets/819d8302-f43f-456d-83af-392f4d8bbcd5">


