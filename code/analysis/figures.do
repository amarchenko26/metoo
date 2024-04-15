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
		scatter mean_y ym if sh == 0, mcolor("gs3") yaxis(1) ytitle("Number of Other Cases", axis(1)) /// 
		|| scatter mean_y ym if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Number of Sexual Harassment Cases", axis(2)) ///
		|| lowess mean_y ym if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_y ym if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		legend(order(1 "Other" 3 "Sexual harassment") ///
             region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
		xtitle("Date filed") ///
		xline(693, lpattern(solid))
	graph export "$figures/timeseries.png", replace 	
restore	


// Damages over time
preserve 
winsor relief, p(.05) gen(relief_wins)

	collapse (mean) mean_relief = relief_wins, by(ym sh)

	twoway ///
		scatter mean_relief ym if sh == 0, mcolor("gs3") yaxis(1) ytitle("Other Cases", axis(1)) /// 
		|| scatter mean_relief ym if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Sexual Harassment Cases", axis(2)) ///
		|| lowess mean_relief ym if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_relief ym if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		legend(order(1 "Other" 3 "Sexual harassment") ///
             region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
		xtitle("Date filed") ///
		xline(693, lpattern(solid))
	graph export "$figures/timeseries_relief.png", replace 	
restore	


// Probability of winning over time
preserve 

	collapse (mean) mean_prob_cause = probable_cause, by(ym sh)

	twoway ///
		scatter mean_prob_cause ym if sh == 0, mcolor("gs3") yaxis(1) ytitle("Other Cases", axis(1)) /// 
		|| scatter mean_prob_cause ym if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Sexual Harassment Cases", axis(2)) ///
		|| lowess mean_prob_cause ym if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_prob_cause ym if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		legend(order(1 "Other" 3 "Sexual harassment") ///
             region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
		xtitle("Date filed") ///
		xline(693, lpattern(solid))
	graph export "$figures/timeseries_winprob.png", replace 	
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


// Event study

g horizon = ym - 693
drop if horizon > 24 | horizon < -24 // two years
tab horizon, gen(hdummy)

// Loop to assign labels
forval i = 1/49 {
    local label_value = -25 + (`i' )
    local var_name hdummy`i'
    label variable `var_name' "`label_value'"
}

drop hdummy24 

// Run reg
reghdfe probable_cause sh##(hdummy1-hdummy49), absorb(basis_clean ym state) vce(cluster basis_clean)
estimates store TWFE

* make graph
coefplot TWFE, vertical ///
	yline(0, lcolor(blue*0.8)) ///
	addplot(line @b @at, lcolor(blue*0.8)) ///
	ciopts(recast(rcap) msize(medium)) ///
	xline(25) ///
	ytitle("Effect of MeToo") ///
	xtitle("Months since treatment")

	
graph export "$figures/eventstudy.png", replace 	







