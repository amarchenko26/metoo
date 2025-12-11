* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc tabulations		= 1
loc selection 		= 0
loc event 	   		= 0
loc timeseries 		= 0
loc duration   		= 0
loc file_invariance = 0

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
	
	// First 8 months percent change in cases filed (No WI): 2.85 when run on Jun 17, 2025
	preserve
	di td("15feb2017") // 20865, when CA and FL have both begun reporting
	di td("15oct2017") // 21107, MeToo
	di td("15jun2018") // 21350, same time post MeToo
	drop if inlist(state, "WI") 
	count if charge_file_date > 21107 & charge_file_date < 21350 & sh == 1
	gen sex_post_metoo = r(N) 
	count if charge_file_date > 21107 & charge_file_date < 21350 & sh == 0
	gen no_sex_post_metoo = r(N) 
	count if charge_file_date < 21107 & charge_file_date > 20865 & sh == 1
	gen sex_pre_metoo = r(N) 
	count if charge_file_date < 21107 & charge_file_date > 20865 & sh == 0
	gen no_sex_pre_metoo = r(N) 
	gen eight_month_percent_increase = ((sex_post_metoo/no_sex_post_metoo) - (sex_pre_metoo/no_sex_pre_metoo))/(sex_pre_metoo/no_sex_pre_metoo)
	tab eight_month_percent_increase
	drop *metoo
	restore
	

	// Pre-Covid percent change in cases filed (No CA, WI, FL): 0.2772736 when run on Jun 17, 2025
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

	// First year percent change in cases filed (No CA, FL, WI): 0.16 when run on Jun 17, 2025
	preserve
	di td($metoo) // 21107
	tab state if charge_file_date > 21107 & charge_file_date < 21472
	tab state if charge_file_date < 21107 & charge_file_date > 20742
	drop if inlist(state, "CA", "FL", "WI") // based on tabbing and seeing if there were large differences

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
	// .1624251 when run on Aug 24, 2025
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
	tab sex_post_metoo // 957
	tab no_sex_post_metoo // 6656
	tab sex_pre_metoo // 767    
	tab no_sex_pre_metoo // 6201
	gen control_frac = (no_sex_post_metoo-no_sex_pre_metoo)/no_sex_pre_metoo // 455/6201 = 0.07337526
	gen sex_frac = (sex_post_metoo-sex_pre_metoo)/sex_pre_metoo // 190/767 = .24771838 
// 	gen omega_1 = control_frac/sex_frac // make global and update below section
// 	global omega_1 = omega_1
// 	tab omega_1
	
	gen omega_2 = sex_pre_metoo/(sex_post_metoo/(1+control_frac))
	global omega_2 = omega_2
	tab omega_2
	
	gen omega_1 = sex_pre_metoo/(sex_post_metoo/0.989)
	global omega_1 = omega_1
	tab omega_1
	stop
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
	
	set obs 10
	g omega = (_n - 1) / 10  

	insobs 1  
	replace omega = $omega_1 if _n == _N // Add method 2 omega

	insobs 1  
	replace omega = $omega_2 if _n == _N // Add method 3 omega
	
	// Add point at 0.95
	insobs 1
	replace omega = 0.95 if _n == _N
	
	sort omega 

	g omega_c = 1-omega
	g twfe 	  = 0.101
	g overlap = 0.087

	// TWFE = omega (A-C) + (1-omega) (B-C)
	g bc = (twfe - (omega*overlap))/omega_c
	
	sort omega

	* Generate variables for shading the area between 0.745 and 0.949
	gen shade_min = . 
	gen shade_max = .
	replace shade_min = 0 if inrange(omega, $omega_1, $omega_2)
	replace shade_max = .4 if inrange(omega, $omega_1, $omega_2)

	#delimit ;
	twoway 	(rarea shade_min shade_max omega, color(gs14) fintensity(60))
			(line bc omega, lp(dash) lcolor("dkgreen") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen"))
    		(scatteri 0 $omega_1 .4 $omega_1, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash))
    		(scatteri 0 $omega_2 .4 $omega_2, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.026 .46 "ATT for AR", color("dkgreen") place(r) size(medsmall))
			text(.175 .2 "ATT for IR", color("dkgreen") place(r) size(medsmall))
			text(.25 .645 "Shaded area" "is range of" "calibrated {&omega}", color("gs5") place(r) size(small))
			text(.35 .755 "{&omega}{sub:1}", color("gs3") place(r) size(medlarge))
			text(.35 .868 "{&omega}{sub:2}", color("gs3") place(r) size(medlarge))
			xlabel(-.03 `" " " "Only" "Induced" "Reporters" "' 
				   0 "0"
				  .1 ".1" 
				  .3 ".3"
				  .5 ".5"
				  .7 ".7"
				  .9 ".9"
				  1 "1"
				  1.03 `" " " "Only" "Always" "Reporters""'
				  1.06 " ", labsize(medsmall) noticks)
			xsize(8)
		;

	addplot: pcarrowi .25 0.75 .25 0.78 (3) " ",
		lwidth(thin) lcolor(gs5) mcolor(gs5) 
		;
	addplot: pcarrowi .048 0.51 .078 0.51 (12) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	addplot: pcarrowi .15 0.25 .12 0.25 (6) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	#delimit cr
 	graph export "$figures/omega.png", replace  
	restore


	***************** COMBINED *****************
	preserve 
	clear 
	
	// Make omega grid
	set obs 10
	gen omega = (_n - 1)/10
	
  	insobs 1 
  	replace omega = .95 if _n == _N 
