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
	- TX
	- WA
	- ND
	- MN (all post)
	- RI
	- AK
	- PA (all post)
	- WI
	- KY
	- DE
	- FL
	- NC
	- CA
	- GA (waiting for SH and date filed, all post)
	- MD (all post)
	- NY
	- MT
	- SC
	
*******************************************************************************/

clear all
set maxvar 32767

/*******************************************************************************
Pull cleaned EEOC filed data (2010-2017)
*******************************************************************************/

tempfile temp
use "$clean_data/clean_eeoc.dta", clear
di _N // 2287 
save "`temp'", replace

use "$clean_data/clean_eeoc_filed.dta", clear
di _N // 3443510

/*******************************************************************************
Merge using EEOC court case data
*******************************************************************************/

merge m:1 civil_action_number_clean court_res_date using "`temp'"
count if _merge == 3 // 1,634 matched obs using civil_action_number_clean
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

append using "$clean_data/clean_tx.dta"

/*******************************************************************************
Append to ND
*******************************************************************************/

append using "$clean_data/clean_nd.dta"

/*******************************************************************************
Append to WA
*******************************************************************************/

append using "$clean_data/clean_wa.dta"

// /*******************************************************************************
// Append to MN
// *******************************************************************************/
//
// append using "$clean_data/clean_mn.dta"

/*******************************************************************************
Append to RI
*******************************************************************************/

append using "$clean_data/clean_ri.dta"

/*******************************************************************************
Append to AK
*******************************************************************************/

append using "$clean_data/clean_ak.dta"

// /*******************************************************************************
// Append to PA
// *******************************************************************************/
//
// append using "$clean_data/clean_pa.dta"

/*******************************************************************************
Append to WI
*******************************************************************************/

append using "$clean_data/clean_wi.dta"

/*******************************************************************************
Append to KY
*******************************************************************************/

append using "$clean_data/clean_ky.dta"

/*******************************************************************************
Append to DE
*******************************************************************************/

append using "$clean_data/clean_de.dta"

/*******************************************************************************
Append to FL
*******************************************************************************/

append using "$clean_data/clean_fl.dta"

/*******************************************************************************
Append to NC
*******************************************************************************/

append using "$clean_data/clean_nc.dta"

/*******************************************************************************
Append to CA
*******************************************************************************/

append using "$clean_data/clean_ca.dta"

// /*******************************************************************************
// Append to GA
// *******************************************************************************/
//
// append using "$clean_data/clean_ga.dta"
//
// /*******************************************************************************
// Append to MD
// *******************************************************************************/
//
// append using "$clean_data/clean_md.dta"

/*******************************************************************************
Append to NY
*******************************************************************************/

append using "$clean_data/clean_ny.dta"

/*******************************************************************************
Append to MT
*******************************************************************************/

append using "$clean_data/clean_mt.dta"

/*******************************************************************************
Append to SC
*******************************************************************************/

