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
		ren crime_type crime_category
		ren uor_desc crime
		ren ucr_hierarchy crime_hierarchy
	}
	if `n' >= 2023 {
		ren date_occurred date_occured
		ren offense_classification crime_category
		ren offense_code_name crime
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

// Keeping only relevant vars
keep incident_number date_reported date_occured crime_category crime nibrs_code city year

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

replace crime_type = "Sexual assault"        if inlist(crime_category, "4 FORCIBLE RAPE", "5 SODOMY FORCE", "7 FORCIBLE FONDLING")
replace crime_type = "Sexual assault"        if crime_category == "SEX CRIMES"
replace crime_type = "Sexual assault"		 if strpos(crime, "SEXUAL MISCONDUCT") > 0


replace crime_type = "Sexual harassment"     if inlist(crime_category, "54 VOYEURISM")
replace crime_type = "Sexual harassment"     if crime_category == "SEX CRIMES" & strpos(crime, "VOYEURISM") > 0
replace crime_type = "Sexual harassment"     if crime_category == "12 INTIMIDATION" & strpos(crime, "STALKING") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime, "INDECENT EXPOSURE") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime, "STALKING") > 0
replace crime_type = "Sexual harassment"	 if strpos(crime, "W/OUT CONSENT") > 0


replace crime_type = "Excluded crime"        if inlist(crime_category, "36 INCEST", "37 STAT RAPE", "43 PROSTITUTION", "44 PROMOTING PROSTITUTION")
replace crime_type = "Excluded crime"        if strpos(crime, "INCEST") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "SPOUSE") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "MINOR") > 0 & strpos(crime, "MINOR INJURY") == 0
replace crime_type = "Excluded crime"        if strpos(crime, "U/") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "FAILURE TO COMPLY W/SEX OFFENDER") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "DOMESTIC VIOLENCE") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "DATING") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "HUMAN TRAF") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "PROSITUTION") > 0
replace crime_type = "Excluded crime"		 if crime_category == "DISTURBING THE PEACE" & strpos(crime, "MINOR") > 0
replace crime_type = "Excluded crime"		 if crime == "BIGAMY"

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


