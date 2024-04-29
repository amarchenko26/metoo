/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_summary = 1
loc run_balance = 1
loc run_duration = 1
loc	run_did = 1
loc run_overlap = 1

/*******************************************************************************
Prep vars for tables
*******************************************************************************/

tab state, gen(state_dummy)
ren state_dummy1 federal
ren state_dummy2 MA

la var federal "\textbf{Jurisdiction} \\ \hspace{5mm} Federal"
la var MA "\hspace{5mm} Massachusetts"

tab juris, gen(juris_dummy)
la var juris_dummy1 "\hspace{5mm} Employment"
la var juris_dummy2 "\hspace{5mm} Private housing"
la var juris_dummy3 "\hspace{5mm} Public housing"

tab basis_clean, gen(basis_dummy)
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
    sex_cases ///
		federal ///
        MA ///
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
    probable_cause


loc balance ///
    sh ///
    sex_cases ///
		federal ///
        MA ///
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
    settle ///
	court ///
	duration ///
    overlap ///
    relief ///
    probable_cause

/*******************************************************************************
Summary
*******************************************************************************/
if `run_summary' == 1 {

	est clear
	estpost tabstat post `summary', c(stat) stat(mean sd min max n)

	esttab using "$tables/summary.tex", replace ///
		nomtitle nonote noobs label booktabs f ///
		cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(a2)) max(fmt(a2)) count(fmt(a2))") ///
		collabels("Mean" "SD" "Min" "Max" "N")
}

/*******************************************************************************
Balance table
*******************************************************************************/
capture program drop balancetable_program
program define balancetable_program
    syntax [anything] [, using(string) sample(string) ctitles(string) wide(string) by(string) errors(string)]

    balancetable `by' `anything' ///
        using "`using'", ///
        varlabels vce(`errors') replace ///
        ctitles(`ctitles') ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(`wide')
        if `"`sample'"' != "" {
            balancetable `by' `anything' if `sample' ///
                using "`using'", ///
                varlabels vce(`errors') replace ///
                ctitles(`ctitles') ///
                pvalues staraux pval(nopar) format(%9.2f) ///
                wide(`wide')
        }
end

/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
    balancetable_program `balance', using("$tables/balance.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis_clean)

    balancetable_program `balance', sample(sh == 1) using("$tables/balance_sex.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    // Filed pre-covid
    balancetable_program `balance', sample(ym < 721) using("$tables/balance_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis_clean)

	g covid = date("11mar2020", "DMY")
	
    // Resolved pre-covid
    balancetable_program `balance', sample(common_res_date < covid) using("$tables/balance_res_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis_clean)

	drop covid 
	
	// overlap case characteristics
    balancetable_program `balance', using("$tables/balance_overlap.tex") ctitles("Before" "Overlap" "Diff" "p-value") wide(mean diff pval) by(overlap) errors(robust)
}


/*******************************************************************************
Correlation b/w duration and outcomes
*******************************************************************************/
if `run_duration' == 1 {

	reg duration relief_scale, r
		eststo A

	reg duration relief_scale if sh == 1, r
		eststo B

	reg duration relief_scale if sex_cases == 1, r
		eststo C

	reg duration i.probable_cause, r
		eststo D

	reg duration i.probable_cause if sh == 1, r
		eststo E

	reg duration i.probable_cause if sex_cases == 1, r
		eststo F
		
	#delimit ;
	
	estout D E F A B C using "$tables/duration_corr.tex", style(tex) replace
		drop(_cons)
		varlabels(relief_scale "Compensation" 1.probable_cause "Probable cause")
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
}


/*******************************************************************************
DiD regression
*******************************************************************************/

loc y1 filed_per_year
loc y2 settle
loc y3 probable_cause
loc y4 relief_scale

loc outcome_vars y1 y2 y3 y4
loc i 1

encode state, g(state_cat)
encode basis_clean, g(basis_cat)
g unit_state = basis_clean * state_cat
g time_state = ym * state_cat

if `run_did' == 1 {

	foreach y of local outcome_vars {
		
		// Outcome `y'
		reghdfe ``y'' treat, absorb(basis_clean ym) vce(cluster basis_clean)
		eststo a`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace
		
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis_clean)
		eststo s`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "Yes", replace
				
		loc ++i
	}

	#delimit ;
	
	estout a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did.tex", style(tex) replace
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Filed per year" "Settled" "P(win)" "Compensation", pattern(1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(feunit fetime festate N r2, 
			label("Case type FE" "Time FE" "State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
	
}


/*******************************************************************************
OVERLAP regression
*******************************************************************************/

loc i 1

if `run_overlap' == 1 {

	foreach y of local outcome_vars {
		
		// Outcome `y'
		reg ``y'' overlap, r
		eststo a`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace
		
		reg ``y'' overlap duration, r
		eststo s`i'
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "Yes", replace
				
		loc ++i
	}
	
	#delimit ;
	
	estout a1 s1 a2 s2 a3 s3 a4 s4 using "$tables/did_overlap.tex", style(tex) replace
		varlabels(overlap "Overlap") keep(overlap)
		mgroups("Filed per year" "Settled" "P(win)" "Compensation", pattern(1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(N r2, 
			label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
}
