/*******************************************************************************
Tables for MeToo project 
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_did		 	= 0
loc run_did_win	 	= 0
loc run_did_outcomes = 1
loc run_overlap		= 0
loc run_overlap_win	= 0
loc overlap_placebo = 0
loc run_overlap_winter = 0
loc run_did_sex	 	= 0
loc run_did_robust 	= 0
loc run_did_alljuris = 0
loc run_summary  	= 0
loc run_overlap_balance = 0
loc run_duration 	= 0
loc run_unit   		= 0


/*******************************************************************************
Win-only Main DID 
*******************************************************************************/

if `run_did_win' == 1 {
	preserve 
	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s1
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s2
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
	eststo s3
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\cmidrule(lr){2-2} \cmidrule(lr){3-4}"
				"& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Triple Diff} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
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
Other Outcomes DID 
*******************************************************************************/
loc y1 dismissed
loc y2 settle
loc y3 court

loc outcome_vars y1 y2 y3
loc i 1

if `run_did_outcomes' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
		loc ++i
		
		reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
		loc ++i
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
		loc ++i	
		
	}		
		

	#delimit ;	
	esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$tables/did_outcomes.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{}" 
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}"
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}" 
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
	"\cmidrule(lr){2-2} \cmidrule(lr){3-4}"
    "\cmidrule(lr){5-5} \cmidrule(lr){6-7}"
    "\cmidrule(lr){8-8} \cmidrule(lr){9-10}"
	"& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Triple Diff}" 
	"& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Triple Diff}" 
	"& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Triple Diff} \\" 
	"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mgroups("Dismissed" "Settled" "Court", pattern(1 0 0 1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
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
Win-only Overlap DID 
*******************************************************************************/

if `run_overlap_win' == 1 {

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s1
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . &  common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s2
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
	eststo s3
	qui estadd loc feunit_s "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\cmidrule(lr){2-2} \cmidrule(lr){3-4}"
				"& \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{TWFE} & \multicolumn{1}{c}{Triple Diff} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
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
	
	
	loc y1 win 
	loc y2 dismissed
	loc y3 settle
	loc y4 court

	loc outcome_vars y1 y2 y3 y4 
	loc i 1
	
	preserve 
	drop if file_season == 2 // drop summer 

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_overlap_summer.tex", style(tex) replace 
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
	esttab s1 s2 s3 s4 using "$tables/did_overlap_summer.tex", style(tex)
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

if `run_did_robust' == 1 {

	// Single-tagged 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s1
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Drop retaliation 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s2
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Filed before covid 
	preserve 
		keep if ym_filed < 722
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s3
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_robust_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule")
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
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



