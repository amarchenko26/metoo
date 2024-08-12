/*******************************************************************************

Clean Wisconsin cases

*******************************************************************************/

import excel "$raw_data/WI/ORR-1394-JiangM-2.xlsx", firstrow case(lower) clear
save "$raw_data/WI/wi_raw_cases.dta", replace
import excel "$raw_data/WI/ORR-1394-JiangM-3.xlsx", firstrow case(lower) clear
merge 1:1 casenumber respondentname basisname using "$raw_data/WI/wi_raw_cases.dta"
drop _merge
save "$raw_data/WI/wi_raw_cases.dta", replace


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren casenumber id
ren respondentname resp_org
ren initialinquirydate charge_file_date
ren lawname juris
ren basisname basis_raw
ren closedate charge_res_date


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "WI"

// Duration
format charge_file_date %td
format charge_res_date %td
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Employment" if inlist(juris, "EEOC/FEL", "Fair Employment Law")
replace juris = "Education" if juris == "Post Secondary Education"

// Multi-category
g multi_cat = 0

// Basis
g basis = strtrim(basis_raw)
replace basis = "Sex"			if basis == "Pregnancy / Maternity"
replace basis = "LGBTQ"			if inlist(basis, "GENDER IDENTITY/TRANSGENDER", "Sexual Orientation")
replace basis = "Religion"		if basis == "Religion/Creed"
replace basis = "Race"			if basis == "Color"
replace basis = "Nationality"	if basis == "National Origin/Ancestry"
replace basis = "Disability"	if inlist(basis, "Disability - Housing Only", "Physical Condition - PSE")
replace basis = "Retaliation"	if strpos(basis, "Retaliation") > 0
replace basis = "Other"			if inlist(basis, "Arrest Record", "Conviction Record", "Domestic Abuse", "Family Status - Housing", "Genetic Testing", "Honesty Testing") | inlist(basis, "Lawful Income - Housing", "Lawful Products", "Marital Status", "Military Status", "NONE", "Political Beliefs")

// SH
g sh = 0
replace sh = 1 if issuename == "Sexual Harassment"
replace sh = . if sh == 1 & basis != "Sex"
drop issuename

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .

// Settle
g settle = .

// Administrative closure
g admin_close = .

// Withdrawn
g withdraw = .

// Dismissal
g dismissed = .

// Court
g court = .


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_wi.dta", replace