//  	sort omega 

	// WOMEN
	gen omega_c_women = 1 - omega
	gen twfe_women = 0.123
	gen overlap_women = 0.086
	gen bc_women = (twfe_women - (omega * overlap_women)) / omega_c_women

	// MEN
	gen omega_c_men = 1 - omega
	gen twfe_men = 0.119
	gen overlap_men = 0.153
	gen bc_men = (twfe_men - (omega * overlap_men)) / omega_c_men

	// Add zero line
	gen zero = 0
	
	#delimit ;
	twoway  (line bc_men omega, lp(dash) lcolor(ebblue) lwidth(thick)) 
			(line overlap_men omega, lp(solid) lp(solid) lwidth(thick) lcolor(ebblue)) 
			(line bc_women omega, lp(dash) lcolor(orange_red) lwidth(thick)) 
			(line overlap_women omega, lp(solid) lwidth(thick) lcolor(orange_red)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}", size(medlarge)) 
			legend(off) 
			ylabel(-.6(0.2)1) 
			text(.22 .91 "ATT for men AR", color("ebblue") place(r) size(medsmall)) 
			text(.008 .91 "ATT for women AR", color("orange_red") place(r) size(medsmall)) 
			text(-.23 .7 "ATT for men IR", color("ebblue") place(r) size(medsmall)) 
			text(.5 .7 "ATT for women IR", color("orange_red") place(r) size(medsmall)) 
			xlabel(-.03 `" " " "Only" "Induced" "Reporters" "' 
				   0 "0"
				  .1 ".1"
				   .2 ".2"
				   .3 ".3"
				   .4 ".4"
				   .5 ".5"
				   .6 ".6"
				   .7 ".7"
				   .8 ".8"
				   .9 ".9"
				  1 "1"
				  1.03 `" " " "Only" "Always" "Reporters""'
				  1.06 " ", labsize(medsmall) noticks)
			xsize(8)
		;
	#delimit cr
  	graph export "$figures/omega_combined.png", replace  
	restore

}

/*******************************************************************************
Event-study
*******************************************************************************/
loc outcomes "settle win court"
// deleted dismissed

