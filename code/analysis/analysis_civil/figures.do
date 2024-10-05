* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc event_all  = 0
loc event 	   = 0
loc timeseries = 0
loc state_did  	= 1
loc run_placebo = 0
loc run_placebo_single = 0
loc run_placebo_overlap = 0
loc run_placebo_f = 0
loc duration   = 0
loc yhat		= 0

/*******************************************************************************
Event-study
*******************************************************************************/

local outcomes "relief_scale win settle"

if `event_all' == 1 {
		
	foreach y in `outcomes' {
		
		g event = months_to_treat_12 * sh
		replace event = event + 9 // dummies can't be negative

		// Run dynamic DiD
		reghdfe `y' ib8.event, ///
			absorb(basis ym) ///
			vce(cluster basis) noconstant
		estimates store TWFE
		
		// Run Rambachan & Roth (2021)
		/* honestdid, numpre(9) omit ///
			coefplot xtitle(Mbar) ytitle(95% Robust CI)
		graph export "$figures/honestdid_`y'_all.png", replace */

		// Make graph
		#delimit ;
		coefplot (TWFE, omitted baselevel), vertical
			ciopts(recast(rcap) msize(medium) color(orange_red))
			addplot(line @b @at, lcolor(orange_red*0.8))
			yline(0, lp(dash))
			xline(9)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo", size(medium))
			xlabel(1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "-1" 9 "0" 10 "1" 11 "2" 12 "3" 13 "4" 14 "5", labsize(medium))
		;
		#delimit cr
					
		graph export "$figures/eventstudy_`y'_all.png", replace 
		
		estimates clear
	}
}

if `event' == 1 {
	foreach y in `outcomes' {
		
		preserve
		keep if eeoc == 0
		
		g event = months_to_treat_12 * sh
		replace event = event + 9 // dummies can't be negative

		// Run dynamic DiD
		reghdfe `y' ib8.event, ///
			absorb(basis ym) ///
			vce(cluster basis) noconstant
		estimates store TWFE
		
		// Run Rambachan & Roth (2021)
		honestdid, numpre(9) omit ///
			coefplot xtitle(Mbar) ytitle(95% Robust CI)
		graph export "$figures/honestdid_`y'_state.png", replace

		// Make graph
		#delimit ;
		coefplot (TWFE, omitted baselevel), vertical
			ciopts(recast(rcap) msize(medium) color(orange_red))
			addplot(line @b @at, lcolor(orange_red*0.8))
			yline(0, lp(dash))
			xline(9)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo", size(medium))
			xlabel(1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "-1" 9 "0" 10 "1" 11 "2" 12 "3" 13 "4" 14 "5", labsize(medium))
		;
		#delimit cr
					
		graph export "$figures/eventstudy_`y'_state.png", replace 
		
		estimates clear
		restore
	}	
}


/*******************************************************************************
Cases/outcomes over time 
*******************************************************************************/

