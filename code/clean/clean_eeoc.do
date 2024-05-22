/*******************************************************************************

Cleans EEOC data 

*******************************************************************************/

import delimited "$raw_data/EEOC/cases_edited.csv", varnames(1) clear

	
/*******************************************************************************
Rename Variables
*******************************************************************************/

ren casename resp_org
ren civilactionnumber Civil_Action_Number
ren court court_name
ren courtfilingdate Court_Filing_Date_temp
ren resolutiondate Resolution_Date_temp
ren relief Relief_temp
ren allegations basis

ren *, lower

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

// Remove the dollar sign and commas from the 'Relief' column
replace relief_temp = regexreplaceall(relief_temp, "[$,]", "")

// Create a new column to indicate missing relief
gen missing_relief = 1 if missing(relief_temp)
replace missing_relief = 0 if missing_relief != 1
//
// // Convert to numeric, coercing errors to NaN, and fill NaNs with 0
replace relief_temp = "0" if missing(relief_temp)
destring relief_temp, gen(relief)

drop relief_temp court_filing_date_temp resolution_date_temp



/*******************************************************************************
Clean EEOC court case data from .py files to match state files
*******************************************************************************/
 


// remove time (all times are zero anyway)
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


