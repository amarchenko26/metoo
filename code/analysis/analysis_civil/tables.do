/*******************************************************************************
Tables for MeToo project - change2
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_did		 	= 0
loc run_overlap		= 0
loc overlap_placebo = 0
loc run_overlap_winter = 1
loc run_did_sex	 	= 0
loc run_did_robust 	= 0
loc run_did_alljuris = 0
loc run_selection 	= 0
loc run_summary  	= 0
loc run_balance  	= 0
loc run_overlap_balance = 0
loc run_duration 	= 0
loc run_unit   		= 0

/*******************************************************************************
Main DID 
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: All complaints}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
						
		loc ++i

	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex)  
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Complaints with gender}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr

	estimates clear
	eststo clear

	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Complaints with gender (triple difference)}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}

/*******************************************************************************
DiD overlap
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4 
loc i 1

if `run_overlap' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Difference-in-differences}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did_overlap.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Triple difference}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}



/*******************************************************************************
Overlap placebo regression 
*******************************************************************************/
// Take cases filed before MeToo, some overlap and some don't
// for every month in 2015, 2016, and 2017
// we take the complaints that did and didn't overlap in each month 
// we sum the % that are sex_cases 

if `overlap_placebo' == 1 {

	// From 2016m1 to 2017m10
	forvalues i = 672(1)693 {
		sum sex_cases if overlap_all == 1 & ym_filed == `i'
		sum sex_cases if overlap_all == 0 & ym_filed == `i'
	}

	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = sex_cases, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("% sex cases") ///
		title("Trends in overlap and non-overlap cases filed in the same year-month") 
	restore


	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = win, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Win rate") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
	restore


	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = duration, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Win rate") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
	restore

}


/*******************************************************************************
DiD overlap - drop winter 
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4 
loc i 1

if `run_overlap_winter' == 1 {
	preserve 
	drop if file_season == 4 // drop winter 

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_overlap_winter.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Difference-in-differences}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did_overlap_winter.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Triple difference}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}


/*******************************************************************************
DiD with Sex as treated
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 relief_scale
loc y4 settle
loc y5 court


loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_sex' == 1 {
	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace
	keep if juris == "Employment" // Only employment cases

	foreach y of local outcome_vars {
				
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_sex.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: All complaints}} \\ \midrule")
		fragment
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mgroups("Won" "Dismissed" "Compensation" "Settled" "Court", pattern(1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex ==0 & common_file_date < date("$metoo", "DMY") 
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_sex.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Overlap sample}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}


/*******************************************************************************
DiD regression - Robustness Check
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 relief_scale
loc y4 settle
loc y5 court

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_robust' == 1 {

	// DID - Single-tagged ****************************************************/
	preserve 
	keep if multi_cat == 0
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat ==0  
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Single-tagged cases}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Compensation" "Settled" "Court", pattern(1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	restore

	// DID - No retaliation ***************************************************/
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1

	preserve 
	drop if basis == "Retaliation"
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat ==0  
		estadd scalar control_mean = `r(mean)'
	
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{No retaliation cases}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear
	restore

	// DID - Before Covid *******************************************************/
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	
	preserve 
	keep if juris == "Employment"
	foreach y of local outcome_vars {
				
		reghdfe ``y'' treat if ym_filed < 722, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat ==0 & ym_filed < 722
		estadd scalar control_mean = `r(mean)'
					
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Filed before Covid-19}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}


/*******************************************************************************
Main DID 
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did_alljuris' == 1 {
	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_alljuris.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: All jurisdictions}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i

	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_alljuris.tex", style(tex)  
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Overlap complaints}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr

	estimates clear
	eststo clear

	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did_alljuris.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Complaints with gender (triple difference)}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}



/*******************************************************************************
Selection table
*******************************************************************************/

