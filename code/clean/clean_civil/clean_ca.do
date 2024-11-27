/*******************************************************************************

Clean California cases

*******************************************************************************/

import delimited "$raw_data/CA/ca_raw_cases.csv", varnames(3) bindquote(strict) maxquotedrows(1000) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

drop no

foreach var of varlist _all {
	replace `var' = subinstr(subinstr(`var',"`=char(10)'"," ",.),"`=char(13)'"," ",.) //removes line breaks
}

// Rename vars
ren ccrscaserecordtype juris
ren casefiledate charge_file_date
ren closedate charge_res_date
ren closereason outcome

replace discriminationbasis = legacybasis if discriminationbasis == "" & legacybasis != ""
replace discriminationactofharm = legacyharms if discriminationactofharm == "" & legacyharms != ""
drop legacy*
ren discriminationbasis basis_raw
ren discriminationactofharm issue

replace basis_raw = basis_raw + "; Retaliation" if retaliationactofharm != ""
split retaliationactofharm, parse(;)
forvalues no = 1/23 {
	replace retaliationactofharm`no' = strtrim(retaliationactofharm`no')
	replace retaliationactofharm`no' = "" if strpos(issue, retaliationactofharm`no') > 0
	replace issue = issue + "; " + retaliationactofharm`no' if retaliationactofharm`no' != ""
	drop retaliationactofharm`no'
}
drop retaliationactofharm

replace issue = issue + "; Harassment" if harassmentbasis != ""
split harassmentbasis, parse(;)
forvalues no = 1/26 {
	replace harassmentbasis`no' = strtrim(harassmentbasis`no')
	replace harassmentbasis`no' = "" if strpos(basis_raw, harassmentbasis`no') > 0
	replace basis_raw = basis_raw + "; " + harassmentbasis`no' if harassmentbasis`no' != ""
	drop harassmentbasis`no'
}
drop harassmentbasis

replace basis_raw = subinstr(basis_raw, "; ", "", .) if substr(basis_raw, 1, 2) == "; "
replace issue = subinstr(issue, "; ", "", .) if substr(issue, 1, 2) == "; "
drop typeofprotectedactivity

/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "CA"

// Duration
gen charge_file_date2 = date(charge_file_date, "MD20Y")
format charge_file_date2 %td
drop charge_file_date
gen charge_res_date2 = date(charge_res_date, "MD20Y")
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date
g flag = 1 if duration < 0
replace duration = charge_file_date if flag == 1
replace charge_file_date = charge_res_date if flag == 1
replace charge_res_date = duration if flag == 1 
replace duration = charge_res_date - charge_file_date if flag == 1
drop flag

// Jurisdiction
replace juris = "Employment" if regexm(juris, "EEOC|Employment|Equal Pay Act|Right to Sue")
replace juris = "Public Accommodation" if regexm(juris, "Unruh")
replace juris = "Unspecified" if regexm(juris, "CC54|GC11135|Human Trafficking|Ralph|Sexual Harassment Prevention Training|State Contractors")

// Multi-category
g multi_cat = 0
replace multi_cat = 1 if regexm(basis_raw, ";")

// Basis
g basis = ""
replace basis = "Other" 		if regexm(basis_raw, "|Ancestry|Association|Bereavement|Cannabis|Criminal|Engagement|Familial|Family|Genetic|Marital|Military|Position|Language|Other|Health|Source")
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "Citizenship|Immigration|National")
replace basis = "Religion"		if regexm(basis_raw, "Religion|Religious")
replace basis = "Sex"			if regexm(basis_raw, "Gender")
replace basis = "Disability"	if regexm(basis_raw, "Disability|Medical condition|Medical Condition")
replace basis = "Race"			if regexm(basis_raw, "Color|Ethnicity|Race")
replace basis = "Sex" 			if regexm(basis_raw, "Sex|Pregnancy")

// SH
g sh = 0
replace sh = 1 if regexm(basis_raw, "Sexual harassment")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if regexm(outcome,"Conciliation/Settlemen t Successful|Judgment - Favorable")
replace win = 0 if regexm(outcome, "Insufficient Evidence|No Cause Determination")

// Settle
g settle = 0 
replace settle = 1 if regexm(outcome, "Settle|Complaint Withdrawn by Complainant After Resolution|Resolved between Parties") & win != 1
replace settle = . if inlist(outcome, "", "Agency Discretion", "Assignment Completed", "Decline to File: Exercise of Discretion", "Determination by Another Agency", "Not Provided", "Processing Waived to Another Agency", "Reasonable remedy refused")

// Court
g court = 0
replace court = 1 if regexm(outcome, "Trial|Court|Suit|Right to Sue Issued|lawsuit")
replace court = . if inlist(outcome, "", "Agency Discretion")

// Dismissal
g dismissed = 0
replace dismissed = 1 if regexm(outcome, "Withdrawn") & settle == 0 & court == 0
replace dismissed = 1 if regexm(outcome, "Dismiss") & court == 0
replace dismissed = 1 if regexm(outcome, "No Basis to Proceed|No Follow-Up Info Rcvd from Requestor|ime|No Jurisdiction|Respondent Bankrupt|Unable")
replace dismissed = . if inlist(outcome, "", "Agency Discretion")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ca.dta", replace


