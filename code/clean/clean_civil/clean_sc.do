/*******************************************************************************

Clean South Carolina cases

*******************************************************************************/

import excel "$raw_data/SC/sc_raw_cases.xlsx", firstrow cellrange(A3:L1458) case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

drop fhapcasenumber hudcasenumberandname referredtolegalforadjdate

// Rename vars
ren c case_name
ren filingdatefhap charge_file_date_1
ren filingdatehud charge_file_date_2
ren bases basis_raw
ren sexharassmentbasis sh
ren fhapclosuredate charge_res_date
ren closurereason outcome
ren compensation relief


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "SC"

// Respondent name
replace case_name = subinstr(case_name, " v.", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " v ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " V. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " V ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " Vs. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, "Vs. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs.", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs, ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " Vs ", " v. ", .) if strpos(case_name, " v. ") == 0
split case_name, parse(v.)
replace case_name1 = strtrim(case_name1)
replace case_name2 = strtrim(case_name2)
ren case_name1 comp_name
ren case_name2 resp_org

// Duration
g charge_file_date = min(charge_file_date_1, charge_file_date_2)
drop charge_file_date_?
format charge_file_date %td
g duration = charge_res_date - charge_file_date

// Jurisdiction
g juris = "Housing"

// Multi-category
g multi_cat = 0 if !regexm(basis_raw, ",")
replace multi_cat = 1 if regexm(basis_raw, ",")

// Basis
g basis = "Other"				if regexm(basis_raw, "Familial") | inlist(basis_raw, "")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "National")
replace basis = "Religion"		if regexm(basis_raw, "Religion")
replace basis = "Disability"	if regexm(basis_raw, "Disability")
replace basis = "Race"			if regexm(basis_raw, "Race|Color")
replace basis = "Sex"			if regexm(basis_raw, "Sex")

// SH
replace sh = "0" if sh == ""
replace sh = "1" if sh == "Yes"
destring sh, replace

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if causedate != .
replace win = 1 if outcome == "Litigation ended - discrimination found"
replace win = 0 if outcome == "No cause determination"
drop causedate

// Settle
g settle = 0 
replace settle = 1 if outcome == "Complaint withdrawn by complainant after resolution"
replace settle = 1 if outcome == "Conciliation/settlement successful"
replace settle = 1 if outcome == "FHAP judicial consent order"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Complainant failed to cooperate"
replace admin_close = 1 if outcome == "Unable to locate complainant"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Complaint withdrawn by complainant without resolution"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "Dismissed for lack of jurisdiction"
replace dismissed = 1 if outcome == "FHAP judicial dismissal"
replace dismissed = 1 if admin_close == 1 | withdraw == 1

// Court
g court = 0
replace court = 1 if outcome == "Litigation ended - discrimination found"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_sc.dta", replace