if `timeseries' == 1 {

	* Women winning vs men winning vs. other complaints 
	plot_lpolyci_gender win ym, title("Probability of Winning by Complainant Gender") ylabel("Probability of win")

	* Plot outcomes over time 
	preserve
	keep if eeoc == 0
	plot_lpolyci ln_total_cases_per_month_by_sh ym, title("Number Complaints Filed Over Time") ylabel("Ln(count of complaints filed)")
	restore

	plot_lpolyci settle ym, title("Probability Complainant Settles Over Time") ylabel("Probability settled")

	plot_lpolyci dismissed ym, title("Probability Complaint Dismissed Over Time") ylabel("Probability dismissed")

	preserve 
	keep if eeoc_took_to_court == 0
	plot_lpolyci win ym, title("Probability of Complainant Winning Over Time") ylabel("Probability of win")
	restore

	plot_lpolyci relief_scale ym, title("Compensation Paid to Complainant (conditional on winning)") ylabel("Compensation in $1000s")

	* Plot outcomes over time by basis
	// Number of cases
    preserve
    collapse (mean) mean_y = filed_per_year, by(common_year sh)
		lowess mean_y common_year if sh == 0, gen(lowess1) nograph
		lowess mean_y common_year if sh == 1, gen(lowess2) nograph
		su lowess1 if sh == 0 & common_year == 2023, meanonly
		local call text(`r(mean)' 2023 "Other", color("gs3") place(r) size(small))
		su lowess2 if sh == 1 & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "SH", color("orange_red") place(r) size(small))
		twoway ///
		scatter mean_y common_year if sh == 0, mcolor("gs3") yaxis(1) ytitle("Proportion of Other Cases", axis(1)) ///
		|| scatter mean_y common_year if sh == 1, mcolor("orange_red") yaxis(2) ytitle("Proportion of Sexual Harassment Cases", axis(2)) ///
		|| lowess mean_y common_year if sh == 0, color("gs3") lwidth(thick) yaxis(1) ///
		|| lowess mean_y common_year if sh == 1, color("orange_red") lwidth(thick) yaxis(2) ///
		`call' legend(off) ///
		xtitle("Date filed", size(medium)) ///
		xline(2017.79, lpattern(solid))
    graph export "$figures/timeseries.png", replace
    restore
	
	preserve
	collapse (mean) mean_y = share_filed_by_basis, by(common_year basis)
		lowess mean_y common_year if basis == "Age", gen(lowess1) nograph
		lowess mean_y common_year if basis == "Race", gen(lowess2) nograph
		lowess mean_y common_year if basis == "Disability", gen(lowess3) nograph
		lowess mean_y common_year if basis == "Religion", gen(lowess4) nograph
		lowess mean_y common_year if basis == "Nationality", gen(lowess5) nograph
		lowess mean_y common_year if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_y common_year if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & common_year == 2023, meanonly
		local call text(`r(mean)' 2023 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & common_year == 2023, meanonly
		local call `call' text(`r(mean)' 2023 "Sex", color("magenta") place(r) size(small))
	#delimit ;
	twoway
		lowess mean_y common_year if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_y common_year if basis == "Race", color("blue") lwidth(thick) 
		|| lowess mean_y common_year if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_y common_year if basis == "Religion", color("red") lwidth(thick) 
		|| lowess mean_y common_year if basis == "Nationality", color("orange") lwidth(thick) 
		|| lowess mean_y common_year if basis == "Retaliation", color("brown") lwidth(thick)  
		|| lowess mean_y common_year if basis == "Sex", color("magenta") lwidth(thick) 
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Proportion of cases", size(medium)) 
	xline(2017.79, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis.png", replace
    restore
	
	preserve
	collapse (mean) mean_settle = settle, by(ym basis)
		lowess mean_settle ym if basis == "Age", gen(lowess1) nograph
		lowess mean_settle ym if basis == "Race", gen(lowess2) nograph
		lowess mean_settle ym if basis == "Disability", gen(lowess3) nograph
		lowess mean_settle ym if basis == "Religion", gen(lowess4) nograph
		lowess mean_settle ym if basis == "Nationality", gen(lowess5) nograph
		lowess mean_settle ym if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_settle ym if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym == 764, meanonly
		local call `call' text(`r(mean)' 764 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Sex", color("magenta") place(r) size(small))
	#delimit ;
	twoway
		lowess mean_settle ym if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_settle ym if basis == "Race", color("blue") lwidth(thick) 
		|| lowess mean_settle ym if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_settle ym if basis == "Religion", color("red") lwidth(thick) 
		|| lowess mean_settle ym if basis == "Nationality", color("orange") lwidth(thick) 
		|| lowess mean_settle ym if basis == "Retaliation", color("brown") lwidth(thick)  
		|| lowess mean_settle ym if basis == "Sex", color("magenta") lwidth(thick) 
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of settling", size(medium)) 
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_settle.png", replace
    restore
	
	preserve
	collapse (mean) mean_dismissed = dismiss, by(ym basis)
		lowess mean_dismissed ym if basis == "Age", gen(lowess1) nograph
		lowess mean_dismissed ym if basis == "Race", gen(lowess2) nograph
		lowess mean_dismissed ym if basis == "Disability", gen(lowess3) nograph
		lowess mean_dismissed ym if basis == "Religion", gen(lowess4) nograph
		lowess mean_dismissed ym if basis == "Nationality", gen(lowess5) nograph
		lowess mean_dismissed ym if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_dismissed ym if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym == 764, meanonly
		local call `call' text(`r(mean)' 764 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Sex", color("magenta") place(r) size(small))
	#delimit ;
	twoway
		lowess mean_dismissed ym if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_dismissed ym if basis == "Race", color("blue") lwidth(thick) 
		|| lowess mean_dismissed ym if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_dismissed ym if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_dismissed ym if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_dismissed ym if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_dismissed ym if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of dismissal", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_dismissed.png", replace
    restore
	
	preserve
	collapse (mean) mean_relief = relief_scale, by(ym basis)
		lowess mean_relief ym if basis == "Age", gen(lowess1) nograph
		lowess mean_relief ym if basis == "Race", gen(lowess2) nograph
		lowess mean_relief ym if basis == "Disability", gen(lowess3) nograph
		lowess mean_relief ym if basis == "Religion", gen(lowess4) nograph
		lowess mean_relief ym if basis == "Nationality", gen(lowess5) nograph
		lowess mean_relief ym if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_relief ym if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym == 761, meanonly
		local call `call' text(`r(mean)' 761 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym == 764, meanonly
		local call `call' text(`r(mean)' 764 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym == 759, meanonly
		local call `call' text(`r(mean)' 759 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym == 759, meanonly
		local call `call' text(`r(mean)' 759 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym == 764, meanonly
		local call `call' text(`r(mean)' 764 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym == 764, meanonly
		local call `call' text(`r(mean)' 764 "Sex", color("magenta") place(r) size(small)) 
	#delimit ;
	twoway
		lowess mean_relief ym if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_relief ym if basis == "Race", color("blue") lwidth(thick)
		|| lowess mean_relief ym if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_relief ym if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_relief ym if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_relief ym if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_relief ym if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Compensation", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_relief.png", replace
    restore
	
	preserve
	collapse (mean) mean_prob_cause = win, by(ym basis)
		lowess mean_prob_cause ym if basis == "Age", gen(lowess1) nograph
		lowess mean_prob_cause ym if basis == "Race", gen(lowess2) nograph
		lowess mean_prob_cause ym if basis == "Disability", gen(lowess3) nograph
		lowess mean_prob_cause ym if basis == "Religion", gen(lowess4) nograph
		lowess mean_prob_cause ym if basis == "Nationality", gen(lowess5) nograph
		lowess mean_prob_cause ym if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_prob_cause ym if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym == 760, meanonly
		local call `call' text(`r(mean)' 760 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym == 763, meanonly
		local call `call' text(`r(mean)' 763 "Sex", color("magenta") place(r) size(small)) 
	#delimit ;
	twoway
		lowess mean_prob_cause ym if basis == "Age", color("gs3") lwidth(thick) 
		|| lowess mean_prob_cause ym if basis == "Race", color("blue") lwidth(thick)
		|| lowess mean_prob_cause ym if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_prob_cause ym if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_prob_cause ym if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_prob_cause ym if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_prob_cause ym if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of winning", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_win.png", replace
    restore
}

