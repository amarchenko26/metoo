/*******************************************************************************

Clean Michigan cases

*******************************************************************************/

import excel "$raw_data/MI/mi_raw_cases.xlsx", sheet("FOIA Data Request") firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// drop random vars 
drop donotmodifycase donotmodifyrowchecksum donotmodifymodifieddate

// Rename vars
ren caseid id
ren caseaccount resp_org
ren actual relief
ren closingcodeclosingcodecas outcome
ren areaofcomplaint juris
ren issueandbasis basis_raw
ren createddate charge_file_date
ren closeddate charge_res_date

// Clean relief 
egen temp_sum = rowtotal(relief annualized)
replace relief = temp_sum
drop temp_sum annualized

g missing_relief = (relief == 0)
replace relief = . if relief == 0

format charge_file_date %td
format charge_res_date %td

// Jurisdiction
replace juris = "Public Accommodation" if juris == "Public Accommodation/Public Service"

g state = "MI"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Probable cause
g win = .
replace win = 1 if outcome == "I17 - Decided by Court- w/adjustment"
replace win = 1 if outcome == "P02 - Post-Charge Settlement Agreement"
replace win = 1 if outcome == "P03 - Decided by MCRC Order - w/adjustment"
replace win = 0 if outcome == "I01 - Insufficient evidence - adjusted"
replace win = 0 if outcome == "I02 - Insufficient evidence"

// Court
g court = 0
replace court = 1 if outcome == "I07 - Claimant in court"
replace court = 1 if outcome == "I12 - Withdrawn - pursue in Court - no RTS" //Right to Sue
replace court = 1 if outcome == "I13 - Withdrawn - pursue in Court - with RTS"
replace court = 1 if outcome == "I16 - Decided by Court - no ruling on merits"
replace court = 1 if outcome == "I17 - Decided by Court- w/adjustment"
replace court = 1 if outcome == "I18 - Decided by Court – no adjustment"

// Settle
g settle = 0 
replace settle = 1 if outcome == "CO2 - Post-Investigation Settlement Agreement"
replace settle = 1 if outcome == "I03 - Settlement Agreement"
replace settle = 1 if outcome == "I11 - Withdrawn adjusted"
replace settle = 1 if outcome == "L02 - Post-Investigation Settlement Agreement"
replace settle = 1 if outcome == "M01 - Settlement Agreement"
replace settle = 1 if outcome == "M02 - Withdrawn adjusted"
replace settle = 1 if outcome == "P02 - Post-Charge Settlement Agreement"
replace settle = 1 if outcome == "I01 - Insufficient evidence - adjusted" & relief != .

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "C01 - Signed/notarized complaint not returned"
replace admin_close = 1 if outcome == "C02 - Allegations contained in duplicate EEOC case"
replace admin_close = 1 if outcome == "CO1 - Post-Investigation Administrative closure"
replace admin_close = 1 if outcome == "CO3 - Post-Investigation Legal Determination of Inability to proceed"
replace admin_close = 1 if outcome == "E02 - Lack of jurisdiction for MDCR"
replace admin_close = 1 if outcome == "E03 - Untimely for MDCR and / or EEOC"
replace admin_close = 1 if outcome == "E05 - EEOC assumed jurisdiction - no adjustment"
replace admin_close = 1 if outcome == "I04 - Unable to locate claimant"
replace admin_close = 1 if outcome == "I05 - Claimant failure to cooperate"
replace admin_close = 1 if outcome == "I06 - Wrong respondent"
replace admin_close = 1 if outcome == "I08 - Respondent out of business"
replace admin_close = 1 if outcome == "I09 - Duplicate complaint"
replace admin_close = 1 if outcome == "I10 - Federal agency assumed jurisdiction"
replace admin_close = 1 if outcome == "L01 - Post-Investigation Administrative closure"
replace admin_close = 1 if outcome == "L03 - Post-Investigation Legal Determination of Inability to proceed"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "I14 - Withdrawn - Not interested in pursuing"
replace withdraw = 1 if outcome == "I15 - Withdrawn - pursue with EEOC"
replace withdraw = 1 if outcome == "M03 - Withdrawn - not interested in pursuing"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "A7 - Administrative Dismissal"
replace dismissed = 1 if outcome == "C5 - Administrative Dismissal"
replace dismissed = 1 if admin_close == 1 | withdraw == 1

