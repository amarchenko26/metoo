* reg pierre philosophical_ideas timeless_whimsy fluffiness, cluster(hairball)
/*******************************************************************************
Figures for MeToo project
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc tabulations		= 0
loc sum_stats		= 0
loc event 	   		= 0
loc heterogeneity   = 0
loc selection       = 1
loc timeseries 		= 0
loc fake_win		= 0
loc states			= 0
loc duration   		= 0
loc file_invariance = 0
loc reg_disc		= 0


/*******************************************************************************
Tabulations
*******************************************************************************/

if `tabulations' == 1 {
	
	// Complaint flow diagram
	tab dismissed //arrow to "Dismissed": 7.40 when run on May 28, 2026
	tab settle //arrow to "Settled": 6.76 when run on May 28, 2026
	tab court //arrow to "Court": 43.77 when run on May 28, 2026
	tab investigation //added to court for arrow to "Investigation or Court": 42.10 when run on May 28, 2026
	tab win_investigation //arrow to "Won": 6.65 when run on May 28, 2026
	tab lose_investigation //arrow to "Lost": 35.45 when run on May 28, 2026
	
	preserve
	di td($metoo) // 21107
	tab state if charge_file_date > 21107 & charge_file_date < 21472
	tab state if charge_file_date < 21107 & charge_file_date > 20742
	drop if inlist(state, "CA", "FL", "WI") // based on tabbing and seeing if there were large differences
	
	g filed_first_year_post = 1 if charge_file_date > 21107 & charge_file_date < 21472
	g filed_first_year_pre  = 1 if charge_file_date < 21107 & charge_file_date > 20742
	
	count if filed_first_year_post == 1
	gen filed_first_year_post_count = r(N)
	count if filed_first_year_pre == 1
	gen filed_first_year_pre_count = r(N)
	
	count if filed_first_year_pre == 1 & sh == 1	// 767
	gen sex_pre_metoo = r(N)
	count if filed_first_year_post == 1 & sh == 1	// 957
	gen sex_post_metoo = r(N)
	
	count if investigation == 1 & filed_first_year_pre == 1 & post == 0
	gen invest = r(N)
	count if win_investigation == 1 & filed_first_year_pre == 1 & post == 0
	gen win_invest = r(N)
 	egen pre_win = mean(win_investigation) if filed_first_year_pre == 1 & post == 0
 	tab pre_win		// .1650129
	
 	gen dec_incidence = 0.014	// inspired by Levy and Mattsson

	// Omegas
	gen omega_1 = sex_pre_metoo / sex_post_metoo
	tab omega_1		// .8014629 
	
	gen always_report_post = (sex_post_metoo * (pre_win - dec_incidence) / pre_win)
	gen omega_2 = always_report_post / sex_post_metoo
	tab omega_2		// .9151582
	
	restore 
}

/*******************************************************************************
Summary Statistics 
*******************************************************************************/

if `sum_stats' == 1 {
	
	
	// Page 2 & 8, number of usable discrimination complaints

	use "$clean_data/clean_cases.dta", replace

	count   // 191,985


	// Page 3 & 12, increased probability sh cases win over control mean

	use "$clean_data/clean_cases.dta", replace

	local sh_win = .101 
	local control_mean = 0.152

	display `sh_win' / `control_mean'   // .664


	// Page 6 (footnote 7) & 10, percent of cases that lose at the investigation stage

	use "$clean_data/clean_cases.dta", replace

	mean lose_investigation if investigation == 1   // .842


	// Page 8, number of states in main sample

	use "$clean_data/clean_cases.dta", replace

	egen state_main = tag(state)
	count if state_main    // 10


	// Page 8, prevalence of employment discrimination complaints relative to public accommodation

	use "$clean_data/clean_cases_all_juris.dta", clear

	count if juris == "Employment"
	local employ = r(N)

	count if juris == "Public Accommodation"
	local public = r(N)

	display `employ' / `public'   // 26.238


	// Page 8, number of complaints & states in second sample 
	
	** includes CT **

	use "$clean_data/clean_cases_w_ct.dta", clear

	preserve 
	drop if state == "RI"

	count   //  211,761 
	
	egen state_second = tag(state)
	count if state_second    // 11 

	restore


	// Page 8 & Appendix C (page 19), number of complaints & states in third sample 
	
	** includes all discrimination types **

	use "$clean_data/clean_cases_all_juris.dta", clear

	preserve 
	drop if state == "RI"

	count  // 351,222 
	
	egen state_third = tag(state)
	count if state_third    // 18 

	restore


	// Page 8 (footnote 14), percent of cases with discrimination bases outside main categories

	local basis_other = 68487   	// found in merge_all.do 
	local all_cases = 3272644		// after drops 
	local all_data = 3843073		// before drops 
	
	// either way you calculate, 2% of the data have an unknown basis 

	display `basis_other' / `all_cases'		// .021
	display `basis_other' / `all_data'		// .018


	// Page 9, cutoff for complaint resolution time 

	// this goes on in merge_all.do file 

	local res_mean = 262.9444	// found in merge.do file
	local res_dev = 251.7213
	
	display `res_mean' + 2*`res_dev'	// 766.387
	


	// Page 9 (footnote 15), percent of non-duplicative cases

	use "$clean_data/clean_cases.dta", clear

	capture drop double_code
	gen double_code = (investigation == 1) & (settle == 1 | court == 1 | dismissed == 1)

	mean double_code    // .0017


	// Page 10 and Appendix C (page 18), number of clusters 

	use "$clean_data/clean_cases.dta", clear

	reghdfe win treat, absorb(basis_state ym_res_state) cluster(basis_state)   // 57


	// Page 24 (footnote 30), percent of overlap cases resolved in 1 vs 3 months

	use "$clean_data/clean_cases.dta", clear

	count if duration > 0   	//   122,583
	local overlap_total = r(N)					

	count if duration <=30 & duration >0   // 3,947
	local one_month = r(N) 

	count if duration <=90 & duration >0   // 11,658
	local three_months = r(N) 

	display `one_month' / `overlap_total'      // .032

	display `three_months' / `overlap_total'   // .095


	// Page 26, effect on adjudicator belief larger for male complainants than female

	local overlap_women = 0.086
	local overlap_men = 0.153

	display `overlap_women' / `overlap_men'		// .562


	// Appendix C (page 17, footnote 35), single-tagged vs multi-tagged cases

	mean win if multi_cat == 0         // .156
	mean  win if multi_cat == 1        // .159
	 
	mean duration if multi_cat == 0    // 241
	mean duration if multi_cat == 1    // 105

	mean dismissed if multi_cat == 0   // .102
	mean dismissed if multi_cat == 1   // .057

	mean settle if multi_cat == 0     // .115
	mean settle if multi_cat == 1     // .040

	mean court if multi_cat == 0     // .202
	mean court if multi_cat == 1     // .575


	// Appendix C (page 18), number of Connecticut complaints

	use "$clean_data/clean_cases_all_juris.dta", clear

	count if state == "CT"  // 22,837


	// Appendix C (page 19), percent of cases related to employment/public accommodation

	use "$clean_data/clean_cases_all_juris.dta", clear
	drop if inlist(state, "CT") 


	count if juris == "Employment"   // 241,118
	local employ = r(N)

	count				 // 328,386
	local cases = r(N)  

	display `employ' / `cases'  // .734


	count if juris == "Public Accommodation"   // 9,982
	local public = r(N)

	display `public' / `cases'  // .030

}

