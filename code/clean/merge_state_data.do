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
Load EEOC data from .py files
*******************************************************************************/

use "$clean_data/clean_eeoc.dta", clear


/*******************************************************************************
Clean EEOC data to match formatting of state files
*******************************************************************************/

drop index 
ren *, lower

ren case_name resp_org
ren allegations basis
ren resolution_date court_resolution_date
gen state = "Federal"
gen juris = "Employment"
gen went_to_court = 1 // all EEOC cases we have are court cases

la var resp_org "Respondent organization"
la var civil_action_number "ID of court case"
la var basis "Basis of discrimination alleged"
la var court "Court ID where case filed"
la var court_filing_date "Court filing date"
la var court_resolution_date "Court resolution date"
la var juris "Employment, public housing, education, etc"
la var sh "=1 if basis is sexual harassment"
la var relief "$ compensation to plaintiff, if non-missing"
la var missing_relief "=1 if plaintiff received $0 compensation"
la var sex_cases "=1 if basis is Title VII / Sex‐Female or Title VII / Sex‐Female / Sexual-Harassment"
la var before "=1 if court filing date before Oct 1 2017"
la var duration "Days between court filing and resolution"

// remove time (all times are zero anyway)


/*******************************************************************************
Append to MA
*******************************************************************************/

append using "$clean_data/clean_ma.dta"

* g datevar = date(court_filing_date, "DMY")


/*******************************************************************************
Clean joint data
*******************************************************************************/




/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta"
