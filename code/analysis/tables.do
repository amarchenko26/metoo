/*******************************************************************************
Tables for MeToo project
*******************************************************************************/

local run_summary = 1
local run_balance = 1
local run_duration = 1

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Clean data for tables
*******************************************************************************/

tab state, gen(state_dummy)
ren state_dummy1 federal
ren state_dummy2 MA

la var federal "\textbf{Case type} \\ \hspace{5mm} Federal"
la var MA "\hspace{5mm} Massachusetts"

tab juris, gen(juris_dummy)
la var juris_dummy1 "\hspace{5mm} Employment"
la var juris_dummy2 "\hspace{5mm} Private housing"
la var juris_dummy3 "\hspace{5mm} Public housing"

/*******************************************************************************
Prep vars
*******************************************************************************/

loc balance ///
    sh ///
    sex_cases ///
		federal ///
        MA ///
        juris_dummy1 ///
        juris_dummy2 ///
        juris_dummy3 ///
    charge_file_year ///
    charge_res_year ///
    went_to_court ///
    court_file_year ///
    court_res_year ///
    duration ///
    overlap ///
    relief ///
    probable_cause

format relief %10.0fc
format sh sex_cases %4.3f

/*******************************************************************************
Summary
*******************************************************************************/
if `run_summary' == 1 {

	est clear
	estpost tabstat treat `balance', c(stat) stat(mean sd min max n)

	esttab using "$tables/summary.tex", replace ///
		nomtitle nonote noobs label booktabs f ///
		cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(a2)) max(fmt(a2)) count(fmt(a2))") ///
		collabels("Mean" "SD" "Min" "Max" "N")
}

/*******************************************************************************
Balance table
*******************************************************************************/
capture program drop balancetable_program
program define balancetable_program
    syntax [anything] [, using(string) sample(string) ctitles(string) wide(string) by(string)]

    balancetable `by' `anything' ///
        using "`using'", ///
        varlabels vce(robust) replace ///
        ctitles(`ctitles') ///
        pvalues staraux pval(nopar) format(%9.2f) ///
        wide(`wide')
        if `"`sample'"' != "" {
            balancetable `by' `anything' if `sample' ///
                using "`using'", ///
                varlabels vce(robust) replace ///
                ctitles(`ctitles') ///
                pvalues staraux pval(nopar) format(%9.2f) ///
                wide(`wide')
        }
end

/****************************************************************************
Balance table
****************************************************************************/

if `run_balance' == 1 {
    balancetable_program `balance', using("$tables/balance.tex") ctitles("Before MeToo" "After MeToo" "Diff" "p-value") wide(mean diff pval) by(treat)

    balancetable_program `balance', sample(sh == 1) using("$tables/balance_sex.tex") ctitles("Before MeToo" "After MeToo" "Diff" "p-value") wide(mean diff pval) by(treat)

    // Pre-covid
    balancetable_program `balance', sample(ym < 721) using("$tables/balance_covid.tex") ctitles("Before MeToo" "After MeToo" "Diff" "p-value") wide(mean diff pval) by(treat)

    // overlap case characteristics
    balancetable_program `balance', using("$tables/balance_overlap.tex") ctitles("Ends before MeToo" "Overlaps MeToo" "Diff" "p-value") wide(mean diff pval) by(overlap)
}


/*******************************************************************************
Correlation b/w duration and outcomes
*******************************************************************************/
if `run_duration' == 1 {

	g relief_scale = relief / 1000

	reg duration relief_scale, r
		eststo A

	reg duration relief_scale if sh == 1, r
		eststo B

	reg duration relief_scale if sex_cases == 1, r
		eststo C

	reg duration i.probable_cause, r
		eststo D

	reg duration i.probable_cause if sh == 1, r
		eststo E

	reg duration i.probable_cause if sex_cases == 1, r
		eststo F

	estout A B C D E F using "$tables/duration_corr.tex", style(tex) replace ///
		nobaselevels ///
		eqlabels(none) collabels(none) mlabel(none) ///
		label varlabels(relief_scale "Compensation (in \$1000s)" 1.probable_cause "Probable cause" _cons "Constant") ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") starlevels(* .1 ** .05 *** .01) ///
		stats(N r2, labels(`"Observations"' `" \(R^{2}\)"') fmt(%9.0fc 3 3)) ///
		prehead("\begin{tabular}{l*{@E}{c}}" ///
		"\toprule" ///
		"\multicolumn{1}{l}{\texbf{Outcome: Duration}}  & \multicolumn{1}{c}{All} & \multicolumn{1}{c}{SH cases} & \multicolumn{1}{c}{Sex cases} & \multicolumn{1}{c}{All cases} & \multicolumn{1}{c}{SH cases} & \multicolumn{1}{c}{Sex cases}\\") ///
		posthead("\midrule") ///
		prefoot("\\" "\midrule" "\multicolumn{1}{c}{}\\") ///
		postfoot("\bottomrule" "\end{tabular}")
}
