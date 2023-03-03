# Elasticities of Care Utilization Patterns During the COVID-19 Pandemic: A High-Dimensional Study of Presentations for Ophthalmic Conditions in the United States
_Charles Li, Flora Lum, Evan M. Chen, Philip A. Collender, Jennifer R. Head, Rahul N. Khurana, Emmett T. Cunningham Jr., Ramana S. Moorthy, David W. Parke II, Stephen D. McLeod_

*Last updated:* **March XX, 2023** by Charles Li (cli@aao.org), including data up to **December 31, 2021**

## About


## Data Processing and Analytic Steps

This project consists of the following main stages:

![common-analytical-framework](main-figures/figure-1.jpg)

### Step 1A. Construct an inventory of ophthalmic diagnoses to study

1. An inventory of conditions ("diagnosis entities") to include for analysis was delineated using the spreadsheet file `codebooks/source materials/CCSR ICD10 5.4.20_modified.xlsx`, adapted from [v2020.2](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/v2020_2.zip) of the U.S. Agency for Healthcare Research and Quality [Clinicial Classifications Software Refined (CCSR) database](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp#overdiagnoses). The CCSR aggregates tens of thousands of International Classification of Diseases, Tenth Revision, Clinical Modification (ICD-10-CM) codes into [clinically meaningful groupings](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/DXCCSR-User-Guide-v2023-1.pdf), which are called "diagnosis entities" in this study. Only the "EYE" chapter of the CCSR, which encompasses ICD-10-CM codes related to diseases of the eye and adnexa, was considered for this analysis. 

    `CCSR ICD10 5.4.20_modified.xlsx` contains two tabs: the first tab is a spreadsheet that maps each ICD-10-CM diagnosis code (`ICD-10 Code`) to a diagnosis entity (`DiagnosisEntity`). Each distinct ICD-10-CM code is listed once (on a single row), with the ICD-10-CM description of the diagnosis code (`Diagnosis`), the diagnosis entity that the ICD-10-CM code belongs to (`DiagnosisEntity`), and the broader diagnosis category that the diagnosis entity belongs to (`CCSR Category`), in abbreviation form (EYE0XX), listed across the columns of the spreadsheet. Unlike the original CCSR mapping, which allowed for some ICD-10-CM codes to be cross-classified into more than one category, we adopted a mutually exclusive categorization scheme by assigning each diagnosis entity to one of 13 diagnosis categories (EYE001 - EYE013). Furthermore, an ICD-10-CM diagnosis code with incomplete time series (TS) data of monthly counts of patients observed with that condition and/or very low monthly case counts was excluded from consideration in this study if it was not feasible to assign the code into an existing or new (standalone) diagnosis entity in a clinically meaningful way. For ICD-10-CM codes that are not assigned to any diagnosis entity, `CODE EXCLUDED` was written in the `DiagnosisEntity` column. **Text SX** of the [Supplementary Information]() contains further details on the assignment of ICD-10-CM codes to diagnosis entities and other adaptations made from the original groupings provided by the CCSR database.

    The second tab includes a list the full names of the diagnosis categories and their abbreviations (EYE0XX).

    For ease of import into R, both sheets of the Excel file were separately converted into CSV format:
    > **Outputs**: \
     `codebooks/source materials/CCSR ICD10 dx_entities 5.4.20_modified.csv`\
     `codebooks/source materials/CCSR ICD10 categories 5.4.20_modified.csv`

2. Next, the R script `codebooks/source materials/ccsr_codebook_qc_wrangling.Rmd` was run to produce a clean mapping of ICD-10-CM codes and diagnosis entities that can be imported into a relational database as a lookup table that facilitates the querying of monthly case numbers for each diagnosis entity. Data pre-processing steps and quality control checks were run to remove ICD-10-CM codes designated for exclusion, make formatting changes to ICD-10-CM codes to ensure compatability with database queries, and verify that each diagnosis entity is assigned to exactly one diagnosis category. 

    > **Inputs**:\
      `codebooks/source materials/CCSR ICD10 dx_entities 5.4.20_modified.csv`\
      `codebooks/source materials/CCSR ICD10 categories 5.4.20_modified.csv`  
      **Output**:\
      `codebooks/diagnoses/ccsr_codebook_for_sql.csv`

### Step 1B. Extract monthly counts of patients observed with each diagnosis

3. `covid19_alldx_pull.sql` to pull the monthly case numbers of all diagnosis entities queried
    
    INPUT:
        `codebooks/diagnoses/ccsr_codebook_for_sql.csv` imported into AWS Redshift (the database schema) as `aao_team.master_icd_list_ccsr` 

    OUTPUT:
        `aao_project.covid_elasticity_all_dx_2017_2021_complete`

4. `covid_elasticity_dataset_prep.Rmd` to generate a dataset to the Shiny app (see Step 5)
    
    INPUT:
        `data-exports/covid_elasticity_all_dx_2017_2021_202201242318.csv`

    OUTPUT:
        `shiny-app/dx_proportions_and_cnts.csv`

    OPTIONAL STEP: to generate summary stats for the monthly volume of each diagnosis entity, run `codebooks/diagnoses/dxentities_eda.Rmd` with the same INPUT file. OUTPUT: `codebooks/diagnoses/dx_entities_EDA_summary.csv`

5. `shiny-app/app.R`
    
    INPUTS:
        `shiny-app/ccsr_codebook_for_sql.csv` (copied from `codebooks/diagnoses/`) [NOT DONE YET]
        `CCSR categories 5.4.20_CLedits_01102021.csv` (copied from `codebooks/diagnoses/`)
        `shiny-app/dx_proportions_and_cnts.csv`

    OUTPUT:
        the Shiny dashboard (https://aao-charlesli.shinyapps.io/covid-elasticity-analyses/)
