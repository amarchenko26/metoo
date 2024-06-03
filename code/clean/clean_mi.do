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
ren issueandbasis basis
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

g state = "MI"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Probable cause
g win = .
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
replace settle = 1 if outcome == "L02 - Post-Investigation Settlement Agreement"
replace settle = 1 if outcome == "M01 - Settlement Agreement"
replace settle = 1 if outcome == "P02 - Post-Charge Settlement Agreement"

// Duration 
g duration = charge_res_date - charge_file_date

// Clean basis (general)
split basis, parse(;)

foreach a of numlist 7/12 {
	drop basis`a'
}

foreach a of numlist 1/6 {
	replace basis`a' = "" if basis`a' == "?" | basis`a' == " ?" | strpos(basis`a', "?: ?") > 0
	replace basis`a' = subinstr(basis`a', ": ", ":", .)
	split basis`a', parse(:)
	drop basis`a'
}

// SH
g sh = 0
replace sh = 1 if basis11 == "Sexual harassment" | (basis21 == "Sexual harassment" & basis11 == "") | (basis31 == "Sexual harassment" & basis11 == "" & basis21 == "")
// no cases that are SH but not sex-based

// basis_clean
foreach a of numlist 1/6 {
	drop basis`a'1
	rename basis`a'2 basis`a'
	replace basis`a' = subinstr(basis`a', ", ", ",", .)
	split basis`a', parse(,)
	drop basis`a'
}

g basis_clean = "Sex" 				if basis11 == "Sex" | (basis21 == "Sex" & basis11 == "") | (basis31 == "Sex" & basis11 == "" & basis21 == "")
replace basis_clean = "Religion" 	if basis11 == "Religion"
replace basis_clean = "Race"		if basis11 == "Race" | (basis21 == "Race" & basis11 == "")
replace basis_clean = "Nationality" if basis11 == "National Origin" | (basis21 == "National Origin" & basis11 == "")
replace basis_clean = "Disability"  if basis11 == "Disability" | (basis21 == "Disability" & basis11 == "")
replace basis_clean = "Age" 		if basis11 == "Age" | (basis21 == "Age" & basis11 == "")
replace basis_clean = "Retaliation" if basis11 == "Retaliation" | (basis21 == "Retaliation" & basis11 == "")
replace basis_clean = "Other" 		if inlist(basis11, "Arrest Record", "Color", "Familial Status", "Height", "Marital Status", "Weight") | ///
(basis21 == "Familial Status" & basis11 == "") | (basis11 == "" & basis21 == "" & basis31 == "")
replace basis_clean = "Sex"         if sh == 1

drop basis11-basis61

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis_clean == "Sex"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_mi.dta", replace


