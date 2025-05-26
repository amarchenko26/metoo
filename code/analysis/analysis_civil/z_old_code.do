//EVENT STUDY CODE THAT DROPS LAST COEFFICIENTS
******** Overlap (drop last coefs) ********
	preserve
	drop if inlist(event, 0, 13, 14)

	// Create dynamic xlabel with offset adjustment
	sum event, meanonly
	loc xmin = r(min)
	loc xmax = r(max)
			
	loc xlabel "xlabel("
	forvalues x = `xmin'/`xmax' {
		loc rel = `x' - `offset'
		loc xlabel `xlabel' `x' "`rel'" 
	}
	loc xlabel "`xlabel', labsize(medium))"

	reghdfe win ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis) noconstant
	estimates store TWFE

	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge)), vertical
		ciopts(recast(rcap) lwidth(.4) color(orange_red)) 
		yline(0, lp(dash))
		ylabel(-0.1(0.05)0.2)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel';
	#delimit cr
				
	graph export "$figures/eventstudy_win_overlap.png", replace 
	estimates clear

******** Female complainants OVERLAP (drop last coefs) ********
	drop if inlist(event_f, 0, 13, 14)
	
	reghdfe win ib7.event_f ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis) noconstant
	estimates store full
	local j 1
	forval i = 1/`xmax' {
		estimates restore full
		margins, expression(_b[`i'.event]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		repostb
		est sto coef`j'
		local ++j
	}
	local j `=`j'-1'
	forval i = 1/`xmax' {
		estimates restore full
		margins, expression(_b[`i'.event]+ _b[`i'.event_f]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		local ++j
		repostb
		est sto coef`j'
	}
	
	#delimit ; 
	coefplot (coef1\coef2\coef3\coef4\coef5\coef6\coef7\coef8\coef9\coef10\coef11,
	omitted baselevel label(Male))
	(coef12\coef13\coef14\coef15\coef16\coef17\coef18\coef19\coef20\coef21\coef22,
	omitted baselevel label(Female)),
		vertical
		legend(ring(0) bplacement(nwest) size(medium))
		ciopts(recast(rcap) msize(medium))
		recast(connected) offset(0)
		yline(0, lp(dash))
		ylabel(-0.1(0.05)0.2)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
	;
	#delimit cr
				
	graph export "$figures/eventstudy_win_female_overlap.png", replace 
	estimates clear	
	restore

		/* 
		// ALTERNATIVE EVENT STUDY CODE
		sum years_to_treat_res
		loc min = r(min)
		loc max = r(max)

		loc j = 1
		forvalues i = `min'(1)`max' {
			gen treatyr`j' = 0
			replace treatyr`j' = 1 if sh == 1 & years_to_treat_res == `i'
			loc j = `j' + 1
		}

		reghdfe `y' treatyr1-treatyr7 zero treatyr9-treatyr14, ///
			absorb(basis_state ym_res_state) ///
			vce(cluster basis) 
			
		estimates store TWFE
				
		#delimit ;
		coefplot TWFE, drop(_cons) omitted vertical
			ciopts(recast(rcap) msize(medium) color(orange_red))
			addplot(line @b @at, lcolor(orange_red*0.8))
			yline(0, lp(dash)) //yscale(range(-.1 .1)) ylabel(-.1(.025).1, labsize(small))
			xline(8.5)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on `y'", size(medium)) xlabel(1 "-8" 2 "-7" 3 "-6" 4 "-5" 5 "-4" 6 "-3" 7 "-2" 8 "-1" 9 "0" 10 "1" 11 "2" 12 "3" 13 "4" 14 "5", labsize(medium)) 
			note("Fixed effects: unit/state and year-month/state", size(small))
		;
		#delimit cr
		graph export "$figures/eventstudy_`y'_state_new.png", replace  */


/* if `timeseries_basis' == 1 {
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
	collapse (mean) mean_settle = settle, by(ym_filed basis)
		lowess mean_settle ym_filed if basis == "Age", gen(lowess1) nograph
		lowess mean_settle ym_filed if basis == "Race", gen(lowess2) nograph
		lowess mean_settle ym_filed if basis == "Disability", gen(lowess3) nograph
		lowess mean_settle ym_filed if basis == "Religion", gen(lowess4) nograph
		lowess mean_settle ym_filed if basis == "Nationality", gen(lowess5) nograph
		lowess mean_settle ym_filed if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_settle ym_filed if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym_filed == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym_filed == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym_filed == 764, meanonly
		local call `call' text(`r(mean)' 764 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Sex", color("magenta") place(r) size(small))
	#delimit ;
	twoway
		lowess mean_settle ym_filed if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_settle ym_filed if basis == "Race", color("blue") lwidth(thick) 
		|| lowess mean_settle ym_filed if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_settle ym_filed if basis == "Religion", color("red") lwidth(thick) 
		|| lowess mean_settle ym_filed if basis == "Nationality", color("orange") lwidth(thick) 
		|| lowess mean_settle ym_filed if basis == "Retaliation", color("brown") lwidth(thick)  
		|| lowess mean_settle ym_filed if basis == "Sex", color("magenta") lwidth(thick) 
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of settling", size(medium)) 
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_settle.png", replace
    restore
	
	preserve
	collapse (mean) mean_dismissed = dismiss, by(ym_filed basis)
		lowess mean_dismissed ym_filed if basis == "Age", gen(lowess1) nograph
		lowess mean_dismissed ym_filed if basis == "Race", gen(lowess2) nograph
		lowess mean_dismissed ym_filed if basis == "Disability", gen(lowess3) nograph
		lowess mean_dismissed ym_filed if basis == "Religion", gen(lowess4) nograph
		lowess mean_dismissed ym_filed if basis == "Nationality", gen(lowess5) nograph
		lowess mean_dismissed ym_filed if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_dismissed ym_filed if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym_filed == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym_filed == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym_filed == 764, meanonly
		local call `call' text(`r(mean)' 764 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Sex", color("magenta") place(r) size(small))
	#delimit ;
	twoway
		lowess mean_dismissed ym_filed if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_dismissed ym_filed if basis == "Race", color("blue") lwidth(thick) 
		|| lowess mean_dismissed ym_filed if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_dismissed ym_filed if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_dismissed ym_filed if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_dismissed ym_filed if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_dismissed ym_filed if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of dismissal", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_dismissed.png", replace
    restore
	
	preserve
	collapse (mean) mean_relief = relief_scale, by(ym_filed basis)
		lowess mean_relief ym_filed if basis == "Age", gen(lowess1) nograph
		lowess mean_relief ym_filed if basis == "Race", gen(lowess2) nograph
		lowess mean_relief ym_filed if basis == "Disability", gen(lowess3) nograph
		lowess mean_relief ym_filed if basis == "Religion", gen(lowess4) nograph
		lowess mean_relief ym_filed if basis == "Nationality", gen(lowess5) nograph
		lowess mean_relief ym_filed if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_relief ym_filed if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym_filed == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym_filed == 761, meanonly
		local call `call' text(`r(mean)' 761 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym_filed == 764, meanonly
		local call `call' text(`r(mean)' 764 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym_filed == 759, meanonly
		local call `call' text(`r(mean)' 759 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym_filed == 759, meanonly
		local call `call' text(`r(mean)' 759 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym_filed == 764, meanonly
		local call `call' text(`r(mean)' 764 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym_filed == 764, meanonly
		local call `call' text(`r(mean)' 764 "Sex", color("magenta") place(r) size(small)) 
	#delimit ;
	twoway
		lowess mean_relief ym_filed if basis == "Age", color("gs3") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Race", color("blue") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_relief ym_filed if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Compensation", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_relief.png", replace
    restore
	
	preserve
	collapse (mean) mean_prob_cause = win, by(ym_filed basis)
		lowess mean_prob_cause ym_filed if basis == "Age", gen(lowess1) nograph
		lowess mean_prob_cause ym_filed if basis == "Race", gen(lowess2) nograph
		lowess mean_prob_cause ym_filed if basis == "Disability", gen(lowess3) nograph
		lowess mean_prob_cause ym_filed if basis == "Religion", gen(lowess4) nograph
		lowess mean_prob_cause ym_filed if basis == "Nationality", gen(lowess5) nograph
		lowess mean_prob_cause ym_filed if basis == "Retaliation", gen(lowess6) nograph
		lowess mean_prob_cause ym_filed if basis == "Sex", gen(lowess7) nograph
		su lowess1 if basis == "Age" & ym_filed == 765, meanonly
		local call text(`r(mean)' 765 "Age", color("gs3") place(r) size(small))
		su lowess2 if basis == "Race" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Race", color("blue") place(r) size(small)) 
		su lowess3 if basis == "Disability" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Disability", color("purple") place(r) size(small)) 
		su lowess4 if basis == "Religion" & ym_filed == 763, meanonly
		local call `call' text(`r(mean)' 763 "Religion", color("red") place(r) size(small)) 
		su lowess5 if basis == "Nationality" & ym_filed == 760, meanonly
		local call `call' text(`r(mean)' 760 "Nationality", color("orange") place(r) size(small)) 
		su lowess6 if basis == "Retaliation" & ym_filed == 765, meanonly
		local call `call' text(`r(mean)' 765 "Retaliation", color("brown") place(r) size(small)) 
		su lowess7 if basis == "Sex" & ym_filed == 763, meanonly
		local call `call' text(`r(mean)' 763 "Sex", color("magenta") place(r) size(small)) 
	#delimit ;
	twoway
		lowess mean_prob_cause ym_filed if basis == "Age", color("gs3") lwidth(thick) 
		|| lowess mean_prob_cause ym_filed if basis == "Race", color("blue") lwidth(thick)
		|| lowess mean_prob_cause ym_filed if basis == "Disability", color("purple") lwidth(thick)
		|| lowess mean_prob_cause ym_filed if basis == "Religion", color("red") lwidth(thick)
		|| lowess mean_prob_cause ym_filed if basis == "Nationality", color("orange") lwidth(thick)
		|| lowess mean_prob_cause ym_filed if basis == "Retaliation", color("brown") lwidth(thick)
		|| lowess mean_prob_cause ym_filed if basis == "Sex", color("magenta") lwidth(thick)
	`call' legend(off)
	xtitle("Date filed", size(medium))
	ytitle("Probability of winning", size(medium))
	xline(693, lpattern(solid));
	#delimit cr
    graph export "$figures/timeseries_basis_win.png", replace
    restore
} */


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


