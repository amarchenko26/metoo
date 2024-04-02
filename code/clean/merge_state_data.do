/*******************************************************************************

This file merges all state + federal data into a .dta. I start with EEOC data and 
then merge in states, formatting all variables and labels equivalently. 

Inputs: 
	- EEOC cleaned data
	- stata cleaned data
	
Outputs: 
	- clean_cases.dta 
	
Already merged: 
	- EEOC
	- MA

*******************************************************************************/


/*******************************************************************************
Clean EEOC data from .py files to match state files
*******************************************************************************/

use "$clean_data/clean_eeoc.dta", clear

drop index 
ren *, lower

ren case_name resp_org
ren allegations basis
ren resolution_date court_res_date
ren court_filing_date court_file_date
gen state = "Federal"
gen juris = "Employment"
gen went_to_court = 1 // all EEOC cases we have are court cases

// remove time (all times are zero anyway)
replace court_file_date = dofc(court_file_date)
format court_file_date %td

replace court_res_date = dofc(court_res_date)
format court_res_date %td


/*******************************************************************************
Append to MA
*******************************************************************************/

append using "$clean_data/clean_ma.dta"


/*******************************************************************************
Clean joint data
*******************************************************************************/

// Make common filing date, regardless of stage of case
gen common_file_date = cond(missing(charge_file_date), court_file_date, charge_file_date)
format common_file_date %td

// Clean duration variable 
replace duration = 0 if duration < 0 

gen ym = ym(year(common_file_date), month(common_file_date)) 
format ym %tm 
la var ym "Year-month var"

// Get year
gen charge_file_year = year(charge_file_date)
gen charge_res_year = year(charge_res_date)
gen court_file_year = year(court_file_date)
gen court_res_year = year(court_res_date)


/*******************************************************************************
Label all variables
*******************************************************************************/

// EEOC
la var resp_org "Respondent organization"
la var resp_ln "Respondent last name"
la var civil_action_number "ID of court case"
la var court "Court ID where case filed"
la var court_file_date "Court filing date"
la var court_res_date "Court resolution date"
la var court_file_year "Year court case filed"
la var court_res_year "Year court case resolved"
la var relief "Compensation to plaintiff, if non-missing"
la var missing_relief "=1 if plaintiff received no compensation"

// MA
la var id "State-given ID"
la var charge_file_year "Year charge filed"
la var charge_res_year "Year charge resolved"
la var outcome "Outcome of charge: no cause finding, hearing, settlement, etc"
la var charge_file_date "Date charge filed"
la var charge_res_date "Date charge resolved"
la var went_to_court "=1 if case went to court"

//Common
la var state "State"
la var basis "Basis of discrimination alleged"
la var sh "=1 if basis is sexual harassment"
la var sex_cases "=1 if basis is sex-related" // Title VII / Sex‐Female or Title VII / Sex‐Female / Sexual-Harassment for EEOC
la var treat "=1 if filing date after Oct 1 2017"
la var juris "Employment, public housing, or education"
la var duration "Days between filing and resolution"


/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta", replace
