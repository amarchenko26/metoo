/*******************************************************************************

Clean Chicago cases

*******************************************************************************/

import delimited "$raw_data/Criminal/Chicago.csv", clear


/*******************************************************************************
Clean var
*******************************************************************************/

// Rename vars
ren iucr crime_code
ren primarytype crime

// Keeping only cases in years 2010+
keep if year > 2009 & year != .


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "Chicago"

// Date
gen incident_date = date(substr(date, 1, 10), "MD20Y")
format incident_date %td

// Crime type
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime, "CRIM SEXUAL ASSAULT", "CRIMINAL SEXUAL ASSAULT", "SEX OFFENSE")

replace crime_type = "Sexual harassment" 	 if inlist(crime, "PUBLIC INDECENCY", "STALKING", "OBSCENITY")
replace crime_type = "Sexual harassment"	 if crime == "OTHER OFFENSE" & description == "OBSCENE TELEPHONE CALLS"
replace crime_type = "Sexual harassment"	 if crime == "SEX OFFENSE" & strpos(description, "DISSEMINATION") > 0
replace crime_type = "Sexual harassment"	 if crime == "SEX OFFENSE" & description == "PUBLIC INDECENCY"
replace crime_type = "Sexual harassment"	 if crime == "PUBLIC PEACE VIOLATION" & description == "PEEPING TOM"

replace crime_type = "Excluded crime"		 if inlist(crime, "DOMESTIC VIOLENCE", "OFFENSE INVOLVING CHILDREN", "PROSTITUTION")
replace crime_type = "Excluded crime"		 if crime == "OTHER OFFENSE" & strpos(description, "HARASSMENT") > 0
replace crime_type = "Excluded crime"		 if crime == "OTHER OFFENSE" & strpos(description, "SEX OFFENDER") > 0
replace crime_type = "Excluded crime"		 if crime == "SEX OFFENSE" & inlist(description, "ADULTRY", "BIGAMY", "CRIMINAL TRANSMISSION OF HIV", "FORNICATION")
replace crime_type = "Excluded crime"		 if crime == "SEX OFFENSE" & strpos(description, "SOLICITATION") > 0
replace crime_type = "Excluded crime"		 if crime == "SEX OFFENSE" & strpos(description, "FAMILY") > 0
replace crime_type = "Excluded crime"		 if domestic == "true"
replace crime_type = "Excluded crime"		 if crime == "HUMAN TRAFFICKING" & description == "COMMERCIAL SEX ACTS"

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"

// Clearance
g clearance = .
replace clearance = 1 if arrest == "true"
replace clearance = 0 if arrest == "false"

// Court
g court = .
replace court = 1 if arrest == "true"
replace court = 0 if arrest == "false"

/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_chicago.dta", replace


