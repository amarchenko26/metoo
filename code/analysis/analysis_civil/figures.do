* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc tabulations		= 0
loc selection 		= 1
loc event 	   		= 0
loc timeseries 		= 0
loc state_did  		= 0
loc run_placebo 	= 0
loc duration   		= 0
loc yhat			= 0
loc run_overlap_comparison = 0

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

	****** Count omega for men 
	preserve
	keep if victim_f == 0 
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
	replace omega = 0.745 if _n == _N // Add method 1 omega

	insobs 1  
	replace omega = 0.949 if _n == _N // Add method 2 omega

	insobs 1  
	replace omega = 0.793 if _n == _N // Add method 3 omega
	
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
	replace shade_min = 0 if inrange(omega, 0.745, .95)
	replace shade_max = .4 if inrange(omega, 0.745, 0.95)

	#delimit ;
	twoway 	(rarea shade_min shade_max omega, color(gs14) fintensity(60))
			(line bc omega, lp(dash) lcolor("dkgreen") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen"))
			(scatteri 0 0.745 .4 0.745, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash)) 
    		(scatteri 0 0.793 .4 0.793, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash))
    		(scatteri 0 0.949 .4 0.949, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.025 .46 "ATT for AR", color("dkgreen") place(r) size(medsmall))
			text(.175 .2 "ATT for IR", color("dkgreen") place(r) size(medsmall))
			text(.25 .6 "Shaded area" "is range of" "calibrated {&omega}", color("gs5") place(r) size(small))
			text(.35 .71 "{&omega}{sub:1}", color("gs3") place(r) size(medlarge))
			text(.35 .8 "{&omega}{sub:2}", color("gs3") place(r) size(medlarge))
			text(.35 .96 "{&omega}{sub:3}", color("gs3") place(r) size(medlarge))
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

	addplot: pcarrowi .25 0.7 .25 0.73 (3) " ",
		lwidth(thin) lcolor(gs5) mcolor(gs5) 
		;
	addplot: pcarrowi .05 0.5 .083 0.5 (12) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	addplot: pcarrowi .15 0.25 .12 0.25 (6) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	#delimit cr
 	graph export "$figures/omega.png", replace  
	restore



	***************** WOMEN *****************
	preserve 
	clear
	
	set obs 11
	g omega = (_n - 1) / 10

	/* insobs 1  
	replace omega = 0.745 if _n == _N // Add method 1 omega

	insobs 1  
	replace omega = 0.949 if _n == _N // Add method 2 omega

	insobs 1  
	replace omega = 0.793 if _n == _N // Add method 3 omega */

	g omega_c = 1-omega
	g twfe 	  = 0.123
	g overlap = 0.086

	// TWFE = omega (A-C) + (1-omega) (B-C)
	g bc = (twfe - (omega*overlap))/omega_c
	
	sort omega

	* Generate variables for shading the area 
