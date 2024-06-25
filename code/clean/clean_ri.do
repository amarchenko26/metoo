/*******************************************************************************

Clean Rhode Island cases

*******************************************************************************/

import delimited "$raw_data/RI/ri_raw_cases.csv", varnames(1) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren jurisdiction juris
ren case_id id
ren file_date charge_file_date
ren res_date charge_res_date

gsort -charge_res_date
duplicates drop id, force


/*******************************************************************************
Clean outcomes
*******************************************************************************/
 
g state = "RI"

// Case IDs
replace id = "17EPD189" if id == "17€PD189"

// Respondent name
replace resp_org = "Seidi Transportation and Mutaro Seidi, alias" if id == "19EPD022"
replace resp_org = "R.I. Billiard Club, Inc. and Anthony Costanzo, alias " if id == "17ERA320"
replace resp_org = "Wooma, Inc. d/b/a Soban Korean Eatery" if id == "15ESE146"
replace resp_org = "YF RHODE ISLAND, LLC d/b/a YOU FIT HEALTH CLUBS" if id == "16ERA256"
replace resp_org = "The Maxx Fitness Clubzz and Matthew D'Amico, alias" if id == "13ERA184"
replace resp_org = "Bukana's Sport Bar, Inc." if id == "15ESO089"

// Duration
replace charge_file_date = "August 29 2011" if id == "12BAG054"
gen charge_file_date2 = date(charge_file_date, "MD20Y")
format charge_file_date2 %td
drop charge_file_date
gen charge_res_date2 = date(charge_res_date, "YMD")
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Jurisdiction
replace juris = "Employment"

// Basis
replace basis = "Other" if id == "12BAG054"

// SH
g sh = 0
replace sh = 1 if inlist(id, "11ESH080", "12ESH150", "15ESO089")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g missing_relief = (relief == .)

// Probable cause
replace win = 1 if id == "12BAG054"

// Court
replace court = 1


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ri.dta", replace


