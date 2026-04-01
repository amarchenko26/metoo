/*******************************************************************************

Clean CT cases

*******************************************************************************/

// Load wide data
use "$raw_data/CT/ClosedComplaints2010-2022_wide.dta", clear


/*******************************************************************************
Clean vars
*******************************************************************************/

ren Case__ case
ren Complainant comp_name
ren Comp_City comp_city
ren Respondent resp_org
ren Date_Filed charge_file_date_str
ren Date_Closed charge_res_date_str
ren Closure outcome
ren Bases basis
ren Issues issue

// include Gender data from Genderize (Bobby computed this)
// Gender file has many empty rows; keep first observation per case
preserve
use "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data/raw/CT/ClosedComplaints2010-2022_with_gender.dta", clear
drop if missing(case)
bysort case: keep if _n == 1
tempfile gender_clean
save `gender_clean'
restore
merge 1:1 case using `gender_clean', keepusing(gender genderprobability)
drop _merge


// Create gender 
g victim_f = 1 if gender =="female"
replace victim_f = 0 if gender =="male"
replace victim_f = . if gender =="unknown"

// Convert dates (format is MM/DD/YYYY)
gen charge_file_date = date(charge_file_date_str, "MDY")
format charge_file_date %td
drop charge_file_date_str

gen charge_res_date = date(charge_res_date_str, "MDY")
format charge_res_date %td
drop charge_res_date_str

// Duration
gen duration = charge_res_date - charge_file_date


/*******************************************************************************
Jurisdiction (from case number)
*******************************************************************************/

// From Charles Perry, CT FOIA Officer:
// First two numbers = year filed
// Third number: 1,2,3,4 = employment/public accommodation; 5 = housing

tostring case, gen(case_str) format(%12.0f)
gen third_digit = real(substr(case_str, 3, 1))

gen juris = ""
// NOTE: WE DENOTE ALL EMP OR PUBLIC ACCOMMODATION CASES AS EMPLOYMENT
// WE CAN CHANGE THIS LATER, BUT FOR RIGHT NOW, WE'RE ASSIGNING ALL UNCERTAINTY TO EMPLOYMENT
replace juris = "Employment" if inlist(third_digit, 1, 2, 3, 4)
replace juris = "Housing" if third_digit == 5

drop case_str third_digit


/*******************************************************************************
Define new vars
*******************************************************************************/

// State
gen state = "CT"

// Multi-category (check if there's a comma in basis = multiple bases)
gen multi_cat = 0
replace multi_cat = 1 if regexm(basis, ",")

// Sexual harassment (check Issues for "Sexual Harassment")
gen sh = 0
replace sh = 1 if regexm(issue, "Sexual Harassment")

// Sex cases (check if basis includes Sex or Gender)
gen sex_cases = 0
replace sex_cases = 1 if regexm(basis, "Gender")
replace sex_cases = 1 if regexm(basis, "Sexual Orientation")
replace sex_cases = 1 if regexm(basis, "Sex")


/*******************************************************************************
Outcome variables

Closure code meanings (from CT FOIA Officer):
- CAR/RE: Case Assessment Review/Respondent Exempt → dismissed
- CARC: Case Assessment Review – No Claim for Relief → dismissed
- CARF: Case Assessment Review - Frivolous → dismissed
- CARR: Case Assessment Review - No Possibility of Reasonable Cause → win=0
- HEDD: Hearing Examiner Decision on Default → dismissed
- MAR/RE: Merit Assessment Review/Retained → (investigation ongoing)
- MARC: Merit Assessment Review – No Claim for Relief → dismissed
- MARF: Merit Assessment Review - Frivolous → dismissed
- MARR: Merit Assessment Review – No Possibility of Reasonable Cause → win=0
- NFA: No Fault Agreement → settle
- NRC: No Reasonable Cause → win=0
- NRC/AD: No Reasonable Cause/Administratively Dismissed → win=0
- NRC/LOJ: No Reasonable Cause/Lack of Jurisdiction → dismissed
- PH: Matter assigned to Public Hearing → win=1
- PNDG: Matter Pending Investigation → all missing
- ROJ: Release of Jurisdiction → dismissed
- SA: Satisfactorily Adjusted → settle
- WDWS: Withdrawn With Settlement → settle
- WD: Withdrawn → dismissed
- AD: Administratively Dismissed → dismissed
- PDC: Pre-Determination Closure → dismissed
*******************************************************************************/

// Win (probable cause found or hearing)
gen win = .
replace win = 1 if outcome == "PH"
replace win = 0 if inlist(outcome, "CARR", "MARR", "NRC", "NRC/AD")
replace win = . if outcome == "PNDG"

// Settle
gen settle = 0
replace settle = 1 if inlist(outcome, "NFA", "SA", "WDWS")
replace settle = . if outcome == "PNDG"

// Court (release of jurisdiction to court)
gen court = 0
replace court = 1 if outcome == "ROJ"
replace court = . if outcome == "PNDG"

// Dismissed
gen dismissed = 0
replace dismissed = 1 if inlist(outcome, "CAR/RE", "CARC", "CARF", "HEDD", "MARC", "MARF")
replace dismissed = 1 if inlist(outcome, "NRC/LOJ", "WD", "AD", "PDC")
replace dismissed = . if outcome == "PNDG"


/*******************************************************************************
Export data
*******************************************************************************/

save "$clean_data/clean_ct.dta", replace
