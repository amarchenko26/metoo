/*******************************************************************************
Tables for MeToo project 
*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

loc run_stat_significant = 0
loc run_did_win	 		= 1
loc run_overlap_win		= 1
loc run_did_outcomes 	 = 1
loc run_overlap_outcomes = 1
loc run_overlap_season  = 1
loc run_did_robust 		= 1
loc run_did_alljuris 	= 1
loc run_did_ct			= 1
loc run_summary  		= 0
loc run_overlap_balance = 1
loc run_did_duration 	= 1
loc run_overlap_duration = 1


/*******************************************************************************
Testing whether the difference is statistically significant 
*******************************************************************************/

if `run_stat_significant' == 1 {
	
	*-- Full sample
	reghdfe win, absorb(basis_state ym_res_state) resid
	rename _reghdfe_resid win_resid_full

	reghdfe treat, absorb(basis_state ym_res_state) resid
	rename _reghdfe_resid treat_resid_full

	*-- Overlap sample only
	reghdfe win if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) resid
	rename _reghdfe_resid win_resid_pre

	reghdfe treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) resid
	rename _reghdfe_resid treat_resid_pre

	* Now run simple OLS on residuals
	reg win_resid_full treat_resid_full
	estimates store full

	reg win_resid_pre treat_resid_pre
	estimates store pre

	* Test the difference
	suest full pre, vce(cluster basis_state)
	lincom [full_mean]treat_resid_full - [pre_mean]treat_resid_pre
	// betaCE - betaO = 0
	// Diff = .015, SE = .024, p = .523


	estimates clear 

	* === FULL SAMPLE ===
	reghdfe win, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid win_resid_full

	reghdfe treat, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid treat_resid_full

	reghdfe treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid treat_f_resid_full

	* === PRE-METOO SAMPLE ===
	reghdfe win if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid win_resid_pre

	reghdfe treat if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid treat_resid_pre

	reghdfe treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) resid
	rename _reghdfe_resid treat_f_resid_pre

	* === OLS ON RESIDUALS ===
	reg win_resid_full treat_resid_full treat_f_resid_full
	estimates store full

	reg win_resid_pre treat_resid_pre treat_f_resid_pre if common_file_date < date("$metoo", "DMY")
	estimates store pre

	* === TEST DIFFERENCES ===
	suest full pre, vce(cluster basis_state)

	* Men: treat in full vs treat in pre
	lincom [full_mean]treat_resid_full - [pre_mean]treat_resid_pre

	* Women: (treat + treat_f) in full vs (treat + treat_f) in pre
	lincom ([full_mean]treat_resid_full + [full_mean]treat_f_resid_full) - ([pre_mean]treat_resid_pre + [pre_mean]treat_f_resid_pre)

}


/*******************************************************************************
Win-only Main DID 
*******************************************************************************/

if `run_did_win' == 1 {
	preserve 
	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
 	esttab s1 s2 s3 using "$tables/did_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\"  
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
Win-only Overlap DID 
*******************************************************************************/

