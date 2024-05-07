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
ren actual relief
ren closingcodeclosingcodecas outcome
ren areaofcomplaint juris
ren issueandbasis basis
ren createddate charge_file_date
ren closeddate charge_res_date


// Clean relief 
egen temp_sum = rowtotal(total_benefit_amount selectsumnvlbackpay0nvlfrontpay0)
replace total_benefit_amount = temp_sum
drop temp_sum selectsumnvlbackpay0nvlfrontpay0

g missing_relief = (total_benefit_amount == 0)
replace total_benefit_amount = . if total_benefit_amount == 0


/*

// Clean time
foreach var in charge_file_date charge_res_date court_file_date court_res_date {
	replace `var' = "" if `var' == "null"
    gen temp_`var' = date(`var', "MDY")
    format temp_`var' %td
    drop `var'
    rename temp_`var' `var'
}

g state = "Michigan"
g juris = "Employment"

/*******************************************************************************
Clean outcomes
*******************************************************************************/

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

// Probable cause
g probable_cause = .
replace probable_cause = 1 if outcome == "Hearings Discrimination Finding"
replace probable_cause = 0 if outcome == "No Cause Finding Issued"

// Court
g court = (!missing(court_file_date))
replace court = 1 if outcome == "NRTS Issued At CP Request" //CP is charging party, Notice of Right to Sue

// Settle
g settle = 0 
replace settle = 1 if outcome == "Settlement With Benefits"
replace settle = 1 if outcome == "Withdrawal With Benefits"

// Duration 
g duration = charge_res_date - charge_file_date
g duration_court = court_file_date - court_res_date


// Sex of complainant 
g victim_f = 1 if sex == "F"
replace victim_f = 0 if sex == "M"

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_mi.dta", replace


