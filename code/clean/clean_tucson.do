/*******************************************************************************

Clean Tucson cases

*******************************************************************************/

clear
tempfile temp
save "`temp'", replace emptyok

forval n = 2010/2023 {
	import delimited "$raw_data/Criminal/Tucson `n'.csv", clear
	if inlist(`n', 2013, 2017) {
		continue
	}
	drop objectid primarykey
	g year = `n'
	if !inlist(`n', 2010, 2012, 2022) {
		format inci_id %20.0g
		tostring inci_id, replace
	}
	if `n' < 2013 {
		drop if offense == "CONVERTED                "
		replace offense = strtrim(offense)
	}
	if `n' == 2018 {
		replace hour_fnd = "1800" if hour_fnd == "18PM"
	}
	if `n' == 2015 {
		replace time_occu = subinstr(time_occu, "-", "0", .)
		destring time_occu, replace
		replace hour_occu = subinstr(hour_occu, "-", "0", .)
	}
	destring offense, replace
	destring hour_rept, replace
	destring hour_occu, replace
	destring hour_fnd, replace
	append using "`temp'"
	save "`temp'", replace
}

/*******************************************************************************
Clean vars
*******************************************************************************/

// Standardizing vars across years
replace address_public = addrress_public if address_public == ""
drop addrress_public
g lon = .
replace lon = v43 if v43 != .
replace lon = v44 if v44 != .
drop v43 v44
replace emdivision = strtrim(emdivision)
replace divsect = neighborhd if divsect == ""
drop neighborhd

// Keeping only relevant vars
drop if statutdesc == "" & reportedas == ""
replace statutdesc = reportedas if statutdesc == ""
drop reportedas
keep inci_id date_rept date_occu city offense statutdesc crimetype year

// Rename vars
ren inci_id id
ren date_rept report_date
ren date_occu incident_date
ren offense crime_code
ren statutdesc crime
ren crimetype crime_category

// Keeping only cases in Tucson
replace city = strtrim(city)
keep if (strpos(city, "SON") > 0 | strpos(city, "son") > 0) & !inlist(city, "BENSON", "Benson", "HIXSON")
replace city = "Tucson"


/*******************************************************************************
Clean outcomes
*******************************************************************************/

// Duration
gen report_date2 = date(substr(report_date,1,10), "20YMD")
format report_date2 %td
drop report_date
gen incident_date2 = date(substr(incident_date,1,10), "20YMD")
format incident_date2 %td
drop incident_date
rename *2 *

// Crime type
tostring crime_code, replace
g crime_type = "Excluded crime"

replace crime_type = "Non-sex crime"		 if inlist(crime_category, "Agg. Assault", "Arson", "Assault", "Burglary", "Criminal Damage", "DUI", "Disorderly Conduct", "Drug Offense", "Embezzlement")
replace crime_type = "Non-sex crime"		 if inlist(crime_category, "Forgery & Counterfeiting", "Fraud", "Gambling", "Homicide", "Larceny", "Liquor Laws", "MV Theft", "Offense Against Family/Children", "Other Felony/Misdemeanor")
replace crime_type = "Non-sex crime"		 if inlist(crime_category, "Robbery", "Stolen Property", "Substance Use Deflection", "Weapons Violation")

replace crime_type = "Sexual assault"        if crime_category == "Sex Assault"

replace crime_type = "Sexual harassment"	 if crime_category == "Sex Offense"
replace crime_type = "Sexual harassment"	 if inlist(crime, "OTHER OFFENSES/STALKING", "Other Offenses - Stalking")

replace crime_type = "Excluded crime"        if strpos(crime, "DOMESTIC VIOLENCE") > 0 | strpos(crime, "DV") > 0 | inlist(crime, "OTHER OFFENSES/DATING VIOLENCE", "Other Offenses - Dating Violence")
replace crime_type = "Excluded crime"        if crime_category == "Sex Offense" & (strpos(crime, "MOLESTING") > 0 | strpos(crime, "OTHER") > 0 | strpos(crime, "Molesting") > 0 | strpos(crime, "Other") > 0)

// SH
g sh = 0
replace sh = 1 if crime_type == "Sexual harassment"

// Sex
g sex_cases = 0 
replace sex_cases = 1 if crime_type == "Sexual harassment" | crime_type == "Sexual assault"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_tucson.dta", replace


