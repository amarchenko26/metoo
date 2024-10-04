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

// Relief 
destring total_benefit_amount, replace force
destring selectsumnvlbackpay0nvlfrontpay0, replace force

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
ren state_code state

// Dates
foreach var in charge_file_date charge_res_date court_file_date court_res_date {
	replace `var' = "" if `var' == "null"
    gen temp_`var' = date(`var', "MDY")
    format temp_`var' %td
    drop `var'
    rename temp_`var' `var'
}

// State
replace state = "" if inlist(state, "null", "AP", "FM", "MB", "MH", "MP", "ON", "PW", "WQ") 

// g state = "Federal" // Commenting out so that we can re-run code using real states instead of Federal designation as our state FE
g juris = "Employment"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Multi-category
g multi_cat = 0

// Clean basis 
g basis = "Sex" 				if regexm(basis_raw, "Equal Pay") | regexm(basis_raw, "Sex")
replace basis = "Sex" 		if basis_raw == "Sex-Gender Identity/Transgender" | basis_raw == "Sex-Sexual Orientation"
replace basis = "Religion" 	if regexm(basis_raw, "Religion") 
replace basis = "Race"		if regexm(basis_raw, "Race") | basis_raw == "Color"
replace basis = "Nationality" if regexm(basis_raw, "National Origin")
replace basis = "Disability"  if basis_raw == "Alcoholism" | basis_raw == "Allergies" | basis_raw == "Alzheimers" | basis_raw == "Asthma"| basis_raw == "Autism"| basis_raw == "Blood (Other)"| regexm(basis_raw, "Brain")| basis_raw == "Cancer" | basis_raw == "Cerebral Palsy"| basis_raw == "Chemical Sensitivity"| basis_raw == "Cumulative Trauma Disorder"| basis_raw == "Cystic Fibrosis"| basis_raw == "Depression"| basis_raw == "Diabetes"| basis_raw == "Disfigurement"| basis_raw == "Drug Addiction"| basis_raw == "Dwarfism"| basis_raw == "Epilepsy" | basis_raw == "Gastrointestinal" | basis_raw == "HIV" | basis_raw == "Handicap (Not ADA)" | basis_raw == "Hearing Impairment" | basis_raw == "Heart/Cardiovascular"| basis_raw == "Intellectual Disability" | basis_raw == "Kidney Impairment" | basis_raw == "Learning Disability" | regexm(basis_raw, "Depression") | basis_raw == "Missing Digits/Limbs" | regexm(basis_raw, "Sclerosis") | regexm(basis_raw, "Orthopedic") | regexm(basis_raw, "Anxiety") | regexm(basis_raw, "Disability") | regexm(basis_raw, "Neurological") | regexm(basis_raw, "Psychiatric") | regexm(basis_raw, "Respiratory") | regexm(basis_raw, "Paralysis")| regexm(basis_raw, "Stress")| regexm(basis_raw, "Disability")| regexm(basis_raw, "Disabled") | basis_raw == "Schizophrenia" | regexm(basis_raw, "Speech") | regexm(basis_raw, "Tuberculosis") | regexm(basis_raw, "Vision")
replace basis = "Age" 		if basis_raw == "Age"
replace basis = "Retaliation" if basis_raw == "Retaliation"
replace basis = "Other" 		if regexm(basis_raw, "Genetic") | basis_raw == "Other" | basis_raw == "Relationship/Assn." | basis_raw == "Unassigned" | basis_raw == "" // if it's missing

// SH
g sh = (issue == "Sexual Harassment")
replace sh = . if basis != "Sex" & basis != "Retaliation" & sh == 1 // remove cases that are SH but not sex-based

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Clean missings 
replace outcome = "" if outcome == "null"

// Probable cause
g win = .
replace win = 1 if outcome == "Hearings Discrimination Finding"
replace win = 1 if outcome == "Successful Conciliation"
replace win = 1 if outcome == "Conciliation Failure"
replace win = 0 if outcome == "No Cause Finding Issued"
replace win = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null")

// Court
replace civil_action_number = "" if civil_action_number =="null"

// Court = 1 if either CP or EEOC took case to court
g court = (!missing(court_file_date))
replace court = 1 if civil_action_number != ""
replace court = 1 if outcome == "NRTS Issued At CP Request" //CP is charging party, Notice of Right to Sue
replace court = 1 if outcome == "CP Filed Suit"
replace court = 1 if outcome == "Closed Due To Court Decision"
replace court = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null") & missing(court_file_date)

// Gen eeoc_took_to_court = 1 if EEOC took case to court
g eeoc_took_to_court = (civil_action_number != "" & outcome == "Conciliation Failure")

// Settle
g settle = 0 
replace settle = 1 if outcome == "Settlement With Benefits"
replace settle = 1 if outcome == "Withdrawal With Benefits"
replace settle = 1 if outcome == "Case Settled By Legal Unit"
replace settle = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null")

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "ADEA Sect. 7(D) Closure"
replace admin_close = 1 if outcome == "Administrative Closure"
replace admin_close = 1 if outcome == "CP Failed To Cooperate"
replace admin_close = 1 if outcome == "CP Failed To Respond To 30-Day Letter"
replace admin_close = 1 if outcome == "Failure To Locate Charging Party"
replace admin_close = 1 if outcome == "No Jurisdiction"
replace admin_close = 1 if outcome == "Remand - Failure To Prosecute"
replace admin_close = 1 if outcome == "Respondent Bankruptcy"
replace admin_close = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null")

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "CP Withdrawal - No Ben."
replace withdraw = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null")

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = . if inlist(outcome, "", "CP Refused Full Relief", "Open Charge Closed By Legal Activity", "null")

// Duration 
g duration = charge_res_date - charge_file_date
g duration_court = court_file_date - court_res_date

// Sex of complainant 
g victim_f = 1 if sex == "F"
replace victim_f = 0 if sex == "M"

g eeoc = 1
g eeoc_filed = 1

/*******************************************************************************
Export data
*******************************************************************************/

drop sex date_of_birth id case_type statute fiscal_year 

save "$clean_data/clean_eeoc_filed.dta", replace


