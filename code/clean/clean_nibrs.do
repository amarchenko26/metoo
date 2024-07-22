/*******************************************************************************

Clean NIBRS cases

*******************************************************************************/

clear
tempfile temp
save "`temp'", replace emptyok

/*******************************************************************************
Define Variables
*******************************************************************************/

loc keep_variables "STATE INCDATE BH041 V1006 V1013 V1014 V20061 V40191 V40321 V60081"

local dates = "INCDATE V60081 V1014"

/*******************************************************************************
Pull data from NIBRS Incident Level Extract Files
*******************************************************************************/

forval n = 2010/2020 {
	use "$raw_data/Criminal/`n' NIBRS data.dta", clear
	if `n' < 2017 {
		if `n' < 2013 {
			// Rename variables to match later years
			rename B3011 BH041
		}
		keep `keep_variables'
		// Replace all values labelled as missing with actual missing indicators
		foreach var of local keep_variables {
			replace `var' = . if ((`var' == -5) | (`var' == -6) | (`var' == -7) | (`var' == -8) | (`var' == -9))
			
		}
		// Convert the dates to stata date format
		foreach var of local dates {
			gen year = floor(`var' / 10000)
			gen month = floor((`var' - year * 10000) / 100)
			gen day = `var' - year * 10000 - month * 100
			gen statadate = mdy(month, day, year)
			replace `var' = statadate
			drop year month day statadate
			format `var' %td
		}
	}
	else {
		keep `keep_variables'
		// Replace all values labelled as missing with actual missing indicators
		foreach var of local keep_variables {
			if ("`var'" != "INCDATE") & ("`var'" != "V60081") & ("`var'" != "V1014"){
				replace `var' = . if ((`var' == -5) | (`var' == -6) | (`var' == -7) | (`var' == -8) | (`var' == -9))
			}
		}
		// Convert the dates to stata date format
		foreach var of local dates {
			gen `var'_stata = date(`var', "DMY")
			format `var'_stata %td
			drop `var'
			ren `var'_stata `var'
		}
	}
	
	
	/*******************************************************************************
	Clean vars
	*******************************************************************************/

	
	// Rename vars
	ren STATE state
	ren INCDATE common_file_date
	ren BH041 year
	ren V1006 incident_indicator
	ren V1013 clear_exception
	ren V1014 exception_date
	ren V20061 temp_crime_code
	ren V40191 temp_victim_sex
	ren V40321 relationship
	ren V60081 arrest_date
	
	/*******************************************************************************
	Clean outcomes
	*******************************************************************************/

	// gen crime_code var
	gen crime_code = temp_crime_code
	tostring crime_code, replace
	drop temp_crime_code

	// gen sex_cases var
	// If any of the crimes are sex-related mark it in sex_cases
	gen sex_cases = 0
	replace sex_cases = 1 if ((crime_code == "111") | (crime_code == "112") | (crime_code == "113") | (crime_code == "114") | (crime_code == "362"))

	// No sh cases in NIBRS data
	gen sh = 0

	// gen crime_type variables
	gen crime_type = "Non-sex crime"

	replace crime_type = "Sexual assault" 	if sex_cases == 1
	replace crime_type = "Excluded crime" 	if inlist(crime_code, "361", "370", "401", "402", "403", "641", "642")
	replace crime_type = "Excluded crime" 	if (crime_code == "131" & inlist(relationship, 1, 2, 18, 20, 21))
	drop relationship


	// gen clearance-related vars
	// gen clearance var
	gen clearance = 0
	replace clearance = 1 if !missing(arrest_date)
	replace clearance = 1 if inlist(clear_exception, 1, 2, 3, 4, 5)
	drop clear_exception

	// gen arrest var
	gen arrest = 0
	replace arrest = 1 if !missing(arrest_date)

	gen clear_date = arrest_date
	replace clear_date = exception_date if !missing(exception_date)
	format clear_date %td

	// gen court var
	gen court = 0
	replace court = 1 if !missing(arrest_date)
	drop arrest_date exception_date


	// gen duration between report date and clear date
	gen duration = (clear_date - common_file_date) if (incident_indicator == 1)
	replace duration = 0 if duration < 0
	drop incident_indicator

	// gen ym var
	drop year
	gen ym = ym(year(common_file_date), month(common_file_date))
	format ym %tm
	la var ym "Year-month var of report date"

	gen report_year = year(common_file_date)
	gen clear_year = year(clear_date)

	// gen victim_f var
	gen victim_f = 1 if temp_victim_sex == 0
	replace victim_f = 0 if temp_victim_sex == 1
	drop temp_victim_sex


	/*******************************************************************************
	Gen post and treat 
	*******************************************************************************/

	// Gen post and treat
	gen overlap = .
	replace overlap = 1 if (common_file_date < date("$metoo", "DMY")) & (clear_date > date("$metoo", "DMY")) & (sex_cases == 1)
	replace overlap = 0 if (common_file_date < date("$metoo", "DMY")) & (clear_date < date("$metoo", "DMY")) & (sex_cases == 1)
	replace overlap = 0 if(common_file_date < date("$metoo", "DMY")) & missing(clear_date) & (sex_cases == 1)


	gen post = (common_file_date > date("$metoo", "DMY"))

	gen treat = post*sex_cases // treat=1 if post=1 and sex_cases=1
	// replace treat = 1 if the case is an overlap case
	replace treat = 1 if overlap == 1

	// Gen index var for count
	gen y = 1

	// 	Gen cases_filed for regression 
	bys sex_cases report_year: gen filed_per_year = _N
	bys report_year: gen total_cases_per_year = _N
	replace filed_per_year = filed_per_year / total_cases_per_year
	
	/*******************************************************************************
	Create time to treat - 0 is the pre-period before MeToo
	*******************************************************************************/

	// Create quarters
	create_time_to_treat, period(3) period_label("Quarters relative to MeToo")

	// Create time_to_treat for half-years
	create_time_to_treat, period(6) period_label("Half-years relative to MeToo")

	// Create time_to_treat for years
	create_time_to_treat, period(12) period_label("Years relative to MeToo")
		
	append using "`temp'"
	save "`temp'", replace
}

/*******************************************************************************
Label all variables
*******************************************************************************/

la var state "Numeric State Code"
la var clear_date "Date incident cleared"
la var crime_code "Agency-given code for reported crime"
la var crime_type "Excluded crime, Non-sex crime, Sexual assault, Sexual harassment"
la var clearance "Whether case was cleared"
la var arrest "Arrest issued"
la var court "Case went to court "
la var victim_f "Whether victim was female"
la var sh "Sexual harassment"
la var sex_cases "Sex-related cases"
la var post "Filed after MeToo"
la var treat "Post = 1 and case is sex-related"
la var overlap "Filed before MeToo and Resolved After"
la var duration "Duration (days)"
la var filed_per_year "Number of sex-related cases filed by S Post"
la var report_year "Year of reporting"
la var clear_year "Year of clearance"

// Indent all variable labels for tables
foreach v of varlist * {
	label variable `v' `"\hspace{0.1cm} `: variable label `v''"'
	}

save "$clean_data/clean_nibrs.dta", replace