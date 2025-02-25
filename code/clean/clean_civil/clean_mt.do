/*******************************************************************************

Clean Montana cases

*******************************************************************************/

import excel "$raw_data/MT/mt_raw_cases.xlsx", firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren randomid id
ren open charge_file_date
ren hrbdecisiondate charge_res_date
ren claim basis_raw
ren hrbdecision outcome
ren area juris
drop g-j


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "MT"

// Duration
format charge_file_date %td
format charge_res_date %td
g duration = charge_res_date - charge_file_date
g temp = charge_file_date if duration < 0
replace charge_file_date = charge_res_date if duration < 0
replace charge_res_date = temp if duration < 0
drop temp
replace duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Other"
replace juris = "Education" if regexm(juris, "EDUCATION")
replace juris = "Public Accommodation" if regexm(juris, "PUB ACCOM")
replace juris = "Housing" if juris == "HSNG"
replace juris = "Employment" if regexm(juris, "EMP")

// Multi-category
replace basis_raw = subinstr(basis_raw, "/", " ", .)
replace basis_raw = stritrim(basis_raw)
replace basis_raw = strtrim(basis_raw)

g sumsex = 1 if regexm(basis_raw, "SEX|GENDER")
g sumreligion = 1 if regexm(basis_raw, "RELIGION|CREED")
g sumrace = 1 if regexm(basis_raw, "RACE|COLOR")
g sumnationality = 1 if regexm(basis_raw, "NAT")
g sumdisability = 1 if regexm(basis_raw, "DISABILITY")
g sumage = 1 if regexm(basis_raw, "AGE")
g sumother = 1 if regexm(basis_raw, "FAMILIAL|MARITAL|POLITICAL")
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
drop sum*

// Basis
g basis = ""
replace basis = "Other" 		if regexm(basis_raw, "FAMILIAL|MARITAL|POLITICAL")
replace basis = "Age"			if regexm(basis_raw, "AGE")
replace basis = "Nationality"	if regexm(basis_raw, "NAT")
replace basis = "Religion"		if regexm(basis_raw, "RELIGION|CREED")
replace basis = "Disability"	if regexm(basis_raw, "DISABILITY")
replace basis = "Race"			if regexm(basis_raw, "RACE|COLOR")
replace basis = "Sex" 			if regexm(basis_raw, "SEX|GENDER")
replace basis = "Other" 		if basis == ""

// SH
g sh = 0
replace sh = 1 if regexm(basis_raw, "SEXUAL HARASSMENT")

// Victim female
g victim_f = .
replace victim_f = 0 if regexm(basis_raw, "MALE")
replace victim_f = 1 if regexm(basis_raw, "FEMALE")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
replace outcome = strtrim(outcome)
g win = .
replace win = 1 if outcome == "CAUSE"
replace win = 0 if outcome == "NO CAUSE"

// Settle
g settle = 0 
replace settle = 1 if outcome == "VRA"
replace settle = 1 if outcome == "WDB"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "ADMIN CLSR"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "WD"

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1

// Court
g court = 0


/*******************************************************************************
Export data
*******************************************************************************/

drop id

save "$clean_data/clean_mt.dta", replace