// 	gen shade_min = . 
// 	gen shade_max = .
// 	replace shade_min = 0 if inrange(omega, 0.745, .95)
// 	replace shade_max = .4 if inrange(omega, 0.745, 0.95)

	#delimit ;
	twoway 	(line bc omega, lp(dash) lcolor(orange_red) lwidth(thick)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			yline(0.086, lp(solid) lwidth(thick) lcolor(orange_red))
			yline(0, lp(solid) lwidth(medium) lcolor(gs3))
			ylabel(0(0.1)1)
			legend(off) 
			text(.23 .9 "ATT for women ARs", color("orange_red") place(r) size(medium))
			text(.6 .7 "ATT for women IRs", color("orange_red") place(r) size(medium))
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

	#delimit cr
	graph export "$figures/omega_women.png", replace  
	restore

	***************** MEN *****************
	preserve 
	clear
	
	set obs 11
	g omega = (_n - 1) / 10

	/* insobs 1  
	replace omega = 0.234 if _n == _N // Add method 1 omega

	insobs 1  
	replace omega = 0.872 if _n == _N // Add method 2 omega

	insobs 1  
	replace omega = 0.910 if _n == _N // Add method 3 omega */

	g omega_c = 1-omega
	g twfe 	  = 0.119
	g overlap = 0.153

	// TWFE = omega (A-C) + (1-omega) (B-C)
	g bc = (twfe - (omega*overlap))/omega_c
	
	sort omega

	* Generate variables for shading the area 
// 	gen shade_min = . 
// 	gen shade_max = .
// 	replace shade_min = -.5 if inrange(omega, 0.22, .92)
// 	replace shade_max = .5 if inrange(omega, 0.22, .92)
	gen zero = 0 

	#delimit ;
	twoway  (line bc omega, lp(dash) lcolor(ebblue) lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor(ebblue))
			(line zero omega, lp(solid) lwidth(medium) lcolor(gs3)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}{sup:M}", size(medlarge))
			legend(off) 
			ylabel(-.5(.1).5)
			text(.25 .3 "ATT for men ARs", color("ebblue") place(r) size(medium))
			text(-.2 .65 "ATT for men IRs", color("ebblue") place(r) size(medium))
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
	#delimit cr
 	graph export "$figures/omega_men.png", replace  
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
loc outcomes "settle dismissed win court"

if `event' == 1 {

	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 
// 	drop if event   == 0
// 	drop if event_f == 0

	******** All outcomes ********
	foreach y in `outcomes' {
		
		reghdfe `y' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		loc att: display %5.3f _b[treat]
		
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

		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			ciopts(recast(rcap) lwidth(.5) color(dkgreen)) 
			yline(0, lp(dash)) // yline(`att', lcolor(grey) lwidth(medium) lp(dash))
			ylabel(-0.1(0.05)0.25)
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

	reghdfe relief_scale treat, absorb(basis_state ym_res_state) vce(cluster basis)
	loc att: display %5.3f _b[treat]
	
	reghdfe relief_scale ib7.event, ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis) noconstant
	estimates store TWFE

	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
		ciopts(recast(rcap) lwidth(.5) color(dkgreen)) 
		yline(0, lp(dash)) 	// yline(`att', lcolor(gray) lwidth(medium) lp(dash))
		xline(6.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on compensation ($1000s)", size(medium))
		xlabel(1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3" 11 "4", labsize(medium)) 
		text(45 2 "{&beta}{sup:CE}: `att'", size(medium) color(black))
	;
	#delimit cr
				
 	graph export "$figures/eventstudy_relief_scale.png", replace 
	estimates clear

	******** Overlap ********
	reghdfe win treat if common_file_date < date("$metoo", "DMY"), ///
		absorb(basis_state ym_res_state) ///
		vce(cluster basis)
	loc att: display %5.3f _b[treat]
	
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

	#delimit ;
	coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
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
		vce(cluster basis)
	local att_diff = _b[treat_f]
	local att_m    = _b[treat]
	
	local att_diff_rounded = round(`att_diff', 0.001)
	local att_m_rounded    = round(`att_m', 0.001)
	local att_f_rounded = `att_diff_rounded' + `att_m_rounded'

	local att_m_display: display %5.3f `att_m_rounded'
	local att_f_display: display %5.3f `att_f_rounded'
	
	
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
	omitted baselevel label(Male) mcolor(ebblue) ciopts(recast(rcap) lwidth(.5) color(ebblue)))
	(coef15\coef16\coef17\coef18\coef19\coef20\coef21\coef22\coef23\coef24\coef25\coef26\coef27\coef28,
	omitted baselevel label(Female) mcolor(orange_red) ciopts(recast(rcap) lwidth(.5) color(orange_red))),
		vertical
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
		vce(cluster basis)
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
	omitted baselevel label(Male) mcolor(ebblue) ciopts(recast(rcap) lwidth(.5) color(ebblue)))
	(coef10\coef11\coef12\coef13\coef14\coef15\coef16\coef17\coef18,
	omitted baselevel label(Female) mcolor(orange_red) ciopts(recast(rcap) lwidth(.5) color(orange_red))),
		vertical
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
		
	******** Rambachan & Roth (2021) for win ********
	reghdfe win ib7.event, absorb(basis_state ym_res_state) vce(cluster basis)
	honestdid, numpre(7) omit ///
		coefplot xtitle(Mbar) ytitle(95% Robust CI)
 	graph export "$figures/honestdid_win.png", replace

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

/*******************************************************************************
Placebo coef plots for outcome = win only
*******************************************************************************/

if `run_placebo' == 1 {

	// General placebo tests
	loc i 1
	preserve
		drop if basis == "Sex"
		levelsof basis_cat, local(levels)

		foreach l of local levels {
			gen placebo_treat_`l' = (post == 1 & basis_cat == `l')
		}

		forvalues index = 1/6 {
			reghdfe win placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo placebo_all_`i'
			loc ++i
		}
	restore

	// Single-basis placebo tests
	loc i 1
	preserve
		drop if basis == "Sex" 
		keep if multi_cat == 0
		levelsof basis_cat, local(levels)

		foreach l of local levels {
			gen placebo_treat_`l' = (post == 1 & basis_cat == `l')
		}

		forvalues index = 1/6 {
			reghdfe win placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo placebo_single_`i'
			loc ++i
		}
	restore

	// Overlap-only placebo tests
	loc i 1
	preserve
		drop if basis == "Sex"
		keep if common_file_date < date("$metoo", "DMY")
		levelsof basis_cat, local(levels)

		foreach l of local levels {
			gen placebo_treat_`l' = (post == 1 & basis_cat == `l')
		}
		
		forvalues index = 1/6 {
			reghdfe win placebo_treat_`index', absorb(basis_state ym_res_state) vce(cluster basis)
			eststo placebo_overlap_`i'
			loc ++i
		}
	restore

	// True effects
	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
	eststo true_effect

	reghdfe win treat if multi_cat == 0, absorb(basis_state ym_res_state) vce(cluster basis)
	eststo true_effect_single

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
	eststo true_effect_overlap


	* Plot all together by panel
	#delimit ;
	coefplot 
		placebo_all_1 placebo_all_2 placebo_all_3 placebo_all_4 placebo_all_5 placebo_all_6 true_effect, bylabel(All complaints) 
		||placebo_single_1 placebo_single_2 placebo_single_3 placebo_single_4 placebo_single_5 placebo_single_6 true_effect_single, bylabel(Single-basis) 
		||placebo_overlap_1 placebo_overlap_2 placebo_overlap_3 placebo_overlap_4 placebo_overlap_5 placebo_overlap_6 true_effect_overlap, bylabel(Overlap only) 
		|| , drop(_cons) 
		byopts(xrescale legend(off))
		ciopts(lwidth(thick) recast(rcap))
		ylabel(1 "Age" 2 "Disability" 3 "Nationality" 4 "Race" 5 "Religion" 6 "Retaliation" 7 "SH (actual treatment)", labsize(medium))
		xline(0, lc(gs8) lp(dash)) 
		xlabel(-.15(.05).15, labsize(medium))
		xtitle("Placebo Effect of MeToo on Complainant Win Probability", size(medium))
		ytitle("Placebo treatment type", size(medium))
	;
	#delimit cr

	graph export "$figures/placebo_win.png", replace
	eststo clear
	estimates clear
}


