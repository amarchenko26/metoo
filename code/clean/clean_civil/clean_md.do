/*******************************************************************************

Clean Maryland cases

*******************************************************************************/

import excel "$raw_data/MD/Receipt Report - 06012010 thru 06012023.xlsx", firstrow clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
//drop Statute
ren CaseType juris
ren InitialInquiryDate charge_file_date
ren ClosureType outcome
ren ClosureDate charge_res_date
ren Basis basis_raw


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "MD"

// Duration
format charge_file_date %td
format charge_res_date %td
g duration = trunc(charge_res_date - charge_file_date)
drop if duration == .

// Jurisdiction
replace juris = "Employment" if regexm(juris, "EMPLOYMENT")
replace juris = "Housing" if regexm(juris, "Housing")
replace juris = "Public Accommodation" if regexm(juris, "Public Accommodations")
replace juris = "Unspecified" if !inlist(juris, "Employment", "Housing", "Public Accommodation")

// Multi-category
g multi_cat = 0
replace multi_cat = 1 if regexm(basis_raw, ",")

// Basis
g basis = ""
replace basis = "Other"			if regexm(basis_raw, "Familial|Genetic|Marital|Other Basis|Relationship|FEPA Only - Basis|Source")
replace basis = "Age"			if regexm(basis_raw, "Age")
replace basis = "Retaliation"	if regexm(basis_raw, "Retaliation")
replace basis = "Nationality"	if regexm(basis_raw, "National Origin")
replace basis = "Religion"		if regexm(basis_raw, "Religion")
replace basis = "Disability"	if regexm(Statute,"ADA") | regexm(basis_raw, "Handicap|Disability|Senses")
replace basis = "Race"			if regexm(basis_raw, "Color|Race")
replace basis = "Sex" 			if regexm(basis_raw, "Sex|Equal Pay")
drop Statute

// SH


// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = .
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 0 if inlist(outcome, "No Cause Finding")

// Settle
g settle = 0 
replace settle = 1 if inlist(outcome, "Case settled by Legal Unit", "Negotiated Settlement", "Two-party Negotiated Settlement", "Withdrawal with benefits")
replace settle = . if inlist(outcome, "Other", "Prior State Court Filing")

// Court
g court = 0
replace court = 1 if outcome == "CP Filed Suit" | regexm(outcome, "NRTS")
replace court = . if inlist(outcome, "Other", "Prior State Court Filing")

// Dismissal
g dismissed = 0
replace dismissed = 1 if inlist(outcome, "Administrative Closure", "Duplicate Charge", "No Jurisdiction", "Not Enough Employees", "Untimely", "Withdrawal without Benefits") | regexm(outcome, "Charging Party|Employer")
replace dismissed = . if inlist(outcome, "Other", "Prior State Court Filing")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_md.dta", replace


