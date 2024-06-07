# MeToo

Run the project by navigating to metoo Github folder (using `cd`) and typing `./run_project.sh` into command line. 

## Description of datasets

**$raw_data/WA/wa_raw_cases.dta**  
These data contain all employment, housing, public accommodation/public service, and education cases filed in Washington from June 1, 2010 to June 1, 2023.
- N: 9949
- SH:
- wshrc: unique identifier for each case
- respondent: respondent name
- date filed: date case was filed
- basismergedcolumn: basis of discrimination
- closuredate: date case was closed
- findingsbyname: how case was closed
- settlementamountaladdin: settlement amount
- settlementamountspreadsheet: settlement amount
- cause: whether probable cause was found

**$raw_data/ND/nd_raw_cases.dta**  
These data contain all employment, housing, and public accommodation/public service cases filed in North Dakota from June 1, 2010 to June 1, 2023.
- N: 2977
- SH:
- Entity: respondent name
- Case Type: identifies whether the case is employment, housing, or public accommodations
- Date Opened: date case was filed
- Status Reason: current status of case
- Date Closed: date case was closed
- Basis of discrimination is listed in wide format:
  - (Other) Color
  - Age
  - Disability
  - (Other) Religion
  - (Other) Race
  - (Other) National Origin
  - (Other) Public Assistance
  - Retaliation
  - Sex
  - Pregnancy
  - Marital Status
  - Lawful Activity
  - Other Issue
- Closure Resolution: how case was closed

**$raw_data/IL/il_raw_cases.csv**  
These data contain all education, employment, housing, and public accommodation/public service cases filed in Illinois from June 1, 2010 to June 1, 2023.
- N: 46431
- SH: 3224
- Charge #: unique identifier for each case
- CP Name: complainant name
- RP Name: respondent name
- RP Addess: respondent address
- RP CITY: respondent city
- RP STATE: respondent state
- RP ZIP: respondent ZIP code
- File Date: date case was filed
- Close Date: date case was closed
- Finding: how case was closed
  - ACL: administrative closure
  - ADM: administrative dismissal
  - DEF: default
  - DUP: duplicate
  - EXP: expired
  - LOS: lack of service/letter of service
  - STA: stay
  - UNK: unknown
  - LSE: lack of substantial evidence
  - LOJ: lack of jurisdiction
  - SE: substantial evidence
  - WD: withdrawn
  - AW: adjusted and withdrawn
  - AT: adjusted/terms of settlement
  - OPT: opt out
  - FTP: failure to proceed
- Settle: settlement amount
- Basis: basis of discrimination
- Issue: adverse action alleged by complainant
- Request for Review: date complainant requested the case for review (cases with LSE findings)
- Dept filed Complaint: date department filed a complaint (cases with SE findings)
- Pro Se Complaint: date complainant decided to appear pro se (represent themselves in court)

**$raw_data/TX/tx_raw_cases.csv**  
These data contain all housing cases filed in Texas from June 1, 2010 to June 1, 2023.
- N: 5018
- SH:
- Case Name: complainant v. respondent
- Closure Reason: how case was closed
- HUD Filing Date: date case was filed
- HUD Closure Date: date case was closed
- Bases: basis of discrimination
- Relief Summary with Amounts: summary of relief given after case closed (monetary relief, housing, reasonable accommodation, etc.)
- Compensation Amount: amounts paid directly to the claimant

**$raw_data/HI/hi_raw_cases.xls**  
These data contain all employment, housing, and public accommodation/public service cases filed in Hawaii from June 1, 2010 to June 1, 2023.
- N: 3790
- SH: 161
- CaseType: identifies whether the case is employment, housing, or public accommodations
- Island: identifies on which island the case was filed
- Docket: unique identifier for each case
- EEOC No.: corresponding EEOC case number
- ComplaintFiled: date complaint was filed
- Basis: basis of discrimination alleged by complainant
- AdverseAct: adverse action alleged by complainant
- Closed: date complaint was closed at investigation stage
- Closure Code: code for closure at investigation stage
- Enf Closure: date complaint was closed at enforcement stage
- Enf Closure Code: code for closure at enforcement stage
- Compensation: amounts paid directly to the claimant