/*******************************************************************************
Event-study: Impact of #MeToo on probability complainant wins
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
			ylabel(-.7(0.2).7)
			xline(7.5)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on `y'", size(medium))
			`xlabel' 
			text(0.3 2 "{&beta}{sup:CE}: `att'", size(medium) color(black))
		;
		#delimit cr
  		graph export "$figures/eventstudy_`y'.png", replace 
		estimates clear
	}	
	
	
/*******************************************************************************
Event-study: Impact of #MeToo on probability complainant wins, by gender
*******************************************************************************/

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
		yline(0, lp(dash)) 
		ylabel(-.7(0.2).7)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.43 2 "{&beta}{sup:CE}{sub:M}: `att_m_display'", size(medium) color(black))
		text(.30 2 "{&beta}{sup:CE}{sub:W}: `att_f_display'", size(medium) color(black))
	;
	#delimit cr
				
    graph export "$figures/eventstudy_win_female.png", replace 
	estimates clear
	
	
	
/*******************************************************************************
Event-study: Impact of #MeToo on probability complainant wins, overlap
*******************************************************************************/
	
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
		ylabel(-.7(0.2).7)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.33 2 "{&beta}{sup:O}: `att'", size(medium) color(black))
		;
	#delimit cr
				
    graph export "$figures/eventstudy_win_overlap.png", replace 
	estimates clear
	
	