if `event' == 1 {

	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
// make sure ATT numbers are accurate by including all data points 
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 
// 	drop if event   == 0
// 	drop if event_f == 0

	******** All outcomes ********
	foreach y in `outcomes' {
		
		reghdfe `y' treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		loc att: display %5.3f _b[treat]
		
		reghdfe `y' ib7.event, absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
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

		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen)) 
			yline(0, lp(dash)) // yline(`att', lcolor(grey) lwidth(medium) lp(dash))
			ylabel(-0.1(0.1)0.4)
			xline(7.5)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on `y'", size(medium))
			`xlabel' 
			text(0.19 2 "{&beta}{sup:CE}: `att'", size(medium) color(black))
		;
		#delimit cr
 		graph export "$figures/eventstudy_`y'.png", replace 
		estimates clear
	}	


	******** Overlap ********
	reghdfe win treat if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis_state)
	loc att: display %5.3f _b[treat]
	
	reghdfe win ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis_state) noconstant
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

	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
				levels(95)
		ciopts(recast(rcap) lwidth(.5) color(dkgreen)) 
		yline(0, lp(dash)) 
		ylabel(-0.1(0.1)0.4)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.33 1.6 "{&beta}{sup:O}: `att'", size(medium) color(black))
		;
	#delimit cr
				
 	graph export "$figures/eventstudy_win_overlap.png", replace 
	estimates clear

	******** Female complainants only ********
	cap program drop repostb
	program repostb,  eclass
	erepost b = b, rename
	end

	reghdfe win treat_f treat, ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis_state)
	local att_diff = _b[treat_f]
	local att_m    = _b[treat]
	
	local att_diff_rounded = round(`att_diff', 0.001)
	local att_m_rounded    = round(`att_m', 0.001)
	local att_f_rounded = `att_diff_rounded' + `att_m_rounded'

	local att_m_display: display %5.3f `att_m_rounded'
	local att_f_display: display %5.3f `att_f_rounded'
	
	
	reghdfe win ib7.event_f ib7.event, ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis_state) noconstant
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
	omitted baselevel label(Male) mcolor(ebblue) ciopts(recast(rcap) lwidth(.5) color(ebblue)))
	(coef15\coef16\coef17\coef18\coef19\coef20\coef21\coef22\coef23\coef24\coef25\coef26\coef27\coef28,
	omitted baselevel label(Female) mcolor(orange_red) ciopts(recast(rcap) lwidth(.5) color(orange_red))),
		vertical
					levels(95)
		legend(ring(0) bplacement(nwest) size(medium))
		offset(0)
		yline(0, lp(dash)) ylabel(-1(0.2)1)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.55 2.2 "{&beta}{sup:CE}{sub:M}: `att_m_display'", size(medium) color(black))
		text(.42 2.2 "{&beta}{sup:CE}{sub:W}: `att_f_display'", size(medium) color(black))
	;
	#delimit cr
				
 	graph export "$figures/eventstudy_win_female.png", replace 
	estimates clear
	 
	******** Female OVERLAP ********
	reghdfe win treat_f treat if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis_state)
	local att_diff = _b[treat_f]
	local att_m    = _b[treat]
	local att_f    = `att_diff' + `att_m'

	* Format for display
	local att_m_display : display %5.3f `att_m'
	local att_f_display : display %5.3f `att_f'

	display "`att_m_display'"
	display "`att_f_display'"

	reghdfe win ib7.event_f ib7.event if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) ///
		vce(cluster basis_state) noconstant
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
	omitted baselevel label(Male) mcolor(ebblue) ciopts(recast(rcap) lwidth(.5) color(ebblue)))
	(coef10\coef11\coef12\coef13\coef14\coef15\coef16\coef17\coef18,
	omitted baselevel label(Female) mcolor(orange_red) ciopts(recast(rcap) lwidth(.5) color(orange_red))),
		vertical
		levels(95)
		legend(ring(0) bplacement(nwest) size(medium))
		ciopts(recast(rcap) lwidth(.5) color(orange_red)) 
		offset(0)
		yline(0, lp(dash)) ylabel(-1(0.2)1)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.55 1.6 "{&beta}{sup:O}{sub:M}: `att_m_display'", size(medium) color(black))
		text(.42 1.6 "{&beta}{sup:O}{sub:W}: `att_f_display'", size(medium) color(black))
	;
	#delimit cr
	
 	graph export "$figures/eventstudy_win_female_overlap.png", replace 
	estimates clear
		

}


/*******************************************************************************
Cases/outcomes over time 
*******************************************************************************/

