# MeToo National Incident-Based Reporting System Data

## Description of datasets (kept variables bolded)

**$raw_data/Criminal/`year` NIBRS data'.dta**
These data contain all cases reported to NIBRS from 2010 to 2020 from US agencies

- N: 60,729,477
- SA: 935,987
- ID: Unique identifier for the case
- SEGMENT: Type of record - administrative, offense, property, victim, offender, and arrestee
- **STATE**: Numeric code representing the state in which the crime took place
- ORI: Identifier for the agency that reported the case to NIBRS
- INCNUM: Unique case identifier assigned by the agency reporting the case
- **INCDATE**: Date of the incident
- B1007: City the agency is associated with
- B1011: Region of the country the sate is located in - North East, North Central, South, West
- **B3011/BH041**: File year
  - Variable name is B3011 for 2010-2012, and BH041 starting in 2013
- **V1006**: Whether INCDATE is the date the incident occurred or the report date
- V1007: Hour the incident occurred
- V1008: Number of offenses for the case
- V1009: Number of victims for the case
- V1010: Number of offenders for the case
- V1011: Number of arrestees for the case
- **V1013**: Whether the case was cleared by nonarrest circumstances
- **V1014**: If the case was cleared exceptionally, the date it was cleared
- **V20061**: Primary offense and offense code for the case
- V20062: Secondary offense of the case
- V20063: Tertiary offense of the case
- V20071-20073: Whether the primary-tertiary offense was completed or just attempted
- V20111-V20113: Type of location where the primary-tertiary crime was committed
- V20201-V20203: Bias motivation of the primary-tertiary crime
- **V40191**: Sex of primary victim
- V40192-V40193: Sex of secondary and tertiary victim
- V40201-V40203: race of primary-tertiary victim
- **V40321**: Relationship of primary victim to primary offenders
- V40322-V40323: Relationship of primary victim to secondary and tertiary offenders
- V50081-V50083: Sex of primary-tertiary offender
- **V60081**: Primary arrest date
- V60082-60083: Secondary and tertiary arrest dates
- ALLOFNS: all offense codes for the case

## Variable Definitions Guide

### Sex-based cases

`sex_cases == 1` if `crime_code` is 111, 112, 113, 114, or 362, leading to:

- Rape
- Sodomy
- Sexual Assault with an Object
- Forcible Fondling
- Statutory Rape  
  
`sex_cases == 0` otherwise.

### Sexual harassment cases

`sh == 0` always, since no sexual harassment cases are reported to NIBRS  

### Crime type

`crime_type == Sexual assault` if `sex_cases == 1`

`crime_type == Excluded crime` if the crime is not directly affected by the MeToo movement but could be indirectly related to it.

- Incest
- Pornography/Obscene Material
- Prostitution
- Human Trafficking
- Aggravated assault where the victim was:
  - Ex-spouse
  - Spouse
  - Boyfriend/Girlfriend
  - Common-law spouse
  - Victim and Offender were in a homosexual relationship

`crime_type == Non-sex crime` for all other crimes.

### Clearance

`clearance == 1` if the case was marked as cleared by arrest or exception  
`clearance == 0` otherwise

### Victim_f

`victim_f == 1` if the victim of the case is female
`victim_f == 0` otherwise

### Court

`court == 1` if the case went to court
`court == 0` otherwise

### Overlap

`overlap == 1` if `sex_cases == 1` and case filed before MeToo and resolved after MeToo  
`overlap == 0` if `sex_cases == 1` and case filed before MeToo and resolved before MeToo  
`overlap == .` if `sex_cases == 0`  
`overlap == .` if case filed after MeToo

### Treat

`post = 1` if file date after MeToo.  
`post = 0` if file date before MeToo.  
`post = .` never

`treat = post*sex_cases`  
`treat = 1` if `overlap == 1` since overlap cases are sex cases AND treated, but definition of post doesn't capture them.
