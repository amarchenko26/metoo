/*******************************************************************************

Cleans Massachussets data 

*******************************************************************************/

import delimited "$raw_data/MA/ma_gender_w_algo.csv", clear varnames(1)
duplicates drop docketid, force
save "$clean_data/clean_ma.dta", replace


import excel "$raw_data/MA/ma_raw_cases.xlsx", ///
	sheet("No Duplicate Complaints") firstrow clear
ren *, lower
duplicates drop docketid, force
merge 1:1 docketid using "$clean_data/clean_ma.dta"


/*******************************************************************************
Clean vars
*******************************************************************************/

drop casestatus // only closed cases in MA
drop organization _merge

ren docketid id

ren chargefilingdate charge_file_date
gen datefiled_date = date(datefiled, "MDY")
replace charge_file_date = datefiled_date if charge_file_date == .
drop datefiled datefiled_date

ren resolutiondate charge_res_date

ren jurisdiction juris 
replace juris = jurisdictiondiscription if juris == ""
drop jurisdictiondiscription

ren respondentlastname resp_ln 
ren respondentorganization resp_org
ren allegationsbasisofdiscrimina basis_raw
g comp_name = firstname + " " + lastname
replace comp_name = "" if comp_name == " "
drop firstname lastname


/*******************************************************************************
Define new vars
*******************************************************************************/

// Jurisdiction
replace juris = "Housing" if juris != "Employment"

// Multi-category
g multi_cat = 0

// Clean basis 
replace basis_raw = basisdiscription if basis_raw == ""
drop basisdiscription
drop if basis_raw == ""
g basis = "Sex" if regexm(basis_raw, "Sex|Female|Male")
replace basis = "Sex" if regexm(basis_raw, "Sexual orientation|Gender")
replace basis = "Religion" if regexm(basis_raw, "Atheist|Catholic|Creed|Orthodox|Islamic|Jehovah's|Jewish|Protestant|Sabbath|Adventist") | regexm(basis_raw, "^Other Religion")| regexm(basis_raw, "^Other religious")| regexm(basis_raw, "^Other specified creed")
replace basis = "Race" if regexm(basis_raw, "African|Asian|Black|Hispanic|White|hispanic|Race") | regexm(basis_raw, "^Other Race")
replace basis = "Nationality" if regexm(basis_raw, "American|Arab|Chinese|Caribbean|Indian|European|Filipino|Greek|Italian|Japanese|Korean|Mexican|Middle Eastern|National|Polish|national") | regexm(basis_raw, "^Other European") | regexm(basis_raw, "^Other National")
replace basis = "Disability" if regexm(basis_raw, "Abnormal pregnancy|AIDS|Acquired|Alcoholism|Back|Blindness|Cancer|Diabetes|Deafness|Disability|Epilepsy|Disease|Illness|Obesity|Retarded|Skin|Speech|Uses|motor|asthma") | regexm(basis_raw, "^Other Visual") | regexm(basis_raw, "^Other disability")| regexm(basis_raw, "^Other hearing")| regexm(basis_raw, "^Other hearing")| regexm(basis_raw, "^Other mental")| regexm(basis_raw, "^Other organic")
replace basis = "Age" if regexm(basis_raw, "Age") 
replace basis = "Retaliation" if regexm(basis_raw, "Retaliation")
replace basis = "Other" if regexm(basis_raw, "Arrest|Children|Conviction|Divorced|Drug|Familial|Genetic|Lead|Marital|Married|Military|Misdemeanor|Police|Public|Separated|Single|Unspecified|Veteran|Widowed")
replace basis = "Other" if basis_raw == "Other"

// Make SH vars
gen sh = basis_raw == "Sex discrimination / Sexual Harassment"
gen sex_cases = basis == "Sex"
replace sh = . if sex_cases == 0 & sh == 1 // remove cases that are SH but not sex-based

/*replace sex_cases = 0 if basis == "Male" //don't count Male discrimination in Sex
replace sex_cases = 0 if basis == "Male (Paternity-related)" */

// Victim female
g victim_f = .
replace victim_f = 1 if gendercode == "Female"
replace victim_f = 1 if regexm(basis_raw, "Female") & gendercode != "Male"
replace victim_f = 0 if gendercode == "Male"
replace victim_f = 0 if regexm(basis_raw, "Male") & gendercode != "Female"

// Duration
gen duration = charge_res_date - charge_file_date

// Gen state var
gen state = "MA"

replace outcome = description if outcome == ""
drop description

// Probable cause
g win = .
replace win = 1 if outcome == "Probable Cause Found"
replace win = 1 if outcome == "Split Decision: PC/LOPC or PC/LOJ"
replace win = 1 if outcome == "Closed - Conciliated"
replace win = 1 if outcome == "Closed - Violation/Enforcement"
replace win = 0 if outcome == "Closed - Lack of Probable Cause"
replace win = 0 if outcome == "Closed - No Violation"

// Clean settle
g settle = 0
replace settle = 1 if outcome == "Closed - Pre-Determination Settlement"
replace settle = 1 if outcome == "Closed - Settled At Hearing"
replace settle = 1 if outcome == "Closed - Withdrawn With Settlement"
replace settle = . if inlist(outcome, "Closed - Compliance With Order", "Closed - Housing Judicial Review  ", "Closed - Judicial Review")

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Closed - Bankruptcy"
replace admin_close = 1 if outcome == "Closed - EEOC-Administrative"
replace admin_close = 1 if outcome == "Closed - Failure to Cooperate"
replace admin_close = 1 if outcome == "Closed - Lack of Jurisdiction"
replace admin_close = 1 if outcome == "Closed - Unable to Locate Complainant"
replace admin_close = . if inlist(outcome, "Closed - Compliance With Order", "Closed - Housing Judicial Review  ", "Closed - Judicial Review")

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Closed - Withdrawn"
replace withdraw = . if inlist(outcome, "Closed - Compliance With Order", "Closed - Housing Judicial Review  ", "Closed - Judicial Review")

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "Closed - Dismissed"
replace dismissed = 1 if outcome == "Closed - R&A Dismissal"
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = . if inlist(outcome, "Closed - Compliance With Order", "Closed - Housing Judicial Review  ", "Closed - Judicial Review")

// Clean court
g court = 0
replace court = 1 if outcome == "Closed - Chapter 478 (removed to court)" 
replace court = . if inlist(outcome, "Closed - Compliance With Order", "Closed - Housing Judicial Review  ", "Closed - Judicial Review")

// Relief
g relief = .
g missing_relief = (relief == .)

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace


