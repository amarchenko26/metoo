/*******************************************************************************

Cleans EEOC data 

*******************************************************************************/

import delimited "$raw_data/EEOC/cases.csv", varnames(1) clear

	
/*******************************************************************************
Rename Variables
*******************************************************************************/

ren casename Case_Name
ren civilactionnumber Civil_Action_Number
ren court Court
ren courtfilingdate Court_Filing_Date_temp
ren resolutiondate Resolution_Date_temp
ren relief Relief_temp
ren allegations Allegations


/*******************************************************************************
Identify SH cases
*******************************************************************************/

g sh = regexm(lower(Allegations), "sexual harassment")

g sex_cases = regexm(lower(Allegations), "title vii / sex‐female")

// // Total cases of Sexual Harassment
count if sh == 1
// // Total cases brought under Title VII / Sex-Female
count if sex_cases == 1



/*******************************************************************************
Clean columns
*******************************************************************************/

// convert 'Court Filing Date' and 'Resolution Date' to datetime format

gen Court_Filing_Date = date(Court_Filing_Date_temp, "MDY"), after(Court_Filing_Date_temp)
gen Resolution_Date = date(Resolution_Date_temp, "MDY"), after(Resolution_Date_temp)

// Calculate the duration in days between filing and resolution
gen Duration = Resolution_Date - Court_Filing_Date

// Remove the dollar sign and commas from the 'Relief' column
replace Relief_temp = regexreplaceall(Relief_temp, "[$,]", "")

// Create a new column to indicate missing relief
gen missing_relief = 1 if missing(Relief_temp)
replace missing_relief = 0 if missing_relief != 1
//
// // Convert to numeric, coercing errors to NaN, and fill NaNs with 0
replace Relief_temp = "0" if missing(Relief_temp)
destring Relief_temp, gen(Relief)

drop Relief_temp Court_Filing_Date_temp Resolution_Date_temp

// save dta file to desktop
save "/Users/`c(username)'/Desktop/eeoc_clean_test.dta", replace


