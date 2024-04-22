/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc timeseries = 0 // Number of cases, relief, prob winning over time
loc event 	   = 1 // Event study
loc diff 	   = 0 // Difference between non-SH and SH cases filed over time

/*******************************************************************************
Prep data for plotting
*******************************************************************************/

drop if ym < 606 //drop cases before Jan 2010
gen y = 1 // index var

di tm(2017m10) // di numeric value for October 2017, it's 693


/*******************************************************************************
Plot
*******************************************************************************/

// Event study
if `event' == 1 {
	
	loc y probable_cause

	g horizon = common_year - 2018	
	g horizon_pos = horizon + 9

// 	//* Loop to assign labels
// 	forval i = 1/13 {
// 		local label_value = -9 + (`i' )
// 		local var_name hdummy`i'
// 		label variable `var_name' "`label_value'"
// 	}
//
// 	drop hdummy8 // drop -1

	// Run reg
	reghdfe `y' ib8.horizon_pos##sh, ///
		absorb(basis_clean common_year) ///
		vce(cluster basis_clean)

	estimates store TWFE
	   
	* make graph
	coefplot TWFE, keep(*.horizon_pos#1.sh) baselevel vertical ///
		addplot(line @b @at, lcolor(orange_red*0.8)) ///
		ciopts(recast(rcap) msize(medium) color(orange_red)) ///
		yline(0, lc(gs8) lp(dash)) ///
		xline(9, lp(dash) lc(gs4)) ///
		ylabel(`ylab_`y'', labsize(medium) angle(0)) ///
		ytitle("Effect of MeToo on winning") ///
		xtitle("Years relative to treatment") ///
		xlabel( 1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "-1" 9 "0" 10 "1" 11 "2" 12 "3" 13 "4", labsize(medium)) 
				
	graph export "$figures/eventstudy_`y'.png", replace 	
}


// Number of discrimination cases filed over time
if `timeseries' == 1 {
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
}


// Difference between non-SH and SH cases filed over time
if `diff' == 1 {
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
}












