/*******************************************************************************

Cleans EEOC data 

*******************************************************************************/

import delimited "$raw_data/EEOC/cases_edited.csv", varnames(1) clear

	
/*******************************************************************************
Rename Variables
*******************************************************************************/

ren casename resp_org
ren civilactionnumber civil_action_number
ren court court_name
ren courtfilingdate court_filing_date_temp
ren resolutiondate resolution_date_temp
ren relief relief
ren allegations basis_raw

gen state = substr(court_name, -2, 2)
gen juris = "Employment"


/*******************************************************************************
Identify SH cases
*******************************************************************************/

g sh = regexm(lower(basis_raw), "sexual harassment")

g sex_cases = regexm(lower(basis_raw), "title vii / sex‐")

g victim_f = 1 if regexm(lower(basis_raw), "title vii / sex‐female")
replace victim_f = 0 if regexm(lower(basis_raw), "title vii / sex‐male")

/*******************************************************************************
Clean columns
*******************************************************************************/

// convert 'Court Filing Date' and 'Resolution Date' to datetime format
gen court_file_date = date(court_filing_date_temp, "MDY"), after(court_filing_date_temp)
gen court_res_date = date(resolution_date_temp, "MDY"), after(resolution_date_temp)

// Calculate the duration in days between filing and resolution
gen duration = court_res_date - court_file_date

// Convert the 'Relief' column to numbers
replace relief = regexreplaceall(relief, "[$,]", "")
destring relief, replace

// Create a new column to indicate missing relief
g missing_relief = missing(relief)

drop court_filing_date_temp resolution_date_temp

gen civil_action_number_clean = ustrregexra(civil_action_number, "[^a-zA-Z0-9]", "") //removes non-numeric and non-letter characters
replace civil_action_number_clean = lower(civil_action_number_clean)

* Drop N = 1 duplicate
duplicates drop civil_action_number_clean court_res_date, force

replace civil_action_number = subinstr(civil_action_number, "‐", "-", .)

/*******************************************************************************
Clean EEOC court case data to match state files
*******************************************************************************/

// reformat time
format court_file_date %td

format court_res_date %td

// Multi-category
g multi_cat = 0

// Clean basis 
g basis = "Sex" if regexm(basis_raw, "^Title VII / Sex")  | regexm(basis_raw, "^EPA / Equal Pay-Female") 
replace basis = "Religion" if regexm(basis_raw, "^Title VII / Religion") 
replace basis = "Race" if regexm(basis_raw, "^Title VII / Race") | regexm(basis_raw, "^Title VII / Color")
replace basis = "Nationality" if regexm(basis_raw, "^Title VII / National Origin")
replace basis = "Disability" if regexm(basis_raw, "^ADA") //Americans with Disabilities
replace basis = "Age" if regexm(basis_raw, "^ADEA") //Age Discrimination in Employment
replace basis = "Retaliation" if regexm(basis_raw, "^Title VII / Retaliation") | regexm(basis_raw, "^EPA / Retaliation")
replace basis = "Other" if regexm(basis_raw, "^Title VII / Other") | regexm(basis_raw, "^GINA") | basis == "" // if it's missing

replace sh = 1 if basis == "Retaliation" & regexm(basis_raw, "Sexual Harassment")
replace sex_cases = 1 if basis == "Retaliation" & regexm(basis_raw, "Sex") & sh == 0

g win = 1 if missing_relief == 0
replace win = 0 if missing_relief == 1 // no probable cause if relief is missing

g court = 1 
g settle = 0 
g admin_close = 0
g withdraw = 0
g dismissed = 0

g eeoc = 1
g eeoc_foia = 1
g eeoc_took_to_court = 1

// save dta file to clean data folder
save "$clean_data/clean_eeoc.dta", replace


