/*******************************************************************************

Clean Los Angeles cases

*******************************************************************************/

clear
tempfile temp
save "`temp'", replace emptyok
import delimited "$raw_data/Criminal/Los Angeles 1.csv", clear
append using "`temp'"
save "`temp'", replace
import delimited "$raw_data/Criminal/Los Angeles 2.csv", clear
append using "`temp'"
save "`temp'", replace


/*******************************************************************************
Clean vars
*******************************************************************************/

// Keeping only relevant vars
keep dr_no daterptd dateocc crmcd crmcddesc statusdesc

// Rename vars
ren dr_no id
ren daterptd report_date
ren dateocc incident_date
ren crmcd crime_code
ren crmcddesc crime
ren statusdesc clear_status


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "Los Angeles"

// Duration
gen report_date2 = date(substr(report_date, 1, 10), "MD20Y")
format report_date2 %td
drop report_date
gen incident_date2 = date(substr(incident_date, 1, 10), "MD20Y")
format incident_date2 %td
drop incident_date
rename *2 *

// Crime type
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime, "BATTERY WITH SEXUAL CONTACT", "ORAL COPULATION", "SEXUAL PENETRATION W/FOREIGN OBJECT", "SODOMY/SEXUAL CONTACT B/W PENIS OF ONE PERS TO ANUS OTH")
replace crime_type = "Sexual assault"        if strpos(crime, "RAPE") > 0

replace crime_type = "Sexual harassment"     if inlist(crime, "CHILD ANNOYING (17YRS & UNDER)", "INDECENT EXPOSURE", "LETTERS, LEWD  -  TELEPHONE CALLS, LEWD", "LEWD CONDUCT", "PEEPING TOM", "STALKING")

replace crime_type = "Excluded crime"        if inlist(crime, "BIGAMY", "CHILD PORNOGRAPHY", "LEWD/LASCIVIOUS ACTS WITH CHILD", "PANDERING", "PIMPING")
replace crime_type = "Excluded crime"        if strpos(crime, "INTIMATE PARTNER") > 0
replace crime_type = "Excluded crime"        if strpos(crime, "SEX") > 0 & !inlist(crime, "BATTERY WITH SEXUAL CONTACT", "SEXUAL PENETRATION W/FOREIGN OBJECT", "SODOMY/SEXUAL CONTACT B/W PENIS OF ONE PERS TO ANUS OTH")

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"

// Clearance
g clearance = .
replace clearance = 1 if inlist(clear_status, "Adult Arrest", "Adult Other", "Juv Arrest", "Juv Other")
replace clearance = 0 if clear_status == "Invest Cont"

// Court
g court = .
replace court = 1 if inlist(clear_status, "Adult Arrest", "Juv Arrest")
replace court = 0 if inlist(clear_status, "Adult Other", "Juv Other", "Invest Cont")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_la.dta", replace


