/*******************************************************************************

Cleans EEOC cases filed data 
Downloaded from: https://github.com/PublicI/employment-discrimination?tab=readme-ov-file

This text file contains data on employment discrimination charges for fiscal years 2011 through 2017. The data comes from the Equal Employment Opportunity Commission and encompasses charges filed with the EEOC and charges filed with state and local fair employment practices agencies alleging violations of federal anti-discrimination laws.
*******************************************************************************/

import delimited "$raw_data/EEOC/filed_11_17.txt", varnames(1) clear

/*******************************************************************************
Clean vars
*******************************************************************************/

// drop codes 
drop number_of_employees_code naics_code institution_type_code statute_code basis_code issue_code closure_code

// drop 6 weird obs w no content
drop if closure_action == "CLOSURE_ACTION"

// Destring relief 
destring total_benefit_amount, replace force
destring selectsumnvlbackpay0nvlfrontpay0, replace force

// Clean relief 
egen temp_sum = rowtotal(total_benefit_amount selectsumnvlbackpay0nvlfrontpay0)
replace total_benefit_amount = temp_sum
drop temp_sum selectsumnvlbackpay0nvlfrontpay0

g missing_relief = (total_benefit_amount == 0)
replace total_benefit_amount = . if total_benefit_amount == 0

// Rename vars
ren total_benefit_amount relief
ren sex_code sex
ren date_first_office charge_file_date
ren closure_date charge_res_date
ren court_filing_date court_file_date
ren resolution_date court_res_date
ren closure_action outcome
ren charge_inquiry_seq id //unique identifier for each case (a case is a collection of related charges)
ren court court_name
ren basis basis_raw

// Clean time
foreach var in charge_file_date charge_res_date court_file_date court_res_date {
	replace `var' = "" if `var' == "null"
    gen temp_`var' = date(`var', "MDY")
    format temp_`var' %td
    drop `var'
    rename temp_`var' `var'
}

g state = "Federal"
g juris = "Employment"

/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Clean basis 
g basis = "Sex" 				if regexm(basis_raw, "Equal Pay") | regexm(basis_raw, "Sex")
replace basis = "LGBTQ" 		if basis_raw == "Sex-Gender Identity/Transgender"
replace basis = "Religion" 	if regexm(basis_raw, "Religion") 
replace basis = "Race"		if regexm(basis_raw, "Race")
replace basis = "Nationality" if regexm(basis_raw, "National Origin")
replace basis = "Disability"  if basis_raw == "Alcoholism" | basis_raw == "Allergies" | basis_raw == "Alzheimers" | basis_raw == "Asthma"| basis_raw == "Autism"| basis_raw == "Blood (Other)"| regexm(basis_raw, "Brain")| basis_raw == "Cancer" | basis_raw == "Cerebral Palsy"| basis_raw == "Chemical Sensitivity"| basis_raw == "Color"| basis_raw == "Cumulative Trauma Disorder"| basis_raw == "Cystic Fibrosis"| basis_raw == "Depression"| basis_raw == "Diabetes"| basis_raw == "Disfigurement"| basis_raw == "Drug Addiction"| basis_raw == "Dwarfism"| basis_raw == "Epilepsy" | basis_raw == "Gastrointestinal" | basis_raw == "HIV" | basis_raw == "Handicap (Not ADA)" | basis_raw == "Hearing Impairment" | basis_raw == "Heart/Cardiovascular"| basis_raw == "Intellectual Disability" | basis_raw == "Kidney Impairment" | basis_raw == "Learning Disability" | regexm(basis_raw, "Depression") | basis_raw == "Missing Digits/Limbs" | regexm(basis_raw, "Sclerosis") | regexm(basis_raw, "Orthopedic") | regexm(basis_raw, "Anxiety") | regexm(basis_raw, "Disability") | regexm(basis_raw, "Neurological") | regexm(basis_raw, "Psychiatric") | regexm(basis_raw, "Respiratory") | regexm(basis_raw, "Paralysis")| regexm(basis_raw, "Stress")| regexm(basis_raw, "Disability")| regexm(basis_raw, "Disabled") | basis_raw == "Schizophrenia" | regexm(basis_raw, "Speech") | regexm(basis_raw, "Tuberculosis") | regexm(basis_raw, "Vision")
replace basis = "Age" 		if basis_raw == "Age"
replace basis = "Retaliation" if basis_raw == "Retaliation"
replace basis = "Other" 		if regexm(basis_raw, "Genetic") | basis_raw == "Other" | basis_raw == "Relationship/Assn." | basis_raw == "Unassigned" | basis_raw == "" // if it's missing

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// SH
g sh = (issue == "Sexual Harassment")
replace sh = . if sex_cases == 0 & sh == 1 // remove cases that are SH but not sex-based

// Probable cause
g win = .
replace win = 1 if outcome == "Hearings Discrimination Finding"
replace win = 0 if outcome == "No Cause Finding Issued"

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

g eeoc_filed = 1

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_eeoc_filed.dta", replace


