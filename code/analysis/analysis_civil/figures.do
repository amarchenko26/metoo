* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc tabulations		= 0
loc selection 		= 1
loc event 	   		= 0
loc timeseries 		= 0
loc state_did  		= 1
loc run_placebo 	= 0
loc run_placebo_single = 0
loc run_placebo_overlap = 0
loc run_placebo_f 	= 0
loc duration   		= 0
loc yhat			= 0

/*******************************************************************************
Tabulations
*******************************************************************************/

if `tabulations' == 1 {
	
	// Complaint flow diagram
	tab dismissed //arrow to "Dismissed": 10.22 when run on Feb 25, 2025
	tab settle //arrow to "Settled": 10.82 when run on Feb 25, 2025
	tab court //arrow to "Court": 29.95 when run on Feb 25, 2025
	tab investigation //added to court for arrow to "Investigation or Court": 49.19 when run on Feb 25, 2025
	tab win_investigation //arrow to "Won": 7.30 when run on Feb 25, 2025
	tab lose_investigation //arrow to "Lost": 41.89 when run on Feb 25, 2025
	
	// Percent change in cases filed (Pre-COVID): 0.0513324 when run on Feb 25, 2025
	preserve
	di tm(2020m3) // 722
	di tm(2017m10) // 693
	tab state if ym_filed > 693 & ym_filed < 722
	tab state if ym_filed < 693 & ym_filed > 664
	drop if inlist(state, "CA", "FL", "WI") // based on tabbing and seeing if there were large differences
	count if ym_filed > 693 & ym_filed < 722 & sh == 1
	gen sex_post_metoo = r(N)
	count if ym_filed > 693 & ym_filed < 722 & sh == 0
	gen no_sex_post_metoo = r(N)
	count if ym_filed < 693 & ym_filed > 664 & sh == 1
	gen sex_pre_metoo = r(N)
	count if ym_filed < 693 & ym_filed > 664 & sh == 0
	gen no_sex_pre_metoo = r(N)
	gen covid_percent_increase = ((sex_post_metoo/no_sex_post_metoo) - (sex_pre_metoo/no_sex_pre_metoo))/(sex_pre_metoo/no_sex_pre_metoo)
	tab covid_percent_increase
	drop *metoo
	restore


	// Percent change in cases filed (MeToo): 0.1388661 when run on Feb 25, 2025
	preserve
	di td($metoo) // 21107
	tab state if charge_file_date > 21107 & charge_file_date < 21472
	tab state if charge_file_date < 21107 & charge_file_date > 20742
	drop if inlist(state, "CA", "WI") // based on tabbing and seeing if there were large differences

	g filed_first_year_post = 1 if charge_file_date > 21107 & charge_file_date < 21472
	g filed_first_year_pre  = 1 if charge_file_date < 21107 & charge_file_date > 20742
	
	// Total increase in number of complaints filed 
	count if filed_first_year_post == 1
	gen filed_first_year_post_count = r(N)
	count if filed_first_year_pre == 1
	gen filed_first_year_pre_count = r(N)
	// Percent change in number of complaints filed
	g total_change = (filed_first_year_post_count - filed_first_year_pre_count) / filed_first_year_pre_count
	tab total_change

	// Percent change in cases filed (MeToo): 0.1388661 when run on Feb 25, 2025
	// .0532972 when run on May 27, 2025
	count if filed_first_year_post == 1 & sh == 1
	gen sex_post_metoo = r(N)
	count if filed_first_year_post == 1 & sh == 0
	gen no_sex_post_metoo = r(N)
	count if filed_first_year_pre == 1 & sh == 1
	gen sex_pre_metoo = r(N)
	count if filed_first_year_pre == 1 & sh == 0
	gen no_sex_pre_metoo = r(N)

	gen metoo_percent_increase = ((sex_post_metoo/no_sex_post_metoo) - (sex_pre_metoo/no_sex_pre_metoo))/(sex_pre_metoo/no_sex_pre_metoo)
	tab metoo_percent_increase
	
	// Omegas
	tab sex_post_metoo
	tab no_sex_post_metoo
	tab sex_pre_metoo 
	tab no_sex_pre_metoo
	gen control_frac = (no_sex_post_metoo-no_sex_pre_metoo)/no_sex_pre_metoo
	gen sex_frac = (sex_post_metoo-sex_pre_metoo)/sex_pre_metoo
	gen omega_1 = control_frac/sex_frac
	tab omega_1
	
	gen omega_2 = sex_pre_metoo/(sex_post_metoo/(1+control_frac))
	tab omega_2
	
	gen omega_3 = sex_pre_metoo/(sex_post_metoo/0.989)
	tab omega_3
	drop *metoo

	// Male complainants as share of total sex complaints after MeToo: -.3072776 when run on Feb 26, 2025
	keep if sh == 1

	count if filed_first_year_post == 1 & victim_f == 0 
	gen sex_post_metoo_men = r(N)
	count if filed_first_year_post == 1 
	gen sex_post_metoo = r(N)

	count if filed_first_year_pre == 1 & victim_f == 0 
	gen sex_pre_metoo_men = r(N)
	count if filed_first_year_pre == 1 
	gen sex_pre_metoo = r(N)

	gen metoo_percent_increase_men = ((sex_post_metoo_men/sex_post_metoo) - (sex_pre_metoo_men/sex_pre_metoo))/(sex_pre_metoo_men/sex_pre_metoo)
	tab metoo_percent_increase_men
	drop *metoo
	restore 
	
}

/*******************************************************************************
Selection 
*******************************************************************************/

if `selection' == 1 {
	preserve 
	clear
	
	set obs 11
	g omega = (_n - 1) / 10

	insobs 1  
	replace omega = 0.745 if _n == _N // Add method 1 omega

	insobs 1  
	replace omega = 0.949 if _n == _N // Add method 2 omega

	insobs 1  
	replace omega = 0.793 if _n == _N // Add method 3 omega

	g omega_c = 1-omega
	g twfe 	  = 0.123 
	g overlap = 0.086

	// TWFE = omega (A-C) + (1-omega) (B-C)
	g bc = (twfe - (omega*overlap))/omega_c
	
	#delimit ;
	twoway scatter bc omega,
			ytitle("Treatment effect on induced reporters", size(medium))
			ylabel(0(.2)1)
			title("Treatment effect on induced reporters for given values of {&omega}")
			xtitle("{&omega} = Share always reporters", size(medlarge))
			mlabel(omega) mlabposition(6) 
			msize(large) mlabsize(medium)
			mcolor(orange_red) //mcolor("0 102 204")
			legend(off) //xline(.4, lcolor(orange_red) lp(dash) lwidth(medium))
			text(.4 .05 "TEs for induced reporters" "positive under all values of {&omega}", color("gs3") place(r) size(medlarge))
			xlabel(0 `" "All Induced" "Reporters" "' 
				  .2 " "
				  .4 " "
				  .5 " " // `" "Half Always /" "Half New" "Reporters" "' 
				  .6 " "
				  .8 " "
				  .97 `" "All Always" "Reporters" "' 1 " ", labsize(medlarge) noticks)
			xsize(8)
		;
	/* addplot: pcarrowi -.22 0.63 -.17 0.63 (6) "No change in incidence",
		mlabsize(small) mcolor(orange) lcolor(orange)
		;
	addplot: pcarrowi -.50 0.87 -.55 0.87 (12) "Sex incidence increases by control file rate",
		mlabsize(small) mcolor(orange) lcolor(orange)
		;
	addplot: pcarrowi -.05 0.65 -.11 0.65 (12) "Sex incidence decreases by 1.1pp",
		mlabsize(small) mcolor(orange) lcolor(orange)
		; */
	#delimit cr

	graph export "$figures/omega.png", replace  
	restore
}

/*******************************************************************************
Event-study
*******************************************************************************/

loc outcomes "settle dismissed win court"

if `event' == 1 {

	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	drop if event   == 0
	drop if event_f == 0

	******** All outcomes ********
	foreach y in `outcomes' {
		reghdfe `y' ib7.event, absorb(basis_state ym_res_state) vce(cluster basis) noconstant
		estimates store TWFE

		// Create dynamic xlabel with offset adjustment
		local max_event = 0
		local coef_names : colnames e(b)

		foreach cname of local coef_names {
			if strpos("`cname'", ".event") > 0 {
				local evnum = substr("`cname'", 1, strpos("`cname'", ".event") - 1)
				
				capture confirm number `evnum'
				if _rc == 0 & real("`evnum'") > `max_event' {
					local max_event = real("`evnum'")
				}
			}
		}
		local xlabel "xlabel("
		forvalues x = 1/`max_event' {
			local rel = `x' - `offset'
			local xlabel `xlabel' `x' "`rel'"
		}
		local xlabel "`xlabel', labsize(medium))"

		// Run Rambachan & Roth (2021)
		honestdid, numpre(7) omit ///
			coefplot xtitle(Mbar) ytitle(95% Robust CI)
		graph export "$figures/honestdid_`y'.png", replace

		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge)), vertical
			ciopts(recast(rcap) lwidth(.4) color(orange_red)) 
			yline(0, lp(dash))
			ylabel(-0.1(0.05)0.2)
			xline(7.5)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on `y'", size(medium))
			`xlabel'
		;
		#delimit cr
					
		graph export "$figures/eventstudy_`y'.png", replace 
		estimates clear
	}	

******** Relief ********
	reghdfe relief_scale ib7.event, ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis) noconstant
	estimates store TWFE

	honestdid, numpre(6) omit ///
		coefplot xtitle(Mbar) ytitle(95% Robust CI)
	graph export "$figures/honestdid_relief_scale.png", replace

	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge)), vertical
		ciopts(recast(rcap) lwidth(.4) color(orange_red)) 
		yline(0, lp(dash)) 
		xline(6.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on compensation ($1000s)", size(medium))
		xlabel(1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3" 11 "4", labsize(medium))
	;
	#delimit cr
				
	graph export "$figures/eventstudy_relief_scale.png", replace 
	estimates clear

******** Overlap ********
	reghdfe win ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis) noconstant
	estimates store TWFE

	// Create dynamic xlabel with offset adjustment
	local max_event = 0
	local coef_names : colnames e(b)

	foreach cname of local coef_names {
		if strpos("`cname'", ".event") > 0 {
			local evnum = substr("`cname'", 1, strpos("`cname'", ".event") - 1)
			
			capture confirm number `evnum'
			if _rc == 0 & real("`evnum'") > `max_event' {
				local max_event = real("`evnum'")
			}
		}
	}
	local xlabel "xlabel("
	forvalues x = 1/`max_event' {
		local rel = `x' - `offset'
		local xlabel `xlabel' `x' "`rel'"
	}
	local xlabel "`xlabel', labsize(medium))"

	// Make graph
	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge)), vertical
		ciopts(recast(rcap) lwidth(.4) color(orange_red)) 
		yline(0, lp(dash)) 
		ylabel(-0.1(0.1)0.4)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel';
	#delimit cr
				
	graph export "$figures/eventstudy_win_overlap.png", replace 
	estimates clear
		
		
