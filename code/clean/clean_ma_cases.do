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

// Make SH vars
gen sh = basis == "Sex discrimination / Sexual Harassment"
la var sh "=1 if basis is sexual harassment"

gen sex_cases = basis == "Female"
replace sex_cases = 1 if basis == "Sex"
replace sex_cases = 1 if basis == "Sex discrimination, unspecified or general"
la var sex_cases "=1 if basis is sex-related"

// Gen state var
gen state = "MA"

// Gen outcome vars
gen went_to_court = outcome == "Closed - Chapter 478 (removed to court)" // 1 if condition met, 0 otherwise

gen probable_cause = 1 if outcome == "Probable Cause Found"
replace probable_cause = 0 if outcome == "Closed - Lack of Probable Cause"
la var probable_cause "=1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)"

gen duration = charge_res_date - charge_file_date

gen treat = (charge_file_date > date("01oct2017", "DMY"))

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace


