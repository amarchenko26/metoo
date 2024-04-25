/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_summary = 0
loc run_balance = 0
loc run_duration = 0
loc	run_did = 1

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
    went_to_court ///
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
    went_to_court ///
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

	estout D E F A B C using "$tables/duration_corr.tex", style(tex) replace ///
		nobaselevels ///
		eqlabels(none) collabels(none) mlabel(none) ///
		label varlabels(relief_scale "Compensation (in \$1000s)" 1.probable_cause "Probable cause" _cons "Constant") ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") starlevels(* .1 ** .05 *** .01) ///
		stats(N r2, labels(`"Observations"' `" \(R^{2}\)"') fmt(%9.0fc 3 3)) ///
		prehead("\begin{tabular}{l*{@E}{c}}" ///
		"\toprule" ///
		"\multicolumn{1}{l}{\texbf{Outcome: Duration}}  & \multicolumn{1}{c}{All} & \multicolumn{1}{c}{SH} & \multicolumn{1}{c}{Sex-related} & \multicolumn{1}{c}{All} & \multicolumn{1}{c}{SH} & \multicolumn{1}{c}{Sex-related}\\") ///
		posthead("\midrule") ///
		prefoot("\\" "\midrule" "\multicolumn{1}{c}{}\\") ///
		postfoot("\bottomrule" "\end{tabular}")

	estimates clear
}

eststo clear


/*******************************************************************************
DiD regression
*******************************************************************************/
loc outcome1 relief_scale 
loc outcome2 probable_cause 

if `run_did' == 1 {

	// outcome 1
	reg `outcome1' treat, vce(robust)
		eststo A
		qui estadd loc feunit "No", replace
		qui estadd loc fetime "No", replace
		qui estadd loc festate "No", replace
		
	reghdfe `outcome1' treat, 						  absorb(basis_clean ym) vce(cluster basis_clean)
		eststo B
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace


	reghdfe `outcome1' treat if juris == "Employment", absorb(basis_clean ym) vce(cluster basis_clean)
		eststo C
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace


	reghdfe `outcome1' treat, 						  absorb(basis_clean ym state) vce(cluster basis_clean)
		eststo D
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "Yes", replace

		
	// Outcome 2
	reg `outcome2' treat, vce(robust)
		eststo E
		qui estadd loc feunit "No", replace
		qui estadd loc fetime "No", replace
		qui estadd loc festate "No", replace

	
	reghdfe `outcome2' treat, 						  absorb(basis_clean ym) vce(cluster basis_clean)
		eststo F
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace

	reghdfe `outcome2' treat if juris == "Employment", absorb(basis_clean ym) vce(cluster basis_clean)
		eststo G
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "No", replace

	reghdfe `outcome2' treat, 						  absorb(basis_clean ym state) vce(cluster basis_clean)
		eststo H
		qui estadd loc feunit "Yes", replace
		qui estadd loc fetime "Yes", replace
		qui estadd loc festate "Yes", replace
			
	#delimit ;
	
	estout A B C D E F G H using "$tables/did.tex", style(tex) replace
		varlabels(treat "SH $\times$ Post" _cons "Constant")
		mgroups("Compensation" "Probability of win", pattern(0 0 0 0 1 0 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel("All" "All" "Employment" "All" "All" "All" "Employment" "All")
		stats(feunit fetime festate N r2, 
			label("Case type FE" "Time FE" "State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule") 
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
		
	estimates clear
	
}


loc outcome1 probable_cause 
loc outcome2 relief_scale 

if `run_did' == 1 {

	// outcome 1
	reg `outcome1' treat, vce(robust)
		eststo A

	reghdfe `outcome1' treat, 						  absorb(basis_clean ym) vce(cluster basis_clean)
		eststo B

	reg `outcome1' overlap, 		  vce(robust)
		eststo C
		
	// Outcome 2
	reg `outcome2' treat, vce(robust)
		eststo D
	
	reghdfe `outcome2' treat, 						  absorb(basis_clean ym) vce(cluster basis_clean)
		eststo E

	reg `outcome2' overlap, 		  vce(robust)
		eststo F
		
	estout A B C D E F using "$tables/did_present.tex", style(tex) replace ///
		nobaselevels ///
		eqlabels(none) collabels(none) mlabel(none) ///
		label varlabels(treat "SH $\times$ Post" overlap "Overlap") drop(_cons) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") starlevels(* .1 ** .05 *** .01) ///
		stats(N r2, labels(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3 3)) ///
		prehead("\begin{tabular}{l*{@E}{c}}" ///
		"\toprule" ///
		"\multicolumn{1}{l}{} & \multicolumn{3}{c}{|--- \textbf{Outcome: P(win)} ---|} & \multicolumn{3}{c}{|--  \textbf{Outcome: Compensation} ---|}\\") ///
		posthead("\midrule") ///
		prefoot("\\" "\midrule" "\multicolumn{1}{l}{Time FE} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} \\" ///
		"\multicolumn{1}{l}{Basis FE} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{No} & \multicolumn{1}{c}{Yes} & \multicolumn{1}{c}{No}\\" ///
		"\midrule") ///
		postfoot("\bottomrule" "\end{tabular}") 

		estimates clear
}
