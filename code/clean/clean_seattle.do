/*******************************************************************************

Clean Seattle cases

*******************************************************************************/

import delimited "$raw_data/Criminal/Seattle.csv", clear


/*******************************************************************************
Clean var
*******************************************************************************/

// Keeping only relevant vars
keep offenseid offensestartdatetime reportdatetime offenseparentgroup offense offensecode

// Rename vars
ren offenseid id
ren offenseparentgroup crime_category
ren offense crime
ren offensecode crime_code

// Keeping only cases in years 2010+
gen year = substr(reportdatetime, 7, 4)
destring year, replace
keep if year > 2009 & year != .


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "Seattle"

// Case ID
format id %20.0g
tostring id, replace format("%20.0g") force

// Date
gen incident_date = date(substr(offensestartdatetime, 1, 10), "MD20Y")
format incident_date %td
gen report_date = date(substr(reportdatetime, 1, 10), "MD20Y")
format report_date %td
drop reportdatetime offensestartdatetime

// Crime type
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if crime_category == "SEX OFFENSES"

replace crime_type = "Sexual harassment" 	 if inlist(crime_category, "PEEPING TOM")

replace crime_type = "Excluded crime"		 if inlist(crime_category, "SEX OFFENSES, CONSENSUAL", "PROSTITUTION OFFENSES", "PORNOGRAPHY/OBSCENE MATERIAL", "FAMILY OFFENSES, NONVIOLENT")
replace crime_type = "Excluded crime"		 if crime_category == "HUMAN TRAFFICKING" & crime == "Human Trafficking, Commercial Sex Acts"

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_seattle.dta", replace


