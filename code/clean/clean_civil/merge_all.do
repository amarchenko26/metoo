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
	- MI
	- IL
	- WA
	- ND
	- MN
	- RI
	- AK
	- PA
	- WI
	- KY
	
*******************************************************************************/

clear all
set maxvar 32767

/*******************************************************************************
Pull cleaned EEOC filed data (2010-2017)
*******************************************************************************/

tempfile temp
use "$clean_data/clean_eeoc.dta", clear
duplicates drop civil_action_number court_res_date, force
replace civil_action_number = subinstr(civil_action_number, "‐", "-", .)
save "`temp'", replace

use "$clean_data/clean_eeoc_filed.dta", clear

/*******************************************************************************
Merge using EEOC court case data
*******************************************************************************/

merge m:1 civil_action_number court_res_date using "`temp'"
drop _merge

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

append using "$clean_data/clean_mi.dta"

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

append using "$clean_data/clean_nd.dta"

/*******************************************************************************
Append to WA
*******************************************************************************/

append using "$clean_data/clean_wa.dta"

/*******************************************************************************
Append to MN
*******************************************************************************/

append using "$clean_data/clean_mn.dta"

/*******************************************************************************
Append to RI
*******************************************************************************/

append using "$clean_data/clean_ri.dta"

/*******************************************************************************
Append to AK
*******************************************************************************/

append using "$clean_data/clean_ak.dta"

/*******************************************************************************
Append to PA
*******************************************************************************/

append using "$clean_data/clean_pa.dta"

/*******************************************************************************
Append to WI
*******************************************************************************/

append using "$clean_data/clean_wi.dta"

/*******************************************************************************
Append to KY
*******************************************************************************/

append using "$clean_data/clean_ky.dta"


/*******************************************************************************
Clean dates
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

replace eeoc_filed = 0 if missing(eeoc_filed)

/*******************************************************************************
Consistent sample 
*******************************************************************************/

// Drop cases resolved before filed
drop if common_file_date > common_res_date

// Drop obs before Oct 2010
di tm(2010m10)
drop if ym < 609

// Drop obs after Oct 2023
di tm(2023m10)
drop if ym > 765

// Drop missing bases (N=10 obs in PA) 
cap drop if basis == ""

// Drop Other category 
drop if basis == "Other"

// Drop cases removed to EEOC
di tm(2017m9)
drop if inlist(outcome, "C02 - Allegations contained in duplicate EEOC case", "Closed - EEOC-Administrative", "E05 - EEOC assumed jurisdiction - no adjustment", "I15 - Withdrawn - pursue with EEOC", "Transfer to EEOC (Closed at Commission)", "Transfer to EEOC at Intake", "Transferred to EEOC", "sent to the EEOC") & ym < 692

/*******************************************************************************
Fixed effects  
*******************************************************************************/

encode state, g(state_cat)
encode basis, g(basis_cat)

// Gen state/unit and state/time FE
g basis_state = basis_cat * state_cat
g ym_state 	  = ym * state_cat

/*******************************************************************************
Outcomes
*******************************************************************************/

// Gen index var for count
g y = 1

// Gen filed_per_year for sh vs non
bys common_year: gen total_cases_per_year = _N
bys common_year: egen total_gender_cases_per_year = sum(y) if victim_f != .
bys common_year sh: gen sh_per_year = _N
bys common_year sh victim_f: gen sh_f_per_year = _N
g filed_per_year = sh_per_year / total_cases_per_year
g filed_f_per_year = sh_f_per_year / total_gender_cases_per_year

// Gen share_filed_by_basis
bys basis common_year: gen filed_by_basis = _N
g share_filed_by_basis = filed_by_basis / total_cases_per_year

// Clean relief
winsor relief, p(.05) gen(relief_w)
replace relief = . if missing_relief == 1 // if relief = 0, person lost, so relief is CONDITIONAL ON WINNING 
g relief_scale = relief_w / 1000

// Investigation
g investigation = 0 if dismissed != . | settle != . | court != .
replace investigation = 1 if win != . & court == 0

// Investigation win
g win_investigation = 0 if dismissed != . | settle != . | court != . | investigation != .
replace win_investigation = 1 if win == 1 & investigation == 1

// Investigation lose
g lose_investigation = 0 if dismissed != . | settle != . | court != . | investigation != .
replace lose_investigation = 1 if win == 0 & investigation == 1

// Investigation unknown
g unknown_investigation = 0 if dismissed != . | settle != . | court != . | investigation != .
replace unknown_investigation = 1 if win == . & investigation == 1

// Court win/lose
g win_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace win_court = 1 if win == 1 & court == 1

// Court lose
g lose_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace lose_court = 1 if win == 0 & court == 1

// Court unknown
g unknown_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace unknown_court = 1 if win == . & court == 1

/*******************************************************************************
Overlap
*******************************************************************************/

// overlap_all - all sh cases filed before MeToo & ended after, 0 o/w
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

g triple_did = treat * victim_f

g state_did = treat * state_cat

/*******************************************************************************
Create time to treat - 0 is the pre-period before MeToo
*******************************************************************************/

do "$droot/code/programs/programs.do"

// Create quarters
create_time_to_treat, period(3) period_label("Quarters relative to MeToo")

// Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

// Create time_to_treat for years
create_time_to_treat, period(12) period_label("Years relative to MeToo")

/*******************************************************************************
Label all variables
*******************************************************************************/
drop id 

// EEOC
la var resp_org "Respondent organization"
la var resp_ln "Respondent last name"
la var civil_action_number "ID of court case"
la var court_name "Court ID where case filed"
la var court_file_date "Court filing date"
la var court_res_date "Court resolution date"
la var court_file_year "Year court case filed"
la var court_res_year "Year court case resolved"
la var relief "Compensation to complainant"
la var relief_scale "Compensation"
la var missing_relief "Missing compensation"
la var victim_f "Complainant is female"
la var eeoc_filed "Data from ProPublica request"

// State
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
la var juris "Employment, housing, public accommodations, or education"
la var duration "Duration (days)"
la var overlap_2 "Overlaps with MeToo"
la var overlap_all "Overlaps with MeToo"
la var court "Went to court"
la var filed_per_year "Number of cases filed by SH and Post"
la var common_year "Year of filing"
la var win "Complainant won" //1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)
la var settle "Settled"

// Indent all variable labels for tables
foreach v of varlist * {
	label variable `v' `"\hspace{0.1cm} `: variable label `v''"'
	}
	
/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_cases.dta", replace
