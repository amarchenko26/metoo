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
ren AllegationsBasisofdiscrimina basis


/*******************************************************************************
Define new vars
*******************************************************************************/

// Drops 200 empty observations
drop if charge_file_date == . & charge_res_date == .

// Clean basis 
g basis_clean = "Sex" if regexm(basis, "Abnormal pregnancy|Sex|Female|Male")
replace basis_clean = "LGBTQ" if regexm(basis, "Sexual orientation|Gender")
replace basis_clean = "Religion" if regexm(basis, "Atheist|Catholic|Creed|Orthodox|Islamic|Jehovah's|Jewish|Protestant|Sabbath|Adventist") | regexm(basis, "^Other Religion")| regexm(basis, "^Other religious")| regexm(basis, "^Other specified creed")
replace basis_clean = "Race" if regexm(basis, "African|Asian|Black|Hispanic|White|hispanic|Race") | regexm(basis, "^Other Race")
replace basis_clean = "Nationality" if regexm(basis, "American|Arab|Chinese|Caribbean|Indian|European|Filipino|Greek|Italian|Japanese|Korean|Mexican|Middle Eastern|National|Polish|national") | regexm(basis, "^Other European") | regexm(basis, "^Other National")
replace basis_clean = "Disability" if regexm(basis, "AIDS|Acquired|Alcoholism|Back|Blindness|Cancer|Diabetes|Deafness|Disability|Epilepsy|Disease|Illness|Obesity|Retarded|Skin|Speech|Uses|motor|asthma") | regexm(basis, "^Other Visual") | regexm(basis, "^Other disability")| regexm(basis, "^Other hearing")| regexm(basis, "^Other hearing")| regexm(basis, "^Other mental")| regexm(basis, "^Other organic")
replace basis_clean = "Age" if regexm(basis, "Age") 
replace basis_clean = "Retaliation" if regexm(basis, "Retaliation")
replace basis_clean = "Other" if regexm(basis, "Arrest|Children|Conviction|Divorced|Drug|Familial|Genetic|Lead|Marital|Married|Military|Misdemeanor|Police|Public|Separated|Single|Unspecified|Veteran|Widowed")
replace basis_clean = "Other" if basis == "Other"


// Make SH vars
gen sh = basis == "Sex discrimination / Sexual Harassment"
gen sex_cases = basis == "Female"
replace sex_cases = 1 if basis == "Sex"
replace sex_cases = 1 if basis == "Sex discrimination, unspecified or general"

// Gen state var
gen state = "MA"

// Gen outcome vars
gen went_to_court = outcome == "Closed - Chapter 478 (removed to court)" // 1 if condition met, 0 otherwise
gen probable_cause = 1 if outcome == "Probable Cause Found"
replace probable_cause = 0 if outcome == "Closed - Lack of Probable Cause"


gen duration = charge_res_date - charge_file_date

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace


