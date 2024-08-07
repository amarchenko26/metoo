/*******************************************************************************

Clean Austin cases

*******************************************************************************/

import delimited "$raw_data/Criminal/Austin.csv", clear


/*******************************************************************************
Clean vars
*******************************************************************************/

// Keeping only relevant vars
keep incidentnumber highestoffensedescription highestoffensecode familyviolence occurreddate reportdate clearancestatus clearancedate

// Rename vars
ren incidentnumber id
ren highestoffensedescription crime
ren highestoffensecode crime_code
ren occurreddate incident_date
ren reportdate report_date
ren clearancestatus clear_status
ren clearancedate clear_date

// Keeping only cases in years 2010+
gen year = substr(report_date, -4, 4)
destring year, replace
keep if year > 2009


/*******************************************************************************
Clean outcomes
*******************************************************************************/

g city = "Austin"

// Case ID
format id %20.0g
tostring id, replace format("%20.0g") force

// Duration
gen report_date2 = date(report_date, "MD20Y")
format report_date2 %td
drop report_date
gen clear_date2 = date(clear_date, "MD20Y")
format clear_date2 %td
drop clear_date
gen incident_date2 = date(incident_date, "MD20Y")
format incident_date2 %td
drop incident_date
rename *2 *
g duration = clear_date - report_date

// Crime type
tostring crime_code, replace
g crime_type = "Non-sex crime"

replace crime_type = "Sexual assault"        if inlist(crime, "AGG RAPE", "EXPIRED-ATT RAPE", "RAPE")
replace crime_type = "Sexual assault"        if inlist(crime, "AGG FORCED SODOMY", "AGG SODOMY", "EXPIRED-ATT FORCED SODOMY", "FORCED SODOMY")
replace crime_type = "Sexual assault"        if inlist(crime, "AGG SEXUAL ASSAULT W OBJECT", "ASSAULT  CONTACT-SEXUAL NATURE", "BURG OF RES - SEXUAL NATURE", "EXPIRED-ATT AGG SEXUAL ASSAULT", "EXPIRED-ATT SEXUAL ASSAULT", "SEXUAL ASSAULT W/ OBJECT", "IMPROPER CONTACT-SEX ASLT VICT")

replace crime_type = "Sexual harassment" 	 if inlist(crime, "INDECENT EXPOSURE", "STALKING", "DOC WINDOW PEEPING - HOTEL", "PUBLIC LEWDNESS", "DOC EXPOSURE")
replace crime_type = "Sexual harassment"	 if inlist(crime, "DISCLOSE/PROMO INTIMATE VISUAL", "SEXTING/TRANSMIT SEXUAL PHOTOS", "SEXUAL COERCION")

replace crime_type = "Excluded crime"		 if familyviolence == "Y"
replace crime_type = "Excluded crime"		 if inlist(crime, "AGG FORCED SODOMY OF CHILD", "AGG RAPE OF A CHILD", "AGG SEXUAL ASSAULT CHILD/OBJEC", "AGG SEXUAL ASSAULT CHILD/OBJECT-SUPER", "CHILD GROOMING")
replace crime_type = "Excluded crime"		 if inlist(crime, "CONT SEX ABUSE OF CHILD", "EXPIRED-ATT RAPE OF A CHILD", "EXPIRED-ATT SEXUAL ASULT CHILD", "EXPIRED-ATTAGGFORCESODOMYCHILD", "EXPIRED-SOLICITATION OF CHILD")
replace crime_type = "Excluded crime"		 if inlist(crime, "EXPIREDATT AGG SEX ASSLT CHILD", "FORCED SODOMY OF CHILD", "INDECENCY WITH A CHILD/CONTACT", "INDECENCY WITH CHILD/EXPOSURE", "POSS/PROMO CHILD PORNOGRAPHY")
replace crime_type = "Excluded crime" 		 if inlist(crime, "RAPE OF A CHILD", "SEXUAL ASSAULT OF CHILD/OBJECT", "SEXUAL PERFORMANCE BY CHILD", "STATUTORY RAPE OF CHILD", "SALE OR PURCHASE OF CHILD", "TRAFFICKING OF PERSONS FOR SEX")
replace crime_type = "Excluded crime"		 if strpos(crime, "FAM/DAT") > 0 | strpos(crime, "FAMILY") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "HARASSMENT") > 0
replace crime_type = "Excluded crime"		 if strpos(crime, "PROSTITUTION") > 0
replace crime_type = "Excluded crime"		 if inlist(crime,"FAILURE TO REG AS SEX OFFENDER", "BESTIALITY", "DATING DISTURBANCE", "DOMESTIC VIOLENCE/ALARM", "INCEST-PROHIBITED SEX CONDUCT")
drop familyviolence

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"
replace sh = . if inlist(crime_type, "Sexual assault", "Excluded crime")

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"
replace sex_cases = . if crime_type == "Excluded crime"

// Clearance
g clearance = .
replace clearance = 1 if inlist(clear_status, "C", "O")
replace clearance = 0 if clear_status == "N"

// Arrest
g arrest = .
replace arrest = 1 if clear_status == "C"
replace arrest = 0 if inlist(clear_status, "O", "N")


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_austin.dta", replace


