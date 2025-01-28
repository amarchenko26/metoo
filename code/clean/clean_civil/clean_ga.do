/*******************************************************************************

Clean Georgia cases

*******************************************************************************/

import excel "$raw_data/GA/Housing.xlsx", firstrow clear
drop Number CurrentStatus Issues
rename BasisSelected basis_raw
rename ClosureTypes outcomes
rename Conciliation relief
g juris = "Housing"
save "$clean_data/clean_ga.dta", replace
import excel "$raw_data/GA/Employment.xlsx", firstrow clear
drop GCEOCaseNumber
rename BasisSelected basis_raw
rename DISPOSITION outcomes
rename Mediation relief
g juris = "Employment"
append using "$clean_data/clean_ga.dta"
drop AllegationLocation
rename DateClosed charge_res_date


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "GA"

// Duration


// Multi-category
g multi_cat = 0
replace multi_cat = 1 if regexm(basis_raw, ",") & !inlist(basis_raw, "Disability, Physical Disability", "Mental Disability, Physical Disability", "Race, Black or African American", "Race, White", "Sex, Female", "Sex, Male")

// Basis
g basis = ""
replace basis = "Other"			if regexm(basis_raw, "Familial")
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "National")
replace basis = "Religion"		if regexm(basis_raw, "Religion")
replace basis = "Disability"	if regexm(basis_raw, "Disability")
replace basis = "Race"			if regexm(basis_raw, "Color|Race|Asian|Black|White")
replace basis = "Sex" 			if regexm(basis_raw, "Sex|Female|Male")

// SH


// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
replace relief = "4950.20" if relief == "Salary Increase by $2,000 and retroactive gross pay of $2,950.20.  "
replace relief = "6410.94" if relief == "Transfer of Complainant's position  and an adjustment of salary by increasing $$64,109.39 by 10%"
replace relief = "70005.11" if relief == "Continue Complainant's employment for the 2023-2024 academic year with a salary of $70,005.11"
replace relief = "15850" if relief == "Received $15,850.00 in compensatory (actual damages)"
replace relief = "27300" if relief == "Complainant received $27,300.00"
replace relief = "19450" if relief == "Complainant received $19,450 and assigned courses"
destring relief, replace force
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if inlist(outcome, "Conciliation Successful ", "Charge Issued", "CLOSED: Reasonable Cause Determination", "CLOSED: Cause Determination")
replace win = 0 if inlist(outcome, "No Cause Determination", "CLOSED: No Reasonable Cause Determination", "CLOSED: No Cause Determination")

// Settle
g settle = 0 
replace settle = 1 if inlist(outcome, "CLOSED: Mediation Successful", "Admin Closure-Withdrawal with Benefits")
replace settle = . if inlist(outcome, "Case Transferred to HUD", "CLOSED: Transferred to EEOC", "CLOSED: No Records Found")

// Court
g court = 0
replace court = 1 if outcome == "Admin Closure-Complaint filed in Court-Requested Closure"
replace court = . if inlist(outcome, "Case Transferred to HUD", "CLOSED: Transferred to EEOC", "CLOSED: No Records Found")

// Dismissal
g dismissed = 0
replace dismissed = 1 if inlist(outcome, "CLOSED: Administrative", "Admin Closure-Withdrawal No Benefits", "Admin Closure-Dismissed for Lack of Jurisdiction")
replace dismissed = . if inlist(outcome, "Case Transferred to HUD", "CLOSED: Transferred to EEOC", "CLOSED: No Records Found")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ga.dta", replace