/*******************************************************************************
Event-study: Impact of #MeToo on probability complainant wins by gender, overlap
*******************************************************************************/
	 
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
		yline(0, lp(dash)) 
		ylabel(-.7(0.2).7)
		xline(7.5)
		xtitle("Years relative to treatment", size(medium))
		ytitle("Effect of MeToo on win", size(medium))
		`xlabel'
		text(.43 2 "{&beta}{sup:O}{sub:M}: `att_m_display'", size(medium) color(black))
		text(.30 2 "{&beta}{sup:O}{sub:W}: `att_f_display'", size(medium) color(black))
	;
	#delimit cr
	
  	graph export "$figures/eventstudy_win_female_overlap.png", replace 
	estimates clear
		

}


/*******************************************************************************
Overlap Heterogeneity by Time Spent in Post Period
Varying overlap definition by filing date cutoff
*******************************************************************************/

/*******************************************************************************
Heterogeneity: Treatment Effects for Overlap Cases with Differential Exposure 
			   to pre-#MeToo Regime
*******************************************************************************/

if `heterogeneity' == 1 {
	
	use "$clean_data/clean_cases.dta", replace

	tempfile results
	save `results'

	clear
	set obs 0
	gen cutoff_ym = .
	gen cutoff_label = ""
	gen att = .
	gen se_att = .
	gen ci_lower = .
	gen ci_upper = .
	save `results', replace

	* Loop over different cutoff months (May 2017 through Sept 2017)
	* Each cutoff defines overlap as cases filed before that date
	use "$clean_data/clean_cases.dta", replace
	local metoo_date = date("$metoo", "DMY")
	local metoo_ym = mofd(`metoo_date')

	forvalues months = 5(-1)0 {

		use "$clean_data/clean_cases.dta", replace
		local current_cutoff_ym = `metoo_ym' - `months'
		local cutoff_date = dofm(`current_cutoff_ym')
		local cutoff_month = month(`cutoff_date')
		local cutoff_year = year(`cutoff_date')

		* Run regression
		reghdfe win treat if common_file_date < `cutoff_date', ///
			absorb(basis_state ym_res_state) ///
			vce(cluster basis_state)

		local att_coef = _b[treat]
		local se_coef = _se[treat]
		local ci_lower_temp = `att_coef' - 1.96 * `se_coef'
		local ci_upper_temp = `att_coef' + 1.96 * `se_coef'

		* Append to results
		tempfile temp_result
		clear
		set obs 1
		gen cutoff_ym = `current_cutoff_ym'
		gen cutoff_label = "`cutoff_month'/`cutoff_year'"
		gen att = `att_coef'
		gen se_att = `se_coef'
		gen ci_lower = `ci_lower_temp'
		gen ci_upper = `ci_upper_temp'
		append using `results'
		save `results', replace
	}

	use `results', clear
	sort cutoff_ym
	drop if mi(att)
	gen x_plot = _n

	#delimit ;
	twoway (line att x_plot, lwidth(thick) lcolor(dkgreen) lpattern(solid))
		   (rcap ci_lower ci_upper x_plot, lcolor(dkgreen) lwidth(medium)),
		   xtitle("Filing time cutoff", size(medium))
		   ytitle("Treatment effect", size(medium))
		   legend(off)
		   yline(0, lpattern(solid) lcolor(gray))
		   yline(.087, lpattern(dash))
		   text(.095 1.4 "{&beta}{sup:O} = 0.087", size(medsmall) color(gs5))
		   xlabel(1 "May 2017" 2 "June 2017" 3 "July 2017" 4 "Aug 2017" 5 "Sept 2017" 6 "Oct 2017", labsize(medsmall) angle(45))
		   ylabel(, labsize(medsmall))
		   ;
	#delimit cr

	graph export "$figures/overlap_heterogeneity_by_date.png", replace

}
	
	
/*******************************************************************************
Selection: ATT^{AR} and ATT^{IR} by share of always reporters
*******************************************************************************/

global omega_1 = 0.801
global omega_2 = 0.915
	
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
	replace shade_min = 0 if inrange(omega, .8, 0.920)
	replace shade_max = .4 if inrange(omega, .8, 0.920)

	#delimit ;
	twoway 	(rarea shade_min shade_max omega, color(gs14) fintensity(60))
			(line bc omega, lp(dash) lcolor("dkgreen") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen"))
    		(scatteri 0 $omega_1 .4 $omega_1, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash))
    		(scatteri 0 $omega_2 .4 $omega_2, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash)),
			ytitle("Treatment effect", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.026 .46 "ATT{sup:AR}", color("dkgreen") place(r) size(medium))
			text(.175 .2 "ATT{sup:IR}", color("dkgreen") place(r) size(medium))
			text(.25 .645 "Shaded area" "is range of" "calibrated {&omega}", color("gs5") place(r) size(small))
			text(.35 .755 "{&omega}{sub:1}", color("gs3") place(r) size(medlarge))
			text(.35 .873 "{&omega}{sub:2}", color("gs3") place(r) size(medlarge))
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
	
	
	
	// MAKE A SIMPLER OMEGA GRAPH for PRESENTATION ONLY
	#delimit ;
	twoway 	(line bc omega, lp(dash) lcolor("dkgreen") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen")),
			ytitle(" ", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.026 .46 "ATT{sup:AR}", color("dkgreen") place(r) size(medlarge))
			text(.175 .2 "ATT{sup:AR} + S", color("dkgreen") place(r) size(medlarge))
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

	addplot: pcarrowi .048 0.51 .078 0.51 (12) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	addplot: pcarrowi .15 0.25 .12 0.25 (6) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	#delimit cr
  	graph export "$figures/omega_AR_and_IR.png", replace  
	
	
	#delimit ;
	twoway 	(line bc omega, lp(dash) lcolor("white") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen")),
			ytitle(" ", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.026 .46 "ATT{sup:AR}", color("dkgreen") place(r) size(medlarge))
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

	addplot: pcarrowi .048 0.51 .078 0.51 (12) " ",
		lwidth(medthick) lcolor(dkgreen) mcolor(dkgreen) 
		;
	#delimit cr
  	graph export "$figures/omega_AR_only.png", replace  
	
	
		#delimit ;
	twoway 	(rarea shade_min shade_max omega, color(gs14) fintensity(60))
			(line bc omega, lp(dash) lcolor("dkgreen") lwidth(thick))
			(line overlap omega, lp(solid) lwidth(thick) lcolor("dkgreen"))
    		(scatteri 0 $omega_1 .4 $omega_1, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash))
    		(scatteri 0 $omega_2 .4 $omega_2, c(L) msymbol(none) lcolor(gs5) lwidth(medium) lpattern(dash)),
			ytitle(" ", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			legend(off) 
			text(.026 .46 "ATT{sup:AR}", color("dkgreen") place(r) size(medlarge))
			text(.175 .2 "ATT{sup:AR} + S", color("dkgreen") place(r) size(medlarge))
			text(.25 .645 "Shaded area" "is range of" "calibrated {&omega}", color("gs5") place(r) size(small))
			text(.35 .755 "{&omega}{sub:1}", color("gs3") place(r) size(medlarge))
			text(.35 .873 "{&omega}{sub:2}", color("gs3") place(r) size(medlarge))
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
  	graph export "$figures/omega_fortalk.png", replace  
	
	
	
	
	restore

	
/*******************************************************************************
Selection: ATT^{AR} and ATT^{IR} by gender
*******************************************************************************/

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
			text(.22 .87 "ATT{sup:AR} men", color("ebblue") place(r) size(medium)) 
			text(.008 .87 "ATT{sup:AR} women", color("orange_red") place(r) size(medium)) 
			text(-.23 .7 "ATT{sup:IR} men", color("ebblue") place(r) size(medium)) 
			text(.5 .7 "ATT{sup:IR} women", color("orange_red") place(r) size(medium)) 
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
	
	
	// MAKE A SIMPLER OMEGA GRAPH for PRESENTATION ONLY
	#delimit ;
	twoway  (line bc_men omega, lp(dash) lcolor(ebblue) lwidth(thick)) 
			(line overlap_men omega, lp(solid) lp(solid) lwidth(thick) lcolor(ebblue)) 
			(line bc_women omega, lp(dash) lcolor(orange_red) lwidth(thick)) 
			(line overlap_women omega, lp(solid) lwidth(thick) lcolor(orange_red)),
			ytitle(" ", size(medlarge)) 
			xtitle("{&omega}", size(medlarge)) 
			legend(off) 
			ylabel(-.6(0.2)1) 
			text(.22 .9 "ATT{sup:AR} men", color("ebblue") place(r) size(medlarge)) 
			text(.008 .9 "ATT{sup:AR} women", color("orange_red") place(r) size(medlarge)) 
			text(-.23 .65 "(ATT{sup:AR} + S) men", color("ebblue") place(r) size(medlarge)) 
			text(.5 .65 "(ATT{sup:AR} + S) women", color("orange_red") place(r) size(medlarge)) 
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
  	graph export "$figures/omega_combined_fortalk.png", replace  
	
	// OMEGA FOR WOMEN ONLY 
	#delimit ;
	twoway  (line bc_women omega, lp(dash) lcolor(orange_red) lwidth(thick)) 
			(line overlap_women omega, lp(solid) lwidth(thick) lcolor(orange_red)),
			ytitle(" ", size(medlarge)) 
			xtitle("{&omega}", size(medlarge)) 
			legend(off) 
			ylabel(-.6(0.2)1) 
			text(.008 .87 "ATT{sup:AR} women", color("orange_red") place(r) size(medlarge)) 
			text(.5 .65 "(ATT{sup:AR} + S) women", color("orange_red") place(r) size(medlarge)) 
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
  	graph export "$figures/omega_women_only.png", replace  
	
	
	restore

}


/*******************************************************************************
Timeseries: Number of complaints filed over time
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
	
	
	// One version w/o smoothing 
	preserve
	drop if inlist(state, "CA", "WI", "FL")
	collapse (sum) sum_by_ym = y, by(ym_filed sh)

	* First figure: SH == 1
	local covid_height = 80
	local m2_height = 20
	#delimit ;
	twoway 
		scatter sum_by_ym ym_filed if sh == 1, mcolor("orange_red") msize(small)
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
	graph export "$figures/timeseries_filed_sh_nosmooth.png", replace

	* Second figure: SH == 0
	local height = 700
	#delimit ;
	twoway 
		scatter sum_by_ym ym_filed if sh == 0, mcolor("gs3") msize(small)
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
 	graph export "$figures/timeseries_filed_nsh_nosmooth.png", replace
	restore
}



/*******************************************************************************
Fake win (Page 13, Footnote 19)
*******************************************************************************/

if `fake_win' == 1 {
	
	// first regression: fake_win
	
	set seed 1 
	count if post == 1 & court == 1 & sh == 1 //18,984
	local N = r(N)
	
	local C = round(.007 * `N')
	display `C'
	
	// generate random numbers for cases that match criteria 
	gen random = runiform() if post == 1 & court == 1 & sh == 1
	
	// sort in order of randomly asisgned numbers
	sort post court sh random
	
	// initialize fake_win variable 
	gen fake_win = . 
	
	// all win == 1 cases are also fake_win == 1
	replace fake_win = 1 if win == 1
	replace fake_win = 0 if win == 0
	
	// add 0.7% of post/court/sh cases
	by post court sh: replace fake_win = 1 if post == 1 & court == 1 & sh == 1 & _n <= `C'
	
	// run regression
	preserve 
	reghdfe fake_win treat, absorb(basis_state ym_res_state) vce(cluster basis) // .1022696  
	restore 
	
	
	// second regression: fake_win2 
	
	gen fake_win2 = . 
	
	replace fake_win2 = 1 if win == 1
	replace fake_win2 = 0 if win == 0
	
	by post court sh: replace fake_win2 = 0 if post == 1 & court == 1 & sh == 1 & _n <= `C'
	
	// run regression
	preserve 
	reghdfe fake_win2 treat, absorb(basis_state ym_res_state) vce(cluster basis) // .0999922
	restore 
		
} 


/*******************************************************************************
States: Heterogeneity of aggregate results by state political majority
*******************************************************************************/

if `states' == 1 {
	
	//**************** 
	//**************** BLUE STATES 
	//**************** 

	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 

	******** All outcomes ********	
	loc offset = 8 
		
	* Get all unique state codes (strings like "AK")

preserve 
	keep if inlist(state, "CA", "NY", "MA", "HI")
// 	keep if common_file_date < date("$metoo", "DMY")
	
		di as txt "Running BLUE ONLY states"

		*------------------------------
		* ATT (combined effect)
		*------------------------------
		reghdfe win treat, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state)
		local att: display %5.3f _b[treat]

		*------------------------------
		* Event study
		*------------------------------
		reghdfe win ib7.event, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
		estimates store TWFE

		*------------------------------
		* Dynamic xlabel construction
		*------------------------------
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

		*------------------------------
		* Plot + export
		*------------------------------
		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen))
			yline(0, lp(dash))
			xline(7.5)
			ylabel(-.7(0.2).7)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on win", size(medium))
			`xlabel'
			text(0.3 4 "{&beta}{sup:CE}, blue states only: `att'", size(medium) color(black))
		;
		#delimit cr

 		graph export "$figures/eventstudy_leaveoneout_blue.png", replace

		estimates clear
restore 


	//**************** 
	//**************** RED+ PURPLE STATES 
	//**************** 
	
	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 

	******** All outcomes ********	
	loc offset = 8 
		
	* Get all unique state codes (strings like "AK")

preserve 
	keep if inlist(state, "FL", "AK", "KY", "ND", "WI", "MI")

		di as txt "Running RED+PURPLE ONLY states"

		*------------------------------
		* ATT (combined effect)
		*------------------------------
		reghdfe win treat, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state)
		local att: display %5.3f _b[treat]

		*------------------------------
		* Event study
		*------------------------------
		reghdfe win ib7.event, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
		estimates store TWFE

		*------------------------------
		* Dynamic xlabel construction
		*------------------------------
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

		*------------------------------
		* Plot + export
		*------------------------------
		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen))
			yline(0, lp(dash))
			xline(7.5)
			ylabel(-.7(0.2).7)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on win", size(medium))
			`xlabel'
			text(0.3 4 "{&beta}{sup:CE}, red+purple states only: `att'", size(medium) color(black))
		;
		#delimit cr

 		graph export "$figures/eventstudy_leaveoneout_red_purp.png", replace

		estimates clear