/*******************************************************************************
State-level DID 
*******************************************************************************/

if `state_did' == 1 {

	******* All cases
	// Full regression, get ATT
	qui: reghdfe win treat, absorb(basis_state ym_state) vce(cluster basis_state)

	// FWL regression
	qui: reghdfe win, absorb(basis_state ym_state) vce(cluster basis_state) resid
	predict treat_tilde, residuals

	// ATT2, Should give you ATT = ATT2 
	qui: reg win treat_tilde, cluster(basis_state)

	// Calculate weights 
	g num = treat_tilde  // weight numerator
	egen den = total(treat_tilde * treat_tilde)	 // weights denominator
	g weights = num / den

	// Collapse weights by state and plot
	preserve 
	collapse (mean) mean_weight = weights, by(state_cat)

	scatter mean_weight state_cat, ///
		xtitle("State") mlabel(state) mlabposition(6) ///
		ytitle("Mean weights") ///
		title("DiD regression weights by state") ///
		note("Sample is all cases", size(med))

	graph export "$figures/weights_all_statefe.png", replace 	
	restore
	cap drop weights treat_tilde num den

	***** Individual state effects
	preserve 
	g state_label = "AK" if state_did == 1
	replace state_label = "AL" if state_did == 2
	replace state_label = "AR" if state_did == 3
	replace state_label = "AZ" if state_did == 4
	replace state_label = "CA" if state_did == 5
	replace state_label = "CO" if state_did == 6
	replace state_label = "CT" if state_did == 7
	replace state_label = "DC" if state_did == 8
	replace state_label = "FL" if state_did == 9
	replace state_label = "GA" if state_did == 10
	replace state_label = "HI" if state_did == 11
	replace state_label = "IA" if state_did == 12
	replace state_label = "ID" if state_did == 13
	replace state_label = "IL" if state_did == 14
	replace state_label = "IN" if state_did == 15
	replace state_label = "KS" if state_did == 16
	replace state_label = "KY" if state_did == 17
	replace state_label = "LA" if state_did == 18
	replace state_label = "MA" if state_did == 19
	replace state_label = "MD" if state_did == 20
	replace state_label = "ME" if state_did == 21
	replace state_label = "MI" if state_did == 22
	replace state_label = "MN" if state_did == 23
	replace state_label = "MO" if state_did == 24
	replace state_label = "MS" if state_did == 25
	replace state_label = "MT" if state_did == 26
	replace state_label = "NC" if state_did == 27
	replace state_label = "ND" if state_did == 28
	replace state_label = "NE" if state_did == 29
	replace state_label = "NH" if state_did == 30
	replace state_label = "NJ" if state_did == 31
	replace state_label = "NM" if state_did == 32
	replace state_label = "NV" if state_did == 33
	replace state_label = "NY" if state_did == 34
	replace state_label = "OH" if state_did == 35
	replace state_label = "OK" if state_did == 36
	replace state_label = "OR" if state_did == 37
	replace state_label = "PA" if state_did == 38
	replace state_label = "RI" if state_did == 39
	replace state_label = "SC" if state_did == 40
	replace state_label = "SD" if state_did == 41
	replace state_label = "TN" if state_did == 42
	replace state_label = "TX" if state_did == 43
	replace state_label = "UT" if state_did == 44
	replace state_label = "VA" if state_did == 45
	replace state_label = "WA" if state_did == 46
	replace state_label = "WI" if state_did == 47
	
	drop if state_did == 54 //drop WV bc coefficient is too high 

	reghdfe win i.state_did, absorb(basis_state ym_state) vce(cluster basis_state)
	eststo A

	reghdfe win treat, absorb(basis_state ym_state) vce(cluster basis_state)
    loc att: display %5.4f _b[treat]

	#delimit ;
	coefplot 
		A, 
		drop(_cons)
		vertical omitted 
		ciopts(lwidth(thick) recast(rcap))
		yline(0, lcolor(black)) 
		yline(`att', lcolor(orange_red))
		ytitle("Treatment effect on win", size(medium))
		xtitle("State", size(medium))
		xlabel(1 "AK" 2 "AL" 3 "AR" 4 "AZ" 5 "CA" 6 "CO" 7 "CT" 8 "DC" 9 "FL" 10 "GA" 11 "HI" 12 "IA" 13 "ID" 14 "IL" 15 "IN" 16 "KS" 17 "KY" 18 "LA" 19 "MA" 20 "MD" 21 "ME" 22 "MI" 23 "MN" 24 "MO" 25 "MS" 26 "MT" 27 "NC" 28 "ND" 29 "NE" 30 "NH" 31 "NJ" 32 "NM" 33 "NV" 34 "NY" 35 "OH" 36 "OK" 37 "OR" 38 "PA" 39 "RI" 40 "SC" 41 "SD" 42 "TN" 43 "TX" 44 "UT" 45 "VA" 46 "WA" 47 "WI", alternate) //mlabel(state_label), fix mlabel here
		note("Controls include state X unit and state X time FE. ATT: `att'", size(small)) 
		;
	#delimit cr
    graph export "$figures/state_fx_all.png", replace  
	restore


	** State sample
	preserve 
	keep if eeoc == 0

	qui: reghdfe win treat, absorb(basis_state ym_state) vce(cluster basis_state)

	// FWL regression
	qui: reghdfe win, absorb(basis_state ym_state) vce(cluster basis_state) resid
	predict treat_tilde, residuals

	// ATT2, Should give you ATT = ATT2 
	qui: reg win treat_tilde, cluster(basis_state)

	// Calculate weights 
	g num = treat_tilde  // weight numerator
	egen den = total(treat_tilde * treat_tilde)	 // weights denominator
	g weights = num / den

	cap drop num den 

	// Collapse weights by state and plot
	collapse (mean) mean_weight = weights, by(state_cat)

	scatter mean_weight state_cat, ///
		xtitle("State") mlabel(state) mlabposition(6) ///
		ytitle("Mean weights") ///
		title("DiD regression weights by state") ///
		note("Sample is all cases", size(med))

	graph export "$figures/weights_statefe.png", replace 	
	restore
}

