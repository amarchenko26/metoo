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
ren allegations basis

gen state = "Federal"
gen juris = "Employment"


/*******************************************************************************
Identify SH cases
*******************************************************************************/

g sh = regexm(lower(basis), "sexual harassment")

g sex_cases = regexm(lower(basis), "title vii / sex‐female")

// // Total cases of Sexual Harassment
count if sh == 1
// // Total cases brought under Title VII / Sex-Female
count if sex_cases == 1



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



/*******************************************************************************
Clean EEOC court case data to match state files
*******************************************************************************/

// reformat time
format court_file_date %td

format court_res_date %td

// Clean basis 
g basis_clean = "Sex" if regexm(basis, "^Title VII / Sex")  | regexm(basis, "^EPA / Equal Pay-Female") 
replace basis_clean = "Religion" if regexm(basis, "^Title VII / Religion") 
replace basis_clean = "Race" if regexm(basis, "^Title VII / Race") | regexm(basis, "^Title VII / Color")
replace basis_clean = "Nationality" if regexm(basis, "^Title VII / National Origin")
replace basis_clean = "Disability" if regexm(basis, "^ADA") //Americans with Disabilities
replace basis_clean = "Age" if regexm(basis, "^ADEA") //Age Discrimination in Employment
replace basis_clean = "Retaliation" if regexm(basis, "^Title VII / Retaliation") | regexm(basis, "^EPA / Retaliation")
replace basis_clean = "Other" if regexm(basis, "^Title VII / Other") | regexm(basis, "^GINA") | basis == "" // if it's missing

g win = 1 if missing_relief == 0
replace win = 0 if missing_relief == 1 // no probable cause if relief is missing

g court = 1 


// save dta file to clean data folder
save "$clean_data/clean_eeoc.dta", replace