restore 



/*******************************************************************************
States: Heterogeneity of overlap results by state political majority
*******************************************************************************/

	//**************** 
	//**************** BLUE STATES - OVERLAP
	//**************** 

	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 

	******** All outcomes ********	
	loc offset = 8 
		
	* Get all unique state codes (strings like "AK")

preserve 
	keep if inlist(state, "CA", "NY", "MA", "HI")
	keep if common_file_date < date("$metoo", "DMY")
	
		di as txt "Running BLUE ONLY states"

		*------------------------------
		* ATT (combined effect)
		*------------------------------
		reghdfe win treat, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state)
		local att: display %5.3f _b[treat]

		*------------------------------
		* Event study
		*------------------------------
		reghdfe win ib7.event, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
		estimates store TWFE

		*------------------------------
		* Dynamic xlabel construction
		*------------------------------
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

		*------------------------------
		* Plot + export
		*------------------------------
		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen))
			yline(0, lp(dash))
			xline(7.5)
			ylabel(-.7(0.2).7)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on win", size(medium))
			`xlabel'
			text(0.3 4 "{&beta}{sup:O}, blue states only: `att'", size(medium) color(black))
		;
		#delimit cr

		graph export "$figures/eventstudy_leaveoneout_blue_overlap.png", replace

		estimates clear
