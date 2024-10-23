
/*******************************************************************************
Plots timeseries lpolyci with confidence intervals for two groups by GENDER
*******************************************************************************/
cap program drop plot_lpolyci_gender
program define plot_lpolyci_gender
    syntax varlist(min=2 max=2) [, TITLE(string) YLABEL(string)]

    local Yvar : word 1 of `varlist'
    local Xvar : word 2 of `varlist'

    preserve
    collapse (mean) mean_y = `Yvar', by(`Xvar' sh victim_f)
    
    * Get the min and max values of the x-axis variable
    summarize `Xvar', detail
    local xmin = r(min)
    local xmax = r(max)
    
    * Create the x-axis label with proper formatting
    local xlabel_cmd `"xlabel(`xmin'(12)`xmax', angle(45) format(%tm))"'

    #delimit ;
    twoway 
        lpolyci mean_y `Xvar' if sh == 0, acolor("gs3 %65") lwidth(medthick) clpattern(solid) clcolor(gs3)
        || lpolyci mean_y `Xvar' if sh == 1 & victim_f == 1, acolor("red %65") lwidth(medthick) clpattern(solid) clcolor(red)
        || lpolyci mean_y `Xvar' if sh == 1 & victim_f == 0, acolor("orange %65") lwidth(medthick) clpattern(solid) clcolor(orange)
           legend(order(3 5 1) lab(3 "Female SH complainants") lab(5 "Male SH complainants") lab(1 "All other complainants") size(medium) ring(0) pos(11) rows(3))
           xtitle("Date filed", size(medium))
           xline(693, lpattern(solid))
           `xlabel_cmd'
           xscale(range(`xmin' 700))
           ytitle(`"`ylabel'"', size(medium)) title(`"`title'"')
    ;
    #delimit cr
    local filename = "timeseries_`Yvar'_gender.png"
    graph export "$figures/`filename'", replace
    restore
end

/*******************************************************************************
Plots timeseries lpolyci with confidence intervals for two groups
*******************************************************************************/
cap program drop plot_lpolyci
program define plot_lpolyci
    syntax varlist(min=2 max=2) [, TITLE(string) YLABEL(string)]

    local Yvar : word 1 of `varlist'
    local Xvar : word 2 of `varlist'

    preserve
    collapse (mean) mean_y = `Yvar', by(`Xvar' sh)
    
    * Get the min and max values of the x-axis variable
    summarize `Xvar', detail
    local xmin = r(min)
    local xmax = r(max)
    
    * Create the x-axis label with proper formatting
    local xlabel_cmd `"xlabel(`xmin'(12)`xmax', angle(45) format(%tm))"'

    #delimit ;
    twoway 
        lpolyci mean_y `Xvar' if sh == 0, acolor("gs3 %65") lwidth(medium) clpattern(solid) clcolor(black)
        || lpolyci mean_y `Xvar' if sh == 1, acolor("orange_red %65") lwidth(medium) clpattern(dash) clcolor(black)
        || scatter mean_y `Xvar' if sh == 0, mcolor("gs3") msize(small)
        || scatter mean_y `Xvar' if sh == 1, mcolor("orange_red") msize(small)
           legend(order(3 1) lab(3 "Sexual harassment, 95% CI") lab(1 "Other complaints, 95% CI") size(medium) ring(0) pos(11) rows(2))
           xtitle("Date filed", size(medium))
           xline(693, lpattern(solid))
           `xlabel_cmd'
           ytitle(`"`ylabel'"', size(medium)) title(`"`title'"')
    ;
    #delimit cr
    *local filename = "timeseries_`Yvar'.png"
    *graph export "$figures/`filename'", replace
    restore
end

/*******************************************************************************
Program to create time to treat
*******************************************************************************/

cap program drop create_time_to_treat

program define create_time_to_treat
    syntax, period(integer) [period_label(string)]

    gen event_date = date("$metoo", "DMY")

    // Calculate the months_to_treat var, 0 is first period after MeToo, -1 is pre-period 
    gen months_to_treat_`period' = floor((common_file_date - event_date) / (`period' * 30.4375))
    
    // Label the time_to_treat variable
    if "`period_label'" != "" {
        label var months_to_treat_`period' "`period_label'"
    }
    else {
        label var months_to_treat_`period' "Periods relative to MeToo"
    }
	drop event_date
end


/*******************************************************************************
program to create balance tables
*******************************************************************************/
capture program drop balancetable_program
program define balancetable_program
    syntax [anything] [, using(string) sample(string) ctitles(string) wide(string) by(string) errors(string)]

    balancetable `by' `anything' ///
        using "`using'", ///
        varlabels vce(`errors') replace ///
        ctitles(`ctitles') ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(`wide')
        if `"`sample'"' != "" {
            balancetable `by' `anything' if `sample' ///
                using "`using'", ///
                varlabels vce(`errors') replace ///
                ctitles(`ctitles') ///
                pvalues staraux pval(nopar) format(%9.2f) ///
                wide(`wide')
        }
end

