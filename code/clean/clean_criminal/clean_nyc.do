/*******************************************************************************

Clean New York City cases

*******************************************************************************/

import delimited "$raw_data/Criminal/New York City.csv", clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Keeping only relevant vars
keep cmplnt_num cmplnt_fr_dt rpt_dt ky_cd ofns_desc pd_desc vic_sex

// Rename vars
ren cmplnt_num id
ren cmplnt_fr_dt incident_date
ren rpt_dt report_date
ren ky_cd crime_code
ren ofns_desc crime_category
ren pd_desc crime

// Keeping only cases in years 2010+
gen year = substr(report_date, -4, 4)
destring year, replace
keep if year > 2009


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "New York City"

// Duration
gen incident_date2 = date(incident_date, "MD20Y")
format incident_date2 %td
drop incident_date
gen report_date2 = date(report_date, "MD20Y")
format report_date2 %td
drop report_date
rename *2 *

// Crime type
tostring crime_code, replace
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime_category, "RAPE", "SEX CRIMES", "FELONY SEX CRIMES")
replace crime_type = "Sexual assault"		 if inlist(crime, "RAPE 1", "SEX CRIMES", "SEXUAL ABUSE", "SEXUAL ABUSE 3,2")

replace crime_type = "Sexual harassment"	 if crime_category == "LEWDNESS,PUBLIC"
replace crime_type = "Sexual harassment"	 if inlist(crime, "EXPOSURE OF A PERSON", "LEWDNESS,PUBLIC", "UNLAWFUL DISCLOSURE OF AN INTIMATE IMAGE")

replace crime_type = "Excluded crime"		 if crime_category == "SEX CRIMES" & (strpos(crime, "INCEST") > 0 | crime == "CHILD, ENDANGERING WELFARE" | crime == "COURSE OF SEXUAL CONDUCT AGAIN")
replace crime_type = "Excluded crime"		 if strpos(crime, "PROSTI") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "OBSCEN") > 0
replace crime_type = "Excluded crime"		 if inlist(crime, "BIGAMY", "PROMOTING A SEXUAL PERFORMANCE", "SEX TRAFFICKING", "USE OF A CHILD IN A SEXUAL PER")

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"
replace sh = . if inlist(crime_type, "Sexual assault", "Excluded crime")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"
replace sex_cases = . if crime_type == "Excluded crime"

// Victim
g victim_f = .
replace victim_f = 1 if vic_sex == "F"
replace victim_f = 0 if vic_sex == "M"
drop vic_sex


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_nyc.dta", replace


