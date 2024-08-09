/*******************************************************************************

Cleans Massachussets data 

*******************************************************************************/

import excel "$raw_data/MA/ma_raw_cases.xlsx", ///
	sheet("No Duplicate Complaints") firstrow clear

/*******************************************************************************
Clean vars
*******************************************************************************/

drop CaseStatus // only closed cases in MA

ren DocketId id
ren ChargeFilingDate charge_file_date
ren ResolutionDate charge_res_date
ren Jurisdiction juris 
ren Outcome outcome
ren RespondentLastName resp_ln 
ren RespondentOrganization resp_org
ren AllegationsBasisofdiscrimina basis_raw


/*******************************************************************************
Define new vars
*******************************************************************************/

// Drops 200 empty observations
drop if charge_file_date == . & charge_res_date == .

// Jurisdiction
replace juris = "Housing" if juris != "Employment"

// Clean basis 
g basis = "Sex" if regexm(basis_raw, "Sex|Female|Male")
replace basis = "LGBTQ" if regexm(basis_raw, "Sexual orientation|Gender")
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

// Gen state var
gen state = "MA"

// Gen outcome vars
g win = . 
replace win = 1 if outcome == "Probable Cause Found" | outcome == "Split Decision: PC/LOPC or PC/LOJ"
replace win = 0 if outcome == "Closed - Lack of Probable Cause" | outcome == "Closed - No Violation"

gen duration = charge_res_date - charge_file_date

// Clean settle
g settle = 0
replace settle = 1 if outcome == "Closed - Pre-Determination Settlement"
replace settle = 1 if outcome == "Closed - Settled At Hearing"
replace settle = 1 if outcome == "Closed - Withdrawn With Settlement"
replace settle = 1 if outcome == "Closed - Conciliated"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "Closed - Bankruptcy"
replace admin_close = 1 if outcome == "Closed - EEOC-Administrative"
replace admin_close = 1 if outcome == "Closed - Failure to Cooperate"
replace admin_close = 1 if outcome == "Closed - Lack of Jurisdiction"
replace admin_close = 1 if outcome == "Closed - Unable to Locate Complainant"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Closed - Withdrawn"
replace withdraw = 1 if outcome == "Closed - Withdrawn With Settlement"

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "Closed - Dismissed"
replace dismissed = 1 if outcome == "Closed - R&A Dismissal"

// Clean court
g court = 1 if outcome == "Closed - Chapter 478 (removed to court)" 
replace court = 0 if outcome != "Closed - Chapter 478 (removed to court)" 

// Relief
g relief = .
g missing_relief = (relief == .)

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace


