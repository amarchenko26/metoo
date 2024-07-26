/*******************************************************************************

Clean Alaska cases

*******************************************************************************/

import excel "$raw_data/AK/ak_raw_cases.xls", firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren liability juris
ren datecreated charge_file_date
ren dateclosed charge_res_date
ren closurereason outcome
ren monetaryaward relief


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "AK"

// Duration
g duration = charge_res_date - charge_file_date

// Jurisdiction
keep if inlist(juris, "Employment", "Housing", "Public Accommodation")

// Basis
local basis race sex nationalorigin maritalstatus color changeinmaritalstatus religion pregnancy mentaldisability parenthood physicaldisability retaliation age retaliationforfilingac sexualorientation genderidentity
g basis_raw = ""
foreach var of local basis {
	replace basis_raw = basis_raw + " `var'" if basis`var' == 1
}
replace basis_raw = strtrim(basis_raw)
split basis_raw
ren basis_raw1 basis
replace basis = "Sex"			if inlist(basis, "sex", "pregnancy")
replace basis = "LGBTQ"			if inlist(basis, "sexualorientation", "genderidentity")
replace basis = "Religion"		if basis == "religion"
replace basis = "Race"			if inlist(basis, "race", "color")
replace basis = "Nationality"	if basis == "nationalorigin"
replace basis = "Disability"	if inlist(basis, "mentaldisability", "physicaldisability")
replace basis = "Age"			if basis == "age"
replace basis = "Retaliation"	if inlist(basis, "retaliation", "retaliationforfilingac")
replace basis = "Other"			if inlist(basis, "", "maritalstatus", "changeinmaritalstatus", "parenthood")
drop basisrace-basisgenderidentity basis_raw?

// SH
local issue failuretosell firedconstructivedisch eviction failuretopromote deniedcredit termsconditionsprivila deniedservice failuretodispatch sexualharassment demotion harassment failuretoreasonablyacco failuretohire
g issue = ""
foreach var of local issue {
	replace issue = issue + " `var'" if issue`var' == 1
}
replace issue = strtrim(issue)
drop issuefailuretosell-issuefailuretohire
split issue
g sh = 0
replace sh = 1 if issue1 == "sexualharassment"
replace basis = "Sex" if sh == 1 & strpos(basis_raw, "sex") > 0
replace sh = . if sh == 1 & basis != "Sex"
drop issue?

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
replace relief = . if relief == 0
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if investigationsense == "SE"
replace win = 0 if investigationsense == "NSE" | outcome == "B3 - Not Substantial Evidence (Exception)"

// Settle
g settle = 0 
replace settle = 1 if inlist(outcome, "B1 - Successful Settlement", "B2 - Predetermination Settlement (PDS)", "B2a - Predetermined Settlement", "B4 - Conciliation Finalized", "M1 - Mediation Successful", "M2 - CP Withdrawn with Settlement", "M3 - Complaint Withdrawn in Mediation", "M4 - Mediatin Predetermination Settlement", "RC - Resolution Conference Closure")

// Court
g court = 0
replace court = 1 if outcome == "A6 - Complainant to Court"


/*******************************************************************************
Export data
*******************************************************************************/

// Clean up vars before merging
drop acct casestatus rptype

save "$clean_data/clean_ak.dta", replace


