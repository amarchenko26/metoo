/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_summary  		 = 0
loc run_did_win	 		 = 0
loc run_overlap_win		 = 0
loc run_did_outcomes 	 = 0
loc run_overlap_balance  = 0
loc run_did_robust 		 = 0
loc FE_robust            = 0
loc run_placebo			 = 0 
loc run_did_ct			 = 0
loc run_did_alljuris 	 = 0
loc run_employer_het	 = 0
loc run_overlap_duration = 0 


/*******************************************************************************
Summary table: Complaint characteristics
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
		court; 
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
		court; 
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
		court;
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
		court; 
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
		) 
		substitute("\$" "$")
		stats(N, layout("@ @" "@ @") labels("Observations") fmt("%15.0fc %15.0fc" "%15.0fc %15.0fc"))
	;
	#delimit cr
	
}

*stats(N1 N2 p_joint, layout("@ @" ". @") labels("Observations" "Joint \textit{p}-value" ) fmt("%15.0fc %15.0fc" 2 2))	///



/*******************************************************************************
Win-only Main DID: Effect of #MeToo on likelihood complainant wins sexual 
				   harassment case 
*******************************************************************************/

if `run_did_win' == 1 {
	preserve 
	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
 	esttab s1 s2 s3 using "$tables/did_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\"  
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
Win-only Overlap DID: Effect of #MeToo on likelihood complainant wins 
					  sexual harassment case in overlap sample
*******************************************************************************/

if `run_overlap_win' == 1 {

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}


/*******************************************************************************
Other Outcomes DID: Effects of #MeToo on All Complaint Outcomes
*******************************************************************************/
loc y1 settle
loc y2 court

loc outcome_vars y1 y2
loc i 1

if `run_did_outcomes' == 1 {
	preserve 
	foreach y of local outcome_vars {
        
        reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0 & victim_f != .
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui estadd loc ut_f "\checkmark", replace
        qui: sum ``y'' if treat_f == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i
    
    }

    #delimit ;    
    esttab s1 s2 s3 s4 s5 s6 using "$tables/did_outcomes.tex", style(tex) replace 
        prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
        posthead("\multicolumn{1}{c}{} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
        "\midrule")
        varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
        mgroups("Settled" "Court", pattern(1 0 0 1 0 0) 
            prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
        mlabel(none) nomtitles nonumbers
        stats(ut ut_f N r2 control_mean, 
            label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
        nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
        cells("b(fmt(3)star)" "se(fmt(3)par)") 
        prefoot("\\" "\midrule") 
        postfoot("\bottomrule" "\end{tabular}");

    #delimit cr
    estimates clear
    eststo clear

    restore
}


/****************************************************************************
Overlap balance table: Comparison of actual overlap cases (2017) versus 
					   placebo overlap cases (2016)
****************************************************************************/

if `run_overlap_balance' == 1 {

	preserve	
		
	tab file_season, gen(season)
	la var season1 "\hspace{0.1cm} Filed in Spring"
	la var season2 "\hspace{0.1cm} Filed in Summer"
	la var season3 "\hspace{0.1cm} Filed in Fall"
	la var season4 "\hspace{0.1cm} Filed in Winter"
	
	loc balance ///
	victim_f ///
    sh ///
	season1 ///
	season2 ///
	season3 ///
	season4
	
	g overlap_balance = 1 if overlap_2 == 1
	replace overlap_balance = 0 if common_file_date < 20742 & common_res_date > 20742 
// 	replace overlap_balance = . if common_file_date < 20377 & overlap_balance == 0
// 	replace overlap_balance = . if common_res_date > 21107 & overlap_balance == 0
	
    balancetable overlap_balance `balance' using "$tables/overlap_balance.tex" if overlap_balance != ., ///
        varlabels vce(robust) replace ///
        ctitles("2016" "2017" "Diff" "p-value") ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(mean diff pval)
	restore
}


/*******************************************************************************
DiD regression - Robustness Check: Robustness of \hat{β}^{CE} across
								   different samples and control groups
*******************************************************************************/

if `run_did_robust' == 1 {

// Single-tagged

	// (1) all complaints 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if multi_cat == 0
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	


// Drop retaliation 

	// (1) all complaints 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s4
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s5
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s6
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