if `run_selection' == 1 {
	
	preserve 
	eststo A: reg total_cases_per_year post, r

	eststo B: reg sex_cases_per_year post if sex_cases == 1, r

	bys months_to_treat_12: egen months_to_treat_12_count = total(y) if sex_cases == 0
	eststo C: reg months_to_treat_12_count post if sex_cases == 0 & inlist(months_to_treat_12, -1, 0), r

	bys months_to_treat_12 sex_cases: egen months_to_treat_12_count_sex = total(y)
	eststo D: reg months_to_treat_12_count_sex post if sex_cases == 1 & inlist(months_to_treat_12, -1, 0), r
	
	#delimit ;
	
	esttab A B C D using "$tables/selection_table.tex", style(tex) replace
		drop(_cons)
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule" "\multicolumn{@span}{c}{\textbf{Counts (per year)}} \\ \midrule")
		fragment
		varlabels(post "Post MeToo")
		mlabel("\# filed" "\# Sex filed" "\shortstack{\# Control filed in 12 months\\before vs after MeToo}" "\shortstack{\# Sex filed in 12 months\\before vs after MeToo}" )
		nomtitles nonumbers
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(a3)star)" "se(fmt(a3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear

	eststo B: reg filed_per_year post if sex_cases == 1, r 
	
	eststo C: reg filed_f_per_year post if sex_cases == 1 & victim_f == 1, r

	eststo D: reg filed_f_per_year post if sex_cases == 1 & victim_f == 0, r

	#delimit ;
	
	esttab B B C D using "$tables/selection_table.tex", style(tex)
		prehead("\midrule \multicolumn{@span}{c}{\textbf{Shares}} \\ \midrule")		
		fragment 
		append
		drop(_cons)
		varlabels(post "Post MeToo")
		mlabel("DELETE ME" "\shortstack{Share Sex filed\\of total cases}" "\shortstack{Share Sex filed\\by women}" "\shortstack{Share Sex filed\\by men}")
		nomtitles nonumbers
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(a3)star)" "se(fmt(a3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") 
		;
	#delimit cr
	estimates clear
	eststo clear	

	restore
}

/*******************************************************************************
Summary table
*******************************************************************************/

if `run_summary' == 1 {

	tab basis, gen(basis_dummy)

	#delimit ;
	loc summary_1
	// Case chars
		sh
		victim_f
		post 
		duration 
	// Basis
		basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5 
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court
		relief_scale; 
	#delimit cr
	
	#delimit ;
	loc summary_2 // sex cases
	// Case chars
		sh
		victim_f
		post 
		duration 
	// Basis
		/* basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5  */
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court
		relief_scale; 
	#delimit cr

	#delimit ;
	loc summary_3 // post MeToo
	// Case chars
		sh
		victim_f
		duration 
	// Basis
		basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5 
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court
		relief_scale; 
	#delimit cr

	#delimit ;
	loc summary_4 // post MeToo
	// Case chars
		victim_f
		duration 
	// Basis
		/* basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5  */
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court
		relief_scale; 
	#delimit cr
	
	eststo mean_all: estpost tabstat `summary_1', c(stat) stat(mean sd)
	eststo mean_sex_cases: estpost tabstat `summary_2' if sh == 1, c(stat) stat(mean sd)
	eststo post_all: estpost ttest `summary_3', by(post)
	eststo post_sex_cases: estpost ttest `summary_4' if sh == 1, by(post)

	#delimit ;
	esttab mean_all mean_sex_cases post_all post_sex_cases using "$tables/summary.tex", replace 
		nonote nonumbers label booktabs f 
		cells("mean(fmt(%13.3fc) pattern(1 1 0 0) vacant(.)) b(star fmt(%13.3fc) pattern (0 0 1 1) vacant(.))"
				"sd(fmt(2) par([ ]) pattern(1 1 0 0) vacant(.)) se(par fmt(%15.2gc) pattern (0 0 1 1) vacant(.))")
		collabels(none)
    	mgroups("\shortstack{Sample\\Statistics}" 
				"\shortstack{Mean Difference\\(Post-Pre) MeToo}", 
			pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    	mtitles("All" "SH only" "All" "SH only")
			varlab( 
			sh "\textit{Complaint Characteristics} \\ \hspace{5mm} Sexual harassment" 
			victim_f "\hspace{5mm} Complainant is female" 
			post "\hspace{5mm} Filed after MeToo" 
			charge_file_year "\hspace{5mm} Year filed" 
			charge_res_year "\hspace{5mm} Year resolved" 
			duration "\hspace{5mm} Duration (days)" 
			basis_dummy1 "\textit{Discrimination basis} \\ \hspace{5mm} Age" 
			basis_dummy2 "\hspace{5mm} Disability" 
			basis_dummy3 "\hspace{5mm} Nationality" 
			basis_dummy4 "\hspace{5mm} Race" 
			basis_dummy5 "\hspace{5mm} Religion" 
			basis_dummy6 "\hspace{5mm} Retaliation" 
			basis_dummy7 "\hspace{5mm} Sex" 
			settle "\textit{Outcomes} \\ \hspace{5mm} Settled" 
			win_investigation "\hspace{5mm} Won"
			lose_investigation "\hspace{5mm} Lost"
			dismissed "\hspace{5mm} Dismissed"
			court "\hspace{5mm} Went to court" 
			relief_scale "\hspace{5mm} Compensation, 1000s" 
		) 
		substitute("\$" "$")
		stats(N, layout("@ @" "@ @") labels("Observations") fmt("%15.0fc %15.0fc" "%15.0fc %15.0fc"))
	;
	#delimit cr
	
}

