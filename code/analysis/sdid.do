/*******************************************************************************
Synthetic DiD

package sdid from: https://github.com/Daniel-Pailanir/sdid

Y: Outcome variable (numeric)
S: Unit variable (numeric or string)
T: Time variable (numeric)
D: Dummy of treatement, equal to 1 if units are treated, and otherwise 0 (numeric)

, method() //sdid for SDID, did for DiD and SC for synthetic control
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Prep data 
*******************************************************************************/

drop if ym < 606 // drop cases before Jan 2010

// Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

/*******************************************************************************
Program to create time to treat
*******************************************************************************/

loc y probable_cause
loc time months_to_treat_6
loc unit basis_clean

collapse (mean) `y', by(`time' `unit')
drop if `time' == .

g treat = 0 
replace treat = 1 if `unit' == "Sex" & `time' > 0 

	#delimit ;
	sdid `y' `unit' `time' treat, 
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on 
		g2_opt(xlabel(2010(1)2022) ytitle("P(win)") xtitle("Year of filing"))
		graph_export(sdid_, .png);
	#delimit cr

	
	
	
	


*preserve 

collapse (mean) probable_cause, by(common_year basis_clean)
drop if common_year == .

g treat = 0 
replace treat = 1 if basis_clean == "Sex" & common_year > 2017 

	#delimit ;
	sdid probable_cause basis_clean common_year treat, 
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on 
		g1_opt(xtitle(1 "Stuff" 2 "Other stuff" 3 "Test")) // weights
		g2_opt(xlabel(2010(1)2022) ytitle("P(win)") 
            xtitle("Year of filing") text(125 1995 "ATT = -15.604" " SE = (9.338)"))
			
		graph_export(sdid_, .png);
	#delimit cr

*restore
