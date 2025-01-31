/*******************************************************************************

Clean Florida cases

*******************************************************************************/

tempfile temp
import delimited "$raw_data/FL/fl_housing_cases_2.csv", bindquote(strict) varnames(1) clear
g n = _n
save "`temp'", replace

import delimited "$raw_data/FL/fl_housing_cases.csv", bindquote(strict) varnames(1) clear
g n = _n
merge 1:1 n using "`temp'"
keep if _merge == 3
drop _merge
save "`temp'", replace

import delimited "$raw_data/FL/fl_employment_cases.csv", bindquote(strict) varnames(1) clear
append using "`temp'"
drop respondentcounty n subjectproperty

save "$raw_data/FL/fl_raw_cases.dta", replace

/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren filingdate charge_file_date
ren bases basis_raw
ren casetype juris
ren closuredate charge_res_date
ren closuretype outcome
drop if charge_file_date == "" | basis_raw == ""


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "FL"

// Duration
gen charge_res_date2 = date(charge_res_date, "DM20Y")
format charge_res_date2 %td
drop charge_res_date
gen charge_file_date2 = date(charge_file_date, "DM20Y")
format charge_file_date2 %td
drop charge_file_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Multi-category
g multi_cat = 1 if strpos(basis_raw, "|") > 0
replace multi_cat = 0 if multi_cat != 1

// Basis
g basis = ""
replace basis = "Other" 		if regexm(basis_raw, "Marital|Familial")
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "National Origin")
replace basis = "Religion"		if regexm(basis_raw, "Religion")
replace basis = "Sex"			if regexm(basis_raw, "Gender Identity|Sexual Orientation")
replace basis = "Disability"	if regexm(basis_raw, "Disability")
replace basis = "Race"			if regexm(basis_raw, "Color|Race|Multi-Racial")
replace basis = "Sex" 			if regexm(basis_raw, "Sex") & !regexm(basis_raw, "Gender Identity|Sexual Orientation")

// SH
g sh = 0
replace sh = 1 if regexm(basis_raw, "Sex, Harassment|Sex-Harassment")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if inlist(outcome, "Cause", "Cause/No Cause", "Conciliation", "conciliation")
replace win = 0 if inlist(outcome, "No Cause", "Notice of Rights")

// Settle
g settle = 0 
replace settle = 1 if inlist(outcome, "FHAP judicial consent order", "Mediation/Settlement", "Withdraw with Settlement", "Withdrawal with Resolution/Settlement")
replace settle = . if inlist(outcome, "", "Intake closure|Reactivation", "Reactivation")

// Administrative closure
g admin_close = 0
replace admin_close = 1 if inlist(outcome, "Failure to Cooperate", "Failure to Locate", "No Jurisdiction")
replace admin_close = 1 if strpos(outcome, "Duplicate") > 0
replace admin_close = 1 if strpos(outcome, "losure") > 0
replace admin_close = . if inlist(outcome, "", "Intake closure|Reactivation", "Reactivation")

// Withdrawn
g withdraw = 0
replace withdraw = 1 if inlist(outcome, "Withdraw Without Settlement", "Withdrawal", "Withdrawal without Resolution/Settlement")
replace withdraw = . if inlist(outcome, "", "Intake closure|Reactivation", "Reactivation")

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = 1 if outcome == "Dismissal"
replace dismissed = . if inlist(outcome, "", "Intake closure|Reactivation", "Reactivation")

// Court
g court = 0
replace court = 1 if inlist(outcome, "Right to Sue")
replace court = . if inlist(outcome, "", "Intake closure|Reactivation", "Reactivation")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_fl.dta", replace


