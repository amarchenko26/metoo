/*******************************************************************************

Clean Texas cases

*******************************************************************************/


/*******************************************************************************
Clean vars
*******************************************************************************/

import delimited "$raw_data/TX/tx_raw_cases.csv", varnames(3) bindquote(strict) clear

// Rename vars
ren housingdiscriminationcasesfrom1j case_name
ren v2 outcome
ren v3 charge_file_date
ren v4 charge_res_date
ren v5 basis_raw
ren v6 relief_summary
ren v7 relief

foreach var of varlist _all {
	replace `var' = subinstr(subinstr(`var',"`=char(10)'"," ",.),"`=char(13)'"," ",.) //removes line breaks
}

replace case_name = subinstr(case_name, "Case Name ", "", .)
replace outcome = subinstr(outcome, "Closure Reason ", "", .)
replace charge_file_date = subinstr(charge_file_date, "Filing Date ", "", .)
replace charge_res_date = subinstr(charge_res_date, "Closure Date ", "", .)
replace basis_raw = subinstr(basis_raw, "Bases ", "", .)
replace relief_summary = subinstr(relief_summary, "with Amounts", "", .)
replace relief = subinstr(relief, "Amount", "", .)

save "$raw_data/TX/tx_raw_cases.dta", replace

/*******************************************************************************
Merge SH
*******************************************************************************/

import delimited "$raw_data/TX/tx_sh_cases.csv", varnames(2) bindquote(strict) clear
ren sexharrassmenthousingdiscriminat case_name
ren v2 outcome
ren v3 charge_file_date
ren v4 charge_res_date
ren v5 basis_raw
ren v6 sh
ren v7 relief_summary
ren v8 relief

foreach var of varlist _all {
	replace `var' = subinstr(subinstr(`var',"`=char(10)'"," ",.),"`=char(13)'"," ",.) //removes line breaks
}

replace case_name = subinstr(case_name, "Case Name ", "", .)
replace outcome = subinstr(outcome, "Closure Reason ", "", .)
replace charge_file_date = subinstr(charge_file_date, "Filing Date ", "", .)
replace charge_res_date = subinstr(charge_res_date, "Closure Date ", "", .)
replace basis_raw = subinstr(basis_raw, "Bases ", "", .)
replace sh = subinstr(sh, "Basis ", "", .)
replace relief_summary = subinstr(relief_summary, "with Compensation Amounts", "", .)
replace relief = subinstr(relief, "Amount", "", .)

merge 1:1 case_name charge_file_date using "$raw_data/TX/tx_raw_cases.dta"
drop _merge

save "$raw_data/TX/tx_raw_cases.dta", replace


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "TX"

// Respondent name
replace case_name = subinstr(case_name, " v.", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, "v. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " v ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " V. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " V.", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs. ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " vs ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = subinstr(case_name, " V ", " v. ", .) if strpos(case_name, " v. ") == 0
replace case_name = "Karuna Sharma v. Dove Valley Ranch Apartments" if case_name == "Karuna Sharma Dove Valley Ranch Apartments"
split case_name, parse(v.)
ren case_name1 comp_name
ren case_name2 resp_org

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
gen juris = "Housing"

// Multi-category
g sumsex = 1 if regexm(basis_raw, "Sex")
g sumreligion = 1 if regexm(basis_raw, "Religion")
g sumrace = 1 if regexm(basis_raw, "Race|Color")
g sumnationality = 1 if regexm(basis_raw, "National Origin")
g sumdisability = 1 if regexm(basis_raw, "Disability")
g sumretaliation = 1 if regexm(basis_raw, "Retaliation")
g sumother = 1 if regexm(basis_raw, "Familial Status")
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
replace multi_cat = . if sum == 0 //missing basis
drop sum*

// Basis
replace basis_raw = subinstr(basis_raw, ", ", ",", .)
split basis_raw, parse(,)
g basis = "Sex" 				if basis_raw1 == "Sex"
replace basis = "Religion" 	    if basis_raw1 == "Religion"
replace basis = "Race"		    if inlist(basis_raw1, "Race", "Color")
replace basis = "Nationality"   if basis_raw1 == "National Origin"
replace basis = "Disability"    if basis_raw1 == "Disability"
replace basis = "Retaliation"   if basis_raw1 == "Retaliation"
replace basis = "Other" 		if inlist(basis_raw1, "Familial Status", "")
drop basis_raw?

// SH
replace sh = "1" if sh == "Yes"
replace sh = "0" if sh == ""
destring sh, replace

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
destring relief, replace
replace relief = . if relief == 0
g missing_relief = (relief == .)

// Probable cause
replace outcome = "No cause determination" if outcome == "N o c a u s e d e t e r m i n a t io n"
g win = .
replace win = 1 if outcome == "Administrative hearing ended - discrimination found"
replace win = 0 if outcome == "Litigation ended - no discrimination found"
replace win = 0 if outcome == "No cause determination"

// Settle
g settle = 0 
replace settle = 1 if outcome == "Conciliation/settlement successful"
replace settle = 1 if outcome == "FHAP judicial consent order"
replace settle = 1 if outcome == "Complaint withdrawn by complainant after resolution"
replace settle = . if outcome == ""

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Complainant failed to cooperate"
replace admin_close = 1 if outcome == "Dismissed for lack of jurisdiction"
replace admin_close = 1 if outcome == "Unable to locate complainant"
replace admin_close = 1 if outcome == "Untimely Filed"
replace admin_close = . if outcome == ""

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Complaint withdrawn by complainant without resolution"
replace withdraw = . if outcome == ""

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = . if outcome == ""

// Court
g court = 0
replace court = 1 if outcome == "FHAP judicial consent order"
replace court = 1 if outcome == "FHAP judicial dismissal"
replace court = 1 if outcome == "Litigation ended - no discrimination found"
replace court = . if outcome == ""


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_tx.dta", replace