if `run_overlap_win' == 1 {

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}


/*******************************************************************************
Other Outcomes DID 
*******************************************************************************/
loc y1 settle
loc y2 court

loc outcome_vars y1 y2
loc i 1

if `run_did_outcomes' == 1 {
	preserve 
	foreach y of local outcome_vars {
        
        reghdfe ``y'' treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0 & victim_f != .
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui estadd loc ut_f "\checkmark", replace
        qui: sum ``y'' if treat_f == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i
    
    }

    #delimit ;    
    esttab s1 s2 s3 s4 s5 s6 using "$tables/did_outcomes.tex", style(tex) replace 
        prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
        posthead("\multicolumn{1}{c}{} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
        "\midrule")
        varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
        mgroups("Settled" "Court", pattern(1 0 0 1 0 0) 
            prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
        mlabel(none) nomtitles nonumbers
        stats(ut ut_f N r2 control_mean, 
            label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
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
Other Outcomes Overlap DID 
*******************************************************************************/
loc y1 settle
loc y2 court

loc outcome_vars y1 y2
loc i 1

if `run_overlap_outcomes' == 1 {
	preserve 
	foreach y of local outcome_vars {
        
        reghdfe ``y'' treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui: sum ``y'' if treat == 0 & victim_f != .
        estadd scalar control_mean = `r(mean)'
        loc ++i

        reghdfe ``y'' treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
        eststo s`i'
        qui estadd loc ut "\checkmark", replace
        qui estadd loc ut_f "\checkmark", replace
        qui: sum ``y'' if treat_f == 0
        estadd scalar control_mean = `r(mean)'
        loc ++i
    
    }

    #delimit ;    
    esttab s1 s2 s3 s4 s5 s6 using "$tables/did_overlap_outcomes.tex", style(tex) replace 
        prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
        posthead("\multicolumn{1}{c}{} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
        "& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
        "\midrule")
        varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
        mgroups("Settled" "Court", pattern(1 0 0 1 0 0) 
            prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
        mlabel(none) nomtitles nonumbers
        stats(ut ut_f N r2 control_mean, 
            label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
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
DiD overlap - by season  
*******************************************************************************/

if `run_overlap_season' == 1 {

	reghdfe win treat if file_season == 4 & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if file_season == 4 & victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if file_season == 4 &common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_season.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule")
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule \multicolumn{@span}{c}{\textbf{Panel A: Winter}} \\ \midrule")
		fragment
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear

	reghdfe win treat if file_season == 1 & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if file_season == 1 & victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if file_season == 1 & common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_season.tex", style(tex) 
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel B: Spring}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers
		stats(ut N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear

	reghdfe win treat if file_season == 2 & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if file_season == 2 & victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if file_season == 2 & common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_season.tex", style(tex) 
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel C: Summer}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers
		stats(ut N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule");
	#delimit cr
	estimates clear
	eststo clear

	reghdfe win treat if file_season == 3 & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if file_season == 3 & victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if file_season == 3 & common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;
	esttab s1 s2 s3 using "$tables/did_overlap_season.tex", style(tex)
		posthead("\midrule \multicolumn{@span}{c}{\textbf{Panel D: Fall}} \\ \midrule")
		fragment
		append
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mlabel(none) nomtitles nonumbers nolines
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");
	#delimit cr
	estimates clear
	eststo clear
}


/*******************************************************************************
Comparison by filing season  
*******************************************************************************/

// Winter 
	reghdfe win treat if file_season == 4 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_winter: display %5.3f _b[treat]

	reghdfe win treat treat_f if file_season == 4 & victim_f != ., absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local winter_diff = round(_b[treat_f], 0.001)
	local winter_m = round(_b[treat], 0.001)
	local winter_f = `winter_m' + `winter_diff'

// Spring
	reghdfe win treat if file_season == 1 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_spring: display %5.3f _b[treat]
	
	reghdfe win treat treat_f if file_season == 1 & victim_f != ., absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local spring_diff = round(_b[treat_f], 0.001)
	local spring_m = round(_b[treat], 0.001)
	local spring_f = `spring_diff' + `spring_m'


// Summer 
	reghdfe win treat if file_season == 2 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_summer: display %5.3f _b[treat]
	
	reghdfe win treat treat_f if file_season == 2 & victim_f != ., absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local summer_diff = round(_b[treat_f], 0.001)
	local summer_m = round(_b[treat], 0.001)
	local summer_f = `summer_diff' + `summer_m'

// Fall
	reghdfe win treat if file_season == 3 & victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_fall: display %5.3f _b[treat]
	
	reghdfe win treat treat_f if file_season == 3 & victim_f != ., absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local fall_diff = round(_b[treat_f], 0.001)
	local fall_m = round(_b[treat], 0.001)
	local fall_f = `fall_diff' + `fall_m'
	
// All 
	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_all: display %5.3f _b[treat]

	reghdfe win treat treat_f if victim_f != ., absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local all_diff = round(_b[treat_f], 0.001)
	local all_m = round(_b[treat], 0.001)
	local all_f = `all_m' + `all_diff'
	
// All Overlap 
	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	loc twfe_all_overlap: display %5.3f _b[treat]

	reghdfe win treat treat_f if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	local all_overlap_diff = round(_b[treat_f], 0.001)
	local all_overlap_m = round(_b[treat], 0.001)
	local all_overlap_f = `all_overlap_m' + `all_overlap_diff'

	
// Display 
	di "Winter TWFE: " %5.3f `twfe_winter'
	di "Winter Male ATT: " %5.3f `winter_m'
	di "Winter Female ATT: " %5.3f `winter_f'
	
	di "Spring TWFE: " %5.3f `twfe_spring'
	di "Spring Male ATT: " %5.3f `spring_m'
	di "Spring Female ATT: " %5.3f `spring_f'
	
	di "Summer TWFE: " %5.3f `twfe_summer'
	di "Summer Male ATT: " %5.3f `summer_m'
	di "Summer Female ATT: " %5.3f `summer_f'
	
	di "Fall TWFE: " %5.3f `twfe_fall'
	di "Fall Male ATT: " %5.3f `fall_m'
	di "Fall Female ATT: " %5.3f `fall_f'
	
	di "All TWFE: " %5.3f `twfe_all'
	di "All Male ATT: " %5.3f `all_m'
	di "All Female ATT: " %5.3f `all_f'
	
	di "All Overlap TWFE: " %5.3f `twfe_all_overlap'
	di "All Overlap Male ATT: " %5.3f `all_overlap_m'
	di "All Overlap Female ATT: " %5.3f `all_overlap_f'


/*******************************************************************************
DiD regression - Robustness Check
*******************************************************************************/

if `run_did_robust' == 1 {

// Single-tagged

	// (1) all complaints 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if multi_cat == 0
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	


// Drop retaliation 

	// (1) all complaints 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s4
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s5
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s6
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

// Filed before covid 

	// (1) all complaints
	preserve 
		keep if ym_filed < 722
		reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s7
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s8
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if ym_filed < 722
		reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s9
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

	#delimit ;	
	esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$tables/did_robust_win.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("\multicolumn{1}{c}{} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}" ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
	"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 0 0 1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE"  `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	
	

// Single-tagged

	// (1) all complaints 
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s1
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if multi_cat == 0
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s2
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if multi_cat == 0
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s3
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	


// Drop retaliation 

	// (1) all complaints 
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s4
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s5
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		drop if basis == "Retaliation"
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s6
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

// Filed before covid 

	// (1) all complaints
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s7
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (2) gender TWFE
	preserve 
		keep if ym_filed < 722
		reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
		eststo s8
		qui estadd loc ut "\checkmark", replace
		qui: sum win if treat ==0  & victim_f != .
		estadd scalar control_mean = `r(mean)'
	restore
	
	// (3) gender triple diff
	preserve 
		keep if ym_filed < 722
		reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
		eststo s9
		qui estadd loc ut "\checkmark", replace
		qui estadd loc ut_f "\checkmark", replace
		qui: sum win if treat_f == 0
		estadd scalar control_mean = `r(mean)'
	restore
	
	

	#delimit ;	
	esttab s1 s2 s3 s4 s5 s6 s7 s8 s9 using "$tables/did_robust_win_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("\multicolumn{1}{c}{} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} " ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}}" ///
		"& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" ///
	"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f)
		mgroups("Single-tagged" "No retaliation" "Pre-Covid", pattern(1 0 0 1 0 0 1 0 0) 
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
		mlabel(none) nomtitles nonumbers
		stats(ut uf_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 %9.0fc 3))
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01)
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule")
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear

}

/*******************************************************************************
All jurisdiction DID 
*******************************************************************************/

if `run_did_alljuris' == 1 {
	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace

	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_alljuris.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	restore

	preserve 
	use "$clean_data/clean_cases_all_juris.dta", replace

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_alljuris_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
CT DID  
*******************************************************************************/

if `run_did_ct' == 1 {
	preserve 
	use "$clean_data/clean_cases_w_ct.dta", replace

	reghdfe win treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_ct.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
	restore

	preserve 
	use "$clean_data/clean_cases_w_ct.dta", replace

	reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum win if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum win if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_ct_overlap.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
Summary table
*******************************************************************************/

if `run_summary' == 1 {

	tab basis, gen(basis_dummy)

	#delimit ;
	loc summary_1
	// Case chars
		sh
		victim_f
		post 
		duration 
	// Basis
		basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5 
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court; 
	#delimit cr
	
	#delimit ;
	loc summary_2 // sex cases
	// Case chars
		sh
		victim_f
		post 
		duration 
	// Basis
		/* basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5  */
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court; 
	#delimit cr

	#delimit ;
	loc summary_3 // post MeToo
	// Case chars
		sh
		victim_f
		duration 
	// Basis
		basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5 
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court;
	#delimit cr

	#delimit ;
	loc summary_4 // post MeToo
	// Case chars
		victim_f
		duration 
	// Basis
		/* basis_dummy1 
		basis_dummy2 
		basis_dummy3 
		basis_dummy4 
		basis_dummy5  */
		basis_dummy6 
		basis_dummy7 
	// Outcomes 
		settle
		win_investigation
		lose_investigation
		dismissed
		court; 
	#delimit cr
	
	eststo mean_all: estpost tabstat `summary_1', c(stat) stat(mean sd)
	eststo mean_sex_cases: estpost tabstat `summary_2' if sh == 1, c(stat) stat(mean sd)
	eststo post_all: estpost ttest `summary_3', by(post)
	eststo post_sex_cases: estpost ttest `summary_4' if sh == 1, by(post)

	#delimit ;
	esttab mean_all mean_sex_cases post_all post_sex_cases using "$tables/summary.tex", replace 
		nonote nonumbers label booktabs f 
		cells("mean(fmt(%13.3fc) pattern(1 1 0 0) vacant(.)) b(star fmt(%13.3fc) pattern (0 0 1 1) vacant(.))"
				"sd(fmt(2) par([ ]) pattern(1 1 0 0) vacant(.)) se(par fmt(%15.2gc) pattern (0 0 1 1) vacant(.))")
		collabels(none)
    	mgroups("\shortstack{Sample\\Statistics}" 
				"\shortstack{Mean Difference\\(Post-Pre) MeToo}", 
			pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    	mtitles("All" "SH only" "All" "SH only")
			varlab( 
			sh "\textit{Complaint Characteristics} \\ \hspace{5mm} Sexual harassment" 
			victim_f "\hspace{5mm} Complainant is female" 
			post "\hspace{5mm} Filed after MeToo" 
			charge_file_year "\hspace{5mm} Year filed" 
			charge_res_year "\hspace{5mm} Year resolved" 
			duration "\hspace{5mm} Duration (days)" 
			basis_dummy1 "\textit{Discrimination basis} \\ \hspace{5mm} Age" 
			basis_dummy2 "\hspace{5mm} Disability" 
			basis_dummy3 "\hspace{5mm} Nationality" 
			basis_dummy4 "\hspace{5mm} Race" 
			basis_dummy5 "\hspace{5mm} Religion" 
			basis_dummy6 "\hspace{5mm} Retaliation" 
			basis_dummy7 "\hspace{5mm} Sex" 
			settle "\textit{Outcomes} \\ \hspace{5mm} Settled" 
			win_investigation "\hspace{5mm} Won"
			lose_investigation "\hspace{5mm} Lost"
			dismissed "\hspace{5mm} Dismissed"
			court "\hspace{5mm} Went to court" 
		) 
		substitute("\$" "$")
		stats(N, layout("@ @" "@ @") labels("Observations") fmt("%15.0fc %15.0fc" "%15.0fc %15.0fc"))
	;
	#delimit cr
	
}

*stats(N1 N2 p_joint, layout("@ @" ". @") labels("Observations" "Joint \textit{p}-value" ) fmt("%15.0fc %15.0fc" 2 2))	///

/****************************************************************************
Overlap balance table
****************************************************************************/

if `run_overlap_balance' == 1 {

	preserve	
		
	tab file_season, gen(season)
	la var season1 "\hspace{0.1cm} Filed in Spring"
	la var season2 "\hspace{0.1cm} Filed in Summer"
	la var season3 "\hspace{0.1cm} Filed in Fall"
	la var season4 "\hspace{0.1cm} Filed in Winter"
	
	loc balance ///
	victim_f ///
    sh ///
	season1 ///
	season2 ///
	season3 ///
	season4
	
	g overlap_balance = 1 if overlap_2 == 1
	replace overlap_balance = 0 if common_file_date < 20742 & common_res_date > 20742 
