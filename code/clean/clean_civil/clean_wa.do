/*******************************************************************************

Clean Washington cases

*******************************************************************************/

// Append files

import delimited "$raw_data/WA/PFS 20190101 to present.csv", varnames(1) clear
save "$raw_data/WA/wa_raw_cases.dta", replace
import delimited "$raw_data/WA/data_2.csv", varnames(1) clear
save "$raw_data/WA/wa_raw_cases.dta", replace
import delimited "$raw_data/WA/cases with sex basis, sexual harassment issue.csv", varnames(1) clear
merge 1:1 wshrc using "$raw_data/WA/wa_raw_cases.dta"
save "$raw_data/WA/wa_raw_cases.dta", replace


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren wshrc id
ren respondent resp_org
ren datefiled charge_file_date
ren basismergedcolumn basis_raw
ren closuredate charge_res_date
ren findingsbyname outcome


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "WA"

// Duration
replace charge_file_date = substr(charge_file_date, 1, 10)
gen charge_file_date2 = date(charge_file_date, "YMD")
format charge_file_date2 %td
drop charge_file_date
replace charge_res_date = substr(charge_res_date, 1, 10)
gen charge_res_date2 = date(charge_res_date, "YMD")
format charge_res_date2 %td
drop charge_res_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Multi-category
split basis_raw, parse(,)
g multi_cat = 0 if basis_raw2 == ""
replace multi_cat = 1 if basis_raw2 != ""
replace multi_cat = . if basis_raw1 == "" //missing basis

// Basis
g basis = "Sex" 				if basis_raw1 == "Sex"
replace basis = "Sex"         if basis_raw1 == "Sexual Orientation/Gender Identity"
replace basis = "Race"		    if basis_raw1 == "Race"
replace basis = "Nationality"   if basis_raw1 == "National Origin"
replace basis = "Disability"    if basis_raw1 == "Disability"
replace basis = "Age" 		    if basis_raw1 == "Age"
replace basis = "Retaliation"   if strpos(basis_raw1, "Retaliation") > 0
replace basis = "Other" 		if inlist(basis_raw1, "Familial Status", "Marital Status", "Veteran/Military Status", "")
replace basis = "Sex" if _merge == 3
drop basis_raw?

// Jurisdiction
g juris = "Unspecified"

// SH
g sh = 0
replace sh = 1 if _merge == 3
drop _merge

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"

// Relief
g relief = max(settlementamountaladdin, settlementamountspreadsheet)
drop settlement*
replace relief = . if relief == 0
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if cause != ""
replace win = 1 if outcome == "DF"
replace win = 1 if outcome == "Successful Conciliation"
replace win = 1 if outcome == "Conciliation Failure"
replace win = 0 if outcome == "No Reasonable Cause"
drop cause

// Settle
g settle = 0 
replace settle = 1 if outcome == "Pre-finding Settlement"
replace settle = 1 if outcome == "Withdrawal with Benefits"
replace settle = . if outcome == "Other"

// Administrative closure
g admin_close = 0
replace admin_close = 1 if outcome == "AC: General"
replace admin_close = 1 if outcome == "Duplicate"
replace admin_close = 1 if outcome == "Failure to Cooperate"
replace admin_close = 1 if outcome == "Failure to Locate"
replace admin_close = 1 if outcome == "Non-jurisdictional"
replace admin_close = 1 if outcome == "RP Bankruptcy"
replace admin_close = 1 if outcome == "Transfer to EEOC (Closed at Commission)"
replace admin_close = 1 if outcome == "Transfer to EEOC at Intake"
replace admin_close = 1 if outcome == "Transfer to Tacoma"
replace admin_close = . if outcome == "Other"

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "Withdrawal"
replace withdraw = . if outcome == "Other"

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = . if outcome == "Other"

// Court
g court = 0
replace court = 1 if outcome == "CP Filed Private Lawsuit"
replace court = 1 if outcome == "Right to Sue"
replace court = . if outcome == "Other"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_wa.dta", replace


