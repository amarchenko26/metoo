/*******************************************************************************

Clean New York City cases

*******************************************************************************/

import delimited "$raw_data/Criminal/New York City.csv", clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Dropping location vars
drop boro_nm-vic_sex

// Rename vars
ren cmplnt_num id
ren cmplnt_fr_dt incident_date
ren rpt_dt report_date
ren ky_cd crime_code
ren ofns_desc crime

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
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime, "RAPE", "SEX CRIMES", "RAPE 1", "FELONY SEX CRIMES")
replace crime_type = "Sexual assault"		 if inlist(pd_desc, "RAPE", "SEX CRIMES", "SEXUAL ABUSE", "SEXUAL ABUSE 3,2")

replace crime_type = "Sexual harassment"	 if crime == "LEWDNESS,PUBLIC"
replace crime_type = "Sexual harassment"	 if inlist(pd_desc, "EXPOSURE OF A PERSON", "LEWDNESS,PUBLIC", "MATERIAL              OFFENSIV")

replace crime_type = "Excluded crime"		 if crime == "SEX CRIMES" & (strpos(pd_desc, "INCEST") > 0 | pd_desc == "CHILD, ENDANGERING WELFARE" | pd_desc == "COURSE OF SEXUAL CONDUCT AGAIN")
replace crime_type = "Excluded crime"		 if strpos(pd_desc, "PROSTI") > 0
replace crime_type = "Excluded crime"		 if strpos(pd_desc, "OBSCEN") > 0
replace crime_type = "Excluded crime"		 if inlist(pd_desc, "BIGAMY", "PROMOTING A SEXUAL PERFORMANCE", "SEX TRAFFICKING", "USE OF A CHILD IN A SEXUAL PER")

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_nyc.dta", replace