// 	replace overlap_balance = . if common_file_date < 20377 & overlap_balance == 0
// 	replace overlap_balance = . if common_res_date > 21107 & overlap_balance == 0
	
    balancetable overlap_balance `balance' using "$tables/overlap_balance.tex" if overlap_balance != ., ///
        varlabels vce(robust) replace ///
        ctitles("2016" "2017" "Diff" "p-value") ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(mean diff pval)
	restore
}




/*******************************************************************************
Duration Main DID 
*******************************************************************************/

if `run_did_duration' == 1 {
	preserve 
	reghdfe duration treat, absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat if victim_f != ., absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat treat_f, absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum duration if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
 	esttab s1 s2 s3 using "$tables/did_duration.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\"  
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
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
Duration Overlap DID 
*******************************************************************************/

if `run_overlap_duration' == 1 {

	reghdfe duration treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s1
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat if victim_f != . & common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_res_state) vce(cluster basis_state)
	eststo s2
	qui estadd loc ut "\checkmark", replace
	qui: sum duration if treat == 0 & victim_f != .
	estadd scalar control_mean = `r(mean)'

	reghdfe duration treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_res##state_cat##victim_f) vce(cluster basis_state)
	eststo s3
	qui estadd loc ut "\checkmark", replace
	qui estadd loc ut_f "\checkmark", replace
	qui: sum duration if treat_f == 0
	estadd scalar control_mean = `r(mean)'

	#delimit ;	
	esttab s1 s2 s3 using "$tables/did_overlap_duration.tex", style(tex) replace 
		prehead("\begin{tabular}{l*{@E}{c}}" "\toprule") 
		posthead("& \multicolumn{1}{c}{\textbf{All complaints}} & \multicolumn{2}{c}{\textbf{Complaints with gender}} \\" 
				"\midrule") 
		varlabels(treat "SH $\times$ Post" treat_f "SH $\times$ Post $\times$ Female") keep(treat treat_f) 
		mlabel(none) nomtitles nonumbers
		stats(ut ut_f N r2 control_mean, 
			label("\{Unit, Time\} $\times$ State FE" "\{Unit, Time\} $\times$ State $\times$ Female FE" `"N"' `" \(R^{2}\)"' "Control mean") fmt(3 3 %9.0fc 3)) 
		nobaselevels collabels(none) label starlevels(* .1 ** .05 *** .01) 
		cells("b(fmt(3)star)" "se(fmt(3)par)") 
		prefoot("\\" "\midrule") 
		postfoot("\bottomrule" "\end{tabular}");

	#delimit cr
	estimates clear
	eststo clear
}


