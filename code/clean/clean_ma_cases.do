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
ren Jurisdiction juris 
ren ResolutionDate charge_res_date
ren Outcome outcome
ren RespondentLastName resp_ln 
ren RespondentOrganization resp_org
ren AllegationsBasisofdiscrimina basis

la var id "State-given ID"
la var juris "Employment, public housing, education, etc"
la var charge_file_date "Date charge filed"
la var charge_res_date "Date charge resolved"
la var outcome "Outcome of charge: no cause finding, hearing, settlement, etc"
la var resp_ln "Respondent last name"
la var resp_org "Respondent organization"
la var basis "Basis of discrimination alleged"

/*******************************************************************************
Define new vars
*******************************************************************************/

// Make SH vars
g sh = 0
replace sh = 1 if basis == "Sex discrimination / Sexual Harassment"
la var sh "=1 if basis is sexual harassment"

// Gen state var
gen state = "MA"

// Gen outcome vars

* 1 if condition met, 0 otherwise
gen went_to_court = outcome == "Closed - Chapter 478 (removed to court)"

gen probable_cause = 1 if outcome == "Probable Cause Found"
replace probable_cause = 0 if outcome == "Closed - Lack of Probable Cause"
la var probable_cause "=1 if cause, 0 if no cause, missing does NOT mean plaintiff lost (court, dismissed, etc)"

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace


