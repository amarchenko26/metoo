* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc selection 	= 0
loc event_all  	= 0
loc event 	   	= 0
loc timeseries 	= 1
loc state_did  	= 0
loc run_placebo = 0
loc run_placebo_single = 0
loc run_placebo_overlap = 0
loc run_placebo_f = 0
loc duration   	= 0
loc yhat		= 0

/*******************************************************************************
Selection 
*******************************************************************************/

if `selection' == 1 {
	// TWFE = omega (A-C) + (1-omega) (B-C)
	preserve 
	clear
	set obs 11
	g omega = (_n - 1) / 10

	// Add method 1 omega
	insobs 1  
	replace omega = 0.63 if _n == _N // last observation

	// Add method 2 omega
	insobs 1  
	replace omega = 0.87 if _n == _N // last observation

	// Add method 3 omega
	insobs 1  
	replace omega = 0.65 if _n == _N // last observation

	g omega_c = 1-omega
	g twfe 	  = 0.033
	g overlap = 0.123

	// Selection equation
	g bc = (twfe - (omega*overlap))/omega_c
	
	#delimit ;
	twoway scatter bc omega, yline(0)
			ytitle("Selection effect", size(medium))
			xtitle("Omega (share always reporters)", size(medium))
			mlabel(omega) mlabposition(6) 
			msize(medlarge) mlabsize(vsmall)
			mcolor("0 102 204")
			legend(off)
			xlabel(0(.1)1)
			xsize(8)
		;
	addplot: pcarrowi -.22 0.63 -.17 0.63 (6) "No change in incidence",
		mlabsize(small) mcolor(orange) lcolor(orange)
		;
	addplot: pcarrowi -.50 0.87 -.55 0.87 (12) "SH incidence increases by control file rate",
		mlabsize(small) mcolor(orange) lcolor(orange)
		;
	addplot: pcarrowi -.05 0.65 -.11 0.65 (12) "SH incidence decreases by 1.1pp",
		mlabsize(small) mcolor(orange) lcolor(orange)
		;
	#delimit cr

	graph export "$figures/omega.png", replace  
	restore
}

/*******************************************************************************
Event-study
*******************************************************************************/

local outcomes "settle dismissed win relief_scale"

if `event_all' == 1 {
	
	cap drop event 
	g event = months_to_treat_12 * sh
	replace event = event + 9 // dummies can't be negative

	foreach y in `outcomes' {
		// Run dynamic DiD
		reghdfe `y' ib8.event, ///
			absorb(basis ym) ///
			vce(cluster basis) noconstant
		estimates store TWFE
		
		// Run Rambachan & Roth (2021)
		honestdid, numpre(9) omit ///
			coefplot xtitle(Mbar) ytitle(95% Robust CI)
		graph export "$figures/honestdid_`y'_all.png", replace

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

	cap drop event 
	g event = months_to_treat_12 * sh
	replace event = event + 9 // dummies can't be negative

	foreach y in `outcomes' {
		preserve
		keep if eeoc == 0
	
		// Run dynamic DiD
		reghdfe `y' ib8.event, ///
			absorb(basis ym) ///
			vce(cluster basis) noconstant
		estimates store TWFE

		// Run Rambachan & Roth (2021)
//		matrix l_vec = 1/5 \ 1/5 \ 1/5 \ 1/5 \ 1/5
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
	plot_lpolyci ln_total_cases_per_month_by_sh ym, title("Number Complaints Filed Over Time") ylabel("Ln(count of complaints filed)")

	plot_lpolyci settle ym, title("Probability Complainant Settles Over Time") ylabel("Probability settled")

	plot_lpolyci dismissed ym, title("Probability Complaint Dismissed Over Time") ylabel("Probability dismissed")

	plot_lpolyci win ym, title("Probability of Complainant Winning Over Time") ylabel("Probability of win")

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
	// FWL regression
	cap drop treat_tilde den num weights c_weights treat_weights sum_weight_by_state
	reghdfe treat, absorb(basis ym) vce(cluster basis) resid 
	predict treat_tilde, residuals

	// Calculate weights 
	g num = treat_tilde  
	egen den = total(treat_tilde * treat_tilde)
	g weights = num / den
	
	// Check if weights created correctly 
	egen treat_weights = total(weights) if treat ==1 
	sum treat_weights // should sum to 1 and they do 
		
	egen c_weights = total(weights) if treat ==0 
	sum c_weights // sum is -1

	// Sum weights by state 
	preserve
	keep if treat ==1