append using "$clean_data/clean_sc.dta"


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
sum duration, d 
loc cutoff = r(mean) + 2 * r(sd) 
drop if duration > `cutoff' 

// Gen ym var
g ym_res = ym(year(common_res_date), month(common_res_date)) 
format ym_res %tm 
la var ym_res "Year-month var of resolution date"

g ym_filed = ym(year(common_file_date), month(common_file_date)) 
format ym_filed %tm 
la var ym_filed "Year-month var of filing date"

g common_year = year(common_res_date)

// Get year
g charge_file_year = year(charge_file_date)
g charge_res_year = year(charge_res_date)
g court_file_year = year(court_file_date)
g court_res_year = year(court_res_date)

// Standardize EEOC flags 
replace eeoc = 0 if missing(eeoc) // 0 if state data
replace eeoc_foia = 0 if missing(eeoc_foia) // 0 if state data
replace eeoc_filed = 0 if missing(eeoc_filed) // 0 if state data
replace eeoc_took_to_court = 0 if eeoc == 0 // Make sure to make eeoc_took_to_court = 0 for state data

replace civil_action_number = "" if civil_action_number == "null"


/*******************************************************************************
Consistent sample 
*******************************************************************************/

// Drop cases resolved before filed
drop if common_file_date > common_res_date

// Drop obs before Jun 1 2010
di tm(2010m6) // 605
drop if ym_filed < 605

// Drop obs after June 1 2023 (our FOIA cutoff)
di tm(2023m6)
drop if ym_filed > 761

// Drop missing bases (N=10 obs in PA) 
cap drop if basis == ""

// Drop Other category 
drop if basis == "Other"

// Drop cases removed to EEOC
replace outcome = strtrim(outcome)
drop if inlist(outcome, "C02 - Allegations contained in duplicate EEOC case", "Closed - EEOC-Administrative", "E05 - EEOC assumed jurisdiction - no adjustment", "I15 - Withdrawn - pursue with EEOC", "Transfer to EEOC at Intake", "Transferred to EEOC", "sent to the EEOC")

// Drop outcomes
drop if inlist(outcome, "A10 - Unperfected Complaint", "A3 - Lack of Jurisdiction", "A8 - Tribal Sovereign Immunity", "Bankruptcy of Respondent", "Closed - Bankruptcy", "Closed - Lack of Jurisdiction", "Duplicate", "E02 - Lack of jurisdiction for MDCR", "I08 - Respondent out of business")
drop if inlist(outcome, "I09 - Duplicate complaint", "I10 - Federal agency assumed jurisdiction", "Lack of Jurisdiction", "Non-jurisdictional", "RP Bankruptcy", "Respondent Bankruptcy", "Transfer to Tacoma")
drop if inlist(outcome, "Administrative Dismissal - Waived to Another Agency", "Agency Discretion", "Respondent Bankrupt", "Remand - Failure To Prosecute", "No significant relief available")
drop if regexm(outcome, "Case listed in October 2013 Commission Book|Duplicate/Referral")
drop if regexm(outcome, "No Jurisdiction")
drop if inlist(dismissalrejectionbasis, "Non-Jurisdictional Matter")

replace win = 0 if outcome == "Transfer to EEOC (Closed at Commission)"

/*******************************************************************************
Create time to treat - 0 is the pre-period before MeToo
*******************************************************************************/

do "$droot/code/programs/programs.do"

// Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

// Create time_to_treat for years
create_time_to_treat, period(12) period_label("Years relative to MeToo")

create_years_to_treat, varname(years_to_treat_res) datevar(common_res_date) label("Years to treat, resolution date")

create_years_to_treat, varname(years_to_treat_file) datevar(common_file_date) label("Years to treat, filing date")

// Gen earliest available dates
bysort state eeoc: egen earliest_date = min(common_file_date)
bysort state eeoc: egen last_date = max(common_file_date)

format earliest_date last_date %td


/*******************************************************************************
Fixed effects  
*******************************************************************************/

encode state, g(state_cat)
encode basis, g(basis_cat)

// Gen state/unit and state/time FE
g basis_state 	   = basis_cat * state_cat
g ym_res_state 	   = ym_res * state_cat

g year_filed_state = years_to_treat_file * state_cat
g year_res_state   = years_to_treat_res * state_cat
g ym_filed_state   = ym_filed * state_cat

/*******************************************************************************
Outcomes
*******************************************************************************/

// Gen index var for count
g y = 1

// Gen filed_per_year for sex_cases vs non
bys ym_res sex_cases: egen total_cases_per_month_sex_cases = total(y)
g ln_total_cases_per_month_by_sex = ln(total_cases_per_month_sex_cases)

bys common_year: gen total_cases_per_year = _N
bys common_year: egen total_gender_cases_per_year = sum(y) if victim_f != .
bys common_year sex_cases: gen sex_cases_per_year = _N
bys common_year sex_cases victim_f: gen sex_cases_f_per_year = _N
g filed_per_year = sex_cases_per_year / total_cases_per_year
g filed_f_per_year = sex_cases_f_per_year / total_gender_cases_per_year

// Gen share_filed_by_basis
bys basis common_year: gen filed_by_basis = _N
g share_filed_by_basis = filed_by_basis / total_cases_per_year

// Clean relief
winsor relief, p(.05) gen(relief_w)
replace relief = . if missing_relief == 1 // if relief = 0, person lost, so relief is CONDITIONAL ON WINNING 
g relief_scale = relief_w / 1000
drop relief_w 

// Investigation
g investigation = 0 if dismissed != . | settle != . | court != .
replace investigation = 1 if win != . & court == 0

// Investigation win
g win_investigation = 0 if dismissed != . | settle != . | court != . | investigation != .
replace win_investigation = 1 if win == 1 & investigation == 1

// Investigation lose
g lose_investigation = 0 if dismissed != . | settle != . | court != . | investigation != .
replace lose_investigation = 1 if win == 0 & investigation == 1

// Court win/lose
g win_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace win_court = 1 if win == 1 & court == 1

// Court lose
g lose_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace lose_court = 1 if win == 0 & court == 1

// Court unknown
g unknown_court = 0 if dismissed != . | settle != . | court != . | investigation != .
replace unknown_court = 1 if win == . & court == 1

// Alternative def of win 
g win_alt = win
replace win_alt = 0 if dismissed == 1

// Alternative def of win (for summary table)
g win_1 = 0 if dismissed != . | settle != . | court != .
replace win_1 = 1 if win_alt == 1
g win_0 = 0 if dismissed != . | settle != . | court != .
replace win_0 = 1 if win_alt == 0

/*******************************************************************************
Overlap
*******************************************************************************/

// 1 if case filed before & ended after, 0 if filed before & ended before, . if filed after
g overlap_all = 1 if common_file_date < date("$metoo", "DMY") & common_res_date > date("$metoo", "DMY") 
replace overlap_all = 0 if common_file_date < date("$metoo", "DMY") & common_res_date < date("$metoo", "DMY")

// overlap_2 - Bounded at a duration of 2 years maximum
g overlap_2 = overlap_all
replace overlap_2 = . if common_file_date < date("$metoo", "DMY") - 730 // drop cases filed more than two years before MeToo
replace overlap_2 = . if common_res_date > date("$metoo", "DMY") + 365 // remove cases resolved more than a year after
replace overlap_2 = . if (common_file_date < date("$metoo", "DMY") - 365) & (overlap_2 == 1) // remove overlap cases filed more than a year before MeToo

/*******************************************************************************
Treatment 
*******************************************************************************/
// Post
g post = (common_res_date > date("$metoo", "DMY"))

//***** SH cases ******* //
g sample_sh = 1 if eeoc == 0 
replace sample_sh = . if sex_cases == 1 & sh == 0 //drop all sex cases that are not SH

// Treat for SH 
g treat 	  = post * sh // When regressing on treat, restrict to sample_sh == 1 to avoid including non-SH sex cases

g treat_f 	= treat * victim_f
g state_did = treat * state_cat

// Overlap 
g overlap_treat 	= overlap_all * sh 
g overlap_treat_f 	= overlap_all * sh * victim_f


//***** Sex cases ******* //
// Treat for sex 
g treat_sex = post * sex_cases

g treat_sex_f = treat_sex * victim_f
g state_did_sex = treat_sex * state_cat

// Overlap
g overlap_treat_sex = overlap_all * sex_cases 
g overlap_treat_sex_f = overlap_all * sex_cases * victim_f


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
la var post "Resolved after MeToo"
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
keep if eeoc==0
save "$clean_data/clean_cases_all_juris.dta", replace

keep if juris=="Employment"
keep if sample_sh == 1 
save "$clean_data/clean_cases.dta", replace
