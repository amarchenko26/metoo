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
Clean EEOC court case data from .py files to match state files
*******************************************************************************/

use "$clean_data/clean_eeoc.dta", clear

drop index 
ren *, lower

ren case_name resp_org
ren allegations basis
ren resolution_date court_res_date
ren court_filing_date court_file_date
ren court court_name
gen state = "Federal"
gen juris = "Employment"

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
replace basis_clean = "Other" if regexm(basis, "^Title VII / Other") | regexm(basis, "^GINA") | basis == "" // if it's missing

g probable_cause = 1 if missing_relief == 0
replace probable_cause = 0 if missing_relief == 1 // no probable cause if relief is missing

g court = 1 

/*******************************************************************************
Append to EEOC filed data (2010-2017)
*******************************************************************************/

append using "$clean_data/clean_eeoc_filed.dta"


/*******************************************************************************
Append to MA
*******************************************************************************/

append using "$clean_data/clean_ma.dta"


/*******************************************************************************
Clean joint data
*******************************************************************************/

// Make common filing date, regardless of stage of case
g common_file_date = cond(missing(charge_file_date), court_file_date, charge_file_date)
format common_file_date %td

g common_res_date = cond(missing(charge_res_date), court_res_date, charge_res_date)
format common_res_date %td

// Clean duration variable 
replace duration = 0 if duration < 0 
winsor duration, p(.01) gen(duration_w)

// Gen ym var
g ym = ym(year(common_file_date), month(common_file_date)) 
format ym %tm 
la var ym "Year-month var of file date"

g common_year = year(common_file_date)

// Get year
g charge_file_year = year(charge_file_date)
g charge_res_year = year(charge_res_date)
g court_file_year = year(court_file_date)
g court_res_year = year(court_res_date)

// Overlap MeToo - 1 if case filed before MeToo & ended after, 0 o/w
g overlap = 1 if 	   common_file_date < date("$metoo", "DMY") & common_res_date > date("$metoo", "DMY") & sh == 1
replace overlap = 0 if common_file_date < date("$metoo", "DMY") & common_res_date < date("$metoo", "DMY") & sh == 1
replace overlap = . if common_file_date > date("$metoo", "DMY") // remove cases filed after
replace overlap = . if common_file_date < date("$metoo", "DMY") - 730 // drop cases filed more than a year before MeToo
replace overlap = . if common_res_date > date("$metoo", "DMY") + 365 // remove cases resolved more than a year after

replace overlap = . if sh == 0 // Double check to leave only sh cases

// Gen post and treat
g post = (common_file_date > date("$metoo", "DMY"))
g treat = post*sh // treat=1 if post =1 and sh=1
replace treat = . if sex_cases == 1 
replace treat = 1 if overlap == 1

// Clean relief
winsor relief, p(.05) gen(relief_w)
replace relief = . if missing_relief == 1 // if relief = 0, person lost, so everything is CONDITIONAL ON WINNING 

g relief_scale = relief / 1000

// Gen index var for count
g y = 1

// Gen cases_filed for regression
bys sh common_year: gen filed_per_year = _N
bys common_year: gen total_cases_per_year = _N
replace filed_per_year = filed_per_year / total_cases_per_year

// Gen categorical version of common vars
encode state, g(state_cat)
encode basis_clean, g(basis_cat)

/*******************************************************************************
Create time to treat - 0 is the pre-period before MeToo
*******************************************************************************/

// Create quarters
create_time_to_treat, period(3) period_label("Quarters relative to MeToo")

// Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

// Create time_to_treat for years
create_time_to_treat, period(12) period_label("Years relative to MeToo")


/*******************************************************************************
Label all variables
*******************************************************************************/

// EEOC
la var resp_org "Respondent organization"
la var resp_ln "Respondent last name"
la var civil_action_number "ID of court case"
la var court_name "Court ID where case filed"
la var court_file_date "Court filing date"
la var court_res_date "Court resolution date"
la var court_file_year "Year court case filed"
la var court_res_year "Year court case resolved"
la var relief "Compensation to plaintiff"
la var relief_scale "Compensation"
la var missing_relief "Plaintiff lost EEOC case"
la var victim_f "Complainant is female"

// MA
la var id "State-given ID"
la var charge_file_year "Year case filed"
la var charge_res_year "Year case resolved"
la var outcome "Outcome of charge: no cause finding, hearing, settlement, etc"
la var charge_file_date "Date case filed"
la var charge_res_date "Date case resolved"
la var court "Case went to court"
la var probable_cause "Probable cause" //1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)
la var settle "Case settled"

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
la var court "Case went to court"
la var filed "Number of cases filed by SH and Post"
la var common_year "Year of filing"

/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta", replace