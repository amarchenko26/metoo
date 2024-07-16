/*******************************************************************************

This file merges all city criminal data into a .dta.

Inputs: 
	- cleaned city criminal data
	
Outputs: 
	- clean_criminal_cases.dta 
	
Already merged: 
	- Austin
	- Chicago
	- Kansas City
	- Los Angeles
	- Louisville
	- New York City
	- Seattle
	- Tucson


*******************************************************************************/


/*******************************************************************************
Pull cleaned Austin data
*******************************************************************************/

use "$clean_data/clean_austin.dta", clear

/*******************************************************************************
Append to Chicago
*******************************************************************************/

append using "$clean_data/clean_chicago.dta"

/*******************************************************************************
Append to Kansas City
*******************************************************************************/

append using "$clean_data/clean_kansas_city.dta"

/*******************************************************************************
Append to Los Angeles
*******************************************************************************/

append using "$clean_data/clean_la.dta"

/*******************************************************************************
Append to Louisville
*******************************************************************************/

append using "$clean_data/clean_louisville.dta"

/*******************************************************************************
Append to New York City
*******************************************************************************/

append using "$clean_data/clean_nyc.dta"

/*******************************************************************************
Append to Seattle
*******************************************************************************/

append using "$clean_data/clean_seattle.dta"

/*******************************************************************************
Append to Tucson
*******************************************************************************/

append using "$clean_data/clean_tucson.dta"


/*******************************************************************************
Clean joint data
*******************************************************************************/

// Make common filing date
g common_file_date = cond(missing(report_date), incident_date, report_date)
format common_file_date %td

// Clean duration variable 
replace duration = 0 if duration < 0 

// Gen ym var
drop year
g ym = ym(year(common_file_date), month(common_file_date)) 
format ym %tm 
la var ym "Year-month var of report date"

g report_year = year(common_file_date)
g clear_year = year(clear_date)

keep if report_year >= 2010 & report_year <= 2024


/*******************************************************************************
Gen post and treat 
*******************************************************************************/

// Gen post and treat
g post = (common_file_date > date("$metoo", "DMY"))
g treat = post*sex_cases // treat=1 if post=1 and sex_cases=1

// Gen index var for count
g y = 1

// Gen cases_filed for regression
bys sex_cases report_year: gen filed_per_year = _N
bys report_year: gen total_cases_per_year = _N
replace filed_per_year = filed_per_year / total_cases_per_year

// Gen categorical version of common vars
encode city, g(city_cat)


/*******************************************************************************
Create time to treat - 0 is the pre-period before MeToo
*******************************************************************************/

// Create quarters
create_time_to_treat, period(3) period_label("Quarters relative to MeToo")

// Create time_to_treat for half-years
create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

// Create time_to_treat for years
create_time_to_treat, period(12) period_label("Years relative to MeToo")


/*******************************************************************************
Label all variables
*******************************************************************************/

//Common
la var id "City-given ID"
la var city "City"
la var crime "Name of reported crime"
la var crime_code "City-given code for reported crime"
la var crime_category "Category of crime (raw)"
la var crime_type "Excluded crime, Non-sex crime, Sexual assault, Sexual harassment"
la var clearance "Whether case was cleared"
la var clear_status "Method case was cleared"
la var arrest "Arrest issued"
la var incident_date "Date incident occurred"
la var report_date "Date incident reported"
la var clear_date "Date incident cleared"
la var sh "Sexual harassment"
la var sex_cases "Sex-related cases"
la var post "Filed after MeToo"
la var treat "Post = 1 and case is sex-related"
la var duration "Duration (days)"
la var filed "Number of sex-related cases filed by S Post"
la var report_year "Year of reporting"
la var clear_year "Year of clearance"

// Indent all variable labels for tables
foreach v of varlist * {
	label variable `v' `"\hspace{0.1cm} `: variable label `v''"'
	}
	
/*******************************************************************************
Export all cases
*******************************************************************************/

save "$clean_data/clean_criminal_cases.dta", replace