restore 



	//**************** 
	//**************** RED+ PURPLE STATES - OVERLAP
	//**************** 
	
	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 

	******** All outcomes ********	
	loc offset = 8 
		
	* Get all unique state codes (strings like "AK")

preserve 
	keep if inlist(state, "FL", "AK", "KY", "ND", "WI", "MI")
	keep if common_file_date < date("$metoo", "DMY")

		di as txt "Running RED+PURPLE ONLY states"

		*------------------------------
		* ATT (combined effect)
		*------------------------------
		reghdfe win treat, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state)
		local att: display %5.3f _b[treat]

		*------------------------------
		* Event study
		*------------------------------
		reghdfe win ib7.event, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
		estimates store TWFE

		*------------------------------
		* Dynamic xlabel construction
		*------------------------------
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

		*------------------------------
		* Plot + export
		*------------------------------
		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen))
			yline(0, lp(dash))
			xline(7.5)
			ylabel(-.7(0.2).7)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on win", size(medium))
			`xlabel'
			text(0.3 4 "{&beta}{sup:O}, red+purple states only: `att'", size(medium) color(black))
		;
		#delimit cr

 		graph export "$figures/eventstudy_leaveoneout_red_purp_overlap.png", replace

		estimates clear
restore 



/*******************************************************************************
States: (Appendix B.3, page 2)
*******************************************************************************/

//**************** 
//**************** BLUE+PURPLE STATES 
//**************** 
	loc offset = 8 // offset for event studies, to adjust for the fact that we start at -7
	cap drop event event_f
	g event 	    = years_to_treat_res * sh
	g event_f 		= years_to_treat_res * sh * victim_f		
	replace event   = event + `offset'
	replace event_f = event_f + `offset'
	
	replace event = 1 if event == 0 
	replace event_f = 1 if event_f == 0 

	******** All outcomes ********	
	loc offset = 8 
		
preserve 
	keep if inlist(state, "CA", "NY", "MA", "HI", "WI", "MI")

		di as txt "Running BLUE+PURPLE ONLY states"

		*------------------------------
		* ATT (combined effect)
		*------------------------------
		reghdfe win treat, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state)
		local att: display %5.3f _b[treat]

		*------------------------------
		* Event study
		*------------------------------
		reghdfe win ib7.event, ///
			absorb(basis_state ym_res_state) vce(cluster basis_state) noconstant
		estimates store TWFE

		*------------------------------
		* Dynamic xlabel construction
		*------------------------------
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

		*------------------------------
		* Plot + export
		*------------------------------
		#delimit ;
		coefplot (TWFE, omitted baselevel msize(medlarge) mcolor(dkgreen)), vertical
			levels(95)
			ciopts(recast(rcap) lwidth(.5) color(dkgreen))
			yline(0, lp(dash))
			xline(7.5)
			ylabel(-.7(0.2).7)
			xtitle("Years relative to treatment", size(medium))
			ytitle("Effect of MeToo on win", size(medium))
			`xlabel'
			text(0.3 4 "{&beta}{sup:CE}, blue+purple states only: `att'", size(medium) color(black))
		;
		#delimit cr

 		graph export "$figures/eventstudy_leaveoneout_blue_purp.png", replace

		estimates clear