- Cases labeled `win == 1` if closure code “ORDER” in the enforcement closure column with compensation to complainant (equivalent of the case going to a hearing and the complainant winning)
- Cases labeled `win == 1` and `settle == 1` if closure code "CA" in the investigation closure column and closure code “SETTLED” in the enforcement closure column

**$raw_data/MI/mi_raw_cases.xlsx**  
These data contain all education, employment, housing, and public accommodation/public service cases filed in Michigan from June 1, 2010 to June 1, 2023.
- N: 17854
- SH: 348
- Case ID: unique identifier for each case
- Created Date: date case was opened
- Case Account: name of respondent
- Area of Complaint: description of whether case is related to education, employment, housing, or public accommodation/public service
- Issue and Basis: basis of discrimination and adverse action alleged by complainant
- Closed Date: date case was closed
- Closing Code: description indicating how case was closed
- Process Stage: (unsure, emailed for clarification)
- Actual: amounts paid directly to the claimant
- Annualized: calculated amount to be realized by a claimant over a year’s time, such as an increase in pay or reinstatement in a job as part of a settlement agreement

**$raw_data/MA/ma_raw_cases.xlsx**  
This data contains all housing and employment discrimination cases filed in Massachussets between XX and XX. 
- N: 32739
- SH: 1855

**$clean_data/clean_eeoc.dta**  
This contains all court cases the EEOC filed on behalf of plaintiffs 2010-2022. We retrieved these data by sending a FOIA request for all cases filed. However, this request was denied and only cases where the EEOC took the charge to court were provided. This dataset is constructed by digitizing **$raw_data/EEOC/DATA - 2010-2022 Resolutions as of 08.25.23.pdf** using Python. The resulting .csv is called **$raw_data/EEOC/cases.csv**. 
- N: 2288
- SH: 445