// Filed before covid 

	// (1) all complaints
	preserve 
		keep if ym_filed < 722
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s7
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s8
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if ym_filed < 722
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s9
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

	#delimit ;	
	esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$tables/did_robust_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("\multicolumn{1}{c}{} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}" ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
	"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 0 0 1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE"  `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	
	
	
/*******************************************************************************
DiD regression - Robustness Check: Robustness of \hat{β}^{O} across 
								   different samples and control groups
*******************************************************************************/
	

// Single-tagged

	// (1) all complaints 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if multi_cat == 0
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	


// Drop retaliation 

	// (1) all complaints 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s4
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s5
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s6
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

// Filed before covid 

	// (1) all complaints
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s7
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s8
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if ym_filed < 722
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s9
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

	#delimit ;	
	esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$tables/did_robust_win_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("\multicolumn{1}{c}{} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}" ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
	"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 0 0 1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean,
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear

}


/*******************************************************************************
Filing FE Robustness Check: Robustness of main results to using complaint 
							filing fixed effects 
*******************************************************************************/

if `FE_robust' == 1 {

	// CE
	reghdfe win treat, absorb(basis_state ym_filed_state) vce(cluster basis_state)

	// Overlap
	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_filed_state) vce(cluster basis_state)

	// Gender CE
	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_filed##state_cat##victim_f) vce(cluster basis_state)

	lincom treat+treat_f

	// Gender Overlap
	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_filed##state_cat##victim_f) vce(cluster basis_state)

	lincom treat+treat_f

}



/*******************************************************************************
Permutation test Robustness Check: Permutation Test 
*******************************************************************************/

if `run_placebo' == 1 {

	g age_treat = (basis =="Age" & post==1)

	g disability_treat = (basis =="Disability" & post==1)

	g nat_treat = (basis =="Nationality" & post==1)

	g race_treat = (basis =="Race" & post==1)

	g rel_treat = (basis =="Religion" & post==1)

	g retal_treat = (basis =="Retaliation" & post==1)


	reghdfe win age_treat if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
	reghdfe win disability_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
	reghdfe win nat_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
	reghdfe win race_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
	reghdfe win rel_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
	reghdfe win retal_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)

}



/*******************************************************************************
CT DID: \hat{β}^{CE} including Connecticut complaints
*******************************************************************************/

if `run_did_ct' == 1 {
	preserve 
	use "$clean_data/clean_cases_w_ct.dta", replace

	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_ct.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	restore
	
	
/*******************************************************************************
CT DID: \hat{β}^{O} including Connecticut complaints
*******************************************************************************/

	preserve 
	use "$clean_data/clean_cases_w_ct.dta", replace

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_ct_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
All jurisdiction DID: \hat{β}^{CE}$ pooling housing, public accommodations, 
					  education, and employment complaints 
*******************************************************************************/

if `run_did_alljuris' == 1 {
	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace

	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_alljuris.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	restore
	
	
/*******************************************************************************
All jurisdiction DID: \hat{β}^{O}$ pooling housing, public accommodations, 
					  education, and employment complaints 
*******************************************************************************/

	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_alljuris_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
Employer Analysis: \hat{β}^{CE}$ by employer characteristics
*******************************************************************************/

***  Heterogeneous Effects by Fortune 500 ***

if `run_employer_het' == 1 {

	preserve
	use "$clean_data/clean_cases_w_employer.dta", replace
	
	/*******************************************************************************
	Full Sample - Employer Heterogeneity (Fortune 500 + Male-dominated)
	*******************************************************************************/

	* === FULL SAMPLE: Fortune 500 ===
	* Model 1: All complaints
	reghdfe win treat if fortune_500 == 1, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & fortune_500 == 1
	estadd scalar control_mean = `r(mean)'

	* Model 2: With gender
	reghdfe win treat if fortune_500 == 1 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & fortune_500 == 1 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	* Model 3: Gender triple diff
	reghdfe win treat treat_f if fortune_500 == 1, ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0 & fortune_500 == 1
	estadd scalar control_mean = `r(mean)'

	* === FULL SAMPLE: Male-dominated ===
	* Model 1: All complaints
	reghdfe win treat if male_dominated == 1, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo m1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & male_dominated == 1
	estadd scalar control_mean = `r(mean)'

	* Model 2: With gender
	reghdfe win treat if male_dominated == 1 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo m2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & male_dominated == 1 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	* Model 3: Gender triple diff
	reghdfe win treat treat_f if male_dominated == 1, ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo m3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0 & male_dominated == 1
	estadd scalar control_mean = `r(mean)'

	* Export full sample table
	#delimit ;
	esttab s1 s2 s3 m1 m2 m3 using "$tables/did_employer_het_full.tex", style(tex) replace
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} & \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") ///
		keep(treat treat_f)
		mgroups("Fortune 500 Company" "Male-dominated Industry", pattern(1 0 0 1 0 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean,
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3 3))
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
Duration Overlap DID: \hat{β}^{O} for case duration
*******************************************************************************/

if `run_overlap_duration' == 1 {

	reghdfe duration treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum duration if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_duration.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}
