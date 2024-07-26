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

loc run_sdid   = 1
loc run_robust = 1

/*******************************************************************************
Prep data 
*******************************************************************************/

drop if eeoc_filed == 1
drop if ym < 606 // drop cases before Jan 2010

/*******************************************************************************
Do SDID treat
*******************************************************************************/

loc y1 settle
loc y2 win
loc y3 relief_scale
	
loc outcome_vars y1 y2 y3

if `run_sdid' == 1 {

	loc time months_to_treat_12
	loc unit basis

	loc i 1 // counter for eststo labeling

	foreach y of loc outcome_vars{
		preserve
			collapse (mean) ``y'', by(`time' `unit')
			drop if `time' == .

			egen `unit'_cat = group(`unit') // can't xtset string var
			xtset `unit'_cat `time' // xtset for panel data
			spbalance, balance // check balance, drop if unbalanced

			g treat = 0 
			replace treat = 1 if `unit' == "Sex" & `time' > 0 

			#delimit ;
			eststo sdid`i': sdid ``y'' `unit' `time' treat,
				vce(placebo) reps(100) seed(123) method(sdid) 
				graph g1on msize(medium)
				g2_opt(xlabel(-8(1)5) xtitle("Time to MeToo", size(medium))) //ytitle("Probability of settlement", size(medium))
				graph_export("$figures/sdid_``y''_", .png); 
		
			#delimit cr
			loc ++i
		restore
	}
}


/*******************************************************************************
Robustness 
*******************************************************************************/

// Same locals as above 
loc j 1

if `run_robust' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat c.ym#i.basis_cat, absorb(basis ym) vce(cluster basis)
		eststo u`j'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc unit_time "Yes", replace
				
		loc ++j
	}
	
	#delimit ;	
	estout u1 u2 u3 sdid1 sdid2 sdid3 using "$tables/sdid.tex", style(tex) replace
		varlabels(treat "ATT") keep(treat)
		mgroups("Unit trends" "SDID", pattern(1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel("Settle" "Win" "Comp." "Settle" "Win" "Comp.", pattern(1 1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		stats(feunit fetime unit_time N r2, label("Case FE" "Time FE" "Case $\times$ Time FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
}