restore 


}



/*******************************************************************************
Duration: Average duration of cases open in each month before #MeToo
*******************************************************************************/

if `duration' == 1 {

	use "$clean_data/clean_cases.dta", replace

	preserve 
	keep ym_filed ym_res sh

	* --------------------------------------------------
	* 1. Compute MeToo month window
	* --------------------------------------------------
	local metoo_date = date("$metoo", "DMY")
	local metoo_ym   = mofd(`metoo_date')

	local start_ym = `metoo_ym' - 12     // start month
	local end_ym   = `metoo_ym'     // end month (13 months total)

	* --------------------------------------------------
	* 2. Expand the dataset into a case–month panel
	*    Every case now has 13 rows
	* --------------------------------------------------
	gen panel_month = _n 
	expand 13

	bys panel_month: gen month_index = _n - 1
	drop panel_month

	gen month_ym = `start_ym' + month_index
	format month_ym %tm

	* --------------------------------------------------
	* 3. Compute open-case indicator and duration
	* --------------------------------------------------
	gen is_open = (ym_filed <= month_ym) & ///
				  (ym_res >= month_ym | missing(ym_res))

	gen duration = month_ym - ym_filed if is_open

	* --------------------------------------------------
	* 4. Collapse to the monthly average duration
	* --------------------------------------------------
	collapse (mean) avg_duration = duration, by(month_ym sh)
	format month_ym %tm
	drop if sh ==.

	* --------------------------------------------------
	* 5. Plot
	* --------------------------------------------------
	twoway ///
		(line avg_duration month_ym if sh == 0, lcolor(green) lwidth(medthick) lpattern(dash)) ///
		(line avg_duration month_ym if sh == 1, ///
			lcolor(green) lwidth(medthick) lpattern(solid)), ///
		xtitle("Month", size(medlarge)) ///
		ytitle("Avg Duration (Months)", size(medlarge)) ///
		xlabel(, format(%tmMon_CCYY) angle(45)) ///
		ylabel(0(1)12) ///
		xline(`metoo_ym', lpattern(dash)) ///
		legend(order(2 "SH Case" 1 "Non-SH Case") size(medsmall) symxsize(10))


		graph export "$figures/duration_open.png", replace 

	restore 

}


/*******************************************************************************
Placebo coef plots 
*******************************************************************************/
	
/*******************************************************************************
Filing invariance: Win rate of overlap cases resolved after #MeToo
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



/*******************************************************************************
Regression Discontinuity: RD Plot of Win Rate for Cases Resolved After #MeToo
*******************************************************************************/