if `timeseries' == 1 {

	// One version dropping late entry states 
	preserve
	drop if inlist(state, "CA", "WI", "FL")
	collapse (sum) sum_by_ym = y, by(ym_filed sh)

	* First figure: SH == 1
	local covid_height = 80
	local m2_height = 20
	#delimit ;
	twoway 
		scatter sum_by_ym ym_filed if sh == 1, mcolor("orange_red") msize(small)
		|| lpolyci sum_by_ym ym_filed if sh == 1, acolor("orange_red %65") lwidth(medium) clpattern(dash) clcolor(black)
		|| pcarrowi `covid_height' 729 `covid_height' 723, mlabsize(small) mcolor(black) lcolor(black)
		|| pcarrowi `m2_height' 686 `m2_height' 692, mlabsize(small) mcolor(black) lcolor(black)
		xline(693, lpattern(solid))
		xline(722, lpattern(solid))
		legend(off)
		xtitle("Date filed", size(medium))
		ytitle("Number of complaints", size(medium))
		title("Sexual harassment complaints")
		text(`covid_height' 730 "Covid-19", color("gs3") place(r) size(medlarge))
		text(`m2_height' 685 "#MeToo", color("gs3") place(l) size(medlarge))
	;
	#delimit cr
	graph export "$figures/timeseries_filed_sh.png", replace

	* Second figure: SH == 0
	local height = 700
	#delimit ;
	twoway 
		scatter sum_by_ym ym_filed if sh == 0, mcolor("gs3") msize(small)
		|| lpolyci sum_by_ym ym_filed if sh == 0, acolor("gs3 %65") lwidth(medium) clpattern(dash) clcolor(black)
		|| pcarrowi `height' 729 `height' 723, mlabsize(small) mcolor(black) lcolor(black)
		|| pcarrowi `height' 686 `height' 692, mlabsize(small) mcolor(black) lcolor(black)
		xline(693, lpattern(solid))
		xline(722, lpattern(solid))
		legend(off)
		xtitle("Date filed", size(medium))
		ytitle("Number of complaints", size(medium))
		title("Other complaints")
		text(`height' 730 "Covid-19", color("gs3") place(r) size(medlarge))
		text(`height' 685 "#MeToo", color("gs3") place(l) size(medlarge))
	;
	#delimit cr
	graph export "$figures/timeseries_filed_nsh.png", replace
	restore
}

/*******************************************************************************
Placebo coef plots 
*******************************************************************************/

/*******************************************************************************
Duration
*******************************************************************************/

if `duration' == 1 {

	graph bar (percent) if overlap_all == 1, over(file_month, label(angle(45))) ///
		bar(1, color(navy%70))                ///
		title("Overlap cases filed by calendar month") ///
		ytitle("Percent of cases") legend(off)
	graph export "$figures/month_overlap.png", replace

	// we see 
	tab file_season if overlap_all == 1, sum(win)
	tab file_season if overlap_all == 1, sum(duration)

}

graph bar (percent), ///
    over(file_month, label(angle(45))) ///
    over(overlap_all, relabel(1 "No overlap" 2 "Overlap")) ///
    bar(1, color(gs10)) ///
    bar(2, color(navy%70)) ///
    title("Overlap cases filed by calendar month") ///
    ytitle("Percent of cases") ///
    legend(order(1 "No overlap" 2 "Overlap"))

	
/*******************************************************************************
Filing invariance
*******************************************************************************/
if `file_invariance' == 1 {
	
// 6 months post	
	
	keep if overlap_all == 1
	
	collapse (mean) win, by(ym_res sh)
	list
	
	keep if inrange(ym_res, tm(2017m10), tm(2018m4))

	
	twoway (line win ym_res if sh == 1, lcolor(green) lwidth(medthick) lpattern(solid)) ///
		(line win ym_res if sh == 0, lcolor(green) lwidth(medthick) lpattern(shortdash)), ///
		legend(label(1 "SH Case") label(2 "Non-SH Case") size(medsmall)) ///
		ylabel(0(.1)1, angle(horizontal) labsize(medsmall)) ///
		xlabel(#7, format(%tmMon_CCYY) angle(45) labsize(medsmall)) ///
		xtitle("Resolution Date", size(medlarge)) ///
		ytitle("Win Rate", size(medlarge)) ///
		
  	graph export "$figures/filing_invariance.png", replace 
	estimates clear

}

