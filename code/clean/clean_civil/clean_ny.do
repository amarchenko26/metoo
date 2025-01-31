/*******************************************************************************

Clean New York cases

*******************************************************************************/

import delimited "$raw_data/NY/ny_cases_with_gender.csv", varnames(1) clear


/*******************************************************************************
Clean vars
*******************************************************************************/
drop first_name probability

drop if case_id == "Total"

g tag = case_id == ""
replace case_name = case_name + " " + case_name[_n+1] if tag[_n+1] == 1 & case_name[_n+1] != ""
replace case_name = "" if tag == 1
replace basis = basis + " " + basis[_n+1] if tag[_n+1] == 1 & basis[_n+1] != ""
replace basis = "" if tag == 1
replace acts = acts + " " + acts[_n+1] if tag[_n+1] == 1 & acts[_n+1] != ""
replace acts = "" if tag == 1
drop if tag == 1

drop tag case_id

// Rename vars
ren date_filed charge_file_date
ren closing_date charge_res_date
ren closing_acts outcome
ren jurisdiction juris
ren basis basis_raw
ren acts issue
ren gender victim_f


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "NY"

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
replace juris = "Education" if regexm(juris, "Epdaupceart|aEpdeurc|nEtducation")
replace juris = "Employment" if regexm(juris, "Epmapelory|aEpmepr|loyment")
replace juris = "Housing" if regexm(juris, "ousing|aHpoeurs")
replace juris = "Public Accommodation" if regexm(juris, "mmodation")

// Multi-category
split basis_raw, parse("; ")
g multi_cat = 0
replace multi_cat = 1 if basis_raw2 != "" & basis_raw1 != basis_raw2
drop basis_raw? basis_raw??

// Basis
g basis = ""
replace basis = "Other" 		if regexm(basis_raw, "|Arrest|Conviction|Domestic|Familial|Lawful|Marital|Military|Nonjurisdictional|Genetic|Violation") | basis_raw == "N/A"
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "Citizenship|National")
replace basis = "Religion"		if regexm(basis_raw, "Religion|Creed")
replace basis = "Sex"			if regexm(basis_raw, "Gender")
replace basis = "Disability"	if regexm(basis_raw, "Disability")
replace basis = "Race"			if regexm(basis_raw, "Race")
replace basis = "Sex" 			if regexm(basis_raw, "Sex|Pregnancy")

// SH
g sh = 0
replace sh = 1 if regexm(issue, "Sexual")

// Victim female
replace victim_f = "1" if victim_f == "female"
replace victim_f = "0" if victim_f == "male"
replace victim_f = "." if victim_f == ""
destring victim_f, replace

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if regexm(outcome,"Conciliation|Probable Cause") | strpos(outcome, "Serve Order After Hearing: Sustaining") > 0
replace win = 0 if regexm(outcome, "No Probable Cause") | outcome == "Serve Order After Hearing: Dismissing Complai"

// Settle
g settle = 0 
replace settle = 1 if regexm(outcome, "Settlement")

// Court
g court = 0
replace court = 1 if regexm(outcome, "Annulment")

// Dismissal
g dismissed = 0
replace dismissed = 1 if regexm(outcome, "Dismissing") & win != 0


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ny.dta", replace


