# FSCI_2023Baseline_Replication
Replication files for Schneider et al (2023) "The State of the World's Food Systems: Countding Down to 2030"

FSCI Replication Workflow
Creator: Kate Schneider
Purpose: Replicate the workflow to create the dataset and analyses for Schneider et al (2023), "The State of the World's Food Systems: Counting Down to 2030"
Last updated: 10 September 2023

1. Metadata spreadsheet lists original source and download instructions for all raw datasets.
2. Raw data saved in "Raw data"
3. Two indicators are created in external steps: % Urban population living in a municipality signed onto the MUFPP and the Minimum Species Richness. Code to replicate indicator creation prior to Stata .do data processing file are included in the replication code files.
4. Stata .do file performs the following (in this order):
	a. Ingests raw data, harmonizes units of analysis and merges into analysis datasets. Each indicator saves out at least one dataset into the "FSCI analysis datasets" folder. 
	b. Merges the data together into a single data file, including the full time series, also saved to the "FSCI analysis datasets" folder.
	c. Creates the latest year dataset that keeps one data point per country per indicator from the latest year available, also saved to the "FSCI analysis datasets" folder. This file is renamed as Appendix F the baseline dataset for the baseline paper.
	d. Creates metadata files of which year is the latest year in the baseline dataset. This also saves to the "FSCI analysis datasets" folder.
	e. Creates summary statistics and documents coverage, saved to the "Analysis results" folder. Note that the "ResultsTable.xlsx" file includes many internal dependencies and should only be modified and not replaced. This file contains all the tables that appear in the main paper and supplementary materials.
5. R syntax file creates the figures in the paper and the supplementary materials. Figures output to a "Figures" folder.


Explanation of analysis datasets: This folder contains individual data frames (in .dta and .csv formats) for each indicator and supplementary data created in the Stata .do file. The complete dataset with time series is also found in this folder. There are multiple versions, indicated by the filename and explained here:
- FSCI_2022_latestyear: synonomyous with the baseline dataset found in the root folder, with the only difference being that there is some additional formatting to the baseline dataset labelled as "Supplementary Data - Appendix F - Baseline dataset" as an excel workbook so that it is a standalone human readable file.
- FSCI_2022_latestyear_withweightvars: includes the additional variables needed to compute the weighted means
- FSCI_2022_ltsyr_metadata: records the year of the latest year per country-indicator, and is copied as a sheet into the file "FSCI Baseline_Supplementary Data - Appendix E - Metadata and Codebook"
- FSCI_2022_timeseries: the time series compiled dataset
- FSCI_2022_timeseries_withweightvars: the time series compiled dataset, also including the additional variables needed for the weighted means

Send any questions to: kschne29@jhu.edu
