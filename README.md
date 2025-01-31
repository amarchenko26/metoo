# MeToo

Run the project by navigating to metoo Github folder (using `cd`) and typing `./run_project.sh` into command line. 

## Variable Definitions Guide  

The following variables are cleaned separately for each state. 

### Jurisdiction
`juris` takes the following categories
- Employment
- Public Accommodation
- Housing
- Education

### Basis 
`basis` takes the following categories
- Sex
- Religion
- Race
- Nationality
- Disability
- Age
- Retaliation
- Other  
Other includes missings. `basis` is defined using the finer grained `basis_raw` variable. 

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

We should not have `relief = 0` if the plaintiff lost. If the plaintiff lost, `relief == .` and `missing_relief == 1`. If `settle == 1` most often `relief` is missing, unless the case was resolved by conciliation, in which case `relief` may be provided. 

### Win
`win == 1` if outcome explicitly says discrimination was found at hearing (this may be called probable cause); or if case went to court and plaintiff won the case.  
`win == 0` if outcome explicitly says discrimination was not found (no probable cause)  
`win == .` otherwise...e.g., if case was settled, was dismissed, etc.  

If case went to court and plaintiff won compensation, we do not always make this variable equal 1 because receiving $ may not be an admission of discrimination being found. 

### Settle
`settle == 1` if outcome says case was settled, case was withdrawn with benefits, or case was resolved by conciliation (an administrative process by which two parties resolve their dispute without involving a hearing or court, we can often observe the relief for these cases).  
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

### Victim female
`victim_f = 1` if complainant/victim is female  
`victim_f = 0` if complainant/victim is male     
`victim_f = .` if missing data on complainant gender  


## Description of datasets

**$raw_data/NY/ny_cases_with_gender.csv**  
These data contain all employment and housing cases filed in New York from June 2010 to June 2023.
- N: 86775
- SH: 8234
- case_id: unique identifier for each case
- date_filed: date case was filed
- case_name: plaintiff v. respondent
- closing_date: date case was closed
- closing_acts: how case was closed
- jurisdiction
- basis: basis of discrimination
- acts: adverse action alleged by complainant
- first_name: plaintiff's first name
- gender: plaintiff's assumed gender
- probability: probability of that gender being correct based on name

**$raw_data/NC/nc_raw_cases.xlsx**  
These data contain all employment and housing cases filed in North Carolina from June 2010 to June 2023.
- N: 801
- SH:
- respondentcompany: respondent name
- basis/c: basis of discrimination
- datefiled: date case was filed
- dateclosed: date case was closed
- decision/outcome: how case was closed

**$raw_data/MD/md_raw_cases.xlsx**  
These data contain all employment and housing cases filed in Maryland from June 2019 to June 2023.
- N: 2484
- SH: 131
- CaseType: jurisdiction
- InitialInquiryDate: date case was filed
- ClosureType: how case was closed
- ClosureDate: date case was closed
- Statute: statute of protection
- Basis: basis of discrimination
- Issue: adverse action alleged by complainant

**$raw_data/GA/ga_raw_cases.dta**  
These data contain all employment and housing cases filed in Georgia.
- N: 350
- SH: 
- charge_res_date: date case was closed
- basis_raw: basis of discrimination
- outcomes: how case was closed
- relief
- juris: jurisdiction

**$raw_data/CA/ca_raw_cases.csv**  
These data contain all employment and public accommodations cases filed in California from January 1, 2017 to April 29, 2024.
- N: 139717
- SH: 26547
- no: unique identifier for each case
- ccrscaserecordtype: jurisdiction
- casefiledate: date case was filed
- closedate: date case was closed
- legacybasis/discriminationbasis/harassmentbasis: basis of discrimination
- legacyharms/discriminationactofharm/retaliationactofharm: adverse action alleged by complainant
- typeofprotectedactivity: type of protected activity the plaintiff alleges was retaliated against
- closereason: how case was closed

**$raw_data/FL/fl_raw_cases.dta**  
These data contain all employment and housing cases filed in Delaware from June 1, 2010 to June 30, 2023.
- N: 10673
- SH: 38
- filingdate: date case was filed
- bases: basis of discrimination
- casetype: jurisdiction
- closuredate: date case was closed
- closuretype: how case was closed

**$raw_data/DE/de_raw_cases.xlsx**  
These data contain all housing and public accomodations cases filed in Delaware from June 1, 2010 to June 30, 2023.
- N: 413
- SH: 8
- casename: name for each case
- casefileddate: date case was filed
- systemcloseddate: date case was closed
- protectedclass: basis of discrimination
- basis: whether the case contained the issue of sexual harassment
- results: how case was closed
- dismissalrejectionbasis: reason a case was dismissed or rejected

