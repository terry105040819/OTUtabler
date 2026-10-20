# OTUtabler

R script that converts a taxonomy table (e.g. from Kraken2) into an OTU-style table for downstream analysis (e.g. PCA, diversity analysis).

## Taxonomy table format

The input is a taxonomy table with one row per sample/taxon hit. It needs three columns (names are case-insensitive):

| column | meaning |
|---|---|
| `case_no` | sample ID (change with `--sample_col`) |
| `species` / `genus` / `family` | the column for the resolution you choose with `-l` |
| `num_hits` | number of hits/reads (change with `--hits_col`) |

Other columns are ignored. CSV and TSV are both accepted (the separator is auto-detected). See `example/example_taxonomy.csv`.

![OTU_table](https://github.com/user-attachments/assets/10afd681-9da2-4176-921c-9e641f42faf9)

## OTU table format

Rows are sample IDs, columns are the taxa at the resolution you chose, values are summed hits (or relative abundance with `-r`). Missing combinations are filled with 0. Taxa columns are sorted alphabetically.

![OTU2](https://github.com/user-attachments/assets/28643ae7-d211-4c0f-b437-0c4d8aace8c1)

# Installation

```r
install.packages(c("optparse", "data.table"))
```

The script no longer installs packages by itself; it stops with a clear message if one is missing.

# Usage

```
Rscript OTUtabler.R -h

Options:
	-l CHARACTER, --taxonomy_level=CHARACTER
		OTU table taxonomy resolution: species, genus or family (case-insensitive)

	-i CHARACTER, --input=CHARACTER
		Taxonomy table (.csv or .tsv, separator is auto-detected)

	-o CHARACTER, --output=CHARACTER
		OTU table output path. '.csv' is appended unless the name already ends
		in .csv or .tsv (.tsv writes tab-separated).
		Default: <input name>_<level>_OTU.csv

	-r, --relative
		Output relative abundance (each sample sums to 1) instead of raw hits

	-m NUMBER, --min_hits=NUMBER
		Drop taxa whose total hits across all samples is below this value [default 0]

	-d, --drop_unclassified
		Drop rows with an empty/NA taxon instead of grouping them as 'Unclassified'

	--sample_col=CHARACTER
		Name of the sample ID column [default case_no]

	--hits_col=CHARACTER
		Name of the hit-count column [default num_hits]

	-h, --help
		Show this help message and exit
```

```shell
# raw hit counts at genus level
Rscript OTUtabler.R -l genus -i taxonomy_table.csv -o OTU_genus

# relative abundance at family level
Rscript OTUtabler.R -l family -i taxonomy_table.csv -o OTU_family -r

# species level, drop taxa with < 100 total hits and unclassified rows, write TSV
Rscript OTUtabler.R -l species -i taxonomy_table.csv -o OTU_species.tsv -m 100 -d
```

# Check your installation

`example/` contains a small taxonomy table and the outputs you should get:

```shell
Rscript OTUtabler.R -l genus   -i example/example_taxonomy.csv -o out_genus
Rscript OTUtabler.R -l family  -i example/example_taxonomy.csv -o out_family -r
Rscript OTUtabler.R -l species -i example/example_taxonomy.csv -o out_species -m 100 -d

diff out_genus.csv   example/expected_genus.csv
diff out_family.csv  example/expected_family_relative.csv
diff out_species.csv example/expected_species_min100_dropunc.csv
```

`out_family.csv` may differ from the expected file in the number of decimal places printed (the expected file is rounded to 6 digits); the values should agree.

# Changes from V2

- Single script (`OTUtabler.R`); V1 relied on hard-coded column positions and is no longer needed.
- Uses `data.table` (`fread` / `dcast` / `fwrite`), which is faster and lighter on memory for large tables.
- Clear errors for a missing input file, missing columns, unsupported level or non-numeric hit counts. Only the selected taxonomy column is required now.
- `-o` is optional (V2 wrote a file literally named `.csv` when it was omitted).
- Empty/NA taxa are grouped as `Unclassified` (V2 produced a column named `NA`) or removed with `-d`.
- New options: relative abundance, minimum total hits, TSV in/out, custom column names.
- Packages are no longer installed automatically at run time.

# Output
## example from 16s rRNA full length Gut microbiota
<img width="992" alt="截圖 2024-08-29 下午4 03 59" src="https://github.com/user-attachments/assets/819d8302-f43f-456d-83af-392f4d8bbcd5">
