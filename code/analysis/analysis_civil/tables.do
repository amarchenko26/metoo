/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_overlap  = 1
loc	run_did 	 = 0
loc run_victim_f_present = 0

loc run_summary  = 0
loc run_balance  = 0
loc run_duration = 0


/*******************************************************************************
overlap_2 regression
*******************************************************************************/

loc y1 settle
loc y2 win
loc y3 relief_scale

loc outcome_vars y1 y2 y3
loc i 1

if `run_overlap' == 1 {
	
	// Panel A
	foreach y of local outcome_vars {
		eststo: reg ``y'' overlap_2 duration, r
		qui: sum ``y'' if overlap_2 == 0
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}
	
	#delimit ;
	esttab est1 est2 est3 using "$tables/overlap_panel.tex", style(tex) replace
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: 2 Years Pre-MeToo}} \\ \midrule")
		fragment
		varlabels(overlap_2 "Overlap") keep(overlap_2)
		mgroups("Settled" "Won" "Compensation", pattern(1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(N r2 control_mean, label(`"N"' `" \(R^{2}\)"' "Control mean") fmt(%9.0fc 3 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)")
		prefoot("\\" "\midrule");
		
	#delimit cr
	eststo clear
	estimates clear
	
	// Panel B
	foreach y of local outcome_vars {
		eststo: reg ``y'' overlap_all duration, r
		qui: sum ``y'' if overlap_all == 0
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}
	
	#delimit ;	
	esttab est1 est2 est3 using "$tables/overlap_panel.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: All Pre-MeToo}} \\ \midrule")
		fragment
		append
		varlabels(overlap_all "Overlap") keep(overlap_all)
		mlabel(none) nomtitles nonumbers nolines
		stats(N r2 control_mean, label(`"N"' `" \(R^{2}\)"' "Control mean") fmt(%9.0fc 3 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	eststo clear
	estimates clear

}

	
/*******************************************************************************
DiD regression
*******************************************************************************/

loc y1 filed_per_year
loc y2 settle
loc y3 win
loc y4 relief_scale

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did' == 1 {

	// DID - No EEOC data **********************************************************/
	preserve 
	keep if eeoc_filed == 0
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;	
	//use esttab not estout, estout has no fragment option
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Estimation sample}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Filed" "Settled" "Won" "Compensation", pattern(1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	restore

	// DID - All data ************************************************************/
	loc outcome_vars y1 y2 y3 y4
	loc i 1

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{All cases}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear

	// Victim female **********************************************************/
	loc outcome_vars y1 y2 y3 y4
	loc i 1

	g triple_did = victim_f * treat
	
	foreach y of local outcome_vars {
		
		reghdfe ``y'' triple_did, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' triple_did, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;	// DID - All data
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Complainant is female}} \\ \midrule")
		fragment
		append
		varlabels(triple_did "Female $\times$ SH $\times$ Post") keep(triple_did)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear

}

/*******************************************************************************
Victim female regression - for presentations only, not in paper, generates 
3rd panel of did.tex but separately
*******************************************************************************/

if `run_victim_f_present' == 1 {

	loc outcome_vars y1 y2 y3 y4
	loc i 1

	foreach y of local outcome_vars {
		
		reghdfe ``y'' triple_did, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		
		reghdfe ``y'' triple_did, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "Yes", replace
		qui estadd loc fetime_s "Yes", replace
						
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_f.tex", style(tex) replace
		coeflabel(triple_did "Female $\times$ SH $\times$ Post") keep(triple_did)
		mgroups("Filed" "Settled" "Won" "\($\) paid", pattern(1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)")
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	eststo clear
	estimates clear
}


/*******************************************************************************
Prep vars for tables
*******************************************************************************/
tab juris, gen(juris_dummy)
la var juris_dummy1 "\textbf{Jurisdiction} \\ \hspace{5mm} Education"
la var juris_dummy2 "\hspace{5mm} Employment"
la var juris_dummy3 "\hspace{5mm} Housing"
la var juris_dummy4 "\hspace{5mm} Public Accommodation"
la var juris_dummy5 "\hspace{5mm} Unspecified"

tab basis, gen(basis_dummy)
la var basis_dummy1 "\textbf{Case type} \\ \hspace{5mm} Age"
la var basis_dummy2 "\hspace{5mm} Disability"
la var basis_dummy3 "\hspace{5mm} LGBTQ"
la var basis_dummy4 "\hspace{5mm} Nationality"
la var basis_dummy5 "\hspace{5mm} Other"
la var basis_dummy6 "\hspace{5mm} Race"
la var basis_dummy7 "\hspace{5mm} Religion"
la var basis_dummy8 "\hspace{5mm} Retaliation"
la var basis_dummy9 "\hspace{5mm} Sex"


/*******************************************************************************
Define locals 
*******************************************************************************/

loc summary ///
    sh ///
	juris_dummy1 ///
	juris_dummy2 ///
	juris_dummy3 ///
	juris_dummy4 ///
	juris_dummy5 ///
	basis_dummy1 ///
	basis_dummy2 ///
	basis_dummy3 ///
	basis_dummy4 ///
	basis_dummy5 ///
	basis_dummy6 ///
	basis_dummy7 ///
	basis_dummy8 ///
	basis_dummy9 ///
    charge_file_year ///
    charge_res_year ///
	settle ///
    court ///
    court_file_year ///
    court_res_year ///
    duration ///
    overlap_2 ///
    relief ///
	missing_relief ///
    win


loc balance ///
    sh ///
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



/*******************************************************************************
Summary
*******************************************************************************/
if `run_summary' == 1 {

	preserve
	*keep if eeoc_filed == 0
	
	estpost tabstat post `summary', c(stat) stat(mean sd min max n)

	esttab using "$tables/summary.tex", replace ///
		nomtitle nonote noobs label booktabs f ///
		cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(a2)) max(fmt(a2)) count(fmt(a2))") ///
		collabels("Mean" "SD" "Min" "Max" "N")
	restore

}


/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
	
	preserve 

	// Run overlap_2 on ALL CASES
    balancetable_program `balance', sample(overlap_2 !=.) using("$tables/balance_overlap_2.tex") ctitles("Before" "overlap_2" "Diff" "p-value") wide(mean diff pval) by(overlap_2) errors(robust)

	// Now restrict sample 
	keep if eeoc_filed == 0

    balancetable_program `balance', using("$tables/balance.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

    balancetable_program `balance', sample(sh == 1) using("$tables/balance_sex.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    // Filed pre-covid
    balancetable_program `balance', sample(ym < 721) using("$tables/balance_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	g covid = date("11mar2020", "DMY")
	
    // Resolved pre-covid
    balancetable_program `balance', sample(common_res_date < covid) using("$tables/balance_res_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	restore
}


/*******************************************************************************
Correlation b/w duration and outcomes
*******************************************************************************/
if `run_duration' == 1 {

	eststo: reg settle duration, r

	eststo: reg settle duration if sh == 1, r

	eststo: reg win duration, r

	eststo: reg win duration if sh == 1, r

	eststo:	reg relief_scale duration, r

	eststo:	reg relief_scale duration if sh == 1, r

	#delimit ;
	
	estout _all using "$tables/duration_corr.tex", style(tex) replace
		drop(_cons)
		varlabels(duration "Duration")
		mgroups("Settle" "Win" "Compensation", pattern(1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
	eststo clear
}