**$raw_data/KY/ky_raw_cases.dta**  
These data contain all employment and housing cases filed in Kentucky from June 1, 2010 to June 30, 2023.
- N: 3148
- SH: 66
- kchrcaseno: unique identifier for each case
- respondent: respondent name
- basis: basis of discrimination
- issue: adverse action alleged by complainant
- datefiled: date case was filed
- howresolvedbycommissioners: how case was closed
- dateofresolution: date case was closed
- compensation: relief

**$raw_data/WI/wi_raw_cases.dta**  
These data contain all education, employment, housing, and public accommodation/public service cases filed in Wisconsin from June 1, 2017 to June 30, 2023.
- N: 26436
- SH: 1071
- casenumber: unique identifier for each case
- respondentname: respondent name
- initialinquirydate: date case was filed
- lawname: jurisdiction
- basisname: basis of discrimination
- issuename: whether the case contained the issue of sexual harassment
- closedate: date case was closed

**$raw_data/AK/ak_raw_cases.csv**  
These data contain all employment, housing, and public accommodation/public service cases filed in Alaska from June 1, 2010 to June 1, 2023.
- N: 3611
- SH: 89
- acct: unique identifier for each case
- datecreated: date case was filed
- liability: jurisdiction
- casestatus: open/closed
- dateclosed: date case was closed
- closurereason: how case was closed
- monetaryaward: relief
- rptype: respondent type
- investigationsense: substantial evidence investigation finding (years 2014+: SE/NSE)
- basis (wide variable): basis of discrimination
- issue (wide variable): adverse action alleged by complainant

**$raw_data/PA/PA_raw_cases_severity.csv**  
This file merges PA data from two sources. The first source is a spreadsheet of 21 cases from the public hearing docket (i.e., publicly available cases) of the Pennsylvania Human Relations Commission. We do not have PDFs of these cases. The second source is a set of ~200 PDFs of final orders issued by the Commission based on charges of discrimination which were filed during the period between April 9, 1963 to March 22, 2022. These PDFs were manually digitized by Jacob Hirschhorn.  
- N: 210
- SH: 8
- resp_org: respondent name
- case_id: unique identifier for each case
- file_date: date case was filed
- res_date: date case was closed
- basis: basis of discrimination
- jurisdiction: jurisdiction of the case
  - Employment
  - Public Accommodation
  - Housing
  - Education
- win: whether the complainant won the case
- settle: whether the case was settled
- court: whether the case went to court
- victim_f: whether the complainant was female
- severity_manual: Ranking of the severity of the case, from 0 to 1, done manually by searching for keywords related to sexual harassment
- severity_sentiment: Ranking of the severity of the case, from -1 to 1, done using the VADER sentiment analysis package


**$raw_data/RI/ri_raw_cases.csv**  
These data were extracted from PDF files of copies of all decision and orders issued by the Commission based on charges of employment discrimination which were filed during the period between June 1, 2010 to December 31, 2022.
- N: 12
- SH: 3
- resp_org: respondent name
- case_id: unique identifier for each case
- file_date: date case was filed
- res_date: date case was closed
- basis: basis of discrimination
- jurisdiction: jurisdiction of the case
  - Employment
  - Public Accommodation
  - Housing
  - Education
- win: whether the complainant won the case
- settle: whether the case was settled
- court: whether the case went to court
- victim_f: whether the complainant was female

**$raw_data/MN/mn_raw_cases.xlsx**  
These data contain all employment, housing, public accommodation/public service, and education cases filed in Minnesota from June 1, 2010 to June 1, 2023 (document seems to contain only up to 2019).
- N: 539
- SH: 14
- caseid: unique identifier for each case
- filedate: date case was filed
- basis: basis of discrimination
- allegation: adverse action alleged by complainant
- determination: how case was closed
- determinationdate: date case was determined
- closuredate: date case was closed
- respondentcompanyname: respondent name

**$raw_data/WA/wa_raw_cases.dta**  
These data contain all employment, housing, public accommodation/public service, and education cases filed in Washington from June 1, 2010 to June 1, 2023.
- N: 9949
- SH: 470
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
- SH: 322
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

**$raw_data/TX/tx_raw_cases.dta**  
These data contain all housing cases filed in Texas from June 1, 2010 to June 1, 2023.
- N: 5023
- SH: 79
- case_name: complainant v. respondent
- outcome: how case was closed
- charge_file_dat: date case was filed
- charge_res_date: date case was closed
- basis_raw: basis of discrimination
- relief_summary: summary of relief given after case closed (monetary relief, housing, reasonable accommodation, etc.)
- relief: amounts paid directly to the claimant

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
