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

g eeoc_filed = 1

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_eeoc_filed.dta", replace


