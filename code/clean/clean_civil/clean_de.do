/*******************************************************************************

Clean Delaware cases

*******************************************************************************/

/*
tempfile temp
import excel "$raw_data/DE/Closed Cases Brown FOIA Request Relief Amounts 2024.xlsx", firstrow case(lower) clear
drop relieftype
ren amount relief
collapse (sum) relief, by(casename)
save "`temp'", replace
*/

import excel "$raw_data/DE/de_raw_cases.xlsx", firstrow cellrange(E10:K424) case(lower) clear
drop if casename == ""
replace casename = subinstr(casename, "  ", " ", .)
// merge 1:1 casename using "`temp'"

/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren casename id
ren casefileddate charge_file_date
ren systemcloseddate charge_res_date
ren protectedclass basis_raw
ren basis issue
ren results outcome


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "DE"

// Duration
gen charge_file_date2 = date(charge_file_date, "MD20Y")
format charge_file_date2 %td
drop charge_file_date
gen charge_res_date2 = date(charge_res_date, "MD20Y")
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Jurisdiction
gen n = _n
gen juris = "Public Accommodation" if n <= 167
replace juris = "Housing" if n > 167
drop n

// Multi-category
g multi_cat = 0
replace multi_cat = 1 if regexm(basis_raw, ";")

// Basis
g basis = ""
replace basis = "Other" 		if regexm(basis_raw, "|Marital|Familial|Source of Income")
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Nationality"	if regexm(basis_raw, "National Origin")
replace basis = "Religion"		if regexm(basis_raw, "Creed|Religion")
replace basis = "Sex"			if regexm(basis_raw, "Gender Identity|Sexual Orientation")
replace basis = "Disability"	if regexm(basis_raw, "Disability")
replace basis = "Race"			if regexm(basis_raw, "Color|Race")
replace basis = "Sex" 			if regexm(basis_raw, "Sex") & !regexm(basis_raw, "Sexual Orientation")

// SH
g sh = 0
replace sh = 1 if strpos(basis_raw, "Sex (Harrassment)") > 0

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
// g missing_relief = (relief == .) waiting for new relief files

// Probable cause
replace dismissalrejectionbasis = "" if dismissalrejectionbasis == "N/A"
g win = .
replace win = 1 if inlist(outcome, "Cause Finding Consent Decree", "Cause Finding Hearing", "Conciliation") & dismissalrejectionbasis == ""
replace win = 0 if outcome == "No Cause Finding"

// Settle
g settle = 0 
replace settle = 1 if outcome == "Withdrawal with Resolution"
replace settle = . if outcome == "Schedule For Hearing"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Complaint Rejected"
replace admin_close = . if outcome == "Schedule For Hearing"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Withdrawal without Resolution"
replace withdraw = . if outcome == "Schedule For Hearing"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "Complaint Dismissed"
replace dismissed = 1 if outcome == "Complaint Rejected" // anya added this
replace dismissed = . if outcome == "Schedule For Hearing"


/*******************************************************************************
Export data
*******************************************************************************/

// Clean up vars before merging

save "$clean_data/clean_de.dta", replace


