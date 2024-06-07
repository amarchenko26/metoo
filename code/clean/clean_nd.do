/*******************************************************************************

Clean North Dakota cases

*******************************************************************************/

// Append files

drop _all
quietly save "$raw_data/ND/nd_raw_cases.dta", emptyok replace
local var Employment Housing PA
foreach i of local var {
    import excel using "$raw_data/ND/OR response `i'.xlsx", firstrow case(lower) clear
	foreach v of varlist maritalstatus othercolor othernationalorigin otherrace otherreligion otherpublicassistance {
	tostring `v', replace
	replace `v' = "" if `v' == "."
	}
	if "`i'" != "Employment" {
		tostring discriminationtype, replace
		replace discriminationtype = "" if discriminationtype == "."
	}
    append using "$raw_data/ND/nd_raw_cases.dta"
    quietly save "$raw_data/ND/nd_raw_cases.dta", replace
}


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping random vars
drop donotmodify* 

// Rename vars
ren entity resp_org
ren casetype juris
ren dateopened charge_file_date
ren statusreason processstage
ren dateclosed charge_res_date
ren settlementamount relief


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "ND"

// Duration
format charge_file_date %td
format charge_res_date %td
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = discriminationtype if discriminationtype != ""
drop discriminationtype
replace juris = subinstr(subinstr(juris, " Discrimination", "", .), " Complaint", "", .)

/*
// Basis //commented out to ask ND about primary basis
g basis = ""
replace basis = "Other" 		if otherissueedandcor != "" | familialstatus != "" | otherpublicassistance != "" | maritalstatus != "" | publicassistance != ""
replace basis = "Age"			if age != .
replace basis = "Retaliation"	if retaliation == "Yes"
replace basis = "Nationality"	if othernationalorigin != "" | nationalorigin != ""
replace basis = "Religion"		if otherreligion != "" | religion != ""
replace basis = "LGBTQ"			if strpos(sex, "Sexual Orientation") > 0
replace basis = "Disability"	if disability != ""
replace basis = "Race"			if otherrace != "" | othercolor != "" | race != "" | color != ""
replace basis = "Sex" 			if (sex != "" & basis != "LGBTQ") | pregnancy == "Yes"

gen basis_check = 0

foreach v of varlist color disability religion race nationalorigin publicassistance sex maritalstatus othercolor othernationalorigin otherpublicassistance otherrace otherreligion familialstatus {
	replace basis_check = basis_check + 1 if `v' != ""
}

// SH
g sh = . //currently have this marked as missing bc waiting on North Dakota clarification

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"
*/

// Relief
replace relief = . if relief == 0
g missing_relief = (relief == .)

// Outcome
gen outcome = closureresolutionohr if juris == "Public Accommodation"
replace outcome = closureresolutionhousing if juris == "Housing"
replace outcome = closureresolutioned if juris == "Employment"
drop closure*

// Probable cause
g win = .
replace win = 1 if inlist(outcome, "Probable Cause", "Notice of Right to Sue")
replace win = 0 if inlist(outcome, "No Probable Cause", "No Reasonable Cause")

// Settle
g settle = 0 
replace settle = 1 if outcome == "Conciliated Settlement"
replace settle = 1 if outcome == "Negotiated Settlement"
replace settle = 1 if outcome == "Settled after Charge Issued"
replace settle = 1 if outcome == "Successful Conciliation"
replace settle = 1 if outcome == "Withdrawn With Resolution"

// Court
g court = . // currently have this marked as missing bc North Dakota doesn't track this


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_nd.dta", replace


