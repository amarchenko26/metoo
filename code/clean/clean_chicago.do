/*******************************************************************************

Clean Chicago cases

*******************************************************************************/

import delimited "$raw_data/Criminal/Chicago.csv", clear


/*******************************************************************************
Clean var
*******************************************************************************/

// Keeping only relevant vars
keep casenumber date iucr primarytype description arrest domestic year

// Rename vars
ren casenumber id
ren iucr crime_code
ren primarytype crime_category
ren description crime
ren arrest clear_status

// Keeping only cases in years 2010+
keep if year > 2009 & year != .

// Dropping duplicate cases
duplicates drop id, force


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "Chicago"

// Date
gen incident_date = date(substr(date, 1, 10), "MD20Y")
format incident_date %td
drop date

// Crime type
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime_category, "CRIM SEXUAL ASSAULT", "CRIMINAL SEXUAL ASSAULT", "SEX OFFENSE")

replace crime_type = "Sexual harassment" 	 if inlist(crime_category, "PUBLIC INDECENCY", "STALKING", "OBSCENITY")
replace crime_type = "Sexual harassment"	 if crime_category == "OTHER OFFENSE" & crime == "OBSCENE TELEPHONE CALLS"
replace crime_type = "Sexual harassment"	 if crime_category == "SEX OFFENSE" & strpos(crime, "DISSEMINATION") > 0
replace crime_type = "Sexual harassment"	 if crime_category == "SEX OFFENSE" & crime == "PUBLIC INDECENCY"
replace crime_type = "Sexual harassment"	 if crime_category == "PUBLIC PEACE VIOLATION" & crime == "PEEPING TOM"

replace crime_type = "Excluded crime"		 if inlist(crime_category, "OFFENSE INVOLVING CHILDREN", "PROSTITUTION")
replace crime_type = "Excluded crime"		 if crime_category == "OTHER OFFENSE" & strpos(crime, "HARASSMENT") > 0
replace crime_type = "Excluded crime"		 if crime_category == "OTHER OFFENSE" & strpos(crime, "SEX OFFENDER") > 0
replace crime_type = "Excluded crime"		 if crime_category == "SEX OFFENSE" & inlist(crime, "ADULTRY", "BIGAMY", "CRIMINAL TRANSMISSION OF HIV", "FORNICATION")
replace crime_type = "Excluded crime"		 if crime_category == "SEX OFFENSE" & strpos(crime, "SOLICITATION") > 0
replace crime_type = "Excluded crime"		 if crime_category == "SEX OFFENSE" & strpos(crime, "FAMILY") > 0
replace crime_type = "Excluded crime"		 if domestic == "true"
replace crime_type = "Excluded crime"		 if crime_category == "HUMAN TRAFFICKING" & crime == "COMMERCIAL SEX ACTS"
drop domestic

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"

// Arrest
g arrest = .
replace arrest = 1 if clear_status == "true"
replace arrest = 0 if clear_status == "false"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_chicago.dta", replace


