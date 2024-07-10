/*******************************************************************************

Clean Louisville cases

*******************************************************************************/
clear
tempfile temp
save "`temp'", replace emptyok

forval n = 2010/2024 {
	import delimited "$raw_data/Criminal/Louisville `n'.csv", clear
	g year = `n'
	if `n' == 2010 | `n' == 2023 {
		replace zip_code = substr(zip_code, 1, 5)
	}
	if `n' == 2021 | `n' == 2022 {
		replace badge_id = strtrim(badge_id)
		replace badge_id = subinstr(badge_id, "X", "", .)
		destring badge_id, replace
	}
	if `n' < 2023 {
		ren crime_type crime
		ren uor_desc crime_desc
		ren ucr_hierarchy crime_hierarchy
	}
	if `n' >= 2023 {
		ren date_occurred date_occured
		ren offense_classification crime
		ren offense_code_name crime_desc
		ren nibrs_group crime_hierarchy
		ren was_offense_completed att_comp
		ren location_category premise_type
		replace premise_type = strtrim(premise_type)
	}
	destring zip_code, replace force
	append using "`temp'"
	save "`temp'", replace
}


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping vars
drop id
drop objectid

// Rename vars
ren incident_number id
ren nibrs_code crime_code

// Keeping only cases in Louisville
keep if substr(city, 1, 2) == "LO" & !inlist(city, "LONDON", "LOS ANGELES")
replace city = "Louisville"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Duration
split date_occured
split date_reported

gen incident_date = date(date_occured1, "20YMD") if year >= 2019
replace incident_date = date(date_occured1, "MD20Y") if year < 2019
format incident_date %td
gen report_date = date(date_reported1, "20YMD") if year >= 2019
replace report_date = date(date_reported1, "MD20Y") if year < 2019
format report_date %td
drop *1 *2 *3

// Crime type
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime, "4 FORCIBLE RAPE", "5 SODOMY FORCE", "7 FORCIBLE FONDLING")
replace crime_type = "Sexual assault"        if crime == "SEX CRIMES"
replace crime_type = "Sexual assault"		 if strpos(crime_desc, "SEXUAL MISCONDUCT") > 0


replace crime_type = "Sexual harassment"     if inlist(crime, "54 VOYEURISM")
replace crime_type = "Sexual harassment"     if crime == "SEX CRIMES" & strpos(crime_desc, "VOYEURISM") > 0
replace crime_type = "Sexual harassment"     if crime == "12 INTIMIDATION" & strpos(crime_desc, "STALKING") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime_desc, "INDECENT EXPOSURE") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime_desc, "STALKING") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime_desc, "W/OUT CONSENT") > 0


replace crime_type = "Excluded crime"        if inlist(crime, "36 INCEST", "37 STAT RAPE", "43 PROSTITUTION", "44 PROMOTING PROSTITUTION")
replace crime_type = "Excluded crime"        if strpos(crime_desc, "INCEST") > 0
replace crime_type = "Excluded crime"        if strpos(crime_desc, "SPOUSE") > 0
replace crime_type = "Excluded crime"        if strpos(crime_desc, "MINOR") > 0 & strpos(crime_desc, "MINOR INJURY") == 0
replace crime_type = "Excluded crime"        if strpos(crime_desc, "U/") > 0
replace crime_type = "Excluded crime"		 if strpos(crime_desc, "FAILURE TO COMPLY W/SEX OFFENDER") > 0
replace crime_type = "Excluded crime"		 if strpos(crime_desc, "DOMESTIC VIOLENCE") > 0
replace crime_type = "Excluded crime"		 if strpos(crime_desc, "DATING") > 0
replace crime_type = "Excluded crime"		 if strpos(crime_desc, "HUMAN TRAF") > 0
replace crime_type = "Excluded crime"		 if strpos(crime_desc, "PROSITUTION") > 0
replace crime_type = "Excluded crime"		 if crime == "DISTURBING THE PEACE" & strpos(crime_desc, "MINOR") > 0
replace crime_type = "Excluded crime"		 if crime_desc == "BIGAMY"

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_louisville.dta", replace


