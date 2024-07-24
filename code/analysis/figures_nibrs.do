/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_nibrs_cases.dta", replace

loc event 	   = 1
loc timeseries = 1
loc diff 	   = 1 

/*******************************************************************************
Prep data for plotting
*******************************************************************************/

drop if ym < 609				// drop obs before Oct 2010
drop if months_to_treat_12 == 6 // drop obs after 2022 

drop if sex_cases == . // drop if missing sex_cases
di tm(2017m10) // di numeric value for October 2017, it's 693

/*******************************************************************************
Event-study
*******************************************************************************/

local horizons "months_to_treat_12"
local outcomes "clearance arrest"

if `event' == 1 {
		
	foreach horizon in `horizons' {
		foreach y in `outcomes' {
			
			preserve
			drop if `horizon' == 5 | `horizon' == -8
			
			sum `horizon'
			loc min_val = r(min)
			loc max_val = r(max)
			loc num_points = `max_val' - `min_val' + 1

			gen `horizon'_pos = `horizon' - `min_val'
			loc omit = -1 - `min_val'
			loc xline = `omit' + 2

			// Generate dynamic labels for the x-axis
			local xlabel_str = ""
			forval i = 1/`num_points' {
				local label_val = `i' + `min_val' - 1
				local xlabel_str `xlabel_str' `i' "`label_val'"
			}

			// Run dynamic DiD
			reghdfe `y' ib`omit'.`horizon'_pos##sex_cases, ///
				absorb(basis `horizon'_pos) ///
				vce(robust) noconstant
			estimates store TWFE
			
			// Run Rambachan & Roth (2021)
			honestdid, numpre(`xline') omit ///
				coefplot xtitle(Mbar) ytitle(95% Robust CI)
			graph export "$figures/honestdid_`y'_`horizon'_nibrs.png", replace

			// Make graph
			coefplot (TWFE, omitted baselevel), keep(*.`horizon'_pos#1.sh) vertical ///
				addplot(line @b @at, lcolor(orange_red*0.8)) ///
				ciopts(recast(rcap) msize(medium) color(orange_red)) ///
				yline(0, lc(gs8) lp(dash)) ///
				xline(`xline', lp(dash) lc(gs4)) ///
				ylabel(`ylab_`y'', labsize(medium) angle(0)) ///
				ytitle("Effect of MeToo", size(medium)) ///
				xtitle("Time relative to treatment", size(medium)) ///
				xlabel(`xlabel_str', labsize(medium))
						
			graph export "$figures/eventstudy_`y'_`horizon'_nibrs.png", replace 
			
			// Clean up
			estimates clear
			drop `horizon'_pos 
			restore
		}
	}
	
}


/*******************************************************************************
Other graphs
*******************************************************************************/

// Number of discrimination cases filed over time
if `timeseries' == 1 {
    preserve
    collapse (count) mean_y = y, by(ym sex_cases)
		twoway ///
		scatter mean_y ym if sex_cases == 0, mcolor("gs3") yaxis(1) ytitle("Number of Other Cases", axis(1)) ///
		|| scatter mean_y ym if sex_cases == 1, mcolor("orange_red") yaxis(2) ytitle("Number of Sex-Related Cases", axis(2)) ///
		|| lowess mean_y ym if sex_cases == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_y ym if sex_cases == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		legend(order(1 "Other" 3 "Sex-related") ///
		region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
		xtitle("Date reported", size(medium)) ///
		xline(693, lpattern(solid))
    graph export "$figures/timeseries_nibrs.png", replace
    restore


// Probability of winning over time
	preserve 
	collapse (mean) mean_clear = clearance, by(ym sex_cases)
		twoway ///
			scatter mean_clear ym if sex_cases == 0, mcolor("gs3") yaxis(1) ytitle("Other Cases", axis(1)) /// 
			|| scatter mean_clear ym if sex_cases == 1, mcolor("orange_red") yaxis(2) ytitle("Sex-related Cases", axis(2)) ///
			|| lowess mean_prob_cause ym if sex_cases == 0, color("gs3") lwidth(thick) yaxis(1) ///
			|| lowess mean_prob_cause ym if sex_cases == 1, color("orange_red") lwidth(thick) yaxis(2) ///
			legend(order(1 "Other" 3 "Sex-related") ///
				 region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
			xtitle("Date filed", size(medium)) ///
			xline(693, lpattern(solid))
	graph export "$figures/timeseries_clearprob_nibrs.png", replace 	
	restore	
}


// Difference between non-sex-related and sex-related cases filed over time
if `diff' == 1 {
	preserve
	drop if sex_cases ==.
	collapse (count) mean_y = y, by(ym sex_cases)

	reshape wide mean_y, j(sex_cases) i(ym)
	g diff = mean_y0 - mean_y1 // y0 is non-sex-related

	twoway ///
		scatter diff ym, mcolor("gs3") /// 
		|| lowess diff ym, color("gs3") ///
		legend(off) ///
		xtitle("Date filed", size(medium)) ytitle("Number of cases", size(medium)) ///
		xline(693)
	graph export "$figures/timeseries2_nibrs.png", replace 	

	// Difference between non-sex-related and sex-related cases filed, before Covid-19
	drop if ym > 721 // if after Feb 2020

	twoway ///
		scatter diff ym, mcolor("gs3") /// 
		|| lowess diff ym, color("gs3") ///
		legend(off) ///
		xtitle("Date filed", size(medium)) ytitle("Number of cases", size(medium)) ///
		xline(693)
	graph export "$figures/timeseries_nocovid_nibrs.png", replace 	
restore	
}