******** Female complainants only ********
	cap program drop repostb
	program repostb,  eclass
	erepost b = b, rename
	end
	
	reghdfe win ib7.event_f ib7.event, ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis) noconstant
	estimates store full

	// Create dynamic xlabel with offset adjustment
	local max_event = 0
	local coef_names : colnames e(b)

	foreach cname of local coef_names {
		if strpos("`cname'", ".event") > 0 {
			local evnum = substr("`cname'", 1, strpos("`cname'", ".event") - 1)
			
			capture confirm number `evnum'
			if _rc == 0 & real("`evnum'") > `max_event' {
				local max_event = real("`evnum'")
			}
		}
	}
	local xlabel "xlabel("
	forvalues x = 1/`max_event' {
		local rel = `x' - `offset'
		local xlabel `xlabel' `x' "`rel'"
	}
	local xlabel "`xlabel', labsize(medium))"

	local j 1
	forval i = 1/`max_event' {
		estimates restore full
		margins, expression(_b[`i'.event]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		repostb
		est sto coef`j'
		local ++j
	}
	local j `=`j'-1'
	forval i = 1/`max_event' {
		estimates restore full
		margins, expression(_b[`i'.event]+ _b[`i'.event_f]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		local ++j
		repostb
		est sto coef`j'
	}

	#delimit ; 
	coefplot (coef1\coef2\coef3\coef4\coef5\coef6\coef7\coef8\coef9\coef10\coef11\coef12\coef13\coef14,
	omitted baselevel label(Male) ciopts(recast(rcap) lwidth(.4) color(navy)))
	(coef15\coef16\coef17\coef18\coef19\coef20\coef21\coef22\coef23\coef24\coef25\coef26\coef27\coef28,
	omitted baselevel label(Female) ciopts(recast(rcap) lwidth(.4) color(orange_red))),
		vertical
		legend(ring(0) bplacement(nwest) size(medium))
		offset(0)
		yline(0, lp(dash)) ylabel(-1(0.2)1)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
	;
	#delimit cr
				
	graph export "$figures/eventstudy_win_female.png", replace 
	estimates clear
	 
******** Female complainants OVERLAP ********
	reghdfe win ib7.event_f ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis) noconstant
	estimates store full

	// Create dynamic xlabel with offset adjustment
	local max_event = 0
	local coef_names : colnames e(b)

	foreach cname of local coef_names {
		if strpos("`cname'", ".event") > 0 {
			local evnum = substr("`cname'", 1, strpos("`cname'", ".event") - 1)
			
			capture confirm number `evnum'
			if _rc == 0 & real("`evnum'") > `max_event' {
				local max_event = real("`evnum'")
			}
		}
	}
	local xlabel "xlabel("
	forvalues x = 1/`max_event' {
		local rel = `x' - `offset'
		local xlabel `xlabel' `x' "`rel'"
	}
	local xlabel "`xlabel', labsize(medium))"

	local j 1
	forval i = 1/`max_event' {
		estimates restore full
		margins, expression(_b[`i'.event]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		repostb
		est sto coef`j'
		local ++j
	}
	local j `=`j'-1'
	forval i = 1/`max_event' {
		estimates restore full
		margins, expression(_b[`i'.event]+ _b[`i'.event_f]) post
		mat b = e(b)
		mat colname b = "coef`i'"
		local ++j
		repostb
		est sto coef`j'
	}

	#delimit ; 
	coefplot (coef1\coef2\coef3\coef4\coef5\coef6\coef7\coef8\coef9,
	omitted baselevel label(Male) ciopts(recast(rcap) lwidth(.4) color(navy)))
	(coef10\coef11\coef12\coef13\coef14\coef15\coef16\coef17\coef18,
	omitted baselevel label(Female) ciopts(recast(rcap) lwidth(.4) color(orange_red))),
		vertical
		legend(ring(0) bplacement(nwest) size(medium))
		ciopts(recast(rcap) lwidth(.4) color(orange_red)) 
		offset(0)
		yline(0, lp(dash)) ylabel(-1(0.2)1)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
	;
	#delimit cr
	
	graph export "$figures/eventstudy_win_female_overlap.png", replace 
	estimates clear
		
}

/*******************************************************************************
Cases/outcomes over time 
*******************************************************************************/

if `timeseries' == 1 {

    preserve
	drop if inlist(state, "CA", "WI")
	/*
	collapse (sum) mean_y = y, by(ym_filed state_cat)
	reg mean_y i.state_cat, r 
	predict resid_num, resid

	collapse (mean) mean_resid_by_ym = resid_num, by(ym_filed) */
	collapse (sum) mean_resid_by_ym = y, by(ym_filed sh)

	loc height = 15
	#delimit ;
	twoway 
		scatter mean_resid_by_ym ym_filed if sh == 1, mcolor("orange_red") msize(small) yaxis(1)
		||	lpolyci mean_resid_by_ym ym_filed if sh == 1, acolor("orange_red %65") lwidth(medium) clpattern(dash) clcolor(black) yaxis(1)
		||
		scatter mean_resid_by_ym ym_filed if sh == 0, mcolor("gs3") msize(small) yaxis(2)
		||	lpolyci mean_resid_by_ym ym_filed if sh == 0, acolor("gs3 %65") lwidth(medium) clpattern(dash) clcolor(black) yaxis(2) 
		|| pcarrowi `height' 729 `height' 723, mlabsize(small) mcolor(black) lcolor(black)
		|| pcarrowi `height' 686 `height' 692, mlabsize(small) mcolor(black) lcolor(black)
		legend(off)
		xtitle("Date filed", size(medium))
		xline(693, lpattern(solid))
		xline(722, lpattern(solid))
		title("Number of complaints filed over time")
		ytitle("Number of complaints", axis(1) size(medium))
		text(`height' 730 "Covid-19", color("gs3") place(r) size(medlarge))
		text(`height' 685 "#MeToo", color("gs3") place(l) size(medlarge)) 
	;
	#delimit cr
    graph export "$figures/timeseries_sex_filed.png", replace
    restore


	**** TIMESERIES WIN ALT WITH BALANCED PANEL 
	preserve 
	drop if inlist(state, "CA", "WI")

	loc Yvar win
	loc Xvar ym_filed
 	collapse (mean) mean_y = `Yvar', by(`Xvar' sh)
    
    sum `Xvar', d
    loc xmin = r(min)
    loc xmax = r(max)
    
    loc xlabel_cmd `"xlabel(`xmin'(12)`xmax', angle(45) format(%tm))"'

    #delimit ;
    twoway 
        lpolyci mean_y `Xvar' if sh == 0, acolor("gs3 %65") lwidth(medium) clpattern(solid) clcolor(black)
        || lpolyci mean_y `Xvar' if sh == 1, acolor("orange_red %65") lwidth(medium) clpattern(dash) clcolor(black)
        || scatter mean_y `Xvar' if sh == 0, mcolor("gs3") msize(small)
        || scatter mean_y `Xvar' if sh == 1, mcolor("orange_red") msize(small)
		|| pcarrowi .35 729 .35 723, mlabsize(small) mcolor(black) lcolor(black)
		|| pcarrowi .35 686 .35 692, mlabsize(small) mcolor(black) lcolor(black)
        legend(order(3 1) lab(3 "Sex complaints, 95% CI") lab(1 "Other complaints, 95% CI") size(medium) ring(0) pos(11) rows(2))
        xtitle("Date filed", size(medium))
        xline(693, lpattern(solid))
        xline(722, lpattern(solid))
		text(.35 685 "MeToo", color("gs3") place(l) size(medium)) 
        text(.35 730 "Covid-19", color("gs3") place(r) size(medium))
        `xlabel_cmd'
        ytitle("Probability of win", size(medium))
    ;
    #delimit cr
	graph export "$figures/timeseries_win.png", replace
    restore


	preserve 
	drop if inlist(state, "CA", "WI")

	* Women winning vs men winning vs. other complaints 
	plot_lpolyci_gender win ym_filed, title("Probability of Winning by Complainant Gender (balanced panel)") ylabel("Probability of win")

	plot_lpolyci settle ym_filed, title("Probability Complainant Settles Over Time (balanced panel)") ylabel("Probability settled")

	plot_lpolyci dismissed ym_filed, title("Probability Complaint Dismissed Over Time (balanced panel)") ylabel("Probability dismissed")

	plot_lpolyci relief_scale ym_filed, title("Compensation Paid to Complainant (conditional on winning, balanced panel)") ylabel("Compensation in $1000s")
	restore

}

/*******************************************************************************
State-level DID 
*******************************************************************************/

if `state_did' == 1 {

	** State sample
	preserve 

	// FWL regression
	cap drop treat_tilde den num weights c_weights treat_weights sum_weight_by_state
	reghdfe treat_sex, absorb(basis_state ym_res_state) vce(cluster basis) resid 
	predict treat_tilde, residuals

	// Calculate weights 
	g num = treat_tilde  
	egen den = total(treat_tilde * treat_tilde)
	g weights = num / den
	
	// Check if weights created correctly 
	egen treat_weights = total(weights) if treat_sex ==1 
	sum treat_weights // should sum to 1 and they do 
		
	egen c_weights = total(weights) if treat_sex ==0 
	sum c_weights // sum is -1
	
	// Range plot
	bysort state_cat: egen t_weight_by_state = total(weights) if treat_sex == 1
	bysort state_cat: egen c_weight_by_state = total(weights) if treat_sex == 0
	bysort state_cat: egen sum_weight_by_state = total(weights)
	
	collapse (max) t_weight_by_state c_weight_by_state sum_weight_by_state, by(state)
	sort sum_weight_by_state
	gen order = _n
	labmask order, values(state)
	
	twoway rspike t_weight_by_state c_weight_by_state order, ///
	|| scatter t_weight_by_state order, m(T) mc(green) ///
	|| scatter c_weight_by_state order, m(S) mc(red) ///
	|| scatter sum_weight_by_state order, m(O) mc(black) ///
		mlabel(state) mlabposition(3) ///
		xlabel(, noticks nolabel nogrid) xtitle(" ") ///
		legend(label(1 "") label(2 "Treated") label(3 "Control") label(4 "Sum"))
	
	graph export "$figures/state_range_weights.png", replace 
	restore

		
	preserve 

	label values state_did_sex state_cat
	reghdfe win i.state_did_sex, absorb(basis_state ym_res_state) vce(cluster basis) noconstant
	eststo A

	reghdfe win treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
    loc att: display %5.4f _b[treat_sex]
	
	local my_blue "0 102 204"  
	local my_red "220 20 60"
	local my_purple "128 0 128"

	#delimit ;
	coefplot 
		(A, keep(1.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // AK
		(A, keep(6.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CA
		/* (A, keep(10.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DE */
		(A, keep(11.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // FL
		(A, keep(14.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // HI
		/* (A, keep(17.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // IL */
		(A, keep(20.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // KY
		(A, keep(22.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MA
		(A, keep(25.state_did_sex) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // MI
		/* (A, keep(26.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MN
		(A, keep(29.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // MT
		(A, keep(30.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // NC */
		(A, keep(31.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // ND
		(A, keep(37.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NY
		/* (A, keep(41.state_did_sex) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // PA
		(A, keep(43.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // RI
		(A, keep(44.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // SC
		(A, keep(47.state_did_sex) mcolor("`my_red'") ciopts(color("`my_red'"))) // TX
		(A, keep(52.state_did_sex) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // WA */
		(A, keep(53.state_did_sex) mcolor("`my_purple'") ciopts(color("`my_purple'"))), // WI
		drop(_cons)
		vertical omitted 
		legend(off)
		mlabels(1.state_did_sex = 3 "AK"
				6.state_did_sex = 3 "CA"
				/* 10.state_did_sex = 3 "DE" */
				11.state_did_sex = 3 "FL"
				14.state_did_sex = 3 "HI" 
				/* 17.state_did_sex = 3 "IL"  */
				20.state_did_sex = 3 "KY" 
				22.state_did_sex = 3 "MA" 
				25.state_did_sex = 3 "MI"
				/* 26.state_did_sex = 3 "MN"
				29.state_did_sex = 3 "MT"
				30.state_did_sex = 3 "NC" */
				31.state_did_sex = 3 "ND"
				37.state_did_sex = 3 "NY"				
				/* 41.state_did_sex = 3 "PA"
				43.state_did_sex = 3 "RI"
				44.state_did_sex = 3 "SC"
				47.state_did_sex = 3 "TX"
				52.state_did_sex = 3 "WA" */
				53.state_did_sex = 3 "WI")
		ciopts(lwidth(thick) recast(rcap))
		sort(, by(b))
		yline(0, lcolor(black)) 
		yline(`att', lcolor(grey) lwidth(medium) lp(dash))
		ytitle("Treatment effect on P(win)", size(medium))
		xtitle("State filed", size(medium))
		xlabel(, noticks nolabel) //yscale(range(-.1 .5)) ylabel(-.1(.2).5, labsize(small))
		note("Fixed effects: unit/state and year-month/state", size(small)) 
		text(0.125 2.5 "Overall ATT: `att'")
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
		drop if basis == "Sex" // drop real treated cases

		levelsof basis_cat, local(levels)
		foreach l of local levels {
			g placebo_treat_`l' = (post==1 & basis_cat == `l') 	
		}

		foreach y of local outcome_vars {
			forvalues index = 1(1)6 {
				reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
				eststo s_r_`i'
				loc ++i
			}
		}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
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
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sex", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment test", size(medium));
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
	drop if basis == "Sex" // drop real treated cases
	keep if multi_cat == 0 // only single-tagged cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l')
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat if multi_cat == 0, absorb(basis_state ym_res_state) vce(cluster basis)
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
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sex", labsize(medium)) // angle(45)
		xline(0, lc(gs8) lp(dash))
		xtitle("Effect of MeToo", size(medium))
		ytitle("Placebo treatment test for single-basis complaints", size(medium));
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
	drop if basis == "Sex"  // drop real treated cases
	keep if common_file_date < date("$metoo", "DMY")

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l')
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
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
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sex", labsize(medium)) // angle(45)
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
	drop if basis == "Sex" // drop real treated cases

	levelsof basis_cat, local(levels)
	foreach l of local levels {
		g placebo_treat_`l' = (post==1 & basis_cat == `l' & victim_f==1)
	}

	foreach y of local outcome_vars {
		forvalues index = 1(1)6 {
			reghdfe ``y'' placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo s_r_`i'
			loc ++i
		}
	}
	restore

	// True treatment effect 
	foreach y of local outcome_vars {
		reghdfe ``y'' treat_sex_f treat_sex, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
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
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "Sex", labsize(medium)) // angle(45)
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
	twoway (kdensity duration if ym_filed == 684, lcolor(gray) fcolor(gray%0) recast(area))
		   (kdensity duration if ym_filed == 685, lcolor(yellow) fcolor(yellow%0) recast(area))
		   (kdensity duration if ym_filed == 686, lcolor(green) fcolor(green%0) recast(area))
		   (kdensity duration if ym_filed == 687, lcolor(orange) fcolor(orange%0) recast(area))
		   (kdensity duration if ym_filed == 688, lcolor(red) fcolor(red%0) recast(area))
		   (kdensity duration if ym_filed == 689, lcolor(navy) fcolor(navy%0) recast(area))
		   (kdensity duration if ym_filed == 690, lcolor(yellow) fcolor(yellow%0) recast(area))
		   (kdensity duration if ym_filed == 691, lcolor(lime) fcolor(lime%0) recast(area))
		   (kdensity duration if ym_filed == 692, lcolor(teal) fcolor(teal%40) recast(area))
		   (kdensity duration if ym_filed == 693, lcolor(maroon) fcolor(maroon%0) recast(area))
		   (kdensity duration if ym_filed == 694, lcolor(red) fcolor(red%0) recast(area))
		   (kdensity duration if ym_filed == 695, lcolor(pink) fcolor(pink%0) recast(area))
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

