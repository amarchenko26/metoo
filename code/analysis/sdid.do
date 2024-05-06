/*******************************************************************************
Synthetic DiD

package sdid from: https://github.com/Daniel-Pailanir/sdid

Y: Outcome variable (numeric)
S: Unit variable (numeric or string)
T: Time variable (numeric)
D: Dummy of treatement, equal to 1 if units are treated, and otherwise 0 (numeric)

, method() // change option to did for DiD and SC for synthetic control
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

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
	eststo sdid1: sdid `y' `unit' `time' treat, //covariates(r, projected)
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
	eststo sdid2: sdid `y' `unit' `time' treat, 
		vce(placebo) reps(100) seed(123) method(sdid) 
		graph g1on msize(medium)
		g2_opt(xlabel(-14(1)12) ytitle("Probability of win") xtitle("Time relative to MeToo (6 months)"))
		graph_export("$figures/sdid_`y'_", .png); 
	#delimit cr
restore


#delimit ;	
estout sdid1 sdid2 using "$tables/sdid.tex", style(tex) replace
	varlabels(treat "ATT") keep(treat)
	mgroups("Settled" "P(win)", pattern(1 1) 
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	mlabel(none)
	stats(N r2, label(`"N"') fmt(%9.0fc))
	nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
	cells("b(fmt(3)star)" "se(fmt(3)par)") 
	prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
	prefoot("\\" "\midrule")
	postfoot("\bottomrule" "\end{tabular}") ;
#delimit cr





*create a table
// esttab sdid_1 sdid_2, starlevel ("*" 0.10 "**" 0.05 "***" 0.01) b(%-9.3f) se(%-9.3f)



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






