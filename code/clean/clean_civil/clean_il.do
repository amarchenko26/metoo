/*******************************************************************************

Clean Illinois cases

*******************************************************************************/

import delimited "$raw_data/IL/il_raw_cases_gender.csv", varnames(2) bindquote(strict) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping random vars
drop v1
drop if charge == ""

// Rename vars
ren charge id
ren cpname comp_name
ren rpname resp_org
ren filedate charge_file_date
ren closedate charge_res_date
ren finding outcome
ren settle relief
ren basis basis_raw
ren genderprobabilitybphra victim_f_probability

// Victim female
destring victim_f_original victim_f_bph_ra, replace force

// Count how often the two methods agree
gen equal = (victim_f_original == victim_f_bph_ra) if victim_f_original !=.

rename victim_f_bph_ra victim_f
drop victim_f_original

/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "IL"

// Duration
gen charge_file_date2 = date(charge_file_date, "MD20Y")
format charge_file_date2 %td
drop charge_file_date
gen charge_res_date2 = date(charge_res_date, "MD20Y")
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Jurisdiction
g juris = "Unspecified"

// Multi-category
g multi_cat = 0

// Basis
g basis = "Sex" 				if strpos(basis_raw, "SEX") > 0
replace basis = "Sex"         if inlist(basis_raw, "BISEXUAL", "GEN/IDENTITY", "HETEROSEXUAL", "HOMOSEXUAL", "PERCEIVED SEX", "TRANSGENDER")
replace basis = "Religion" 	    if basis_raw == "RELIGION"
replace basis = "Race"		    if strpos(basis_raw, "RACE") > 0 | basis_raw == "COLOR"
replace basis = "Nationality"   if inlist(basis_raw, "CITIZENSHIP", "NATL ORIGIN", "IMMIGRATION STS")
replace basis = "Disability"    if inlist(basis_raw, "MENTAL DISABLTY", "PHY DISABILITY")
replace basis = "Age"           if basis_raw == "AGE"
replace basis = "Retaliation"   if basis_raw == "RETALIATION"
replace basis = "Other" 		if inlist(basis_raw, "AIDING/ABETN", "ARREST RECORD", "COERCION", "FAM STATUS") | ///
inlist(basis_raw, "INTERFERENCE", "MARITAL STATUS", "MILITARY DISCHG", "ORDER/PROTEC", "OTHER", "UNFAVORABLE MIL", "")

// SH
g sh = 0
replace sh = 1 if strpos(basis_raw, "HAR") > 0

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
replace relief = subinstr(subinstr(relief, "$", "", .), ",", "", .)
destring relief, replace
replace relief = . if relief == 0
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if inlist(outcome, "SE", "SE/")
replace win = 0 if outcome == "LSE"

// Settle
g settle = 0 
replace settle = 1 if outcome == "AT"
replace settle = 1 if outcome == "AW"
replace settle = . if inlist(outcome, "DEF", "OPT", "STA", "UNK")

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "ACL"
replace admin_close = 1 if outcome == "DUP"
replace admin_close = 1 if outcome == "EXP"
replace admin_close = 1 if outcome == "FTP"
replace admin_close = 1 if outcome == "LOJ"
replace admin_close = 1 if outcome == "LOS"
replace admin_close = . if inlist(outcome, "DEF", "OPT", "STA", "UNK")

// Withdrawn
g withdraw = 0
replace withdraw = 1 if strpos(outcome, "WD") > 0
replace withdraw = . if inlist(outcome, "DEF", "OPT", "STA", "UNK")

// Dismissal
g dismissed = 0
replace dismissed = 1 if outcome == "ADM"
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = . if inlist(outcome, "DEF", "OPT", "STA", "UNK")

// Court
g court = 0
replace court = . if inlist(outcome, "DEF", "OPT", "STA", "UNK")

// Outcome
replace outcome = "Administrative Closure" if outcome == "ACL"
replace outcome = "Administrative Dismissal" if outcome == "ADM"
replace outcome = "Adjusted/Terms of Settlement" if outcome == "AT"
replace outcome = "Adjusted and Withdrawn" if outcome == "AW"
replace outcome = "Default" if outcome == "DEF"
replace outcome = "Duplicate" if outcome == "DUP"
replace outcome = "Expired" if outcome == "EXP"
replace outcome = "Failure to Proceed" if outcome == "FTP"
replace outcome = "Lack of Jurisdiction" if outcome == "LOJ"
replace outcome = "Lack of Service/Letter of Service" if outcome == "LOS"
replace outcome = "Lack of Substantial Evidence" if outcome == "LSE"
replace outcome = "Opt Out" if outcome == "OPT"
replace outcome = "Substantial Evidence" if strpos(outcome, "SE") > 0
replace outcome = "Stay" if outcome == "STA"
replace outcome = "Unknown" if outcome == "UNK"
replace outcome = "Withdrawn" if strpos(outcome, "WD") > 0

la var comp_name "Complainant name"

/*******************************************************************************
Export data
*******************************************************************************/

// Drop variables we don't use 
drop id issue deptfiledcomplaint prosecomplaint rpaddess rpcity rpstate rpzip requestforreview genderbphra

save "$clean_data/clean_il.dta", replace


