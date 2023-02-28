# Elasticities of Care Utilization Patterns During the COVID-19 Pandemic: A High-Dimensional Study of Presentations for Ophthalmic Conditions in the US
_Charles Li, Flora Lum, Evan M. Chen, Philip A. Collender, Jennifer R. Head, Rahul N. Khurana, Emmett T. Cunningham Jr., Ramana S. Moorthy, David W. Parke II, Stephen D. McLeod_

*Last updated: February 23, 2023 by Charles Li (cli@aao.org)*

## About


## Data Processing and Analytic Steps

0. Define an inventory of conditions ("diagnosis entities") to study in the `codebooks/diagnoses/CCSR ICD10 5.4.20_modified.xlsx` spreadsheet, which is adapted from [v2020.2](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/v2020_2.zip) of the [Clinicial Classifiactions Software Refined (CCSR) database](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp#overdiagnoses), developed by the U.S. Agency for Healthcare Research and Quality. The CCSR aggregates tens of thousands of International Classification of Diseases, Tenth Revision, Clinical Modification (ICD-10-CM) codes into ["clinically meaningful categories"](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/DXCCSR-User-Guide-v2023-1.pdf),  which are hereafter referred to as "diagnosis entities". Only the "EYE" chapter of the CCSR, which encompasses ICD-10-CM codes related to diseases of the eye and adnexa, was utilized for this study. 

    This spreadsheet file contains two sheets: In the spreadsheet, every line corresponds to an ICD code, and the `DiagnosisEntity` column contains the name of the diagnosis entity that each ICD code is being classifed under (the diagnosis category is represented in the `CCSR Category` column). If an ICD code is to be excluded, write `CODE EXCLUDED` in the `DiagnosisEntity` column. 

    For ease of import into R, both sheets of the .xlsx file were saved as separate CSV files:

    `codebooks/diagnoses/CCSR ICD10 dx_entities 5.4.20_modified.csv` 
    `codebooks/diagnoses/CCSR ICD10 categories 5.4.20_modified.csv`

1. `codebooks/diagnoses/ccsr_codebook_qc_wrangling.Rmd` to produce a codebook that can be imported into Redshift, and to ensure the integrity of the diagnosis entities defined; STEPS: remove all excluded ICD's, add proper formatting to the `ICD-10 Code` column, and ensure that there is a 1:1 mapping between diagnosis entities and diagnosis categories (i.e., a diagnosis entity can only be assigned to one EYE0XX diagnosis category)

    INPUT:
        `codebooks/diagnoses/CCSR ICD10 5.4.20_CLedits_01242021.csv`
        `codebooks/diagnoses/CCSR categories 5.4.20_CLedits_01102021.csv`
    OUTPUT:
        `codebooks/diagnoses/ccsr_codebook_for_sql.csv`

2. `covid19_alldx_pull.sql` to pull the monthly case numbers of all diagnosis entities queried
    
    INPUT:
        `codebooks/diagnoses/ccsr_codebook_for_sql.csv` imported into AWS Redshift (the database schema) as `aao_team.master_icd_list_ccsr` 

    OUTPUT:
        `aao_project.covid_elasticity_all_dx_2017_2021_complete`

3. `covid_elasticity_dataset_prep.Rmd` to generate a dataset to the Shiny app (see Step 5)
    
    INPUT:
        `data-exports/covid_elasticity_all_dx_2017_2021_202201242318.csv`

    OUTPUT:
        `shiny-app/dx_proportions_and_cnts.csv`

    OPTIONAL STEP: to generate summary stats for the monthly volume of each diagnosis entity, run `codebooks/diagnoses/dxentities_eda.Rmd` with the same INPUT file. OUTPUT: `codebooks/diagnoses/dx_entities_EDA_summary.csv`

4. `shiny-app/app.R`
    
    INPUTS:
        `shiny-app/ccsr_codebook_for_sql.csv` (copied from `codebooks/diagnoses/`) [NOT DONE YET]
        `CCSR categories 5.4.20_CLedits_01102021.csv` (copied from `codebooks/diagnoses/`)
        `shiny-app/dx_proportions_and_cnts.csv`

    OUTPUT:
        the Shiny dashboard (https://aao-charlesli.shinyapps.io/covid-elasticity-analyses/)
