/* Elasticities of Care Utilization Patterns During the COVID-19 Pandemic: A High-Dimensional Study of Presentations for Ophthalmic Conditions in the US
 * SQL SCRIPT USED TO GENERATE MONTHLY TIME SERIES DATA OF THE NUMBERS OF PATIENTS OBSERVED WITH EACH DIAGNOSIS ENTITY, FROM JANUARY 2017 TO DECEMBER 2021
 * NOTE: ACCESS TO THE AMERICAN ACADEMY OF OPHTHALMOLOGY INTELLIGENT RESEARCH IN SIGHT (IRIS) REGISTRY IS NEEDED TO RUN THIS SCRIPT
 * AT THIS TIME, THE IRIS REGISTRY IS NOT A PUBLICLY AVAILABLE DATASET. ELIGIBLE APPLICANTS MAY APPLY TO WORK WITH IRIS REGISTRY DATA AT https://www.aao.org/iris-registry/data-analysis/requirements
 * THE MINIMUM DATA NEEDED TO INTERPRET, VERIFY, AND EXTEND THIS RESEARCH (INCLUDING THE DATA OUTPUT OF THIS SCRIPT) ARE AVAILABLE AT https://github.com/charlesli37/covid-elasticity-oph
 * Author: Charles Li (cli@aao.org)
 * Chicago (IRIS Registry database schema) version: 04-Apr-2022
 * Last updated: 15-May-2022
 * Run on AWS Redshift v. 1.0.38698 (PostgreSQL 8.0.2)
 * */

/* STEP 1. Pull all records of patient-provider encounters from the IRIS Registry from 2013 to 2021 */
drop table if exists aao_project.all_visits_chicago_2013_2021;
create table aao_project.all_visits_chicago_2013_2021 as 
select distinct patient_guid, practice_id, encounter_date
from chicago.patient_encounter
where encounter_date between '2013-01-01' and '2021-12-31';
--select count(*), count(distinct patient_guid), count(distinct practice_id) from aao_project.all_visits_chicago_2013_2021; --512471214 records from 73206842 patients and 3546 practice_id's

/* STEP 2A. Pull all records of diagnoses documented between 2017 to 2021, among patients who had at least one provider encounter from 2013 to 2021 */
drop table if exists dx_records_in_2017_2021;
create table dx_records_in_2017_2021 as 
select distinct pc.patient_guid, condition_code, practice_id, p.state as state_of_residence,
case when onset_date is null then documentation_date
	 when documentation_date is null then onset_date
	 when (documentation_date is not null and onset_date is not null and documentation_date = onset_date) then documentation_date
	 when (documentation_date is not null and onset_date is not null and documentation_date > onset_date) then onset_date
	 when (documentation_date is not null and onset_date is not null and documentation_date < onset_date) then documentation_date
end as diagnosis_date
from chicago.patient_condition pc 
left join chicago.patient p 
on pc.patient_guid = p.patient_guid
where diagnosis_date between '2017-01-01' and '2021-12-31'
and practice_id <> 3204 --excluding a particular solo practice from consideration due to an observed data anomaly with its reporting 
and pc.patient_guid in (select distinct patient_guid from aao_project.all_visits_chicago_2013_2021)
and condition_code is not null
and vh_cui not ilike 'SNOMED-CT%' --excluding non-ICD terminologies, like SNOMED-CT, from consideration
and vh_cui not ilike 'UNMAPPED%';
--select count(*), count(distinct patient_guid) from dx_records_in_2017_2021; 1112697306 records from 53406232 patients

/* STEP 2B. Only keep diagnosis records with a corresponding patient-provider encounter on the same date as the diagnosis documentation */
drop table if exists dx_with_sameday_encounters;
create table dx_with_sameday_encounters as 
select d.* 
from dx_records_in_2017_2021 d
inner join aao_project.all_visits_chicago_2013_2021 v
on d.patient_guid = v.patient_guid 
and d.diagnosis_date = v.encounter_date
and d.practice_id = v.practice_id;
--select count(*), count(distinct patient_guid) from dx_with_sameday_encounters; --1026314199 records from 52622246 patients

