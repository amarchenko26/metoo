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
        legend(order(3 1) lab(3 "SH complaints, 95% CI") lab(1 "Other complaints, 95% CI") size(medium) ring(0) pos(11) rows(2))
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
		drop if basis == "Retaliation" // drop retaliation cases
		levelsof basis_cat, local(levels)
		foreach l of local levels {
			g placebo_treat_`l' = (post==1 & basis_cat == `l') 	
		}

		foreach y of local outcome_vars {
			forvalues index = 1(1)5 {
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
	drop if basis == "Retaliation" // drop retaliation cases

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
	drop if basis == "Retaliation" // drop retaliation cases

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
		drop if basis == "Retaliation" // drop retaliation cases

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
Correlation b/w duration and outcomes
*******************************************************************************/
if `run_duration' == 1 {

	eststo: reg settle duration, r

	eststo: reg settle duration if sex_cases == 1, r

	eststo: reg win duration, r

	eststo: reg win duration if sex_cases == 1, r

	eststo:	reg relief_scale duration, r

	eststo:	reg relief_scale duration if sex_cases == 1, r

	#delimit ;
	
	estout _all using "$tables/duration_corr.tex", style(tex) replace
		drop(_cons)
		varlabels(duration "Duration")
		mgroups("Settle" "Win" "Compensation", pattern(1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none)
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 5))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(5)star)" "se(fmt(5)par)") 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") ;

	#delimit cr
	estimates clear
	eststo clear
}

/*******************************************************************************
Selection table
*******************************************************************************/

if `run_selection' == 1 {
	
	preserve 
	eststo A: reg total_cases_per_year post, r

	eststo B: reg sex_cases_per_year post if sex_cases == 1, r

	bys months_to_treat_12: egen months_to_treat_12_count = total(y) if sex_cases == 0
	eststo C: reg months_to_treat_12_count post if sex_cases == 0 & inlist(months_to_treat_12, -1, 0), r

	bys months_to_treat_12 sex_cases: egen months_to_treat_12_count_sex = total(y)
	eststo D: reg months_to_treat_12_count_sex post if sex_cases == 1 & inlist(months_to_treat_12, -1, 0), r
	
	#delimit ;
	
	esttab A B C D using "$tables/selection_table.tex", style(tex) replace
		drop(_cons)
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule" "\multicolumn{@span}{c}{\textbf{Counts (per year)}} \\ \midrule")
		fragment
		varlabels(post "Post MeToo")
		mlabel("\# filed" "\# Sex filed" "\shortstack{\# Control filed in 12 months\\before vs after MeToo}" "\shortstack{\# Sex filed in 12 months\\before vs after MeToo}" )
		nomtitles nonumbers
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(a3)star)" "se(fmt(a3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear

	eststo B: reg filed_per_year post if sex_cases == 1, r 
	
	eststo C: reg filed_f_per_year post if sex_cases == 1 & victim_f == 1, r

	eststo D: reg filed_f_per_year post if sex_cases == 1 & victim_f == 0, r

	#delimit ;
	
	esttab B B C D using "$tables/selection_table.tex", style(tex)
		prehead("\midrule \multicolumn{@span}{c}{\textbf{Shares}} \\ \midrule")		
		fragment 
		append
		drop(_cons)
		varlabels(post "Post MeToo")
		mlabel("DELETE ME" "\shortstack{Share Sex filed\\of total cases}" "\shortstack{Share Sex filed\\by women}" "\shortstack{Share Sex filed\\by men}")
		nomtitles nonumbers
		stats(N r2, label(`"N"' `" \(R^{2}\)"') fmt(%9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(a3)star)" "se(fmt(a3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}") 
		;
	#delimit cr
	estimates clear
	eststo clear	

	restore
}


if `state_did_all' == 1{
	******* All cases
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

	// Sum weights by state 
	preserve
	keep if treat_sex ==1	//bysort state_cat: egen sum_weight_by_state = total(weights)
	collapse (sum) sum_weight_by_state = weights, by(state_cat)

	scatter sum_weight_by_state state_cat, ///
		xtitle(" ") /// //yscale(range(-.1 .1)) ylabel(-.1(.05).1, labsize(small))
		yline(0) mlabel(state) mlabposition(6) ///
		xlabel(, noticks nolabel nogrid) ///
		ytitle("DID treated weights")

	graph export "$figures/state_weights_all.png", replace 	
	restore

	***** Individual state effects
	preserve 
	
	label values state_did state_cat
	drop if inlist(state_did, 42, 54) //drop US territories and WV bc coefficient is too high 

	reghdfe win i.state_did, absorb(basis_state ym_res_state) vce(cluster basis)
	eststo A

	reghdfe win treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
    loc att: display %5.4f _b[treat_sex]
	
	local my_blue "0 102 204"  
	local my_red "220 20 60"
	local my_purple "128 0 128"

	#delimit ;
	coefplot 
		(A, keep(1.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AK
		(A, keep(2.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AL
		(A, keep(3.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // AR
		(A, keep(5.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // AZ
		(A, keep(6.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CA
		(A, keep(7.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CO
		(A, keep(8.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // CT
		(A, keep(9.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DC
		(A, keep(10.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // DE
		(A, keep(11.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // FL
		(A, keep(12.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // GA
		(A, keep(14.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // HI
		(A, keep(15.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // IA
		(A, keep(16.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // ID
		(A, keep(17.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // IL
		(A, keep(18.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // IN
		(A, keep(19.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // KS
		(A, keep(20.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // KY
		(A, keep(21.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // LA
		(A, keep(22.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MA
		(A, keep(23.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // MD
		(A, keep(24.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // ME
		(A, keep(25.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // MI
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
		(A, keep(36.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // NV
		(A, keep(37.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // NY
		(A, keep(38.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // OH
		(A, keep(39.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // OK
		(A, keep(40.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // OR
		(A, keep(41.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))) // PA
		(A, keep(43.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // RI
		(A, keep(44.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // SC
		(A, keep(45.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // SD
		(A, keep(46.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // TN
		(A, keep(47.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // TX
		(A, keep(48.state_did) mcolor("`my_red'") ciopts(color("`my_red'"))) // UT
		(A, keep(49.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // VA
		(A, keep(52.state_did) mcolor("`my_blue'") ciopts(color("`my_blue'"))) // WA
		(A, keep(53.state_did) mcolor("`my_purple'") ciopts(color("`my_purple'"))), // WI
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
}

/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
	
	loc balance ///
    sex_cases ///
	basis_dummy1 ///
	basis_dummy2 ///
	basis_dummy3 ///
	basis_dummy4 ///
	basis_dummy5 ///
	basis_dummy6 ///
	basis_dummy7 ///
	basis_dummy8 ///
	basis_dummy9 ///
	juris_dummy1 ///
	juris_dummy2 ///
	juris_dummy3 ///
	juris_dummy4 ///
	juris_dummy5 ///
    settle ///
	court ///
	duration ///
    overlap_2 ///
    relief ///
	missing_relief ///
    win

	preserve 

	// Run overlap_2 on ALL CASES
    balancetable_program `balance', sample(overlap_2 !=.) using("$tables/balance_overlap_2.tex") ctitles("Before" "overlap_2" "Diff" "p-value") wide(mean diff pval) by(overlap_2) errors(robust)

	// Now restrict sample 
    balancetable_program `balance', using("$tables/balance.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

    balancetable_program `balance', sample(sex_cases == 1) using("$tables/balance_sex.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(robust)

    // Filed pre-covid
    balancetable_program `balance', sample(ym_filed < 721) using("$tables/balance_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	g covid = date("11mar2020", "DMY")
	
    // Resolved pre-covid
    balancetable_program `balance', sample(common_res_date < covid) using("$tables/balance_res_covid.tex") ctitles("Before" "After" "Diff" "p-value") wide(mean diff pval) by(post) errors(cluster basis)

	restore
}

/*******************************************************************************
DiD with gender (appendix)
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 relief_scale
loc y4 settle
loc y5 court

loc outcome_vars y1 y2 y3 y4 y5
loc i 1

if `run_did_gender_appendix' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if victim_f != ., absorb(basis ym_res) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Gender non-missing}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Compensation" "Settled" "Court", pattern(1 0 1 0 1 0 1 0 1 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##victim_f ym_res##victim_f) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex) 
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Complainant is female}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4 y5
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##victim_f ym_res##victim_f) vce(cluster basis)
		eststo a`i'
		qui estadd loc feunit "\checkmark", replace
		qui: sum ``y'' if treat_f ==0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		
		reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab a1 s1 a2 s2 a3 s3 a4 s4 a5 s5 using "$tables/did_gender_appendix.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Overlaps with MeToo}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit feunit_s N r2 control_mean, 
			label("Unit and Time FE" "Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}

/*******************************************************************************
Synthetic DiD

package sdid from: https://github.com/Daniel-Pailanir/sdid

Y: Outcome variable (numeric)
S: Unit variable (numeric or string)
T: Time variable (numeric)
D: Dummy of treatement, equal to 1 if units are treated, and otherwise 0 (numeric)

, method() // change option to did for DiD and SC for synthetic control
*******************************************************************************/



/* if `run_sdid' == 1 {

	loc time years_to_treat_res
	loc unit basis

	loc i 1 // counter for eststo labeling

	foreach y of loc outcome_vars{
		preserve
			collapse (mean) ``y'', by(`time' `unit')
			drop if `time' == .

			egen `unit'_cat = group(`unit') // can't xtset string var
			xtset `unit'_cat `time' // xtset for panel data
			spbalance, balance // check balance, drop if unbalanced

			g treat_sex = 0 
			replace treat_sex = 1 if `unit' == "Sex" & `time' > 0 

			#delimit ;
			eststo sdid`i': sdid ``y'' `unit' `time' treat_sex,
				vce(placebo) reps(100) seed(123) method(sdid) 
				graph g1on msize(medium)
				g2_opt(xlabel(-8(1)5) xtitle("Time to MeToo", size(medium))) //ytitle("Probability of settlement", size(medium))
				graph_export("$figures/sdid_``y''_", .png); 
		
			#delimit cr
			loc ++i
		restore
	}
} */

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

/*******************************************************************************
Main DID 
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4
loc i 1

if `run_did' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: All complaints}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 & victim_f != .
		estadd scalar control_mean = `r(mean)'
						
		loc ++i

	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex)  
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Complaints with gender}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post") keep(treat)
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr

	estimates clear
	eststo clear

	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Complaints with gender (triple difference)}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}

/*******************************************************************************
DiD overlap
*******************************************************************************/
loc y1 win 
loc y2 dismissed
loc y3 settle
loc y4 court

loc outcome_vars y1 y2 y3 y4 
loc i 1

if `run_overlap' == 1 {
	preserve 
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat == 0 
		estadd scalar control_mean = `r(mean)'
						
		loc ++i
	}

	#delimit ;	
	esttab s1 s2 s3 s4 using "$tables/did_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel A: Difference-in-differences}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Won" "Dismissed" "Settled" "Court", pattern(1 1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");

	#delimit cr
	estimates clear
	eststo clear
	
	loc outcome_vars y1 y2 y3 y4
	loc i 1
	foreach y of local outcome_vars {
		
		reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
		eststo s`i'
		qui estadd loc feunit_s "\checkmark", replace
		qui: sum ``y'' if treat_f == 0 & common_file_date < date("$metoo", "DMY")
		estadd scalar control_mean = `r(mean)'
		loc ++i
	}

	#delimit ;
	esttab s1 s2 s3 s4 using "$tables/did_overlap.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Triple difference}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(feunit_s N r2 control_mean, 
			label("Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
	restore
}


/*******************************************************************************
DiD regression - Robustness Check
*******************************************************************************/

if `run_did_robust' == 1 {

	// Single-tagged 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Drop retaliation 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Filed before covid 
	preserve 
		keep if ym_filed < 722
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_robust_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule")
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	
	
	// Single-tagged 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Drop retaliation 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	// Filed before covid 
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_robust_win_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("\midrule")
		varlabels(treat "SH $\times$ Post") keep(treat)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 1 1) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut N r2 control_mean, 
			label("Unit and Time $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}


/*******************************************************************************
DiD with Sex as treated
*******************************************************************************/
if `run_did_sex' == 1 {

	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace
	keep if juris == "Employment" // Only employment cases

	reghdfe win treat_sex, absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat_sex == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat_sex if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat_sex == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat_sex treat_sex_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_sex_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_sex.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("Unit and Time $\times$ State FE" "Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");
	;
	#delimit cr
	estimates clear
	eststo clear
	restore

	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace
	keep if juris == "Employment" // Only employment cases

	reghdfe win treat_sex if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat_sex == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat_sex if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat_sex == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat_sex treat_sex_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_sex_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_sex_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat_sex "Sex $\times$ Post" treat_sex_f "Sex $\times$ Post $\times$ Female") keep(treat_sex treat_sex_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("Unit and Time $\times$ State FE" "Unit and Time $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");
	;
	#delimit cr
	estimates clear
	eststo clear
	restore
}


/*******************************************************************************
Unit trends 
*******************************************************************************/

if `run_unit' == 1 {

	reghdfe win treat, absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui estadd loc unit "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui estadd loc unit "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f (basis_cat##state_cat##victim_f)#ym_res) vce(cluster basis)
	eststo s3
	qui estadd loc ut_f "\checkmark", replace
	qui estadd loc unit_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'
	
		#delimit ;	
	esttab s1 s2 s3 using "$tables/sdid.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut unit ut_f unit_f N r2, label("Unit and Time $\times$ State FE" "Unit $\times$ Time $\times$ State FE" "Unit and Time $\times$ Female $\times$ State FE" "Unit $\times$ Time $\times$ Female $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear


	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui estadd loc unit "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state ym_res_state#basis_state) vce(cluster basis)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui estadd loc unit "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f (basis_cat##state_cat##victim_f)#ym_res) vce(cluster basis)
	eststo s3
	qui estadd loc ut_f "\checkmark", replace
	qui estadd loc unit_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'
	
		#delimit ;	
	esttab s1 s2 s3 using "$tables/sdid_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut unit ut_f unit_f N r2, label("Unit and Time $\times$ State FE" "Unit $\times$ Time $\times$ State FE" "Unit and Time $\times$ Female $\times$ State FE" "Unit $\times$ Time $\times$ Female $\times$ State FE" `"N"' `" \(R^{2}\)"') fmt(3 3 3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}

/*******************************************************************************
EEOC foia
*******************************************************************************/
if eeoc_foia == 1 {

use "$clean_data/eeoc_foia.dta", clear

keep if eeoc_foia == 1


 estpost summarize relief_scale if sh == 1 & post == 0
 eststo sh_pre

 estpost summarize relief_scale if sh == 1 & post == 1
 eststo sh_post

 estpost summarize relief_scale if sh == 0 & post == 0
 eststo non_pre

 estpost summarize relief_scale if sh == 0 & post == 1
 eststo non_post

 // Output LaTeX table with grouped columns and clean headers
 esttab sh_pre sh_post non_pre non_post using "$tables/eeoc_relief.tex", style(tex) replace ///
     prehead("\begin{tabular}{lcccc}" "\toprule") ///
     posthead("\multicolumn{1}{c}{} " ///
         "& \multicolumn{1}{c}{\textbf{Pre}} & \multicolumn{1}{c}{\textbf{Post}} " ///
         "& \multicolumn{1}{c}{\textbf{Pre}} & \multicolumn{1}{c}{\textbf{Post}} \\" ///
         "\midrule") ///
     varlabels(relief_scale "Relief (mean)") ///
 	mgroups("SH complaints" "Non-SH complaints", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
     nomtitles nonumbers noobs ///
	 collabels(none) ///
     cells(mean(fmt(3) label(""))) ///
     postfoot("\bottomrule" "\end{tabular}")
}


/*******************************************************************************
Selection 
*******************************************************************************/

if `selection' == 1 {

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
			ytitle("Treatment effect (B-C)", size(medlarge)) 
			xtitle("{&omega}", size(medlarge))
			yline(0.086, lp(solid) lwidth(thick) lcolor(orange_red))
			yline(0, lp(solid) lwidth(medium) lcolor(gs3))
			ylabel(0(0.1)1)
			legend(off) 
			text(.23 .9 "Treatment effect" "for women" "always reporters", color("orange_red") place(r) size(medium))
			text(.6 .7 "Treatment effect" "for women" "induced reporters", color("orange_red") place(r) size(medium))
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
			ytitle("Treatment effect (B-C)", size(medlarge)) 
			xtitle("{&omega}{sup:M}", size(medlarge))
			legend(off) 
			ylabel(-.5(.1).5)
			text(.25 .3 "Treatment effect for" "men always reporters", color("ebblue") place(r) size(medium))
			text(-.2 .65 "Treatment effect" "for men" "induced reporters", color("ebblue") place(r) size(medium))
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
	
}
	
	
/*******************************************************************************
Event-study
*******************************************************************************/

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
		text(45 2 "ATT: `att'", size(medsmall) color(black))
	;
	#delimit cr
				
 	graph export "$figures/eventstudy_relief_scale.png", replace 
	estimates clear
	
	
		******** Rambachan & Roth (2021) for win ********
	reghdfe win ib7.event, absorb(basis_state ym_res_state) vce(cluster basis)
	honestdid, numpre(7) omit ///
		coefplot xtitle(Mbar) ytitle(95% Robust CI)
 	graph export "$figures/honestdid_win.png", replace
	
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

if `duration' == 1 {
	
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
// 	graph export "$figures/overlap_balance_sex.png", replace
	restore

	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = win, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Win rate") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
// 	graph export "$figures/overlap_balance_win.png", replace
	restore


	preserve
	keep if ym_filed < 693 
	collapse (mean) avg_sex_cases = duration, by(ym_filed overlap_all)

	twoway (line avg_sex_cases ym_filed if overlap_all==0, lcolor(blue)) ///
		(line avg_sex_cases ym_filed if overlap_all==1, lcolor(red)), ///
		legend(label(1 "Resolved before") label(2 "Overlap")) ///
		xtitle("Year-month filed") ytitle("Duration") ///
		title("% sex cases in overlap and non-overlap cases filed in the same year-month") 
// 	graph export "$figures/overlap_balance_duration.png", replace
	restore

}

/*******************************************************************************
Filing invariance
*******************************************************************************/

if `file_invariance' == 1 {
	
// 6 months pre and post
	
	keep if inrange(ym_res, tm(2017m04), tm(2018m04))


	collapse (mean) win, by(ym_res sh overlap_all)
	list
	
	local me_too_date = tm(2017m10)


	twoway ///
		(line win ym_res if sh == 1 & inrange(ym_res, tm(2017m04), tm(2017m10)) & overlap_all == 0, lcolor(gray) lpattern(solid) lwidth(medthick)) ///
		(line win ym_res if sh == 0 & inrange(ym_res, tm(2017m04), tm(2017m10)) & overlap_all == 0, lcolor(gray) lpattern(shortdash) lwidth(medthick)) ///
		(line win ym_res if sh == 1 & overlap_all == 1, lcolor(green) lpattern(solid) lwidth(medthick)) ///
		(line win ym_res if sh == 0 & overlap_all == 1, lcolor(green) lpattern(shortdash) lwidth(medthick)), ///
		xline(`me_too_date', lpattern(dash) lcolor(black) lwidth(medthick)) ///
		text(0.9 693.15 "MeToo", place(e) size(medsmall)) ///
		legend(order(1 "SH (Pre Period)" 2 "Non-SH (Pre Period)" 3 "SH (Overlap)" 4 "Non-SH (Overlap)") size(small)) ///
		ylabel(0(.1)1, angle(horizontal) labsize(medsmall)) ///
		xlabel(#12, format(%tmMon_CCYY) angle(45) labsize(medsmall)) ///
		xtitle("Resolution Date", size(medlarge)) ///
		ytitle("Win Rate", size(medlarge)) ///
		
	graph export "$figures/filing_invariance_comp.png", replace 
	estimates clear
}

