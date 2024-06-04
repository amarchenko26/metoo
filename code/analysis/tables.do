/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc	run_did 	 = 0
loc run_did_all  = 0
loc run_overlap  = 1

loc run_summary  = 0
loc run_balance  = 0
loc run_duration = 0

/*******************************************************************************
Prep vars for tables
*******************************************************************************/
tab juris, gen(juris_dummy)
la var juris_dummy1 "\textbf{Jurisdiction} \\ \hspace{5mm} Employment"
la var juris_dummy2 "\hspace{5mm} Private housing"
la var juris_dummy3 "\hspace{5mm} Public housing"

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
    overlap ///
    relief ///
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
    settle ///
	court ///
	duration ///
    overlap ///
    relief ///
    win


/*******************************************************************************
OVERLAP regression
*******************************************************************************/

loc y1 settle
loc y2 win
loc y3 relief_w

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
	estout _all using "$tables/overlap_panel_a.tex", style(tex) replace
		varlabels(overlap_2 "Overlap" duration "Duration") keep(overlap_2 duration)
		mgroups("Settle" "Win" "Compensation", pattern(1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(N r2 control_mean, 
			label(`"N"' `" \(R^{2}\)"' "Control mean") fmt(%9.0fc 3 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)")
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
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
	estout _all using "$tables/overlap_panel_b.tex", style(tex) replace
		varlabels(overlap_all "Overlap" duration "Duration") keep(overlap_all duration)
		stats(N r2 control_mean, 
			label(`"N"' `" \(R^{2}\)"' "Control mean") fmt(%9.0fc 3 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		mlabel(none)
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	
// 	include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"
// 	panelcombine, use($tables/overlap_panel_b.tex $tables/overlap_panel_a.tex ) columncount(3) paneltitles("Overlap 1" "Overlap 2") save("$tables/did_overlap.tex") cleanup

	eststo clear
	estimates clear
}

	*	refcat(age18 "\emph{Age}" male "\emph{Demographics}" educationage "\emph{Education}" employeddummy "\emph{Employment}" oowner "\emph{Housing}" hhincome_thou "\emph{Household Finances}" reduntant "\emph{Income and Expenditure Risk}" literacyscore "\emph{Behavioural Characteristics}", nolabel) ///

	
/*******************************************************************************
DiD regression
*******************************************************************************/

loc y1 filed_per_year
loc y2 settle
loc y3 win
loc y4 relief_w

loc outcome_vars y1 y2 y3 y4
loc i 1

g unit_state = basis * state_cat
g time_state = ym * state_cat

if `run_did_all' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "Yes", replace
		qui estadd loc fetime_s "Yes", replace
						
		loc ++i
	}

	#delimit ;	
	estout a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_all.tex", style(tex) replace
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Filed per year" "Settle" "Win" "Compensation", pattern(1 0 1 0 1 0 1  0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
	eststo clear
}

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did' == 1 {

	preserve 
	keep if eeoc_filed == 0

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis ym) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "Yes", replace
		qui estadd loc fetime_s "Yes", replace
						
		loc ++i
	}

	#delimit ;	
	estout a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did.tex", style(tex) replace
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Filed per year" "Settle" "Win" "Compensation", pattern(1 0 1 0 1 0 1  0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(feunit fetime feunit_s fetime_s N r2, 
			label("Case FE" "Time FE" "Case $\times$ State FE" "Time $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
	eststo clear
	restore
}

drop time_state unit_state


/*
mgroups("\shortstack{Income from \\ non ag wages}" ///
"\shortstack{Income from \\ NREGA}" ///
"\shortstack{Income from \\ non-NREGA \\ non ag wage}" ///
"\shortstack{Income from \\ wage & salary}" ///
"\shortstack{Income from \\ HH businesses}" ///
"\shortstack{All Income}" "HH Cons" "\shortstack{Current HH \\ debt}" ///
, pattern(1 1 1 1 1 1 1 1) ///
span) ///

*/



/*******************************************************************************
Summary
*******************************************************************************/
if `run_summary' == 1 {

	preserve
	keep if eeoc_filed == 0
	
	tabstat post `summary', c(stat) stat(mean sd min max n)

	esttab using "$tables/summary.tex", replace ///
		nomtitle nonote noobs label booktabs f ///
		cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(a2)) max(fmt(a2)) count(fmt(a2))") ///
		collabels("Mean" "SD" "Min" "Max" "N")
	restore
	eststo clear

}


/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
	
	preserve 

	// Run overlap on ALL CASES
    balancetable_program `balance', sample(overlap !=.) using("$tables/balance_overlap.tex") ctitles("Before" "Overlap" "Diff" "p-value") wide(mean diff pval) by(overlap) errors(robust)

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

	preserve 
	keep if eeoc_filed == 0

	eststo: reg duration i.win, r

	eststo: reg duration i.win if sh == 1, r

	eststo:	reg duration i.win if sex_cases == 1, r

	eststo:	reg duration relief_w, r

	eststo:	reg duration relief_w if sh == 1, r

	eststo:	reg duration relief_w if sex_cases == 1, r
		
	#delimit ;
	
	estout _all using "$tables/duration_corr.tex", style(tex) replace
		drop(_cons)
		varlabels(relief_w "Compensation" 1.win "Win")
		mgroups("Duration", pattern(1 0 0 0 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel("All" "SH" "Sex" "All" "SH" "Sex")
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
	eststo clear
	restore
}
