/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc timeseries = 1 // Number of cases, relief, prob winning over time
loc event 	   = 1 // Event study
loc diff 	   = 1 // DiD
loc duration   = 0 // Duration 

/*******************************************************************************
Prep data for plotting
*******************************************************************************/

drop if ym < 606 // drop cases before Jan 2010
drop if sh == . // drop if missing sh
di tm(2017m10) // di numeric value for October 2017, it's 693

/*******************************************************************************
Plot
*******************************************************************************/

local horizons "months_to_treat_6 months_to_treat_12"
local outcomes "relief_w probable_cause"

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
		
		** FIX HERE
		//honestdid, pre(1/5) post(7/8) mvec(0.5(0.5)2)

		
		* Prepare the dynamic labels for the x-axis
		local num_points = `max_val' - `min_val' 
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
			xlabel(`xlabel_str', labsize(medium))
					
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
	pause
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
	collapse (mean) mean_relief = relief_w, by(ym sh)
		twoway ///
			scatter mean_relief ym if sh == 0, mcolor("gs3") /// 
			|| scatter mean_relief ym if sh == 1, mcolor("orange_red") ///
			|| lowess mean_relief ym if sh == 0, color("gs3") lwidth(thick) ///
			|| lowess mean_relief ym if sh == 1, color("orange_red") lwidth(thick) ///
			legend(order(1 "Other" 2 "Sexual harassment") ///
				 region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
			xtitle("Date filed") ///
			ytitle("Number of cases filed") ///
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
	drop if sh ==.
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

if `duration' == 1{
	
	binscatter probable_cause duration_w , n(50) ///
		xtitle("Duration (winsorized at 1%)") ytitle("Probable cause found")

	graph export "$figures/duration_cause.png", replace 	


	preserve 
	keep if common_year == 2017

	#delimit ;
	twoway (kdensity duration if ym == 684, lcolor(gray) fcolor(gray%0) recast(area))
		   (kdensity duration if ym == 685, lcolor(yellow) fcolor(yellow%0) recast(area))
		   (kdensity duration if ym == 686, lcolor(green) fcolor(green%0) recast(area))
		   (kdensity duration if ym == 687, lcolor(orange) fcolor(orange%0) recast(area))
		   (kdensity duration if ym == 688, lcolor(red) fcolor(red%0) recast(area))
		   (kdensity duration if ym == 689, lcolor(navy) fcolor(navy%0) recast(area))
		   (kdensity duration if ym == 690, lcolor(yellow) fcolor(yellow%0) recast(area))
		   (kdensity duration if ym == 691, lcolor(lime) fcolor(lime%0) recast(area))
		   (kdensity duration if ym == 692, lcolor(teal) fcolor(teal%40) recast(area))
		   (kdensity duration if ym == 693, lcolor(maroon) fcolor(maroon%0) recast(area))
		   (kdensity duration if ym == 694, lcolor(red) fcolor(red%0) recast(area))
		   (kdensity duration if ym == 695, lcolor(pink) fcolor(pink%0) recast(area))
		   , legend(ring(0) pos(2) order(12 11 10 9 8 7 6 5 4 3 2 1)
					label(1 "Jan") label(2 "Feb") label(3 "March")
					label(4 "April") label(5 "May") label(6 "June")
					label(7 "July") label(8 "Aug") label(9 "Sept")
					label(10 "Oct") label(11 "Nov") label(12 "Dec"))
			 xtitle("Duration") ytitle("Density by month filed")
			 note("Kruskal–Wallis test where Null is equality of distributions: p < 0.336");
	#delimit cr

	graph save "$figures/duration_by_file.png", replace
	restore

}



