/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

use "$clean_data/clean_criminal_cases.dta", replace

loc run_did  = 1

loc run_summary  = 1
loc run_balance  = 1
loc run_duration = 1

/*******************************************************************************
Prep vars for tables
*******************************************************************************/
tab crime_type, gen(crime_type_dummy)
la var crime_type_dummy1 "\textbf{Crime Type} \\ \hspace{5mm} Excluded crime"
la var crime_type_dummy2 "\hspace{5mm} Non-sex crime"
la var crime_type_dummy3 "\hspace{5mm} Sexual assault"
la var crime_type_dummy4 "\hspace{5mm} Sexual harassment"


/*******************************************************************************
Define locals 
*******************************************************************************/

loc summary ///
	crime_type_dummy1 ///
	crime_type_dummy2 ///
	crime_type_dummy3 ///
	crime_type_dummy4 ///
    report_year ///
    clear_year ///
	clearance ///
    court ///
    duration


loc balance ///
	sex_cases ///
    sh ///
	crime_type_dummy1 ///
	crime_type_dummy2 ///
	crime_type_dummy3 ///
	crime_type_dummy4 ///
	court ///
	duration

	
/*******************************************************************************
DiD regression
*******************************************************************************/

loc y1 filed_per_year
loc y2 clearance
loc y3 court

loc outcome_vars y1 y2 y3
loc i 1

g time_city = ym * city_cat

if `run_did' == 1 {

	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(ym) vce(robust)
		eststo a`i'
		qui estadd loc fetime "Yes", replace
		
		reghdfe ``y'' treat, absorb(time_city) vce(robust)
		eststo s`i'
		qui estadd loc fetime_c "Yes", replace
						
		loc ++i
	}

	#delimit ;	
	estout a1 s1 a2 s2 a3 s3 using "$tables/did_criminal.tex", style(tex) replace
		varlabels(treat "Sex Cases $\times$ Post") keep(treat)
		mgroups("Filed per year" "Clearance" "Arrest", pattern(1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(fetime fetime_c N r2, 
			label("Time FE" "Time $\times$ City FE" `"N"' `" \(R^{2}\)"') fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;
	#delimit cr
	estimates clear
	eststo clear
}

drop time_city


/*******************************************************************************
Summary
*******************************************************************************/
if `run_summary' == 1 {

	estpost tabstat post `summary', c(stat) stat(mean sd min max n)

	esttab using "$tables/summary_criminal.tex", replace ///
		nomtitle nonote noobs label booktabs f ///
		cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(a2)) max(fmt(a2)) count(fmt(a2))") ///
		collabels("Mean" "SD" "Min" "Max" "N")

}


/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {

    balancetable_program `balance', using("$tables/balance_criminal.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    balancetable_program `balance', sample(sex_cases == 1) using("$tables/balance_sex_criminal.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    // Filed pre-covid
    balancetable_program `balance', sample(ym < 721) using("$tables/balance_covid_criminal.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

}

