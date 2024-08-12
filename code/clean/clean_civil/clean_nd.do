/*******************************************************************************

Clean North Dakota cases

*******************************************************************************/

// Append files

drop _all
quietly save "$raw_data/ND/nd_appended_cases.dta", emptyok replace
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
	append using "$raw_data/ND/nd_appended_cases.dta"
	quietly save "$raw_data/ND/nd_appended_cases.dta", replace
}

foreach i of local var {
    import excel using "$raw_data/ND/OR response `i' 2.xlsx", firstrow case(lower) clear
	foreach v of varlist maritalstatus othercolor othernationalorigin otherrace otherreligion otherpublicassistance {
	tostring `v', replace
	replace `v' = "" if `v' == "."
	}
	merge 1:1 donotmodifycase using "$raw_data/ND/nd_appended_cases.dta"
	keep if _merge == 3
	drop _merge
    append using "$raw_data/ND/nd_raw_cases.dta"
    quietly save "$raw_data/ND/nd_raw_cases.dta", replace
}


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping random vars
drop donotmodify* intakedate other* domesticviolence

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
replace juris = "Employment" if juris == "Employment Discrimination Complaint"
replace juris = "Housing" if juris == "Housing Complaint"
replace juris = "Public Accommodation" if juris == "Other Human Rights Complaint"
drop discriminationtype

// Multi-category
g sumsex = 1 if (sex != "" & strpos(sex, "Sexual Orientation") == 0) | pregnancy == "Yes"
g sumlgbtq = 1 if strpos(sex, "Sexual Orientation") > 0
g sumreligion = 1 if religion != ""
g sumrace = 1 if race != "" | color != ""
g sumnationality = 1 if nationalorigin != ""
g sumdisability = 1 if disability != ""
g sumage = 1 if age != .
g sumretaliation = 1 if retaliation == "Yes"
g sumother = 1 if familialstatus != "" | maritalstatus != "" | publicassistance != "" | lawfulactivity == "Yes"
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
replace multi_cat = . if sum == 0 //missing basis
drop sum*

// Basis
g basis = ""
replace basis = "Other" 		if familialstatus != "" | maritalstatus != "" | publicassistance != "" | lawfulactivity == "Yes"
replace basis = "Age"			if age != .
replace basis = "Retaliation"	if retaliation == "Yes"
replace basis = "Nationality"	if nationalorigin != ""
replace basis = "Religion"		if religion != ""
replace basis = "LGBTQ"			if strpos(sex, "Sexual Orientation") > 0
replace basis = "Disability"	if disability != ""
replace basis = "Race"			if race != "" | color != ""
replace basis = "Sex" 			if (sex != "" & basis != "LGBTQ") | pregnancy == "Yes"
replace basis = "Other" 		if basis == ""

gen basis_raw = ""
foreach v of varlist color disability religion race nationalorigin publicassistance sex maritalstatus familialstatus {
	replace basis_raw = basis_raw + "`: var label `v''" + ": " + `v' + "; " if `v' != ""
	drop `v'
}

replace basis_raw = basis_raw + "Age; " if age != .
drop age
replace basis_raw = basis_raw + "Lawful Activity; " if lawfulactivity == "Yes"
drop lawfulactivity
replace basis_raw = basis_raw + "Retaliation; " if retaliation == "Yes"
drop retaliation
replace basis_raw = basis_raw + "Sex: Pregnancy; " if pregnancy == "Yes"
drop pregnancy
replace basis_raw = substr(basis_raw, 1, strlen(basis_raw) - 2)

// SH
g issue = issueohr if juris == "Public Accommodation"
replace issue = issuehousing if juris == "Housing"
replace issue = issueedandcor if juris == "Employment"
drop issueohr issuehousing issueedandcor
g sh = 1 if strpos(issue, "Sexual Harassment") > 0
replace sh = 0 if sh == .
replace sh = . if sh == 1 & basis != "Sex"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

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
replace win = 1 if outcome == "Probable Cause"
replace win = 1 if outcome == "Charge Issued"
replace win = 1 if outcome == "Settled after Charge Issued"
replace win = 0 if outcome == "EEOC=NJ & NDHRA=NPC"
replace win = 0 if outcome == "No Probable Cause"
replace win = 0 if outcome == "No Reasonable Cause"

// Settle
g settle = 0 
replace settle = 1 if outcome == "Conciliated Settlement"
replace settle = 1 if outcome == "Negotiated Settlement"
replace settle = 1 if outcome == "Settled after Charge Issued"
replace settle = 1 if outcome == "Successful Conciliation"
replace settle = 1 if outcome == "Withdrawn With Resolution"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Closed at Intake"
replace admin_close = 1 if outcome == "Failure to Cooperate"
replace admin_close = 1 if outcome == "Lack of Jurisdiction"
replace admin_close = 1 if outcome == "Transferred to EEOC"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Withdrawn With Resolution"
replace withdraw = 1 if outcome == "Withdrawn Without Resolution"

// Court
g court = 0
replace court = 1 if outcome == "Notice of Right to Sue"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_nd.dta", replace


