/*******************************************************************************

This file merges all state + federal data into a .dta. I start with EEOC data and 
then merge in states, formatting all variables and labels equivalently. 

Inputs: 
	- EEOC cleaned data
	- state cleaned data
	
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

// Clean basis 
g basis_clean = "Sex" if regexm(basis, "^Title VII / Sex")  | regexm(basis, "^EPA / Equal Pay-Female") 
replace basis_clean = "Religion" if regexm(basis, "^Title VII / Religion") 
replace basis_clean = "Race" if regexm(basis, "^Title VII / Race") | regexm(basis, "^Title VII / Color")
replace basis_clean = "Nationality" if regexm(basis, "^Title VII / National Origin")
replace basis_clean = "Disability" if regexm(basis, "^ADA") //Americans with Disabilities
replace basis_clean = "Age" if regexm(basis, "^ADEA") //Age Discrimination in Employment
replace basis_clean = "Retaliation" if regexm(basis, "^Title VII / Retaliation") | regexm(basis, "^EPA / Retaliation")
replace basis_clean = "Other" if regexm(basis, "^Title VII / Other") | regexm(basis, "^GINA")

g probable_cause = 1 if missing_relief == 0
replace probable_cause = 0 if missing_relief == 1 // no probable cause if relief is missing

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

gen common_res_date = cond(missing(charge_res_date), court_res_date, charge_res_date)
format common_res_date %td

// Clean duration variable 
replace duration = 0 if duration < 0 

gen ym = ym(year(common_file_date), month(common_file_date)) 
format ym %tm 
la var ym "Year-month var of file date"

// Get year
gen charge_file_year = year(charge_file_date)
gen charge_res_year = year(charge_res_date)
gen court_file_year = year(court_file_date)
gen court_res_year = year(court_res_date)

// overlap MeToo - 1 if case filed before MeToo & ended after, 0 o/w
gen overlap = (common_file_date < date("$metoo", "DMY")) ///
			 & (common_res_date > date("$metoo", "DMY"))
replace overlap = . if common_file_date > date("$metoo", "DMY") // remove cases filed after
replace overlap = . if common_file_date < date("$metoo", "DMY") - 365 // drop cases filed more than a year before MeToo
replace overlap = . if common_res_date > date("$metoo", "DMY") + 365 // remove cases resolved more than a year after
replace overlap = . if sh == 0 // leave only sh cases

// Gen post and treat
g post = (common_file_date > date("$metoo", "DMY"))
g treat = post*sh // treat ==1 if post 
replace treat = 1 if overlap == 1

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
la var relief "Compensation to plaintiff"
la var missing_relief "Plaintiff lost EEOC case"

// MA
la var id "State-given ID"
la var charge_file_year "Year case filed"
la var charge_res_year "Year case resolved"
la var outcome "Outcome of charge: no cause finding, hearing, settlement, etc"
la var charge_file_date "Date case filed"
la var charge_res_date "Date case resolved"
la var went_to_court "Case went to court"
la var probable_cause "Probable cause" //1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)

//Common
la var state "State"
la var basis "Basis of discrimination alleged"
la var basis_clean "Basis of discrimination, standardized"
la var sh "Sexual harassment charge"
la var sex_cases "Sex-related charge" // Title VII / Sex‐Female or Title VII / Sex‐Female / Sexual-Harassment for EEOC
la var post "Filing date after MeToo"
la var treat "Post = 1 and case is SH or overlap"
la var juris "Employment, public housing, or education"
la var duration "Days between filing and resolution"
la var overlap "Case overlaps with MeToo"

/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta", replace
