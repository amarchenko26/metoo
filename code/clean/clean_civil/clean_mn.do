/*******************************************************************************

Clean Minnesota cases

*******************************************************************************/

import excel "$raw_data/MN/mn_raw_cases.xlsx", firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping random vars
drop determinationdate

// Rename vars
ren caseid id
ren filedate charge_file_date
ren area juris
ren basis basis_raw
ren allegation issue
ren determination outcome
ren closuredate charge_res_date
ren respondentcompanyname resp_org


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "MN"
tostring id, replace

// Duration
format charge_file_date %td
format charge_res_date %td
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Employment" if strpos(juris, "Employment") > 0
replace juris = "Public Accommodation" if strpos(juris, "Public Accommodation") > 0
replace juris = "Housing" if strpos(juris, "Housing") > 0

// Multi-category
g multi_cat = 0

// Basis
g basis = "Sex" 				if basis_raw == "Sex"
replace basis = "Sex"			if basis_raw == "Sexual Orientation"
replace basis = "Religion" 	    if basis_raw == "Religion"
replace basis = "Race"		    if inlist(basis_raw, "Color", "Race")
replace basis = "Nationality"   if basis_raw == "National Origin"
replace basis = "Disability"    if basis_raw == "Disability"
replace basis = "Age" 		    if basis_raw == "Age"
replace basis = "Other" 		if inlist(basis_raw, "Familial Status", "Marital Status", "Public Assistance Status")

// SH
g sh = 0
replace sh = 1 if issue == "Sexual Harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if outcome == "PC DETERMINATION"
replace win = 1 if outcome == "SPLIT DETERMINATION"
replace win = 0 if outcome == "NPC DETERMINATION"

// Settle
g settle = 0 
replace settle = 1 if outcome == "ADR SETTLEMENT"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "DISMISSAL"

// Court
g court = .


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_mn.dta", replace


