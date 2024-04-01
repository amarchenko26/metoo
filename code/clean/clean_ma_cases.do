/*******************************************************************************

Cleans Massachussets data 

*******************************************************************************/

import excel "$raw_data/MA/ma_raw_cases.xlsx", sheet("No Duplicate Complaints") firstrow clear

/*******************************************************************************
Clean vars
*******************************************************************************/

drop CaseStatus // only closed cases in MA


ren DocketId id
la var id "State-given ID"
ren Jurisdiction juris 
la var juris "Employment, public housing, education, etc"
ren ChargeFilingDate charge_file_date
la var charge_file_date "Date charge filed"
ren ResolutionDate charge_res_date
la var charge_res_date "Date charge resolved"
ren Outcome outcome
la var outcome "What happened to charge: no cause finding, hearing, settlement, etc"
ren RespondentLastName resp_ln 
la var resp_ln "Respondent last name"
ren RespondentOrganization resp_org
la var resp_org "Respondent organization"
ren AllegationsBasisofdiscrimina basis
la var basis "Basis of discrimination alleged"


/*******************************************************************************
Define SH
*******************************************************************************/

// what is paragraph 4, retaliation? maybe this is sexual harssment related 

// clean SH vars
g sh = 0
replace sh = 1 if basis == "Sex discrimination / Sexual Harassment"
la var sh "=1 if basis is sexual harassment"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ma.dta", replace




gen ym = ym(year(charge_file_date), month(charge_file_date)) // Generate year-month variable
format ym %tm
di tm(2017m10) // di numeric value for October 2017



preserve
gen y = 1
collapse (count) mean_y = y, by(ym sh)

twoway line mean_y ym if sh == 0 ///
	|| line mean_y ym if sh == 1, ///
	legend(label(2 "Sexual harassment cases") label(1 "Other discrimination cases")) ///
	title("Number of discrimination cases filed in MA") ///
	ylabel(, format(%9.0g)) ///
	xtitle("Year") ytitle("Number of cases") ///
	xline(693) note("Vertical line indicates start of MeToo")
	
graph export "$figures/parallel.png", replace 	
restore
