/*******************************************************************************

Clean California cases

*******************************************************************************/

import delimited "$raw_data/CA/ca_raw_cases.csv", varnames(3) bindquote(strict) maxquotedrows(1000) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

drop no

foreach var of varlist _all {
	replace `var' = subinstr(subinstr(`var',"`=char(10)'"," ",.),"`=char(13)'"," ",.) //removes line breaks
}

// Rename vars
ren casefiledate charge_file_date
ren closedate charge_res_date
ren closereason outcome


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "CA"

// Relief
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if outcome == "CA"
replace win = 0 if regexm(outcome, "Insufficient Evidence")

// Settle
g settle = 0 
replace settle = 1 if regexm(outcome, "Settle|Complaint Withdrawn by Complainant After Resolution")
replace settle = . if inlist(outcome, "", "Agency Discretion", "Assignment Completed", "Decline to File: Exercise of Discretion", "Determination by Another Agency")

// Dismissal
g dismissed = 0
replace dismissed = 1 regexm(outcome, "Withdrawn") & settle = 0
replace dismissed = 1 regexm(outcome,"Dismiss")
replace dismissed = . if inlist(outcome, "", "Agency Discretion")

// Court
g court = 0
replace court = 1 if regexm(outcome, "Trial|Court|Suit")
replace court = . if inlist(outcome, "", "Agency Discretion")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ca.dta", replace


