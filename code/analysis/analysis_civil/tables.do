/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_selection = 0
loc run_overlap  = 0
loc	run_did 	 = 1
loc run_did_robust = 0
loc run_victim_f_present = 1
loc run_summary  = 1
loc run_balance  = 0
loc run_duration = 0


/*******************************************************************************
Selection table
*******************************************************************************/

g ln_total = ln(total_cases_per_year)

if `run_selection' == 1 {
	
	eststo: reg total_cases_per_year post, r

	eststo: reg ln_total post, r

	eststo: reg sh_per_year post if sh == 1, r

	eststo: reg sh_f_per_year post if sh == 1 & victim_f == 1, r

	eststo:	reg sh_f_per_year post if sh == 1 & victim_f == 0, r

	eststo:	reg filed_per_year post if sh == 1, r
	
	eststo: reg filed_f_per_year post if sh == 1 & victim_f == 1, r

	eststo:	reg filed_f_per_year post if sh == 1 & victim_f == 0, r
	
	#delimit ;
	
	estout _all using "$tables/selection_table.tex", style(tex) replace
		drop(_cons)
		varlabels(post "Post-MeToo")
		mgroups("Cases filed" "Log cases filed" "SH cases filed" "Female SH cases filed" "Male SH cases filed" "Ratio SH cases filed" "Ratio female SH cases filed" "Ratio male SH cases filed", pattern(1 1 1 1 1 1 1 1) 
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


/*******************************************************************************
overlap_2 regression
*******************************************************************************/

loc y1 settle
loc y2 dismissed
loc y3 win
loc y4 relief_scale

loc outcome_vars y1 y2 y3 y4
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
	esttab est1 est2 est3 est4 using "$tables/overlap_panel.tex", style(tex) replace
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Control: SH complaints filed within 2 years pre-MeToo}} \\ \midrule")
		fragment
		varlabels(overlap_2 "Overlap") keep(overlap_2)
		mgroups("Settled" "Dismissed" "Won" "Compensation", pattern(1 1 1 1) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
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
	esttab est1 est2 est3 est4 using "$tables/overlap_panel.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Control: All SH complaints filed before MeToo}} \\ \midrule")
		fragment
		append
		varlabels(overlap_all "Overlap") keep(overlap_all)
		mlabel(none) nomtitles nonumbers nolines
		stats(N r2 control_mean, label(`"N"' `" \(R^{2}\)"' "Control mean") fmt(%9.0fc 3 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
		
	#delimit cr
	eststo clear
	estimates clear
		
	// Panel C
	foreach y of local outcome_vars {
		eststo: reg ``y'' overlap_all duration if victim_f == 1, r
		qui: sum ``y'' if overlap_all == 0 & victim_f == 1
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}
	
	#delimit ;	
	esttab est1 est2 est3 est4 using "$tables/overlap_panel.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Control: All SH complaints filed by women before MeToo}} \\ \midrule")
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

loc y1 settle
loc y2 dismissed
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
		
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
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
		mgroups("Settled" "Dismissed" "Won" "Compensation", pattern(1 0 1 0 1 0 1 0) 
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
		
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
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
	
	foreach y of local outcome_vars {
		
		reghdfe ``y'' triple_did, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' triple_did, absorb(basis_state ym_state) vce(cluster basis)
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
DiD regression - Robustness Check
*******************************************************************************/

loc y1 settle
loc y2 dismissed
loc y3 win
loc y4 relief_scale

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did_robust' == 1 {

	// DID - Single-tagged ****************************************************/
	preserve 
	keep if multi_cat == 0
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_robust.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Single-tagged cases}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Settled" "Dismissed" "Won" "Compensation", pattern(1 0 1 0 1 0 1 0) 
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

	// DID - No retaliation ***************************************************/
	loc outcome_vars y1 y2 y3 y4
	loc i 1

	preserve 
	drop if basis == "Retaliation"
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{No retaliation cases}} \\ \midrule")
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
	restore

	// DID - Employment *******************************************************/
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	
	preserve 
	keep if juris == "Employment"
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui estadd loc fetime "\checkmark", replace
		
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui estadd loc fetime_s "\checkmark", replace
						
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_robust.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Employment cases}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
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
	restore

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
		
		reghdfe ``y'' triple_did, absorb(basis_state ym_state) vce(cluster basis)
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
Summary table
*******************************************************************************/

if `run_summary' == 1 {

	tab basis, gen(basis_dummy)
	tab juris, gen(juris_dummy)

	// Define local 
	#delimit ;
	loc summary 
	// Case chars
		sh
		victim_f
		post 
		charge_file_year 
		charge_res_year 
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
		dismissed 
		settle
		investigation
		win_investigation
		lose_investigation
		court
		win_court
		lose_court
		unknown_court
		relief_scale 
	// Jurisdiction 
		juris_dummy1 
		juris_dummy2 
		juris_dummy3 
		juris_dummy4 
		juris_dummy5; 
	#delimit cr
	
	eststo mean_all: estpost tabstat `summary', c(stat) stat(mean sd)
	eststo mean_state: estpost tabstat `summary' if eeoc_filed == 0, c(stat) stat(mean sd)
	eststo post_all: estpost ttest `summary', by(post)
	eststo post_sh: estpost ttest `summary' if sh == 1, by(post)

	#delimit ;
	esttab mean_all mean_state post_all post_sh using "$tables/summary.tex", replace 
		nonote nonumbers label booktabs f 
		cells("mean(fmt(%13.3fc)) b(star fmt(%13.3fc))" 
				"sd(fmt(2) par([ ])) se(par fmt(%15.2gc))")
		collabels(none)
    	mgroups("\shortstack{Summary stats\\in sample}" 
				"\shortstack{Difference in means\\pre/post MeToo}", 
			pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    	mtitles("All" "State only" "All" "SH")
			varlab( 
			sh "\textit{Characteristics} \\ \hspace{5mm} Sexual harassment" 
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
			dismissed "\textit{Outcomes} \\ \hspace{5mm} Dismissed" 
			settle "\hspace{5mm} Settled" 
			investigation "\hspace{5mm} Went to investigation" 
			win_investigation "\hspace{10mm} Won at investigation" 
			lose_investigation "\hspace{10mm} Lost at investigation" 
			court "\hspace{5mm} Went to court" 
			win_court "\hspace{10mm} Won in court" 
			lose_court "\hspace{10mm} Lost in court"
			unknown_court "\hspace{10mm} Unknown outcome in court"
			relief_scale "\hspace{5mm} Compensation, 1000s (in court or investigation)" 
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
Balance table
****************************************************************************/

if `run_balance' == 1 {
	
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
