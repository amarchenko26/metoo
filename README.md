# MeToo

## Description of datasets

$raw_data/MA/ma_raw_cases.xlsx
This data contains all cases filed in MA 2010 - 2022. 
- N: 32739
- SH: 1855
- Overlap: 

$clean_data/clean_eeoc.dta
This contains all court cases the EEOC filed on behalf of plaintiffs 2010-2022.
- N: 2288
- SH: 445
- Overlap: 

$raw_data/EEOC/filed_11_17.txt
This contains all cases filed with EEOC and their court information, if relevant, from 2010-2017.
- N:
- SH:
- Overlap: 




## Variable Definitions Guide 

The following variables are cleaned separately for each state. 

### Basis 
`basis_clean` takes the following categories
- Sex
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

### Probable cause
`probable_cause == 1` if outcome explicitly says discrimination was found at hearing; or if case went to court and plaintiff won the case.
`probable_cause == 0` if outcome explicitly says discrimination was not found  
`probable_cause == .` otherwise...e.g., if case was settled, was dismissed, etc.  

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
`treat = .` if `sex_cases == 1`, since we don't want the control group to include potentially treated sex cases that are not sexual harassment.  
`treat = 1` if `overlap == 1` since overlap cases are sh AND treated, but definition of post doesn't capture them.  


## Trash - remove
- Total cases brought under Title VII / Sex‐Female: 594
- Number of SH cases straddling Oct 2017: 31
- Number of Title VII / Sex‐Femalecases straddling Oct 2017: 47
- Number of SH cases started and resolved before Oct 2017: 309
- Number of SH cases started and resolved after Oct 2017: 105
- Mean relief $ for SH if case resolved before October 2017, with zeroes: 315780
- Mean relief $ for SH if case resolved after October 2017, with zeroes: 364087
- Relief is missing for SH cases 31 times
- Mean relief $ for SH if case resolved before October 2017, no zeroes: 343578
- Mean relief $ for SH if case resolved after October 2017, no zeroes: 382291
- - if htere's a mechanical issue where all years cases are filed december 2016, and so are the cases filed dec 2017 picking up the metoo cases. so when is the right timing? is it 2018 actually? 

- Mean duration for SH cases, before October 1, 2017: 623.1 days
- Mean duration for SH cases, after October 1, 2017: 403.1 days



