/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Gen plotting vars
*******************************************************************************/

// Gen year-month variable
gen ym = ym(year(charge_file_date), month(charge_file_date)) 
format ym %tm 
la var ym "Year-month"

/*******************************************************************************
Plot
*******************************************************************************/

di tm(2017m10) // di numeric value for October 2017, it's 693
loc ma_pop 6827000 //pop of MA in 2016

// Simple time series
preserve
drop if ym == .
gen y = 1 // index var
collapse (count) mean_y = y, by(ym sh)

twoway ///
	scatter mean_y ym if sh == 0, mcolor("gs3") /// Non-Sexual Harassment Cases
	|| scatter mean_y ym if sh == 1, mcolor("orange_red") /// Sexual Harassment Cases
	|| lowess mean_y ym if sh == 0, color("gs3") ///
	|| lowess mean_y ym if sh == 1, color("orange_red") ///
	legend(order(1 "Other discrimination cases" 2 "Sexual harassment cases")) ///
	title("Number of discrimination cases filed in MA") ///
	xtitle("Year") ytitle("Number of cases") ///
	xline(693) ///
	note("Vertical line indicates start of MeToo", size(small))

graph export "$figures/timeseries.png", replace 	
restore


// Simple difference
preserve
drop if ym == .
gen y = 1 // index var
collapse (count) mean_y = y, by(ym sh)

reshape wide mean_y, j(sh) i(ym)
g diff = mean_y0 - mean_y1 // y0 is non-sh

twoway ///
	scatter diff ym, mcolor("gs3") /// Non-Sexual Harassment Cases
	|| lowess diff ym, color("gs3") ///
	legend(order(1 "Other discrimination minus SH cases")) ///
	title("Difference in non-SH and SH cases filed in MA") ///
	xtitle("Year") ytitle("Number of cases") ///
	xline(693) ///
	note("Vertical line indicates start of MeToo", size(small))

graph export "$figures/timeseries2.png", replace 	
restore



// Simple difference
preserve
drop if ym == .
gen y = 1 // index var
collapse (count) mean_y = y, by(ym sh)

twoway ///
	scatter diff ym, mcolor("gs3") /// Non-Sexual Harassment Cases
	|| lowess diff ym, color("gs3") ///
	legend(order(1 "Other discrimination minus SH cases")) ///
	title("Difference in non-SH and SH cases filed in MA") ///
	xtitle("Year") ytitle("Number of cases") ///
	xline(693) ///
	note("Vertical line indicates start of MeToo", size(small))

graph export "$figures/timeseries2.png", replace 	
restore






// Now drop everything post Covid
preserve
drop if ym == .
drop if ym > 721 // if after Feb 2020

gen y = 1 // index var
collapse (count) mean_y = y, by(ym sh)

reshape wide mean_y, j(sh) i(ym)
g diff = mean_y0 - mean_y1 // y0 is non-sh

twoway ///
	scatter diff ym, mcolor("gs3") /// Non-Sexual Harassment Cases
	|| lowess diff ym, color("gs3") ///
	legend(order(1 "Other discrimination minus SH cases")) ///
	title("Difference in non-SH and SH cases filed in MA") ///
	xtitle("Year") ytitle("Number of cases") ///
	xline(693) ///
	note("Vertical line indicates start of MeToo", size(small))
	
graph export "$figures/timeseries_nocovid.png", replace 	
restore
 