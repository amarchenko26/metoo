/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Prep data for plotting
*******************************************************************************/

drop if ym < 606 //drop cases before Jan 2010
gen y = 1 // index var

di tm(2017m10) // di numeric value for October 2017, it's 693

/*******************************************************************************
Plot
*******************************************************************************/

// Number of discrimination cases filed over time
preserve
	collapse (count) mean_y = y, by(ym sh)

	twoway ///
		scatter mean_y ym if sh == 0, mcolor("gs3") /// Non-Sexual Harassment Cases
		|| scatter mean_y ym if sh == 1, mcolor("orange_red") /// Sexual Harassment Cases
		|| lowess mean_y ym if sh == 0, color("gs3") ///
		|| lowess mean_y ym if sh == 1, color("orange_red") ///
		legend(order(1 "Other discrimination cases" 2 "Sexual harassment cases")) ///
		xtitle("Date filed") ytitle("Number of cases") ///
		xline(693)
	graph export "$figures/timeseries.png", replace 	
restore	


// Difference between non-SH and SH cases filed over time
preserve
	collapse (count) mean_y = y, by(ym sh)

	reshape wide mean_y, j(sh) i(ym)
	g diff = mean_y0 - mean_y1 // y0 is non-sh

	twoway ///
		scatter diff ym, mcolor("gs3") /// 
		|| lowess diff ym, color("gs3") ///
		legend(off) ///
		xtitle("Date filed") ytitle("Number of cases") ///
		xline(693)
	graph export "$figures/timeseries2.png", replace 	

	// Difference between non-SH and SH cases filed, before Covid-19
	drop if ym > 721 // if after Feb 2020

	twoway ///
		scatter diff ym, mcolor("gs3") /// 
		|| lowess diff ym, color("gs3") ///
		legend(off) ///
		xtitle("Date filed") ytitle("Number of cases") ///
		xline(693)
	graph export "$figures/timeseries_nocovid.png", replace 	
restore