/*******************************************************************************
Placebo coef plots 
*******************************************************************************/

loc y1 dismissed
loc y2 settle
loc y3 win
loc y4 relief_scale

loc outcome_vars y1 y2 y3 y4

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
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 true1, bylabel(Dismissed)
		|| s_r_7 s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 true2, bylabel(Settled)
		|| s_r_13 s_r_14 s_r_15 s_r_16 s_r_17 s_r_18 true3, bylabel(Won)
		|| s_r_19 s_r_20 s_r_21 s_r_22 s_r_23 s_r_24 true4, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment", size(medium));
	#delimit cr

    graph export "$figures/placebo.png", replace
	eststo clear
	estimates clear
}

if `run_placebo_single' == 1 {

	loc i 1
	loc j 1

	// Single-tagged placebo treatment effects
	preserve
	drop if basis == "Sex" | sh == 1 // drop real treated cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l' & multi_cat==0)
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat, absorb(basis_state ym_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 true1, bylabel(Dismissed)
		|| s_r_7 s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 true2, bylabel(Settled)
		|| s_r_13 s_r_14 s_r_15 s_r_16 s_r_17 s_r_18 true3, bylabel(Won)
		|| s_r_19 s_r_20 s_r_21 s_r_22 s_r_23 s_r_24 true4, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment for single-tagged cases", size(medium));
	#delimit cr

    graph export "$figures/placebo_single.png", replace  
	eststo clear
	estimates clear
}

if `run_placebo_overlap' == 1 {

	loc i 1
	loc j 1

	// Single-tagged placebo treatment effects
	preserve
	drop if basis == "Sex" | sh == 1 // drop real treated cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l')
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat if overlap_2 != ., absorb(basis_state ym_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 true1, bylabel(Dismissed)
		|| s_r_7 s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 true2, bylabel(Settled)
		|| s_r_13 s_r_14 s_r_15 s_r_16 s_r_17 s_r_18 true3, bylabel(Won)
		|| s_r_19 s_r_20 s_r_21 s_r_22 s_r_23 s_r_24 true4, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment for overlap cases", size(medium));
	#delimit cr

    graph export "$figures/placebo_overlap.png", replace  
	eststo clear
	estimates clear
}