if `reg_disc' == 1 {
	
	use "$clean_data/clean_cases.dta", replace
	
	

	* ------------------------------------------------------------
	* RD Plot WOMEN ONLY 
	* ------------------------------------------------------------

	preserve
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1

	// local cutoff_tm = tm(2017m10)
	local cutoff_tm = td(15oct2017)

	* Running variable centered at cutoff (in months)
	// gen t = ym_filed - `cutoff_tm'
	gen t = common_file_date - `cutoff_tm'

	* Detrend / residualize outcome
	quietly regress win i.ym_res_state
	predict double win_det, resid

	* ------------------------------------------------------------
	* Manual window for the PLOT only: +/- 9 months
	* ------------------------------------------------------------
	rdbwselect win_det t, c(0) bwselect(mserd) // it chose 8.94

	// point estimate 
	rdrobust win_det t, c(0) h(240) p(2)
	ereturn list
	local rd_point_estimate : display %5.3f `e(tau_cl)'
	local rd_se : display %5.3f `e(se_tau_cl)'

	gen in_window6 = (abs(t) <= 240)

	// graph, poly of order 2, 
	rdplot win_det t if in_window6, c(0) p(2) ///
		graph_options( ///
			xtitle("Days relative to #MeToo", size(medium)) ///
			ytitle("Win (residualized)", size(medium)) ///
			ylabel(-.4(.2).4) ///
			legend(off) ///
			text(.3 -100 "RD Effect{sub:W} = `rd_point_estimate' (`rd_se')", size(medium) color(black)) ///
		)
		
	 graph export "$figures/rd_women.png", replace 
	restore



	* ------------------------------------------------------------
	* RD Plot MEN ONLY 
	* ------------------------------------------------------------

	preserve
	set graphics on
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0

	// local cutoff_tm = tm(2017m10)
	local cutoff_tm = td(15oct2017)

	* Running variable centered at cutoff (in months)
	// gen t = ym_filed - `cutoff_tm'
	gen t = common_file_date - `cutoff_tm'

	* Detrend / residualize outcome
	quietly regress win i.ym_res_state
	predict double win_det, resid

	* ------------------------------------------------------------
	* Manual window for the PLOT only: +/- 6 months
	* ------------------------------------------------------------
	rdbwselect win_det t, c(0) bwselect(mserd) // it chose 5.83

	// point estimate 
	// rdrobust win_det t, c(0) h(6) p(2)
	rdrobust win_det t, c(0) h(200) p(2)

	local rd_point_estimate : display %5.3f `e(tau_cl)'
	local rd_se : display %5.3f `e(se_tau_cl)'

	gen in_window6 = (abs(t) <= 200)

	// graph, poly of order 2, 
	rdplot win_det t if in_window6, c(0) p(2) ///
		graph_options( ///
			xtitle("Days relative to #MeToo", size(medium)) ///
			ytitle("Win (residualized)", size(medium)) ///
			ylabel(-.4(.2).4) ///
			legend(off) ///
			text(.3 -100 "RD Effect{sub:M} = `rd_point_estimate' (`rd_se')", size(medium) color(black)) ///
		)
	// 		xlabel(-6(1)6) ///
		
	 graph export "$figures/rd_men.png", replace 
	restore
	
	

/*******************************************************************************
Table A4: RD Point Estimates Across Various Specifications (top panel)
*******************************************************************************/

	use "$clean_data/clean_cases.dta", replace

	* men, no FE, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	rdrobust win t, c(0) h(200) p(1)
	restore 

	* men, no FE, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	rdrobust win t, c(0) h(200) p(2)
	restore 

	* men, state and time, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.state_cat i.ym_res
	predict double win_det, resid

	rdrobust win_det t, c(0) h(200) p(1)
	restore 

	* men, state and time, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.state_cat i.ym_res
	predict double win_det, resid

	rdrobust win_det t, c(0) h(200) p(2)
	restore 

	* men, state X time, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.ym_res_state
	predict double win_det, resid

	rdrobust win_det t, c(0) h(200) p(1)
	restore 

	* men, state X time, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 0
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.ym_res_state
	predict double win_det, resid

	rdrobust win_det t, c(0) h(200) p(2)
	restore 
 


/*******************************************************************************
Table A4: RD Point Estimates Across Various Specifications (bottom panel)
*******************************************************************************/

	use "$clean_data/clean_cases.dta", replace

	* women, no FE, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	rdrobust win t, c(0) h(240) p(1)
	restore 

	* women, no FE, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	rdrobust win t, c(0) h(240) p(2)
	restore 

	* women, state and time, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.state_cat i.ym_res
	predict double win_det, resid

	rdrobust win_det t, c(0) h(240) p(1)
	restore 

	* women, state and time, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.state_cat i.ym_res
	predict double win_det, resid

	rdrobust win_det t, c(0) h(240) p(2)
	restore 

	* women, state X time, p1
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.ym_res_state
	predict double win_det, resid

	rdrobust win_det t, c(0) h(240) p(1)
	restore 

	* women, state X time, p2
	preserve 
	keep if sh == 1
	keep if common_res_date > date("$metoo", "DMY")
	keep if victim_f == 1
	local cutoff_tm = td(15oct2017)
	// local cutoff_tm = tm(2017m10)
	gen t = common_file_date - `cutoff_tm'

	quietly regress win i.ym_res_state
	predict double win_det, resid

	rdrobust win_det t, c(0) h(240) p(2)
	restore 
	
}



