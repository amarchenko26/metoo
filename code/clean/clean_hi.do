/*******************************************************************************

Clean Hawaii cases

*******************************************************************************/

import excel "$raw_data/HI/hi_raw_cases.xls", sheet("HCRC Closures") firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren casetype juris
ren docket id
ren complaintfiled charge_file_date
ren basis basis_raw
ren closed charge_res_date
ren closurecode outcome
ren compensation relief


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "HI"

// Duration
replace charge_res_date = enfclosure if enfclosure != .
drop enfclosure
format charge_file_date %td
format charge_res_date %td
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Employment" if juris == "FE"
replace juris = "Public Accommodation" if juris == "PA"
replace juris = "Housing" if juris == "RE"

// Basis
split basis_raw, parse()
g basis = "Sex" 				if inlist(basis_raw1, "BRE", "DSV", "SEX", "SEX-H", "SEX-P")
replace basis = "LGBTQ"         if inlist(basis_raw1, "SEX-I", "SOR")
replace basis = "Religion" 	    if basis_raw1 == "REL"
replace basis = "Race"		    if inlist(basis_raw1, "RAC", "COL")
replace basis = "Nationality"   if basis_raw1 == "NOR"
replace basis = "Disability"    if strpos(basis_raw1, "DIS") > 0
replace basis = "Age" 		    if basis_raw1 == "AGE"
replace basis = "Retaliation"   if basis_raw1 == "RET"
replace basis = "Other" 		if inlist(basis_raw1, "ANC", "ARR", "CHI", "CRE", "FAM", "MAR", "NAT")

// SH
g sh = 0
replace sh = 1 if basis_raw1 == "SEX-H"
drop basis_raw?

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if outcome == "CA"
replace win = 0 if enfclosurecode == "Order" & relief == . 
replace win = 0 if outcome == "CA" & enfclosurecode == "No Cause"
replace win = 0 if outcome == "13"

// Settle
g settle = 0 
replace settle = 1 if outcome == "9"
replace settle = 1 if outcome == "7" & relief != .
replace settle = 1 if enfclosurecode == "Settled"

// Court
g court = 0
replace court = 1 if outcome == "6"

// Outcome
replace outcome = "No Jurisdiction" if outcome == "1"
replace outcome = "CPT  withdrawn/dropped" if outcome == "2"
replace outcome = "Cp not available" if outcome == "3"
replace outcome = "Cp failed to co-operate" if outcome == "4"
replace outcome = "Cp failed to accept just settlement offer" if outcome == "5"
replace outcome = "CPT withdrawn - Cp electing court action" if outcome == "6"
replace outcome = "CPT  withdrawn - Resolved by parties" if outcome == "7"
replace outcome = "Negotiated Settlement" if outcome == "9"
replace outcome = "NO CAUSE - insufficient evidence" if outcome == "13"
replace outcome = "Administratively closed" if outcome == "15"
replace outcome = "Bankruptcy of Respondent" if outcome == "16"
replace outcome = "No significant relief available" if outcome == "17"
replace outcome = "Relief covered by Ct order/consent decree" if outcome == "19"
replace outcome = "Reasonable Cause Recommendation" + " - " + enfclosurecode if outcome == "CA"
drop enfclosurecode


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_hi.dta", replace