*stats(N1 N2 p_joint, layout("@ @" ". @") labels("Observations" "Joint \textit{p}-value" ) fmt("%15.0fc %15.0fc" 2 2))	///

/*******************************************************************************
Correlation b/w duration and outcomes
*******************************************************************************/
if `run_duration' == 1 {

	eststo: reg settle duration, r

	eststo: reg settle duration if sex_cases == 1, r

	eststo: reg win duration, r

	eststo: reg win duration if sex_cases == 1, r

	eststo:	reg relief_scale duration, r

	eststo:	reg relief_scale duration if sex_cases == 1, r

	#delimit ;
	
	estout _all using "$tables/duration_corr.tex", style(tex) replace
		drop(_cons)
		varlabels(duration "Duration")
		mgroups("Settle" "Win" "Compensation", pattern(1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 5))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(5)star)" "se(fmt(5)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
	eststo clear
}

/****************************************************************************
Overlap balance table
****************************************************************************/

if `run_overlap_balance' == 1 {

	preserve	
	
	loc balance ///
	victim_f ///
    sh ///
	duration
	
	g overlap_balance = 1 if overlap_2 == 1
	replace overlap_balance = 0 if common_file_date < 20742 & common_res_date > 20742 
	replace overlap_balance = . if common_file_date < 20377 & overlap_balance == 0
	replace overlap_balance = . if common_res_date > 21107 & overlap_balance == 0
	
    balancetable overlap_balance `balance' using "$tables/overlap_balance.tex" if overlap_balance != ., ///
        varlabels vce(robust) replace ///
        ctitles("2016" "2017" "Diff" "p-value") ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(mean diff pval)
	restore
}

/*******************************************************************************
Unit trends 
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 relief_scale
loc y4 settle
loc y5 court
	
loc outcome_vars y1 y2 y3 y4 y5

// Same locals as above 
loc j 1

if `run_unit' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
		eststo u`j'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		qui estadd loc unit_time "\checkmark", replace
				
		loc ++j
	}
	
	#delimit ;	
	estout u1 u2 u3 u4 u5 using "$tables/sdid.tex", style(tex) replace
		varlabels(treat "ATT") keep(treat)
		mgroups("Unit trends", pattern(1 0 0 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel("Won" "Dismissed" "Compensation" "Settled" "Court", pattern(1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		stats(feunit fetime unit_time N r2, label("Unit $\times$ State FE" "Time $\times$ State FE" "Case $\times$ Time FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
}