/*******************************************************************************
Duration
*******************************************************************************/

if `duration' == 1{
	
	binscatter win duration , n(50) ///
		xtitle("Duration)") ytitle("Probability of win")
	graph export "$figures/duration_cause.png", replace 	

	preserve 
	keep if common_year == 2017
	keep if overlap_all == 1
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

	* Keep only overlap complaints
	graph bar (percent), over(file_month, label(angle(45))) ///
		bar(1, color(navy%70))                ///
		title("All cases filed by calendar month") ///
		ytitle("Percent of cases") legend(off)
	graph export "$figures/month.png", replace

	graph bar (percent) if overlap_all == 1, over(file_month, label(angle(45))) ///
		bar(1, color(navy%70))                ///
		title("Overlap cases filed by calendar month") ///
		ytitle("Percent of cases") legend(off)
	graph export "$figures/month_overlap.png", replace

	// we see 
	tab file_season if overlap_all == 1, sum(win)
	tab file_season if overlap_all == 1, sum(duration)

}


/*******************************************************************************
Overlap comparison figures  
*******************************************************************************/
// Take cases filed before MeToo, some overlap and some don't
// for every month in 2015, 2016, and 2017
// we take the complaints that did and didn't overlap in each month 
// we sum the % that are sex_cases 

if `run_overlap_comparison' == 1 {

	// From 2016m1 to 2017m10
	forvalues i = 672(1)693 {
		sum sex_cases if overlap_all == 1 & ym_filed == `i'
		sum sex_cases if overlap_all == 0 & ym_filed == `i'
	}

	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = sex_cases, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("% sex cases") ///
		title("Trends in overlap and non-overlap cases filed in the same year-month") 
	graph export "$figures/overlap_balance_sex.png", replace
	restore

	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = win, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Win rate") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
	graph export "$figures/overlap_balance_win.png", replace
	restore


	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = duration, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Duration") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
	graph export "$figures/overlap_balance_duration.png", replace
	restore

}

