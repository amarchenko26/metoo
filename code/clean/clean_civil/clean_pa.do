/*******************************************************************************

Clean Pennsylvania cases

*******************************************************************************/

import delimited "$raw_data/PA/pa_raw_cases_severity.csv", varnames(1) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping vars
drop ind

// Rename vars
ren case_id id
ren file_date charge_file_date
ren res_date charge_res_date
ren jurisdiction juris


/*******************************************************************************
Clean outcomes
*******************************************************************************/
 
g state = "PA"

// Duration
gen charge_file_date2 = date(charge_file_date, "DMY", 2024)
format charge_file_date2 %td
drop charge_file_date
gen charge_res_date2 = date(charge_res_date, "DMY", 2024)
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Public Accommodation" if juris == "Public Accomodation"

// Basis
replace basis = strproper(basis)
replace basis = "Sex" if basis == "Lgbtq"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g missing_relief = (relief == .)

// Court
replace court = 1


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_pa.dta", replace


