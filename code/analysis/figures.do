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

winsor relief, p(.05) gen(relief_wins)

/*******************************************************************************
Program to create time to treat
*******************************************************************************/

* Define a function to create the time_to_treat variable
cap program drop create_time_to_treat
program define create_time_to_treat
    syntax, period(integer) [period_label(string)]

    * Convert the event date to Stata date format
    gen event_date = date("$metoo", "DMY")

    * Generate the time_to_treat variable
    gen months_to_treat_`period' = ceil((common_file_date - event_date) / (`period' * 30.4375))
    replace months_to_treat_`period' = 0 if common_file_date < event_date & common_file_date >= event_date - `period' * 30.4375
    replace months_to_treat_`period' = -1 if common_file_date < event_date - `period' * 30.4375 & common_file_date >= event_date - 2 * `period' * 30.4375
    replace months_to_treat_`period' = -2 if common_file_date < event_date - 2 * `period' * 30.4375 & common_file_date >= event_date - 3 * `period' * 30.4375
    replace months_to_treat_`period' = -3 if common_file_date < event_date - 3 * `period' * 30.4375 & common_file_date >= event_date - 4 * `period' * 30.4375
    replace months_to_treat_`period' = -4 if common_file_date < event_date - 4 * `period' * 30.4375 & common_file_date >= event_date - 5 * `period' * 30.4375
    replace months_to_treat_`period' = -5 if common_file_date < event_date - 5 * `period' * 30.4375 & common_file_date >= event_date - 6 * `period' * 30.4375
    replace months_to_treat_`period' = -6 if common_file_date < event_date - 6 * `period' * 30.4375 & common_file_date >= event_date - 7 * `period' * 30.4375
    replace months_to_treat_`period' = -7 if common_file_date < event_date - 7 * `period' * 30.4375 & common_file_date >= event_date - 8 * `period' * 30.4375
    replace months_to_treat_`period' = -8 if common_file_date < event_date - 8 * `period' * 30.4375 & common_file_date >= event_date - 9 * `period' * 30.4375
    replace months_to_treat_`period' = -9 if common_file_date < event_date - 9 * `period' * 30.4375 & common_file_date >= event_date - 10 * `period' * 30.4375

    * Label the time_to_treat variable
    if "`period_label'" != "" {
        label var months_to_treat_`period' "`period_label'"
    }
    else {
        label var months_to_treat_`period' "Periods relative to MeToo"
    }
	drop event_date
end

* Create time_to_treat for quarters
create_time_to_treat, period(3) period_label("Quarters relative to MeToo")

* Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

* Create time_to_treat for years
create_time_to_treat, period(12) period_label("Years relative to MeToo")


/*******************************************************************************
Plot
*******************************************************************************/

local horizons "months_to_treat_6 months_to_treat_12"
local outcomes "relief_wins probable_cause"

// Event study
if `event' == 1 {
	foreach y in `outcomes' {
		foreach horizon in `horizons' {
		
		sum `horizon'
		loc min_val = r(min)
		loc max_val = r(max)
		loc omit	= -1 * `min_val'
		loc xline	= `omit' + .5

		g `horizon'_pos = `horizon' + (-1*`min_val') + 1
		
		// Run dynamic DiD
		reghdfe `y' ib`omit'.`horizon'_pos##sh, ///
			absorb(basis_clean `horizon'_pos) ///
			vce(cluster basis_clean)
			
		estimates store TWFE
		
		* Prepare the dynamic labels for the x-axis
		local num_points = `max_val' - `min_val'  // Total points from min to max
		local xlabel_str = ""
		forval i = 1/`num_points' {
			local label_val = `i' + `min_val' - 1
			local xlabel_str `xlabel_str' `i' "`label_val'"
		}
		
		// Make graph
		coefplot (TWFE, omitted baselevel), keep(*.`horizon'_pos#1.sh) vertical ///
			addplot(line @b @at, lcolor(orange_red*0.8)) ///
			ciopts(recast(rcap) msize(medium) color(orange_red)) ///
			yline(0, lc(gs8) lp(dash)) ///
			xline(`xline', lp(dash) lc(gs4)) ///
			ylabel(`ylab_`y'', labsize(medium) angle(0)) ///
			ytitle("Effect of MeToo (SH minus non-SH cases)") ///
			xtitle("Time relative to treatment") ///
			xlabel(`xlabel_str', labsize(medium) angle(90))
					
		graph export "$figures/eventstudy_`y'_`horizon'.png", replace 
		
		// Clean up
		estimates clear
		drop `horizon'_pos 
		}
	}
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