/*******************************************************************************
Filing FE Robustness Check 
*******************************************************************************/

// CE
reghdfe win treat, absorb(basis_state ym_filed_state) vce(cluster basis_state)

// Overlap
reghdfe win treat if common_file_date < date("$metoo", "DMY"), absorb(basis_state ym_filed_state) vce(cluster basis_state)

// Gender CE
reghdfe win treat treat_f, absorb(basis_cat##state_cat##victim_f ym_filed##state_cat##victim_f) vce(cluster basis_state)

lincom treat+treat_f

// Gender Overlap
reghdfe win treat treat_f if common_file_date < date("$metoo", "DMY"), absorb(basis_cat##state_cat##victim_f ym_filed##state_cat##victim_f) vce(cluster basis_state)

lincom treat+treat_f


/*******************************************************************************
Permutation test Robustness Check 
*******************************************************************************/

g age_treat = (basis =="Age" & post==1)

g disability_treat = (basis =="Disability" & post==1)

g nat_treat = (basis =="Nationality" & post==1)

g race_treat = (basis =="Race" & post==1)

g rel_treat = (basis =="Religion" & post==1)

g retal_treat = (basis =="Retaliation" & post==1)


reghdfe win age_treat if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
reghdfe win disability_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
reghdfe win nat_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
reghdfe win race_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
reghdfe win rel_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)
reghdfe win retal_treat  if basis!="Sex", absorb(basis_state ym_res_state) vce(cluster basis_state)


// 




preserve 
drop if basis == "Sex"

local offset = 8

* list of placebo bases (as strings)
local placebo_bases "Age Disability Nationality Race Religion Retaliation"

foreach b of local placebo_bases {

    * treated unit indicator (plays role of `sh`)
    cap drop grp
    gen grp = (basis == "`b'")

    * ATT indicator (treated × post)
    cap drop treat
    gen treat = grp * post

    *------------------------------------------------------------
    * Define event-time variables for THIS placebo treated unit
    *------------------------------------------------------------
    cap drop event event_f
    gen event   = years_to_treat_res * grp
    gen event_f = years_to_treat_res * grp * victim_f

    replace event   = event   + `offset'
    replace event_f = event_f + `offset'

    replace event   = 1 if event   == 0
    replace event_f = 1 if event_f == 0

    *------------------------------
    * ATT
    *------------------------------
    reghdfe win treat, ///
        absorb(basis_state ym_res_state) vce(cluster basis_state)
    local att : display %5.3f _b[treat]

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
        text(0.3 4 "{&beta}{sup:CE}, placebo `b': `att'", size(medium) color(black))
    ;
    #delimit cr

    graph export "$figures/eventstudy_placebo_`b'.png", replace

    estimates clear
}

restore 