if `run_placebo_f' == 1 {

	loc i 1
	loc j 1

	// VICTIM FEMALE Placebo treatment effects
	preserve
	drop if basis == "Sex" | sh == 1 // drop real treated cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l' & victim_f==1)
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' triple_did, absorb(basis_state ym_state) vce(cluster basis)
		eststo true`j'
		loc ++j
	}

	#delimit ;
	coefplot 
		s_r_1 s_r_2 s_r_3 s_r_4 s_r_5 s_r_6 true1, bylabel(Dismissed)
		|| s_r_7 s_r_8 s_r_9 s_r_10 s_r_11 s_r_12 true2, bylabel(Settled)
		|| s_r_13 s_r_14 s_r_15 s_r_16 s_r_17 s_r_18 true3, bylabel(Won)
		|| s_r_19 s_r_20 s_r_21 s_r_22 s_r_23 s_r_24 true4, bylabel(Compensation)
		|| , drop(_cons)
		byopts(xrescale legend(off)) // so x-axis is different for all plots
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sexual harassment", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment for female complainants", size(medium));
	#delimit cr

    graph export "$figures/placebo_f.png", replace  
	eststo clear
	estimates clear
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

	graph export "$figures/duration_by_file.png", replace
	restore

}

/*******************************************************************************
Beta-hat
*******************************************************************************/
* Take covariates that predict the outcome in the pre period
* generate a beta-hat 
* multiply beta-hat times the covariates in the post period 
* plot predicted y-hat versus actual y-hat 
* how good is the prediction? in terms of R2

if `yhat' == 1{
	preserve 
	loc y settle
	keep if eeoc == 0

	* Fit model on data pre MeToo
	#delimit ;
	reg `y' i.basis_cat i.victim_f i.state_cat duration court
		if post == 0, cluster(basis_cat);
	#delimit cr

	* Predict for pre-post MeToo
	predict `y'_hat, xb 		// prediction 

	collapse (mean) `y'_hat `y', by(months_to_treat_6)

	#delimit ; 
	twoway line `y'_hat `y' months_to_treat_6,
		xtitle("6 month intervals before and after MeToo")
		ytitle("Probability of `y'") 
		title("")
		xline(0, lc(gs8) lp(dash))
		legend(ring(0) pos(2) order(2 1) 
			label(1 "Predicted y") label(2 "Actual y")
			size(medium));
	#delimit cr

	graph export "$figures/y_hat_`y'.png", replace 	
	restore 
}


