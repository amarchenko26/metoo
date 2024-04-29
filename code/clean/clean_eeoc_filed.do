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
drop if closure_action =="CLOSURE_ACTION"

// Destring relief 
destring total_benefit_amount, replace force
destring selectsumnvlbackpay0nvlfrontpay0, replace force

replace total_benefit_amount = total_benefit_amount + selectsumnvlbackpay0nvlfrontpay0
drop selectsumnvlbackpay0nvlfrontpay0

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

/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Probable cause
g probable_cause = .
replace probable_cause = 1 if outcome == "Hearings Discrimination Finding"
replace probable_cause = 0 if outcome == "No Cause Finding Issued"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if regexm(basis, "Sex")

// SH
g sh = (issue == "Sexual Harassment") //WHY ARE THERE RACE BASES FOR SH CASES? 
replace sh = . if sex_cases == 0 & sh == 1 // remove cases that are SH but not sex-based

// Clean basis 
*g basis_clean = "Sex" if regexm(basis, "^Title VII / Sex")  | regexm(basis, "^EPA / Equal Pay-Female") 
*replace basis_clean = "Religion" if regexm(basis, "^Title VII / Religion") 

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

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_eeoc_filed.dta", replace


