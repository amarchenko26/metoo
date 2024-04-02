/*******************************************************************************

Tables for MeToo project

*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Clean data for tables
*******************************************************************************/

tab state, gen(state_dummy)
ren state_dummy1 federal
ren state_dummy2 MA

la var federal "Federal case"
la var MA "MA case"

/*******************************************************************************
Balancetable
*******************************************************************************/

loc balance ///
	sh sex_cases ///
	federal MA ///
	charge_file_year charge_res_year ///
	court_file_year court_res_year ///
	duration ///
	relief missing_relief /// 
	went_to_court
	
format relief %10.0fc
format sh sex_cases %4.3f


balancetable treat `balance' ///
	using "/Users/anyamarchenko/Documents/GitHub/metoo/output/tables/balance.tex", ///
	varlabels vce(robust) replace ///
	ctitles("Before MeToo" "After MeToo" "Diff" "p-value") ///
	pvalues staraux pval(nopar) format(%9.2f) ///
	wide(mean diff pval)	


// Pre-covid
preserve
drop if ym > 721 // if after Feb 2020

balancetable treat `balance' ///
	using "/Users/anyamarchenko/Documents/GitHub/metoo/output/tables/balance_covid.tex", ///
	varlabels vce(robust) replace ///
	ctitles("Before MeToo" "After MeToo" "Diff" "p-value") ///
	pvalues staraux pval(nopar) format(%9.2f) ///
	wide(mean diff pval)	
restore


/*******************************************************************************
Summary
*******************************************************************************/

est clear 
estpost tabstat treat `balance', c(stat) stat(mean min max n)

esttab using "$tables/summary.tex", replace ///
	nomtitle nonote noobs label booktabs f ///
	cells("mean(fmt(%13.2fc)) min max count") ///
	collabels("Mean" "Min" "Max" "N")
	
/*******************************************************************************
Regression
*******************************************************************************/

reg relief i.treat##i.sh, r

	
	
	
	
	
	
	
	
