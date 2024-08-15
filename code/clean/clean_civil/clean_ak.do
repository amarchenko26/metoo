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

// Dropping open cases
drop if casestatus == "Open" & outcome == "" & investigationsense == ""


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "AK"

// Duration
g duration = charge_res_date - charge_file_date

// Jurisdiction
keep if inlist(juris, "Employment", "Housing", "Public Accommodation")

// Multi-category
g sumsex = max(basissex, basispregnancy)
g sumlgbtq = max(basissexualorientation, basisgenderidentity)
g sumreligion = basisreligion
g sumrace = max(basisrace, basiscolor)
g sumnationality = basisnationalorigin
g sumdisability = max(basismentaldisability, basisphysicaldisability)
g sumage = basisage
g sumretaliation = max(basisretaliation, basisretaliationforfilingac)
g sumother = max(basismaritalstatus, basischangeinmaritalstatus, basisparenthood)
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
replace multi_cat = . if sum == 0 //missing basis
drop sum*

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
replace win = 1 if outcome == "C1 - Hearing Decision for Complainant"
replace win = 1 if outcome == "B4 - Conciliation Finalized"
replace win = 0 if investigationsense == "NSE"
replace win = 0 if outcome == "B3 - Not Substantial Evidence (Exception)"
replace win = 0 if outcome == "C2 - Hearing Decision for Respondent"

// Settle
g settle = 0 
replace settle = 1 if outcome == "B1 - Successful Settlement"
replace settle = 1 if outcome == "B2 - Predetermination Settlement (PDS)"
replace settle = 1 if outcome == "B2a - Predetermined Settlement"
replace settle = 1 if outcome == "C4 - Pre-Hearing Settlement"
replace settle = 1 if outcome == "M1 - Mediation Successful"
replace settle = 1 if outcome == "M2 - CP Withdrawn with Settlement"
replace settle = 1 if outcome == "M3 - Complaint Withdrawn in Mediation"
replace settle = 1 if outcome == "M4 - Mediatin Predetermination Settlement"
replace settle = 1 if outcome == "RC - Resolution Conference Closure"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "A10 - Unperfected Complaint"
replace admin_close = 1 if outcome == "A2 - Complaint not Timely"
replace admin_close = 1 if outcome == "A3 - Lack of Jurisdiction"
replace admin_close = 1 if outcome == "A4 - Complainant Not Available"
replace admin_close = 1 if outcome == "A4 - Complainent Not Available"
replace admin_close = 1 if outcome == "A5 - Fail of CP to Proceed or Cooperate"
replace admin_close = 1 if outcome == "A5 - Failure of CP to Proceed or Cooperate"
replace admin_close = 1 if outcome == "A8 - Tribal Sovereign Immunity"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "A1 - Complaint Withdrawn"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "A7 - Administrative Dismissal"
replace dismissed = 1 if outcome == "C5 - Administrative Dismissal"
replace dismissed = 1 if admin_close == 1 | withdraw == 1

// Court
g court = 0
replace court = 1 if outcome == "A6 - Complainant to Court"


/*******************************************************************************
Export data
*******************************************************************************/

// Clean up vars before merging
drop acct casestatus rptype

save "$clean_data/clean_ak.dta", replace


