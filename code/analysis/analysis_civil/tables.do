/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_did		 	= 0
loc run_did_gender	= 0
loc run_did_gender_appendix	= 0
loc run_did_sh	 	= 0
loc	run_did_all  	= 0
loc run_did_robust 	= 1
loc run_selection 	= 0
loc run_summary  	= 0
loc run_balance  	= 0
loc run_overlap_balance = 0
loc run_duration 	= 0
loc run_unit   		= 0
loc overlap_placebo = 0

keep if eeoc == 0

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

if `run_did' == 1 {
	preserve 
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
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Main effects}} \\ \midrule")
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
		qui: sum ``y'' if overlap_treat_sex == 0
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_sex.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Overlaps with MeToo}} \\ \midrule")
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
DiD with gender
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 relief_scale
loc y4 settle
loc y5 court


loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_gender' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_gender.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Gender non-missing}} \\ \midrule")
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
		
		reghdfe ``y'' treat_sex treat_sex_f, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_gender.tex", style(tex) 
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Complainant is female}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f)
		mlabel(none) nomtitles nonumbers nolines
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
		
		reghdfe ``y'' treat_sex treat_sex_f if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_gender.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Overlaps with MeToo}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f)
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
DiD with gender (appendix)
*******************************************************************************/
loc y1 settle
loc y2 dismissed
loc y3 court
loc y4 win
loc y5 relief_scale

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_gender_appendix' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex if victim_f != ., absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Gender non-missing}} \\ \midrule")
		fragment
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mgroups("Settled" "Dismissed" "Court" "Won" "Compensation", pattern(1 0 1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex treat_sex_f, absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat_sex_f == 0
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex treat_sex_f, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex) 
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Complainant is female}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f)
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex treat_sex_f if common_file_date < date("$metoo", "DMY"), absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat_sex_f ==0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex treat_sex_f if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_sex_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Overlaps with MeToo}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
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
	collapse (mean) avg_sex_cases = win_alt, by(ym_filed overlap_all)

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
DiD with SH as treated
*******************************************************************************/

loc y1 settle
loc y2 dismissed
loc y3 court
loc y4 win
loc y5 relief_scale

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_sh' == 1 {
	preserve 
	foreach y of local outcome_vars {
				
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_sh.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Main effects}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Settled" "Dismissed" "Court" "Won" "Compensation", pattern(1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
		qui: sum ``y'' if treat ==0 & common_file_date < date("$metoo", "DMY") 
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_sh.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Overlaps with MeToo}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit fetime feunit_s fetime_s N r2 control_mean, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 3 3 %9.0fc 3))
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
DiD regression with all data  
*******************************************************************************/
loc y1 settle
loc y2 dismissed
loc y3 court
loc y4 win
loc y5 relief_scale

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_all' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex, absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Main effects}} \\ \midrule")
		fragment
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mgroups("Settled" "Dismissed" "Court" "Won" "Compensation", pattern(1 0 1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear

	// Victim female **********************************************************/
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex treat_sex_f, absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex treat_sex_f, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
		qui: sum ``y'' if treat_sex == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Complainant is female}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear

	// Overlap cases **********************************************************/
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex if common_file_date < date("$metoo", "DMY"), absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		qui: sum ``y'' if treat_sex ==0 & common_file_date < date("$metoo", "DMY") 
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat_sex if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
		qui: sum ``y'' if treat_sex ==0 & common_file_date < date("$metoo", "DMY") 
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Overlap cases}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
}

/*******************************************************************************
DiD regression - Robustness Check
*******************************************************************************/
loc y1 settle
loc y2 dismissed
loc y3 court
loc y4 win
loc y5 relief_scale

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_robust' == 1 {

	// DID - Single-tagged ****************************************************/
	preserve 
	keep if multi_cat == 0
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Single-tagged cases}} \\ \midrule")
		fragment
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mgroups("Settled" "Dismissed" "Court" "Won" "Compensation", pattern(1 1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
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
		
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{No retaliation cases}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear
	restore

	// DID - Employment *******************************************************/
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	
	preserve 
	keep if juris == "Employment"
	foreach y of local outcome_vars {
				
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 s5 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Employment complaints only}} \\ \midrule")
		fragment
		append
		varlabels(treat_sex "Sex $\times$ Post") keep(treat_sex)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
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
	tab juris, gen(juris_dummy)

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
		win_1
		win_0
		court
		relief_scale 
	// Jurisdiction 
		juris_dummy1 
		juris_dummy2 
		juris_dummy3 
		juris_dummy4 
		juris_dummy5; 
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
		win_1
		win_0
		court
		relief_scale 
	// Jurisdiction 
		juris_dummy1 
		juris_dummy2 
		juris_dummy3 
		juris_dummy4 
		juris_dummy5; 
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
		win_1
		win_0
		court
		relief_scale 
	// Jurisdiction 
		juris_dummy1 
		juris_dummy2 
		juris_dummy3 
		juris_dummy4 
		juris_dummy5; 
	#delimit cr

	#delimit ;
	loc summary_4 // post MeToo
	// Case chars
		sh
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
		win_1
		win_0
		court
		relief_scale 
	// Jurisdiction 
		juris_dummy1 
		juris_dummy2 
		juris_dummy3 
		juris_dummy4 
		juris_dummy5; 
	#delimit cr
	
	eststo mean_all: estpost tabstat `summary_1', c(stat) stat(mean sd)
	eststo mean_sex_cases: estpost tabstat `summary_2' if sex_cases == 1, c(stat) stat(mean sd)
	eststo post_all: estpost ttest `summary_3', by(post)
	eststo post_sex_cases: estpost ttest `summary_4' if sex_cases == 1, by(post)

	#delimit ;
	esttab mean_all mean_sex_cases post_all post_sex_cases using "$tables/summary.tex", replace 
		nonote nonumbers label booktabs f 
		cells("mean(fmt(%13.3fc) pattern(1 1 0 0) vacant(.)) b(star fmt(%13.3fc) pattern (0 0 1 1) vacant(.))"
				"sd(fmt(2) par([ ]) pattern(1 1 0 0) vacant(.)) se(par fmt(%15.2gc) pattern (0 0 1 1) vacant(.))")
		collabels(none)
    	mgroups("\shortstack{Sample\\Statistics}" 
				"\shortstack{Mean Difference\\(Post-Pre) MeToo}", 
			pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    	mtitles("All" "Sex only" "All" "Sex only")
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
			win_1 "\hspace{5mm} Won"
			win_0 "\hspace{5mm} Lost or dismissed"
			court "\hspace{5mm} Went to court" 
			relief_scale "\hspace{5mm} Compensation, 1000s" 
			juris_dummy1 "\textit{Jurisdiction} \\ \hspace{5mm} Education" 
			juris_dummy2 "\hspace{5mm} Employment" 
			juris_dummy3 "\hspace{5mm} Housing" 
			juris_dummy4 "\hspace{5mm} Public Accommodation" 
			juris_dummy5 "\hspace{5mm} Unspecified" 
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
	tab juris, gen(juris_dummy)
	
	la var juris_dummy1 "Education"
	la var juris_dummy2 "Employment"
	la var juris_dummy3 "Housing"
	la var juris_dummy4 "Other"
	la var juris_dummy5 "Public Accommodation"
	la var juris_dummy6 "Unspecified"
	
	loc balance ///
    sex_cases ///
	victim_f ///
	juris_dummy1 ///
	juris_dummy2 ///
	juris_dummy3 ///
	juris_dummy4 ///
	juris_dummy5 ///
	juris_dummy6
	
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

/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
	
	loc balance ///
    sex_cases ///
	basis_dummy1 ///
	basis_dummy2 ///
	basis_dummy3 ///
	basis_dummy4 ///
	basis_dummy5 ///
	basis_dummy6 ///
	basis_dummy7 ///
	basis_dummy8 ///
	basis_dummy9 ///
	juris_dummy1 ///
	juris_dummy2 ///
	juris_dummy3 ///
	juris_dummy4 ///
	juris_dummy5 ///
    settle ///
	court ///
	duration ///
    overlap_2 ///
    relief ///
	missing_relief ///
    win

	preserve 

	// Run overlap_2 on ALL CASES
    balancetable_program `balance', sample(overlap_2 !=.) using("$tables/balance_overlap_2.tex") ctitles("Before" "overlap_2" "Diff" "p-value") wide(mean diff pval) by(overlap_2) errors(robust)

	// Now restrict sample 
    balancetable_program `balance', using("$tables/balance.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

    balancetable_program `balance', sample(sex_cases == 1) using("$tables/balance_sex.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    // Filed pre-covid
    balancetable_program `balance', sample(ym_filed < 721) using("$tables/balance_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	g covid = date("11mar2020", "DMY")
	
    // Resolved pre-covid
    balancetable_program `balance', sample(common_res_date < covid) using("$tables/balance_res_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	restore
}