/* STEP 3. Only keep diagnosis records whose ICD-10-CM code corresponds to one that is defined for a diagnosis entity in the 
 * master inventory of all 336 diagnosis entities considered for inclusion in this analysis (stored in a permanent table `aao_team.master_icd_list_ccsr` imported into the database).
 * Diagnosis entities were adapted from existing classifications provided by https://hcup-us.ahrq.gov/toolssoftware/ccsr/dxccsr.jsp 
 */
drop table if exists all_queried_dx_2017; 
create table all_queried_dx_2017 as
select distinct d.*, m.diagnosisentity as dx_name, m.icd10code
from dx_with_sameday_encounters d
inner join aao_team.master_icd_list_ccsr m
on d.condition_code ilike m.icd10code || '%'
where extract(year from d.diagnosis_date) = '2017';

drop table if exists all_queried_dx_2018; 
create table all_queried_dx_2018 as
select distinct d.*, m.diagnosisentity as dx_name, m.icd10code
from dx_with_sameday_encounters d
inner join aao_team.master_icd_list_ccsr m
on d.condition_code ilike m.icd10code || '%'
where extract(year from d.diagnosis_date) = '2018';

drop table if exists all_queried_dx_2019; 
create table all_queried_dx_2019 as
select distinct d.*, m.diagnosisentity as dx_name, m.icd10code
from dx_with_sameday_encounters d
inner join aao_team.master_icd_list_ccsr m
on d.condition_code ilike m.icd10code || '%'
where extract(year from d.diagnosis_date) = '2019';

drop table if exists all_queried_dx_2020; 
create table all_queried_dx_2020 as
select distinct d.*, m.diagnosisentity as dx_name, m.icd10code
from dx_with_sameday_encounters d
inner join aao_team.master_icd_list_ccsr m
on d.condition_code ilike m.icd10code || '%'
where extract(year from d.diagnosis_date) = '2020';

drop table if exists all_queried_dx_2021; 
create table all_queried_dx_2021 as
select distinct d.*, m.diagnosisentity as dx_name, m.icd10code
from dx_with_sameday_encounters d
inner join aao_team.master_icd_list_ccsr m
on d.condition_code ilike m.icd10code || '%'
where extract(year from d.diagnosis_date) = '2021';

drop table if exists all_queried_dx_2017_2021;
create table all_queried_dx_2017_2021 as
select * from all_queried_dx_2017
union 
select * from all_queried_dx_2018
union 
select * from all_queried_dx_2019
union 
select * from all_queried_dx_2020
union 
select * from all_queried_dx_2021;
-- select count(*), count(distinct patient_guid), count(distinct practice_id), count(distinct dx_name) from all_queried_dx_2017_2021; 641483046 records from 50961580 patients and 3452 practices with 336 unique dx

/* STEP 4: Only include diagnosis records from practices with "complete" data throughout the study period 
 * i.e., patient-provider encounter records from each month from January 2017 to December 2021 */
drop table if exists visits_by_practice; 
create table visits_by_practice as
select distinct practice_id, extract(month from encounter_date) as visit_month, extract(year from encounter_date) as visit_year, count(distinct patient_guid) as num_patients				
from aao_project.all_visits_chicago_2013_2021
where encounter_date between '2017-01-01' and '2021-12-31'
group by practice_id, visit_month, visit_year;
--select * from visits_by_practice order by practice_id, visit_year asc, visit_month asc;
--select count(distinct practice_id) from visits_by_practice; --3479 total practice_id's

drop table if exists aao_project.practice_completeness; 
create table aao_project.practice_completeness as
select distinct practice_id, count(*) --count the number of rows in visits_by_practice by practice_id
from visits_by_practice
where num_patients <> 0 --so that a count of "0" will not count as a row 
group by practice_id;
--select count(*) from aao_project.practice_completeness; --3479 practice_id's
--select count(*) from aao_project.practice_completeness where count <> 60; --1023 practice_id's
--select count(*) from aao_project.practice_completeness where count = 60; --2456 practice_id's
--practices with "complete" data should have exactly 60 rows in this table that correspond to its practice_id

drop table if exists all_queried_dx_2017_2021_complete;
create table all_queried_dx_2017_2021_complete as 
select * 
from all_queried_dx_2017_2021
where practice_id in (select distinct practice_id from aao_project.practice_completeness where count = 60);
--select count(*), count(distinct patient_guid), count(distinct dx_name) from all_queried_dx_2017_2021_complete; --566495519, 44906262, 336

