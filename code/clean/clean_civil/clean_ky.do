/*******************************************************************************

Clean Kentucky cases

*******************************************************************************/

import excel "$raw_data/KY/Copy of Employment Case Information M Jiang 09112024.xlsx", firstrow case(lower) clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Rename vars
ren kchrcaseno id
ren respondent resp_org
ren basis basis_raw
ren datefiled charge_file_date
ren howresolvedbycommissioners outcome
ren dateofresolution charge_res_date
ren compensation relief
drop i f
drop if resp_org == "VOID" | resp_org == "" | basis_raw == ""


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g state = "KY"

// Duration
replace charge_file_date = strlower(charge_file_date)
replace charge_file_date = subinstr(charge_file_date, "filed ", "", .)
replace charge_file_date = subinstr(charge_file_date, "file date ", "", .)
replace charge_file_date = subinstr(charge_file_date, "rcd by intake ", "", .)
replace charge_file_date = substr(charge_file_date, 1, 10) if strlen(charge_file_date) > 10 & regexm(charge_file_date, "^([0-9]+)/([0-9]+)/([0-9][0-9][0-9][0-9])")
replace charge_file_date = substr(charge_file_date, 1, 8) if strlen(charge_file_date) > 10 & regexm(charge_file_date, "^([0-9]+)/([0-9]+)/([0-9][0-9])")
replace charge_file_date = subinstr(charge_file_date, ",", "", .)
replace charge_file_date = subinstr(charge_file_date, ";", "", .)
replace charge_file_date = strtrim(charge_file_date)
replace charge_file_date = "4/5/2011" if charge_file_date == "4//5/2011"
replace charge_file_date = "7/23/2012" if charge_file_date == "723/2012"
replace charge_file_date = "10/18/2012" if charge_file_date == "10/18/201"
replace charge_file_date = "12/22/2020" if charge_file_date == "12/22/20"
replace charge_file_date = substr(charge_file_date, 1, strrpos(charge_file_date, "/"))+ "20" + substr(charge_file_date, -2, 2) if !regexm(charge_file_date, "20")

replace charge_res_date = "" if regexm(charge_res_date, "Case listed in October 2013 Commission Book as")
replace charge_res_date = strltrim(charge_res_date)
replace charge_res_date = strlower(charge_res_date)
replace charge_res_date = subinstr(charge_res_date, "recon ", "", .)
replace charge_res_date = subinstr(charge_res_date, "final order issued ", "", .)
replace charge_res_date = subinstr(charge_res_date, "appeal settled 8/2017", "", .)
replace charge_res_date = substr(charge_res_date, 1, 10) if strlen(charge_res_date) > 10 & regexm(charge_res_date, "^([0-9]+)/([0-9]+)/([0-9][0-9][0-9][0-9])")
replace charge_res_date = substr(charge_res_date, 1, 8) if strlen(charge_res_date) > 10 & regexm(charge_res_date, "^([0-9]+)/([0-9]+)/([0-9][0-9])")
replace charge_res_date = subinstr(charge_res_date, "-", "", .)
replace charge_res_date = subinstr(charge_res_date, ",", "", .)
replace charge_res_date = subinstr(charge_res_date, ";", "", .)
replace charge_res_date = strtrim(charge_res_date)
replace charge_res_date = substr(charge_res_date, 1, strlen(charge_res_date) - 1) if substr(charge_res_date, -1, 1) ==  "/"
replace charge_res_date = "11/16/17" if charge_res_date == "11/1617"
replace charge_res_date = "9/15/2016" if charge_res_date == "915/2016"
replace charge_res_date = substr(charge_res_date, 1, strrpos(charge_res_date, "/"))+ "20" + substr(charge_res_date, -2, 2) if !regexm(charge_res_date, "20")

gen charge_res_date2 = date(charge_res_date, "MD20Y")
format charge_res_date2 %td
drop charge_res_date
gen charge_file_date2 = date(charge_file_date, "MD20Y")
format charge_file_date2 %td
drop charge_file_date
rename *2 *
g duration = charge_res_date - charge_file_date

// Jurisdiction
g juris = "Employment"

// Multi-category
g multi_cat = 1 if strpos(basis_raw, ",") > 0 | strpos(basis_raw, "and") > 0 | strpos(basis_raw, ".") > 0
replace multi_cat = 0 if multi_cat != 1

// Basis
replace basis_raw = strtrim(basis_raw)
g basis = substr(basis_raw, 1, 3)
replace basis = "Race"			if inlist(basis, "Col", "Rac")
replace basis = "Other"			if inlist(basis, "Dif", "Har", "Oth", "Smo")
replace basis = "Disability"	if inlist(basis, "Dis", "dis")
replace basis = "Nationality"	if basis == "Nat"
replace basis = "Retaliation"	if inlist(basis, "Rea", "Ret")
replace basis = "Religion"		if basis == "Rel"

// SH
replace issue = strtrim(issue)
g sh = 0
replace sh = 1 if strpos(issue, "Sexual") > 0

// Sex
g sex_cases = 0 
replace sex_cases = 1 if basis == "Sex"
replace sex_cases = 1 if basis == "Retaliation" & strpos(basis_raw, "Sex") > 0 & sh == 0

// Relief
split relief, parse(;)
split relief1
drop relief?
replace relief11 = subinstr(relief11, "$", "", .)
replace relief = subinstr(relief11, ",", "", .)
drop relief1*
destring relief, replace force
g missing_relief = (relief == .)

// Probable cause
g win = .
replace win = 1 if strpos(outcome, "PC Determination") > 0
replace win = 1 if strpos(outcome, "Concil") > 0
replace win = 0 if strpos(outcome, "NPC") > 0

// Settle
g settle = 0 
replace settle = 1 if strpos(outcome, "ett") > 0 & strpos(outcome, "OUT") == 0 & strpos(outcome, "w/o") == 0 & strpos(outcome, "out") == 0 & strpos(outcome, "W/O") == 0 & win == .
replace settle = . if inlist(outcome, "", "Other", "No Case Resolution Located", "Unable to locate case closure", "Void - case already filed  8761-E")

// Administrative closure
g admin_close = 0
replace admin_close = 1 if strpos(outcome, "Admin") > 0 & win == .
replace admin_close = 1 if strpos(outcome, "Error") > 0
replace admin_close = 1 if strpos(outcome, "Juris") > 0
replace admin_close = . if inlist(outcome, "", "Other", "No Case Resolution Located", "Unable to locate case closure", "Void - case already filed  8761-E")

// Withdrawn
g withdraw = 0
replace withdraw = 1 if outcome == "2"
replace withdraw = 1 if strpos(outcome, "Withdra") > 0 & settle == 0 & win == .
replace withdraw = . if inlist(outcome, "", "Other", "No Case Resolution Located", "Unable to locate case closure", "Void - case already filed  8761-E")

// Dismissal
g dismissed = 0
replace dismissed = 1 if admin_close == 1 | withdraw == 1
replace dismissed = 1 if outcome == "DWOP"
replace dismissed = 1 if strpos(outcome, "Di") > 0 & win == .
replace dismissed = . if inlist(outcome, "", "Other", "No Case Resolution Located", "Unable to locate case closure", "Void - case already filed  8761-E")

// Court
g court = 0
replace court = 1 if strpos(outcome, "Circuit") > 0
replace court = . if inlist(outcome, "", "Other", "No Case Resolution Located", "Unable to locate case closure", "Void - case already filed  8761-E")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ky.dta", replace

