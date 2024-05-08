/*******************************************************************************
Synthetic DiD

package sdid from: https://github.com/Daniel-Pailanir/sdid

Y: Outcome variable (numeric)
S: Unit variable (numeric or string)
T: Time variable (numeric)
D: Dummy of treatement, equal to 1 if units are treated, and otherwise 0 (numeric)

, method() // change option to did for DiD and SC for synthetic control
*******************************************************************************/

/*******************************************************************************
Load data 
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_robust = 1

/*******************************************************************************
Prep data 
*******************************************************************************/

drop if ym < 606 // drop cases before Jan 2010

/*******************************************************************************
Do SDID treat
*******************************************************************************/

preserve
	loc y 	 settle
	loc time months_to_treat_12
	loc unit basis_clean

	collapse (mean) `y', by(`time' `unit')
	drop if `time' == .

	g treat = 0 
	replace treat = 1 if `unit' == "Sex" & `time' > 0 

	#delimit ;
	eststo sdid_s: sdid `y' `unit' `time' treat, //covariates(r, projected)
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on msize(medium)
		g2_opt(xlabel(-7(1)6) ytitle("Probability of settlement") xtitle("Time relative to MeToo (12 months)"))
		graph_export("$figures/sdid_`y'_", .png); 
	
	#delimit cr
restore
	
	
preserve 
	loc y 	 probable_cause
	loc time months_to_treat_6
	loc unit basis_clean

	collapse (mean) `y', by(`time' `unit')
	drop if `time' == .

	g treat = 0 
	replace treat = 1 if `unit' == "Sex" & `time' > 0 

	#delimit ;
	eststo sdid_p: sdid `y' `unit' `time' treat, 
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on msize(medium)
		g2_opt(xlabel(-14(1)12) ytitle("Probability of win") xtitle("Time relative to MeToo (6 months)"))
		graph_export("$figures/sdid_`y'_", .png); 
	#delimit cr
restore





/*******************************************************************************
Robustness 
*******************************************************************************/
loc y2 settle
loc y3 probable_cause
loc y4 relief_scale

loc outcome_vars y2 y3 y4
loc i 1

if `run_robust' == 1 {

	foreach y of local outcome_vars {
		
		// Outcome `y'
		reghdfe ``y'' treat c.ym#i.basis_cat, absorb(basis_clean ym) vce(cluster basis_clean)
		eststo u`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc unit_time "Yes", replace
				
		loc ++i
	}
	
	#delimit ;	
	estout sdid_s u1 sdid_p u2 u3 using "$tables/sdid.tex", style(tex) replace
		varlabels(treat "ATT") keep(treat)
		mgroups("Settled" "P(win)" "Compensation", pattern(1 0 1 0 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(feunit fetime unit_time N r2, label("Case FE" "Time FE" "Case $\times$ Time FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
}


/* This panel is currently unabalanced because of not enough observations of relief. 
We can run this when new data gets added. 

preserve 
	loc y 	 relief_scale
	loc time months_to_treat_12
	loc unit basis_clean

	collapse (mean) `y', by(`time' `unit')
	drop if `time' == .

	g treat = 0 
	replace treat = 1 if `unit' == "Sex" & `time' > 0 

	#delimit ;
	sdid `y' `unit' `time' treat, 
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on msize(medium)
		g2_opt(xlabel(-7(1)6) ytitle("Compensation") xtitle("Time relative to MeToo (12 months)"))
		graph_export("$figures/sdid_`y'_", .png); 
	#delimit cr
restore

*/






