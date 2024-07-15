/*******************************************************************************

Clean Kansas City cases

*******************************************************************************/

clear
tempfile temp
save "`temp'", replace emptyok

forval n = 2015/2024 {
	import delimited "$raw_data/Criminal/Kansas City `n'.csv", bindquote(strict) clear
	g year = `n'
	if `n' < 2019 | `n' > 2022 {
		tostring report_no, replace
		tostring offense, replace
		tostring beat, replace
	}
	if `n' >= 2019 {
		destring zipcode, replace force
	}
	append using "`temp'"
	save "`temp'", replace
}

/*******************************************************************************
Clean vars
*******************************************************************************/

// Keeping only relevant vars
keep report_no reported_date from_date offense ibrs description city dvflag year

// Rename vars
ren report_no id
ren reported_date report_date
ren from_date incident_date
ren ibrs crime_code
ren description crime

// Keeping only cases in Kansas City
keep if substr(city, 1, 2) == "KA" | substr(city, 1, 2) == "KK" | substr(city, 1, 2) == "KN"
replace city = "Kansas City"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Duration
gen report_date2 = date(report_date, "MD20Y")
format report_date2 %td
drop report_date
gen incident_date2 = date(incident_date, "MD20Y")
format incident_date2 %td
drop incident_date
rename *2 *

// Crime type
replace dvflag = "Y" if dvflag == "true"
replace dvflag = "N" if dvflag == "false"

replace crime = offense if crime == ""
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if strpos(crime, "Forcible") > 0
replace crime_type = "Sexual assault"        if strpos(crime, "Rape") > 0
replace crime_type = "Sexual assault"        if strpos(crime, "Sexual Abuse") > 0
replace crime_type = "Sexual assault"        if strpos(crime, "Sexual Assault") > 0
replace crime_type = "Sexual assault"        if strpos(crime, "Sodomy") > 0
replace crime_type = "Sexual assault"        if inlist(crime, "RAPE", "Sex Off Fondle - mol")

replace crime_type = "Sexual harassment"	 if strpos(crime, "Misconduct")
replace crime_type = "Sexual harassment"     if inlist(crime, "Harassment / Intimidation - Sex Crimes", "Peeping Tom", "Sex Off Indecent Con", "Sex Off Indecent Exp", "Stalking", "Sex Off Follow/Entic", "Sex Offense -others")

replace crime_type = "Excluded crime"        if dvflag == "Y"
replace crime_type = "Excluded crime"        if strpos(crime, "Prostit") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "Domest") > 0 | strpos(crime, "DV") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "Human Trafficking") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "Pornography") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "Statutory") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "Incest") > 0
replace crime_type = "Excluded crime"        if inlist(crime, "Commercial Sex Acts", "Molestation", "Non Agg Assault Dome", "Unregistered Sex Offender", "agg dv assault")
drop offense dvflag

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_kansas_city.dta", replace


