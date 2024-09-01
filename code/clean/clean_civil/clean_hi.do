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

// Multi-category
g sumsex = 1 if regexm(basis_raw, "BRE|DSV|SEX|SEX-H|SEX-P")
g sumlgbtq = 1 if regexm(basis_raw, "SEX-I|SOR")
g sumreligion = 1 if regexm(basis_raw, "REL")
g sumrace = 1 if regexm(basis_raw, "RAC|COL")
g sumnationality = 1 if regexm(basis_raw, "NOR")
g sumdisability = 1 if regexm(basis_raw, "DIS")
g sumage = 1 if regexm(basis_raw, "AGE")
g sumretaliation = 1 if regexm(basis_raw, "RET")
g sumother = 1 if regexm(basis_raw, "ANC|ARR|CHI|CRE|FAM|MAR|NAT")
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
drop sum*

// Basis
split basis_raw, parse()
g basis = "Sex" 				if inlist(basis_raw1, "BRE", "DSV", "SEX", "SEX-H", "SEX-P")
replace basis = "Sex"         if inlist(basis_raw1, "SEX-I", "SOR")
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
replace win = 0 if enfclosurecode == "No Cause"
replace win = 0 if outcome == "13"

// Settle
g settle = 0 
replace settle = 1 if outcome == "9"
replace settle = 1 if outcome == "7"
replace settle = 1 if enfclosurecode == "Settled"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "1"
replace admin_close = 1 if outcome == "3"
replace admin_close = 1 if outcome == "4"
replace admin_close = 1 if outcome == "15"
replace admin_close = 1 if outcome == "16"
replace admin_close = 1 if outcome == "17"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "2"
replace withdraw = 1 if enfclosurecode == "Withdrawn"

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1

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

// Clean up vars before merging
drop adverseact id eeocno island

save "$clean_data/clean_hi.dta", replace