**$raw_data/EEOC/filed_11_17.txt**  
This contains all employment discrimination cases filed with EEOC for fiscal years 2011 to 2017. N = 3,443,510. These data encompasses charges filed with the EEOC and charges filed with state and local fair employment practices agencies alleging violations of federal anti-discrimination laws. Some cases that went to court have their court information, if relevant.
- FISCAL_YEAR: fiscal year in which a complainant first filed a charge
- CHARGE_INQUIRY_SEQ: unique identifier for each case (a case is a collection of related charges)
- STATE_CODE: complainant state
- NUMBER_OF_EMPLOYEES_CODE: code indicating the approximate number of employees working for respondent employer
- NUMBER_OF_EMPLOYEES: approximate number of employees working for respondent employer
- NAICS_CODE: North American Industry Classification System code of respondent employer
- NAICS_DESCRIPTION: North American Industry Classification System description of respondent company (e.g., crude petroleum and natural gas extraction)
- INSTITUTION_TYPE_CODE: classification code of respondent employer
- INSTITUTION_TYPE: classification of respondent employer (e.g., private employer)
- DATE_OF_BIRTH: complainant’s date of birth
- SEX_CODE: complainant’s gender
- DATE_FIRST_OFFICE: date charge was filed
- CLOSURE_DATE: date investigation of case was closed
- CLOSURE_CODE: code indicating how case was closed
- CLOSURE_ACTION: description indicating how case was closed (e.g., no cause finding issued)
- TOTAL_BENEFIT_AMOUNT: monetary benefit complainant received
- STATUTE_CODE: code for statute under which charge was filed
- STATUTE: statute under which charge was filed (e.g., Americans with Disabilities Act)
- BASIS_CODE: code for basis of discrimination
- BASIS: basis of discrimination (e.g., race-black/African American)
- ISSUE_CODE: type code for adverse action alleged by complainant
- ISSUE: adverse action alleged by complainant (e.g., harassment)
- COURT_FILING_DATE: date complainant filed a lawsuit
- CIVIL_ACTION_NUMBER: case number of lawsuit
- COURT: court in which lawsuit was filed
- RESOLUTION_DATE: date lawsuit was resolved
- CASE_TYPE: case type of lawsuit
- SELECTSUM(NVL(BACKPAY,0)+NVL(FRONTPAY,0)+NVL(INTEREST,0)+NVL(LIQUIDATED_DAMAGES,0)+NVL(NON_PEC_COMP_DAMAGES,0)+NVL(PEC_COMP_DAMAGES,0)+NVL(PUNITIVE_DAMAGES,0)+NVL(COSTS_AND_FEES,0)..: monetary damages recovered through lawsuit



## Variable Definitions Guide 

The following variables are cleaned separately for each state. 

### Jurisdiction
`juris` takes the following categories
- Employment
- Public Accommodation
- Housing
- Education

### Basis 
`basis_clean` takes the following categories
- Sex
- LGBTQ
- Religion
- Race
- Nationality
- Disability
- Age
- Retaliation
- Other  
Other includes missings. `basis_clean` is defined using the finer grained `basis` variable. 

### Sexual harassment
`sh == 1` if `basis` is Sexual Harassment or `issue` (less common) is Sexual Harassment.  
`sh == 0` otherwise  
`sh == .` if `sex_cases == 0 & sh == 1`, so a sexual harassment case was filed not on the basis of sex but of race, age, etc. These are weird and we'd like to exclude these altogether. 

### Sex-based cases
`sex_cases` == 1 includes all cases where `basis` has the word Sex.  
`sex_cases` == 0 otherwise.  
This is determined using regexm, which searches for string matches to "Sex". `sex_cases` == 1 can include discrimination against men as well. This variable can be used to understand trends in sex-based discrimination cases more generally. This variable should not be used to understand trends in discrimination against women, because it includes discrimination against men. 

### Compensation/Relief
`relief >0` is the total compensation plaintiff received from their case, conditional on winning. If plaintiff received money at both the hearing and court stage, relief is the sum of these.  
`relief = 0` never  
`relief = .` when the plantiff lost or when we don't have information on relief.  

We should not have `relief = 0` if the plaintiff lost. If the plaintiff lost, `relief == .` and `missing_relief == 1`.  

### Win
`win == 1` if outcome explicitly says discrimination was found at hearing (this may be called probable cause); or if case went to court and plaintiff won the case.  
`win == 0` if outcome explicitly says discrimination was not found (no probable cause)  
`win == .` otherwise...e.g., if case was settled, was dismissed, etc.  

If case went to court and plaintiff won compensation, we do not always make this variable equal 1 because receiving $ may not be an admission of discrimination being found. 

### Settle
`settle == 1` if outcome says case was settled or case was withdrawn with benefits  
`settle == 0` if otherwise  
`settle == .` never  

### Court 
`court == 1` if data is court data, if outcome says "Notice of Right to Sue" was issued, or outcome says case went to court.  
`court == 0` if otherwise  
`court == .` never  

The following variables are cleaned altogether, after state and federal data is appended together. 

### Overlap
`overlap == 1` if `sh ==1` and case filed before MeToo and resolved after MeToo  
`overlap == 0` if `sh ==1` and case filed before MeToo and resolved before MeToo  
`overlap == .` if `sh == 0`  
`overlap == .` if case filed after MeToo  

### Treat
`post = 1` if file date after MeToo.   
`post = 0` if file date before MeToo.    
`post = .` never  

`treat = post*sh`  
`treat = .` if `sex_cases == 1 & sh == 0`, since we don't want the control group to include potentially treated sex cases that are not sexual harassment.  
`treat = 1` if `overlap == 1` since overlap cases are sh AND treated, but definition of post doesn't capture them.  
