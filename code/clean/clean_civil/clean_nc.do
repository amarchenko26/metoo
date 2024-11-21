/*******************************************************************************

Clean North Carolina cases

*******************************************************************************/

import excel "$raw_data/NC/nc_raw_cases.xlsx", sheet("Sheet1") firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren respondentcompany resp_org
ren basis basis_raw
ren datefiled charge_file_date
ren dateclosed charge_res_date


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "NC"

// Duration
format charge_file_date %td
gen charge_res_date2 = date(charge_res_date, "MD20Y")
format charge_res_date2 %td
drop charge_res_date
rename *2 *

g duration = charge_res_date - charge_file_date

// Jurisdiction
g juris = "Housing"

// Basis
replace basis_raw = basis_raw + "/" + c if c != ""
drop c

replace basis_raw = strtrim(strlower(basis_raw))
replace basis_raw = subinstr(basis_raw, ", ", "/", .)
replace basis_raw = subinstr(basis_raw, " & ", "/", .)
split basis_raw, parse(/)

g basis = "Sex" 				if basis_raw1 == "sex"
replace basis = "Religion" 	    if basis_raw1 == "religion"
replace basis = "Race"		    if inlist(basis_raw1, "color", "race")
replace basis = "Nationality"   if regexm(basis_raw1, "nat")
replace basis = "Disability"    if basis_raw1 == "disability"
replace basis = "Age" 		    if basis_raw1 == "AGE"
replace basis = "Retaliation"   if basis_raw1 == "retaliation"
replace basis = "Other" 		if regexm(basis_raw1, "arrest|fami|rcrno|intimidation")
replace basis = "Other"			if inlist(basis_raw1, "r", "n")
replace basis = "Disability"	if basis == "Other" & regexm(basis_raw2, "dis")
replace basis = "Race"			if basis == "Other" & regexm(basis_raw2, "race")
replace basis = "Nationality"	if basis == "Other" & regexm(basis_raw2, "nat")
replace basis = "Religion"		if basis == "Other" & regexm(basis_raw3, "religion")

// Multi-category
g multi_cat = 0
replace multi_cat = 1 if regexm(basis_raw, "/|,|&")
drop basis_raw?

// SH
g sh = .

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if regexm(decision, "Cause|onciliat")
replace win = 0 if regexm(decision, "No |no ")
replace win = 1 if regexm(decision, "Mixed")

// Settle
g settle = 0 
replace settle = 1 if regexm(decision, "fter Resolution|Settle|onciliat|esol")
replace settle = 0 if regexm(decision, "ithout|W/O")
replace settle = . if regexm(decision, "pen|Closed|Reactivated|HUD|Closure W/O Resolution")

// Dismissal
g dismissed = 0
replace dismissed = 1 if regexm(decision, "Closure|Withdr|Complain|Dismiss|Fail|Unable|not") & settle == 0
replace dismissed = . if regexm(decision, "pen|Closed|Reactivated|HUD|Closure W/O Resolution")

// Court
g court = 0
replace court = 1 if inlist(outcome, "COURT-DISMISSED BY JUDGE", "FILED IN SUPERIOR COURT")
replace court = 1 if regexm(decision, "FHAP|Legal|udicial")
replace court = . if regexm(decision, "pen|Closed|Reactivated|HUD|Closure W/O Resolution") & court == 0


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_nc.dta", replace


