# MeToo

## Data description of EEOC Resolutions pdf

$raw_data/EEOC/filed_11_17.txt
- Total cases in data: 2288
- Total cases of Sexual Harassment: 445

$raw_data/EEOC/filed_11_17.txt
- Total cases in data: 2288
- Total cases of Sexual Harassment: 445


- if htere's a mechanical issue where all years cases are filed december 2016, and so are the cases filed dec 2017 picking up the metoo cases. so when is the right timing? is it 2018 actually? 

## Variable Definitions Guide 
### Sexual harassment
`sh == 1` if `basis` is Sexual Harassment or `issue` (less common) is Sexual Harassment. 
`sh == 0` for all other cases. 

Some `sh` == 1 cases have a `basis` that is not Sex because cases are sometimes filed as racial discrimination / sexual harassment. I don't get this. DECIDE IF WE WANT TO "replace sh == 0 if basis != "Sex" & sh ==1". 

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
`probable_cause == 1` if outcome explicitly says discrimination was found at hearing; or if case went to court and plaintiff won the case
`probable_cause == 0` if outcome explicitly says discrimination was not found
`probable_cause == .` otherwise...e.g., if case was settled, was dismissed, etc. 

If case went to court and plaintiff won compensation, we do not always make this variable equal 1 because receiving $ may not be an admission of discrimination being found. 

### Settle
`settle == 1` if outcome says case was settled or case was withdrawn with benefits 
`settle == 0` if otherwise
`settle == .` should not be present 

### Court 
`court == 1` if we know case went to court because we have court data, or if outcome says "Notice of Right to Sue" was issued, or outcome says case went to court.
`court == 0` if otherwise
`court == .` should not be present

### Treat



----
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
- Mean duration for SH cases, before October 1, 2017: 623.1 days
- Mean duration for SH cases, after October 1, 2017: 403.1 days



