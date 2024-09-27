
/*******************************************************************************
Plots timeseries lpolyci with confidence intervals for two groups
*******************************************************************************/

program define plot_lpolyci
    syntax varlist(min=2 max=2) [, TITLE(string) YLABEL(string)]

    local Yvar : word 1 of `varlist'
    local Xvar : word 2 of `varlist'

    preserve
    collapse (mean) mean_settle = `Yvar', by(`Xvar' sh)
    
    * Get the min and max values of the x-axis variable
    summarize `Xvar', detail
    local xmin = r(min)
    local xmax = r(max)
    
    * Create the x-axis label with proper formatting
    local xlabel_cmd `"xlabel(`xmin'(6)`xmax', angle(45) format(%tm))"'

    twoway (lpolyci mean_settle `Xvar' if sh == 0, acolor("gs3 %65")) ///
           (lpolyci mean_settle `Xvar' if sh == 1, acolor("orange_red %65") ///
           clpattern(dash) clcolor(black) ///
           legend(order(3 1) lab(1 "Other, 95% CI") lab(3 "Sexual harassment, 95% CI") size(medium) ring(0) pos(11)) ///
           xtitle("Date filed", size(medium)) ///
           xline(693, lpattern(solid)) ///
           `xlabel_cmd' ///
           ytitle(`"`ylabel'"') title(`"`title'"'))

    local filename = "timeseries_`Yvar'_smooth.png"
    graph save "$figures/`filename'", replace
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