/* STEP 5: Extract overall numbers of patients recorded with any diagnosis entity for each month from January 2017 to December 2021
 * Note: these numbers are not used in the final analysis */
drop table if exists denoms_complete;
create table denoms_complete as 
select distinct extract(month from diagnosis_date) as month, extract(year from diagnosis_date) as year,
		        count(*) as tot_num_dx_records, count(distinct patient_guid) as tot_num_dx_patients
from all_queried_dx_2017_2021_complete
group by month, year
order by year asc, month asc;
--select count(*) from denoms_complete; --60 (OK. 12*5=60 months from 2017-2021)*/

/* STEP 6: Extract numbers of patients recorded with each diagnosis entity for each month from January 2017 to December 2021 */ 
drop table if exists diag_counts_complete; 
create table diag_counts_complete as 
select distinct extract(month from diagnosis_date) as month, extract(year from diagnosis_date) as year, dx_name, 
	   count(*) as num_dx_records, count(distinct patient_guid) as num_dx_patients,
	   row_number() over(partition by dx_name order by year, month) as rn
from all_queried_dx_2017_2021_complete
group by month, year, dx_name;
--select count(*) from diag_counts_complete; --20160 (OK. 336 unique dx_name (diagnosis entities) * 60 months)
--select count(*) from diag_counts_complete where num_dx_records = 0; --OK. 0 
--select count(*) from diag_counts_complete where num_dx_patients = 0; --OK. 0 

/* STEP 7: Create table of monthly time series data for each diagnosis entity; export this table for further wrangling and analysis */ 
drop table if exists aao_project.covid_elasticity_all_dx_2017_2021_complete;
create table aao_project.covid_elasticity_all_dx_2017_2021_complete as 
select distinct a.month, a.year, dx_name, num_dx_records, num_dx_patients, tot_num_dx_records, tot_num_dx_patients
from diag_counts_complete a
left join denoms_complete b 
on a.year = b.year and a.month = b.month
order by year asc, month asc, dx_name asc;
--select count(*) from aao_project.covid_elasticity_all_dx_2017_2021_complete; --OK. 20160 rows 

/* END OF MAIN SCRIPT */

/* ADDITIONAL CONTENT AND SENSITIVITY ANALYSES */

/* For manuscript reporting - number of patients included in the final analysis after filtering out diagnosis entities with a poor out-of-sample counterfactual model performance */
select count(*) from aao_team.accurate_dx_list_csv; --261 "accurate" diagnoses entities that have a sufficiently low out-of-sample counterfactual model performance, defined as under 12.5% root-mean-squared percentage error
--this table is to be generated from the R script, and imported into the database as `aao_team.accurate_dx_list_csv`

select count(*), count(distinct patient_guid), count(distinct dx_name) 
from (
select a.* 
from all_queried_dx_2017_2021_complete a
inner join aao_team.accurate_dx_list_csv adlc 
on a.dx_name = adlc.x);
--538198111 records from 44624281 patients with 261 unique dx

/* Sensitivity analysis - with same STEPS 1-3 as above, but now relaxing the restriction that all practices included for analysis must have "complete" time series data throughout the entire study period */
/* i.e., run up to (and including) STEP 3 as coded above, and then the following code: */

drop table if exists denoms;
create table denoms as 
select distinct extract(month from diagnosis_date) as month, extract(year from diagnosis_date) as year,
		        count(*) as tot_num_dx_records, count(distinct patient_guid) as tot_num_dx_patients
from dx_records_in_2017_2021
group by month, year
order by year asc, month asc;

drop table if exists diag_counts; 
create table diag_counts as 
select distinct extract(month from diagnosis_date) as month, extract(year from diagnosis_date) as year, dx_name, 
	   count(*) as num_dx_records, count(distinct patient_guid) as num_dx_patients,
	   row_number() over(partition by dx_name order by year, month) as rn
from all_queried_dx_2017_2021
group by month, year, dx_name;

drop table if exists aao_project.covid_elasticity_all_dx_2017_2021;
create table aao_project.covid_elasticity_all_dx_2017_2021 as 
select distinct a.month, a.year, dx_name, num_dx_records, num_dx_patients, tot_num_dx_records, tot_num_dx_patients
from diag_counts a
left join denoms b 
on a.year = b.year and a.month = b.month
order by year asc, month asc, dx_name asc; 
--export this table for the sensitivity analysis