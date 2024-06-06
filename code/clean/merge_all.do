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
	- HI

*******************************************************************************/


/*******************************************************************************
Pull cleaned EEOC court case data
*******************************************************************************/

use "$clean_data/clean_eeoc.dta", clear


/*******************************************************************************
Append to EEOC filed data (2010-2017)
*******************************************************************************/

append using "$clean_data/clean_eeoc_filed.dta"

/*******************************************************************************
Append to MA
*******************************************************************************/

append using "$clean_data/clean_ma.dta"

/*******************************************************************************
Append to HI
*******************************************************************************/

append using "$clean_data/clean_hi.dta"

/*******************************************************************************
Append to MI
*******************************************************************************/

//append using "$clean_data/clean_mi.dta"
//waiting on MI to respond to definition of "win"

/*******************************************************************************
Append to IL
*******************************************************************************/

append using "$clean_data/clean_il.dta"

/*******************************************************************************
Append to TX
*******************************************************************************/

//append using "$clean_data/clean_tx.dta"
//waiting on TX to respond to identification of sh cases filed

/*******************************************************************************
Append to ND
*******************************************************************************/

//append using "$clean_data/clean_nd.dta"
//waiting on ND to respond to identification of primary basis



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



/*******************************************************************************
2 Definitions of Overlap
*******************************************************************************/

// Overlap MeToo - 1 if case filed before MeToo & ended after, 0 o/w
g overlap_all = 1 if common_file_date < date("$metoo", "DMY") & common_res_date > date("$metoo", "DMY") & sh == 1 // 1 if case ended after MeToo
replace overlap_all = 0 if common_file_date < date("$metoo", "DMY") & common_res_date < date("$metoo", "DMY") & sh == 1 // 0 if case ended before MeToo
replace overlap_all = . if common_file_date > date("$metoo", "DMY") // remove cases filed after
replace overlap_all = . if sh == 0 // Double check to leave only sh cases

// overlap_2 - Bounded at a duration of 2 years maximum
g overlap_2 = overlap_all
replace overlap_2 = . if common_file_date < date("$metoo", "DMY") - 730 // drop cases filed more than two years before MeToo
replace overlap_2 = . if common_res_date > date("$metoo", "DMY") + 365 // remove cases resolved more than a year after
replace overlap_2 = . if (common_file_date < date("$metoo", "DMY") - 365) & (overlap_2 == 1) // remove overlap cases filed more than a year before MeToo


/*******************************************************************************
Gen post and treat 
*******************************************************************************/

// Gen post and treat
g post = (common_file_date > date("$metoo", "DMY"))
g treat = post*sh // treat=1 if post =1 and sh=1
replace treat = . if sex_cases == 1 & sh == 0 
replace treat = 1 if overlap_2 == 1

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
encode basis, g(basis_cat)

replace eeoc_filed = 0 if missing(eeoc_filed)

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
la var eeoc_filed "Indicator for if data from ProPublica request"

// MA
la var id "State-given ID"
la var charge_file_year "Year filed"
la var charge_res_year "Year resolved"
la var outcome "Outcome of charge: no cause finding, hearing, settlement, etc"
la var charge_file_date "Date case filed"
la var charge_res_date "Date case resolved"

//Common
la var state "State"
la var basis_raw "Basis of discrimination alleged"
la var basis "Basis of discrimination, standardized"
la var sh "Sexual harassment"
la var sex_cases "Sex-related charge" // Title VII / Sex‐Female or Title VII / Sex‐Female / Sexual-Harassment for EEOC
la var post "Filed after MeToo"
la var treat "Post = 1 and case is SH or overlap"
la var juris "Employment, public housing, or education"
la var duration "Duration (days)"
la var overlap_2 "Overlaps with MeToo"
la var court "Went to court"
la var filed "Number of cases filed by SH and Post"
la var common_year "Year of filing"
la var win "Plaintiff won" //1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)
la var settle "Settled"

// Indent all variable labels for tables
foreach v of varlist * {
	label variable `v' `"\hspace{0.1cm} `: variable label `v''"'
	}
	
/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta", replace
