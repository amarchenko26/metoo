/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_placebo = 0
loc run_placebo_f = 1
loc event 	   = 0 // Event study
loc event_all  = 0 // All cases (eeoc_filed == 1) 
loc timeseries = 0
loc diff 	   = 0 
loc duration   = 0 

/*******************************************************************************
Placebo coef plots 
*******************************************************************************/

*loc y1 filed_per_year
loc y2 settle
loc y3 win
loc y4 relief_scale

loc outcome_vars y2 y3 y4

if `run_placebo' == 1 {

	loc i 1
	loc j 1

	// Placebo treatment effects
	preserve
	drop if basis == "Sex" | sh == 1 // drop real treated cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l') 	// Gen placebos 
	}

	// placebo treatment effects
	foreach y of local outcome_vars {
		forvalues index = 1(1)7 {
			reghdfe ``y'' placebo_treat_`index', absorb(unit_state time_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat, absorb(unit_state time_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 s_r_7 true1, bylabel(Settled)
		|| s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 s_r_13 s_r_14 true2, bylabel(Won)
		|| s_r_15 s_r_16 s_r_17 s_r_18 s_r_19 s_r_20 s_r_21 true3, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "LGBTQ" 4 "Nationality" 5 "Other" 6 "Race" 7 "Religion" 8 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment", size(medium));
	#delimit cr

    graph export "$figures/placebo.png", replace  
}

eststo clear
estimates clear


if `run_placebo_f' == 1 {

	loc i 1
	loc j 1

	// VICTIM FEMALE Placebo treatment effects
	preserve
	drop if basis == "Sex" | sh == 1

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l' & victim_f==1)
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)7 {
			reghdfe ``y'' placebo_treat_`index', absorb(unit_state time_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' triple_did, absorb(unit_state time_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 s_r_7 true1, bylabel(Settled)
		|| s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 s_r_13 s_r_14 true2, bylabel(Won)
		|| s_r_15 s_r_16 s_r_17 s_r_18 s_r_19 s_r_20 s_r_21 true3, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "LGBTQ" 4 "Nationality" 5 "Other" 6 "Race" 7 "Religion" 8 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment for female complainants", size(medium));
	#delimit cr

    graph export "$figures/placebo_f.png", replace  
	eststo clear
	estimates clear
}

/*******************************************************************************
Event-study
*******************************************************************************/

local horizons "months_to_treat_12"
local outcomes "relief_w win settle"

if `event_all' == 1 {
		
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
			reghdfe `y' ib`omit'.`horizon'_pos##sh, ///
				absorb(basis `horizon'_pos) ///
				vce(cluster basis) noconstant
			estimates store TWFE
			
			// Run Rambachan & Roth (2021)
			honestdid, numpre(`xline') omit ///
				coefplot xtitle(Mbar) ytitle(95% Robust CI)
			graph export "$figures/honestdid_`y'_`horizon'_all.png", replace

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
						
			graph export "$figures/eventstudy_`y'_`horizon'_all.png", replace 
			
			// Clean up
			estimates clear
			drop `horizon'_pos 
			restore
		}
	}
	
}


if `event' == 1 {

	foreach horizon in `horizons' {
		foreach y in `outcomes' {
			
			preserve 
			drop if eeoc_filed == 1
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
			reghdfe `y' ib`omit'.`horizon'_pos##sh, ///
				absorb(basis `horizon'_pos) ///
				vce(cluster basis) noconstant
			estimates store TWFE
			
			// Run Rambachan & Roth (2021)
			honestdid, numpre(`xline') omit ///
				coefplot xtitle(Mbar) ytitle(95% Robust CI)
			graph export "$figures/honestdid_`y'_`horizon'.png", replace

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
						
			graph export "$figures/eventstudy_`y'_`horizon'.png", replace 
			
			// Clean up
			estimates clear
			drop `horizon'_pos 
			
			restore 
		}
	}
	
}

/*******************************************************************************
Cases/outcomes over time 
*******************************************************************************/

if `timeseries' == 1 {
	
	drop if eeoc_filed == 1
	drop if sh == . // otherwise it messes up collapse statement

	// Number cases filed over time
    preserve
    collapse (count) mean_y = y, by(ym sh)
		twoway ///
		scatter mean_y ym if sh == 0, mcolor("gs3") yaxis(1) ytitle("Number of Other Cases", axis(1)) ///
		|| scatter mean_y ym if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Number of Sexual Harassment Cases", axis(2)) ///
		|| lowess mean_y ym if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_y ym if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		legend(order(1 "Other" 3 "Sexual harassment") ///
		region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
		xtitle("Date filed", size(medium)) ///
		xline(693, lpattern(solid))
    graph export "$figures/timeseries.png", replace
    restore

    preserve
	collapse (count) mean_y = y, by(ym basis)
	#delimit ;
	twoway
		lowess mean_y ym if basis == "Age", color("gs3") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Race", color("blue") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "LGBTQ", color("green") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Disability", color("purple") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Religion", color("red") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Nationality", color("orange") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Retaliation", color("brown") lwidth(thick) yaxis(1) 
		|| lowess mean_y ym if basis == "Sex", color("orange_red") lwidth(thick) yaxis(1)
	legend(order(1 "Age" 2 "Race" 3 "LGBTQ" 4 "Disability" 5 "Religion" 6 "Nationality" 7 "Retaliation" 8 "Sex") 
		region(lcolor(none)) position(2) ring(0))
	xtitle("Date filed", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis.png", replace
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
			xtitle("Date filed",size(medium)) ///
			ytitle("Number of cases filed", size(medium)) ///
			xline(693, lpattern(solid))
		graph export "$figures/timeseries_relief.png", replace 	
	restore	


	// Win over time
	preserve 
	collapse (mean) mean_prob_cause = win, by(ym sh)
		twoway ///
			scatter mean_prob_cause ym if sh == 0, mcolor("gs3") yaxis(1) ytitle("Other Cases", axis(1)) /// 
			|| scatter mean_prob_cause ym if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Sexual Harassment Cases", axis(2)) ///
			|| lowess mean_prob_cause ym if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
			|| lowess mean_prob_cause ym if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
			legend(order(1 "Other" 3 "Sexual harassment") ///
				 region(lcolor(none)) position(2) ring(0)) /// Legend inside plot region
			xtitle("Date filed", size(medium)) ///
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
		xtitle("Date filed", size(medium)) ytitle("Number of cases", size(medium)) ///
		xline(693)
	graph export "$figures/timeseries2.png", replace 	

	// Difference between non-SH and SH cases filed, before Covid-19
	drop if ym > 721 // if after Feb 2020

	twoway ///
		scatter diff ym, mcolor("gs3") /// 
		|| lowess diff ym, color("gs3") ///
		legend(off) ///
		xtitle("Date filed", size(medium)) ytitle("Number of cases", size(medium)) ///
		xline(693)
	graph export "$figures/timeseries_nocovid.png", replace 	
	restore	
}

/*******************************************************************************
Duration
*******************************************************************************/

if `duration' == 1{
	
	binscatter win duration_w , n(50) ///
		xtitle("Duration (winsorized at 1%)") ytitle("Probability of win")
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
			 xtitle("Duration", size(medium)) ytitle("Density by month filed", size(medium))
			 note("Kruskal–Wallis test where Null is equality of distributions: p < 0.336");
	#delimit cr

	graph save "$figures/duration_by_file.png", replace
	restore

}