/*******************************************************************************
Unit trends 
*******************************************************************************/

loc y1 settle
loc y2 win
loc y3 dismissed
	
loc outcome_vars y1 y2 y3

// Same locals as above 
loc j 1

if `run_unit' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat_sex, absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
		eststo u`j'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		qui estadd loc unit_time "\checkmark", replace
				
		loc ++j
	}
	
	#delimit ;	
	estout u1 u2 u3 using "$tables/sdid.tex", style(tex) replace
		varlabels(treat_sex "ATT") keep(treat_sex)
		mgroups("Unit trends", pattern(1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel("Settle" "Win" "Compensation", pattern(1 1 1) 
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


/*******************************************************************************
Synthetic DiD

package sdid from: https://github.com/Daniel-Pailanir/sdid

Y: Outcome variable (numeric)
S: Unit variable (numeric or string)
T: Time variable (numeric)
D: Dummy of treatement, equal to 1 if units are treated, and otherwise 0 (numeric)

, method() // change option to did for DiD and SC for synthetic control
*******************************************************************************/



/* if `run_sdid' == 1 {

	loc time years_to_treat_res
	loc unit basis

	loc i 1 // counter for eststo labeling

	foreach y of loc outcome_vars{
		preserve
			collapse (mean) ``y'', by(`time' `unit')
			drop if `time' == .

			egen `unit'_cat = group(`unit') // can't xtset string var
			xtset `unit'_cat `time' // xtset for panel data
			spbalance, balance // check balance, drop if unbalanced

			g treat_sex = 0 
			replace treat_sex = 1 if `unit' == "Sex" & `time' > 0 

			#delimit ;
			eststo sdid`i': sdid ``y'' `unit' `time' treat_sex,
				vce(placebo) reps(100) seed(123) method(sdid) 
				graph g1on msize(medium)
				g2_opt(xlabel(-8(1)5) xtitle("Time to MeToo", size(medium))) //ytitle("Probability of settlement", size(medium))
				graph_export("$figures/sdid_``y''_", .png); 
		
			#delimit cr
			loc ++i
		restore
	}
} */
