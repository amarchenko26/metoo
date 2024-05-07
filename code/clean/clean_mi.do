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

g state = "Michigan"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Probable cause
g probable_cause = .
replace probable_cause = 0 if outcome == "I01 - Insufficient evidence - adjusted"
replace probable_cause = 0 if outcome == "I02 - Insufficient evidence"

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

/*
// Clean basis 
g basis_clean = "Sex" 				if regexm(basis, "Equal Pay") | regexm(basis, "Sex")
replace basis_clean = "LGBTQ" 		if basis == "Sex-Gender Identity/Transgender"
replace basis_clean = "Religion" 	if regexm(basis, "Religion") 
replace basis_clean = "Race"		if regexm(basis, "Race")
replace basis_clean = "Nationality" if regexm(basis, "National Origin")
replace basis_clean = "Disability" if basis == "Alcoholism" | basis == "Allergies" | basis == "Alzheimers" | basis == "Asthma"| basis == "Autism"| basis == "Blood (Other)"| regexm(basis, "Brain")| basis == "Cancer" | basis == "Cerebral Palsy"| basis == "Chemical Sensitivity"| basis == "Color"| basis == "Cumulative Trauma Disorder"| basis == "Cystic Fibrosis"| basis == "Depression"| basis == "Diabetes"| basis == "Disfigurement"| basis == "Drug Addiction"| basis == "Dwarfism"| basis == "Epilepsy" | basis == "Gastrointestinal" | basis == "HIV" | basis == "Handicap (Not ADA)" | basis == "Hearing Impairment" | basis == "Heart/Cardiovascular"| basis == "Intellectual Disability" | basis == "Kidney Impairment" | basis == "Learning Disability" | regexm(basis, "Depression") | basis == "Missing Digits/Limbs" | regexm(basis, "Sclerosis") | regexm(basis, "Orthopedic") | regexm(basis, "Anxiety") | regexm(basis, "Disability") | regexm(basis, "Neurological") | regexm(basis, "Psychiatric") | regexm(basis, "Respiratory") | regexm(basis, "Paralysis")| regexm(basis, "Stress")| regexm(basis, "Disability")| regexm(basis, "Disabled") | basis == "Schizophrenia" | regexm(basis, "Speech") | regexm(basis, "Tuberculosis") | regexm(basis, "Vision")
replace basis_clean = "Age" 		if basis == "Age"
replace basis_clean = "Retaliation" if basis == "Retaliation"
replace basis_clean = "Other" 		if regexm(basis, "Genetic") | basis == "Other" | basis == "Relationship/Assn." | basis == "Unassigned" | basis == "" // if it's missing

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis_clean == "Sex"

// SH
g sh = (issue == "Sexual Harassment")
replace sh = . if sex_cases == 0 & sh == 1 // remove cases that are SH but not sex-based

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_mi.dta", replace