// Duration 
g duration = charge_res_date - charge_file_date

// Multi-category
g sumsex = 1 if regexm(basis_raw, "Sex")
g sumreligion = 1 if regexm(basis_raw, "Religion")
g sumrace = 1 if regexm(basis_raw, "Race|Color")
g sumnationality = 1 if regexm(basis_raw, "National Origin")
g sumdisability = 1 if regexm(basis_raw, "Disability")
g sumage = 1 if regexm(basis_raw, "Age")
g sumretaliation = 1 if regexm(basis_raw, "Retaliation")
g sumother = 1 if regexm(basis_raw, "Arrest Record|Familial Status|Height|Marital Status|Weight")
egen sum = rowtotal(sum*)
g multi_cat = 0 if sum == 1
replace multi_cat = 1 if sum != 1
replace multi_cat = . if sum == 0 //missing basis
drop sum*

// Clean basis (general)
split basis_raw, parse(;)

drop basis_raw7-basis_raw12

foreach a of numlist 1/6 {
	replace basis_raw`a' = "" if basis_raw`a' == "?" | basis_raw`a' == " ?" | strpos(basis_raw`a', "?: ?") > 0
	replace basis_raw`a' = subinstr(basis_raw`a', ": ", ":", .)
	split basis_raw`a', parse(:)
	drop basis_raw`a'
}

// SH
g sh = 0
replace sh = 1 if basis_raw11 == "Sexual harassment" | (basis_raw21 == "Sexual harassment" & basis_raw11 == "") | (basis_raw31 == "Sexual harassment" & basis_raw11 == "" & basis_raw21 == "")

// basis_clean
foreach a of numlist 1/6 {
	drop basis_raw`a'1
	rename basis_raw`a'2 basis_raw`a'
	replace basis_raw`a' = subinstr(basis_raw`a', ", ", ",", .)
	split basis_raw`a', parse(,)
	drop basis_raw`a'
}

g basis = "Sex" 				if basis_raw11 == "Sex" | (basis_raw21 == "Sex" & basis_raw11 == "") | (basis_raw31 == "Sex" & basis_raw11 == "" & basis_raw21 == "")
replace basis = "Religion" 	    if basis_raw11 == "Religion"
replace basis = "Race"		    if inlist(basis_raw11, "Race", "Color") | (basis_raw21 == "Race" & basis_raw11 == "")
replace basis = "Nationality"   if basis_raw11 == "National Origin" | (basis_raw21 == "National Origin" & basis_raw11 == "")
replace basis = "Disability"    if basis_raw11 == "Disability" | (basis_raw21 == "Disability" & basis_raw11 == "")
replace basis = "Age" 		    if basis_raw11 == "Age" | (basis_raw21 == "Age" & basis_raw11 == "")
replace basis = "Retaliation"   if basis_raw11 == "Retaliation" | (basis_raw21 == "Retaliation" & basis_raw11 == "")
replace basis = "Other" 		if inlist(basis_raw11, "Arrest Record", "Familial Status", "Height", "Marital Status", "Weight") | ///
(basis_raw21 == "Familial Status" & basis_raw11 == "") | (basis_raw11 == "" & basis_raw21 == "" & basis_raw31 == "")
replace basis = "Sex"           if sh == 1

drop basis_raw11-basis_raw61

replace sh = 1 if basis == "Retaliation" & strpos(basis_raw, "Sexual harassment") > 0

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"
replace sex_cases = 1 if basis == "Retaliation" & strpos(basis_raw, "Sex") > 0 & sh == 0


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_mi.dta", replace