*	bysort state_cat: egen sum_weight_by_state = total(weights)
	collapse (sum) sum_weight_by_state = weights, by(state_cat)

	scatter sum_weight_by_state state_cat, ///
		xtitle(" ") yscale(range(-.1 .1)) ylabel(-.1(.05).1, labsize(small)) ///
		yline(0) mlabel(state) mlabposition(6) ///
		xlabel(, noticks nolabel nogrid) ///
		ytitle("DID weights")

	graph export "$figures/state_weights_all.png", replace 	
	restore



	***** Individual state effects
	preserve 
	
	label values state_did state_cat
	drop if inlist(state_did, 42, 54) //drop US territories and WV bc coefficient is too high 

	reghdfe win i.state_did, absorb(basis_state ym_state) vce(cluster basis_state)
	eststo A

	reghdfe win treat, absorb(basis_state ym_state) vce(cluster basis_state)
    loc att: display %5.4f _b[treat]
	
	local my_blue "0 102 204"  
	local my_red "220 20 60"
	local my_purple "128 0 128"

	#delimit ;
	coefplot 
		(A, keep(1.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AK
		(A, keep(2.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AL
		(A, keep(3.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AR
		(A, keep(5.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AZ
		(A, keep(6.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CA
		(A, keep(7.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CO
		(A, keep(8.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CT
		(A, keep(9.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DC
		(A, keep(10.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DE
		(A, keep(11.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // FL
		(A, keep(12.state_did) mcolor("`my_red'") ciopts(color("`my_blue'"))) // GA
		(A, keep(14.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // HI
		(A, keep(15.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // IA
		(A, keep(16.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // ID
		(A, keep(17.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // IL
		(A, keep(18.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // IN
		(A, keep(19.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // KS
		(A, keep(20.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // KY
		(A, keep(21.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // LA
		(A, keep(22.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MA
		(A, keep(23.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MD
		(A, keep(24.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // ME
		(A, keep(25.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MI
		(A, keep(26.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MN
		(A, keep(27.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // MO
		(A, keep(28.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // MS
		(A, keep(29.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // MT
		(A, keep(30.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // NC
		(A, keep(31.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // ND
		(A, keep(32.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // NE
		(A, keep(33.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NH
		(A, keep(34.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NJ
		(A, keep(35.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NM
		(A, keep(36.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NV
		(A, keep(37.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NY
		(A, keep(38.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // OH
		(A, keep(39.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // OK
		(A, keep(40.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // OR
		(A, keep(41.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // PA
		(A, keep(43.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // RI
		(A, keep(44.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // SC
		(A, keep(45.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // SD
		(A, keep(46.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // TN
		(A, keep(47.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // TX
		(A, keep(48.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // UT
		(A, keep(49.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // VA
		(A, keep(52.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // WA
		(A, keep(53.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))), // WI
		drop(_cons)
		vertical omitted 
		legend(off)
		mlabels(1.state_did = 3 "AK" 2.state_did = 3 "AL" 3.state_did = 3 "AR" 5.state_did = 3 "AZ" 6.state_did = 3 "CA" 7.state_did = 3 "CO" 8.state_did = 3 "CT" 9.state_did = 3 "DC" 10.state_did = 3 "DE" 11.state_did = 3 "FL" 12.state_did = 3 "GA" 14.state_did = 3 "HI" 15.state_did = 3 "IA" 16.state_did = 3 "ID" 17.state_did = 3 "IL" 18.state_did = 3 "IN" 19.state_did = 3 "KS" 20.state_did = 3 "KY" 21.state_did = 3 "LA" 22.state_did = 3 "MA" 23.state_did = 3 "MD" 24.state_did = 3 "ME" 25.state_did = 3 "MI" 26.state_did = 3 "MN" 27.state_did = 3 "MO" 28.state_did = 3 "MS" 29.state_did = 3 "MT" 30.state_did = 3 "NC" 31.state_did = 3 "ND" 32.state_did = 3 "NE" 33.state_did = 3 "NH" 34.state_did = 3 "NJ" 35.state_did = 3 "NM" 36.state_did = 3 "NV" 37.state_did = 3 "NY" 38.state_did = 3 "OH" 39.state_did = 3 "OK" 40.state_did = 3 "OR" 41.state_did = 3 "PA" 43.state_did = 3 "RI" 44.state_did = 3 "SC" 45.state_did = 3 "SD" 46.state_did = 3 "TN" 47.state_did = 3 "TX" 48.state_did = 3 "UT" 49.state_did = 3 "VA" 52.state_did = 3 "WA" 53.state_did = 3 "WI")
		xsize(10)
		ciopts(lwidth(thick) recast(rcap))
		sort(, by(b))
		yline(0, lcolor(black)) 
		yline(`att', lcolor(grey) lwidth(medium) lp(dash))
		ytitle("Treatment effect on win", size(medium))
		yscale(range(-.2 .6)) ylabel(-.2(.2).6, labsize(small))
		xtitle("State filed", size(medium))
		xlabel(, noticks nolabel)
		note("Controls include State X Unit and State X Time FE", size(small)) 
		text(.07 5 "ATT: `att'")
		;
	#delimit cr
    graph export "$figures/state_fx_all.png", replace  
	restore


	** State sample
	preserve 
	keep if eeoc == 0

	// FWL regression
	cap drop treat_tilde den num weights c_weights treat_weights sum_weight_by_state
	reghdfe treat, absorb(basis ym) vce(cluster basis) resid 
	predict treat_tilde, residuals

	// Calculate weights 
	g num = treat_tilde  
	egen den = total(treat_tilde * treat_tilde)
	g weights = num / den
	
	// Check if weights created correctly 
	egen treat_weights = total(weights) if treat ==1 
	sum treat_weights // should sum to 1 and they do 
		
	egen c_weights = total(weights) if treat ==0 
	sum c_weights // sum is -1

	// Sum weights by state 
	collapse (sum) sum_weight_by_state = weights, by(state_cat)

	scatter sum_weight_by_state state_cat, ///
		xtitle(" ") yscale(range(-.1 .1)) ylabel(-.1(.05).1, labsize(small)) ///
		yline(0) mlabel(state) mlabposition(6) msize(medlarge) ///
		xlabel(, noticks nolabel nogrid) ///
		ytitle("DID weights")

	graph export "$figures/state_weights.png", replace 

	** Maggie make graph here 	
	bysort state_cat: egen t_weight_by_state = total(weights) if treat == 1
	bysort state_cat: egen c_weight_by_state = total(weights) if treat == 0
	bysort state_cat: egen sum_weight_by_state = total(weights)

	** Maggie - maybe rspike combined with scatter would work? Feel free to experiment. 
	twoway rspike t_weight_by_state c_weight_by_state state_cat
	restore

	
	preserve 
	keep if eeoc == 0

	label values state_did state_cat

	reghdfe win i.state_did, absorb(basis_state ym_state) vce(cluster basis_state) 
	eststo A

	reghdfe win treat, absorb(basis_state ym_state) vce(cluster basis_state)
    loc att: display %5.4f _b[treat]
	
	local my_blue "0 102 204"  
	local my_red "220 20 60"
	local my_purple "128 0 128"

	#delimit ;
	coefplot 
		(A, keep(1.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AK
		(A, keep(10.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DE
		(A, keep(11.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // FL
		(A, keep(14.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // HI
		(A, keep(17.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // IL
		(A, keep(20.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // KY
		(A, keep(22.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MA
		(A, keep(25.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MI
		(A, keep(26.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MN
		(A, keep(31.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // ND
		(A, keep(52.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // WA
		(A, keep(53.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))), // WI
		drop(_cons)
		vertical omitted 
		legend(off)
		mlabels(1.state_did = 3 "AK"
				10.state_did = 3 "DE"
				11.state_did = 3 "FL"
				14.state_did = 3 "HI" 
				17.state_did = 3 "IL" 
				20.state_did = 3 "KY" 
				22.state_did = 3 "MA" 
				25.state_did = 3 "MI"
				26.state_did = 3 "MN"
				31.state_did = 3 "ND"
				52.state_did = 3 "WA"
				53.state_did = 3 "WI")
		ciopts(lwidth(thick) recast(rcap))
		sort(, by(b))
		yline(0, lcolor(black)) 
		yline(`att', lcolor(grey) lwidth(medium) lp(dash))
		ytitle("Treatment effect on win", size(medium))
		xtitle("State filed", size(medium))
		xlabel(, noticks nolabel)
		yscale(range(-.2 .6)) ylabel(-.2(.2).6, labsize(small))
		note("Controls include State X Unit and State X Time FE", size(small)) 
		text(-.05 2 "ATT: `att'")
		;
	#delimit cr
    graph export "$figures/state_fx.png", replace  
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


