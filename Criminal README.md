# MeToo Criminal Data

**City Data and National Incident-Based Reporting System Data**

## Description of datasets (kept variables bolded)

**$raw_data/Criminal/Austin.csv**  
These data contain all police cases reported in Austin from 2003 to 2024 (downloaded 7/1/2024).

- N: 1,561,674 (years 2010+); 2,477,359 (raw)
- SH: 5,608 (years 2010+)
- SA: 6,324 (years 2010+)
- **Incident number**: Incident report number
- **Highest Offense Description**: Description of crime
- **Highest Offense Code**: Code for crime
- Family Violence: Family violence indicator (Y/N)
- Occurred Date Time: Date and time (combined) incident occurred
- **Occurred Date**: Date the incident occurred
- Occurred Time: Time the incident occurred
- Report Date Time: Date and time (combined) incident was reported
- **Report Date**: Date the incident was reported
- Report Time: Time the incident was reported
- Location Type: General description of the premise where the incident occurred
- Address: Incident location
- Zip code: Zip code where incident occurred
- Council District: Austin city council district where the incident occurred
- APD Sector: APD sector where incident occurred
- APD District: APD district where incident occurred
- PRA: APD police reporting area where incident occurred
- Census Tract: Census tract where incident occurred
- **Clearance Status**: How/whether crime was solved
  - C: Cleared by Arrest
  - O: Cleared by Exception
  - N: Not cleared
- **Clearance Date**: Date crime was solved
- UCR Category: Code for the most serious crimes identified by the FBI as part of its Uniform Crime Reporting program
- Category Description: Description for the most serious crimes identified by the FBI as part of its Uniform Crime Reporting program
- X-coordinate: X-coordinate where the incident occurred
- Y-coordinate: Y-coordinate where the incident occurred
- Latitude: Latitude where incident occurred
- Longitude: Longitude where the incident occurred
- Location: 3rd party generated spatial column

**$raw_data/Criminal/Chicago.csv**  
These data contain all police cases reported in Chicago from 2001 to 2024 (downloaded 7/9/2024).

- N: 4,023,799 (years 2010+); 8,101,448 (raw)
- SH: 7,974 (years 2010+)
- SA: 25,725 (years 2010+)
- ID: Unique identifier for the record
- **Case Number**: The Chicago Police Department RD Number (Records Division Number), which is unique to the incident
- **Date**: Date when the incident occurred (best estimate)
- Block: The partially redacted address where the incident occurred, placing it on the same block as the actual address
- **IUCR**: The Illinois Uniform Crime Reporting code
- **Priamry Type**: The primary description of the IUCR code
- **Description**: The secondary description of the IUCR code, a subcategory of the primary description
- Location Description: Description of the location where the incident occurred
- **Arrest**: Indicates whether an arrest was made (true/false)
- Domestic: Indicates whether the incident was domestic-related as defined by the Illinois Domestic Violence Act (true/false)
- Beat: Indicates the beat where the incident occurred
- District: Indicates the police district where the incident occurred
- Ward: The ward (City Council district) where the incident occurred
- Community Area: Indicates the community area where the incident occurred
- FBI Code: Indicates the crime classification as outlined in the FBI's National Incident-Based Reporting System (NIBRS)
- X Coordinate: The x coordinate of the location where the incident occurred in State Plane Illinois East NAD 1983 projection
- Y Coordinate: The y coordinate of the location where the incident occurred in State Plane Illinois East NAD 1983 projection
- **Year**: Year the incident occurred
- Updated On: Date and time the record was last updated
- Latitude: The latitude of the location where the incident occurred
- Longitude: The longitude of the location where the incident occurred
- Location: The location where the incident occurred in a format that allows for creation of maps and other geographic operations on this data portal

**$raw_data/Criminal/Denver.csv**  
These data contain all police cases reported in Denver from 2019 to 2024 (downloaded 7/2/2024). (not currently used)

**$raw_data/Criminal/Kansas City `year`.csv**  
These data contain all police cases reported in Kansas City from 2015 to 2024 (downloaded 7/2/2024).

- N: 1,061,787 (dropping cases not in Kansas City); 1,068,111 (raw)
- SH: 2,296 (dropping cases not in Kansas City)
- SA: 11,017 (dropping cases not in Kansas City)
- **Report_No**: Unique number assigned to a case, throughout the life of a case numerous reports can be written
- **Reported_Date**: Date the offense was reported
- Reported_Time: Time the offense was reported
- **From_Date**: Earliest date the incident could have occurred
- From_Time: Earliest time the incident could have occurred
- To_Date: Latest date the incident could have occurred
- To_Time: Latest time the incident could have occurred
- Offense
  - 2015-2018: Offense code
  - 2019-2024: Offense description
- **IBRS**: National Incident Based Reporting System offense code
- **Decription**: Short description of the offense
- Beat: Area where offense occurred
- Address: Cross streets of address where offense occurred
- City
- Zip Code
- Rep_Dist: Area where offense occurred
- Area: Division the offense occurred in (Central, East, Metro, South, North, and Shoal Creek)
- DVFlag: Indicates if it was a domestic violence offense
  - 2015-2020:
    - N: No
    - U: Unknown
    - Y: Yes
  - 2021-2024: true/false
- Invl_No: On the report the involvement number of the persons listed
- Involvement: Person’s involvement in the case
  - sus: suspect
  - vic: victim
  - arr: arrestee
- Race:
  - A: Asian
  - B: Black or African American
  - I: American Indian or Alaska Native
  - P: Native Hawaiian or Other Pacific Islander
  - U: Unknown
  - W: White
- Sex:
  - M: Male
  - F: Female
  - U: Unknown
- Age: Age of victim/suspect/arrestee. If the victim/suspect/arrestee is a juvenile, the age is left blank
- Firearm Used Flag: Indicates if a firearm was used in the offense
  - 2015-2018: Y/N
  - 2019-2024: true/false
- Latitude
- Longtitude
- Location 1

**$raw_data/Criminal/Los Angeles 1.csv** (2010-2019) & **$raw_data/Criminal/Los Angeles 2.csv** (2020-2024)  
These data contain all police cases reported in Los Angeles from 2010 to 2024 (downloaded 7/2/2024).

- N: 3,078,199
- SH: 46,571
- SA: 40,989
- **DR_NO**: Division of Records Number: Official file number made up of a 2 digit year, area ID, and 5 digits
- **Date Rptd**: MM/DD/YYYY
- **DATE OCC**: MM/DD/YYYY
- TIME OCC: In 24 hour military time
- AREA: The LAPD has 21 Community Police Stations referred to as Geographic Areas within the department
- AREA NAME: The 21 Geographic Areas or Patrol Divisions are also given a name designation that references a landmark or the surrounding community that it is responsible for
- Rpt Dist No: A four-digit code that represents a sub-area within a Geographic Area. All crime records reference the "RD" that it occurred in for statistical comparisons
- Part 1-2
- **Crm Cd**: Indicates the crime committed
- **Crm Cd Desc**: Defines the Crime Code provided
- Mocodes: Modus Operandi; activities associated with the suspect in commission of the crime
- Vict Age: Two character numeric
- Vict Sex:
  - F: Female
  - M: Male
  - X: Unknown
- Vict Descent: Descent Code
  - A: Other Asian
  - B: Black
  - C: Chinese
  - D: Cambodian
  - F: Filipino
  - G: Guamanian
  - H: Hispanic/Latin/Mexican
  - I: American Indian/Alaskan Native
  - J: Japanese
  - K: Korean
  - L: Laotian
  - O: Other
  - P: Pacific Islander
  - S: Samoan
  - U: Hawaiian
  - V: Vietnamese
  - W: White
  - X: Unknown
  - Z: Asian Indian
- Premis Cd: The type of structure, vehicle, or location where the crime took place
- Premis Desc: Defines the Premise Code provided
- Weapon Used Cd: The type of weapon used in the crime
- Weapon Desc: Defines the Weapon Used Code provided
- Status: Status of the case (IC is the default)
- **Status Desc**: Defines the Status Code provided
- Crm Cd 1: Indicates the primary and most serious crime committed
- Crm Cd 2: May contain a code for an additional crime, less serious than Crime Code 1
- Crm Cd 3: May contain a code for an additional crime, less serious than Crime Code 1
- Crm Cd 4: May contain a code for an additional crime, less serious than Crime Code 1
- LOCATION: Street address of crime incident rounded to the nearest hundred block to maintain anonymity
- Cross Street: Cross Street of rounded Address
- LAT: Latitude
- LON: Longitude

**$raw_data/Criminal/Louisville `year`.csv**  
These data contain all police cases reported in Louisville from 2010 to 2024 (downloaded 7/2/2024).

- N: 1,057,124 (dropping cases not in Louisville); 1,123,144 (raw)
- SH: 1,463 (dropping cases not in Louisville)
- SA: 5,260 (dropping cases not in Louisville)
- **INCIDENT_NUMBER**: the number associated with either the incident or used as reference to store the items in evidence rooms
- **DATE_REPORTED**: the date the incident was reported to LMPD
- **DATE_OCCURED** (2023 Date Occurred): the date the incident actually occurred
- BADGE_ID (2021+): Badge ID of responding Officer
- **UOR_DESC**: Uniform Offense Reporting code for the criminal act committed
  - 2023 Offense Code Name: NIBRS Reporting code for the criminal act committed
- **CRIME_TYPE**: the crime type category
  - 2023 Offense Classification: NIBRS Reporting category for the criminal act committed
- **NIBRS_CODE**: the code that follows the guidelines of the National Incident Based Reporting System
- UCR_HIERARCHY: hierarchy that follows the guidelines of the FBI Uniform Crime Reporting
  - 2023 NIBRS Group: hierarchy that follows the guidelines of the FBI National Incident Based Reporting System
- ATT_COMP (2023 Was Offense Completed): Status indicating whether the incident was an attempted crime or a completed crime
- LMPD_DIVISION: the LMPD division in which the incident actually occurred
- LMPD_BEAT: the LMPD beat in which the incident actually occurred
- PREMISE_TYPE (2023 Location Category): the type of location in which the incident occurred
- BLOCK_ADDRESS: the location the incident occurred
- **CITY**: the city associated to the incident block location
- ZIP_CODE: the zip code associated to the incident block location
- ID: Unique identifier for internal database

**$raw_data/Criminal/New York City.csv**  
These data contain all police cases reported in New York City from 2006 to 2023 (downloaded 7/2/2024).

- N: 6,804,659 (years 2010+); 8,914,838 (raw)
- SH: 12,151 (years 2010+)
- SA: 84,287 (years 2010+)
- **CMPLNT_NUM**: Randomly generated persistent ID for each complaint
- ADDR_PCT_CD: The precinct in which the incident occurred
- BORO: The name of the borough in which the incident occurred
- **COMPLNT_FR_DT**: Exact date of occurrence for the reported event
- COMPLNT_FR_TM: Exact time of occurrence for the reported event
- COMPLNT_TO_DT: Ending date of occurrence for the reported event, if exact time of occurrence is unknown
- COMPLNT_TO_TM: Ending time of occurrence for the reported event, if exact time of occurrence is unknown
- CRM_ATPT_CPTD_CD: Indicator of whether crime was successfully completed or attempted, but failed or was interrupted prematurely
- HADEVELOPT: Name of NYCHA housing development of occurrence, if applicable
- HOUSING_PSA: Development Level Code
- JURISDICTION_CODE: Jurisdiction responsible for incident. Either internal, like Police(0), Transit(1), and Housing(2); or external(3), like Correction, Port Authority, etc.
- JURIS_DESC: Description of the jurisdiction code
- **KY_CD**: Three digit offense classification code
- LAW_CAT_CD: Level of offense: felony, misdemeanor, violation
- LOC_OF_OCCUR_DESC: Specific location of occurrence in or around the premises; inside, opposite of, front of, rear of
- **OFNS_DESC**: Description of offense corresponding with key code
- PARKS_NM: Name of NYC park, playground or greenspace of occurrence, if applicable (state parks are not included)
- PATROL_BORO: The name of the patrol borough in which the incident occurred
- PD_CD: Three digit internal classification code (more granular than Key Code)
- PD_DESC: Description of internal classification corresponding with PD code (more granular than Offense Description)
- PREM_TYP_DESC: Specific description of premises; grocery store, residence, street, etc.
- **RPT_DT**: Date event was reported to police
- STATION_NAME: Transit station name
- SUSP_AGE_GROUP: Suspect’s Age Group
- SUSP_RACE: Suspect’s Race Description
- SUSP_SEX: Suspect’s Sex Description
  - D: Business/Organization
  - E: PSNY/People of the State of New York
  - F: Female
  - L: ?
  - M: Male
  - U: Unknown
- TRANSIT_DISTRICT: Transit district in which the offense occurred
- VIC_AGE_GROUP: Victim’s Age Group
- VIC_RACE: Victim’s Race Description
- VIC_SEX: Victim’s Sex Description
- X_COORD_CD: X-coordinate for New York State Plane Coordinate System, Long Island Zone, NAD 83, units feet (FIPS 3104)
- Y_COORD_CD: Y-coordinate for New York State Plane Coordinate System, Long Island Zone, NAD 83, units feet (FIPS 3104)
- Latitude: Midblock Latitude coordinate for Global Coordinate System, WGS 1984, decimal degrees (EPSG 4326)
- Longitude: Midblock Longitude coordinate for Global Coordinate System, WGS 1984, decimal degrees (EPSG 4326)

**$raw_data/Criminal/Seattle.csv**  
These data contain all police cases reported in Seattle from 2008 to 2024 (downloaded 7/1/2024).

- N: 998,545 (years 2010+); 1,128,357 (raw)
- SH: 183 (years 2010+)
- SA: 6,781 (years 2010+)
- Report Number: Primary key/UID for the overall report; one report can contain multiple offenses, as denoted by the Offense ID
- **Offense ID**: Distinct identifier to denote when there are multiple offenses associated with a single report
- **Offense Start DateTime**: Start date and time the offense(s) occurred
- Offense End DateTime: End date and time the offense(s) occurred, when applicable
- **Report DateTime**: Date and time the offense(s) was reported. (Can differ from date of occurrence)
- Group A B: Corresponding offense group
- Crime Against Category: Corresponding offense crime against category
- **Offense Parent Group**: Corresponding offense parent group
- **Offense**: Corresponding offense
- **Offense Code**: Corresponding offense code
- Precinct: Designated police precinct boundary where offense(s) occurred
- Sector: Designated police sector boundary where offense(s) occurred
- Beat: Designated police beat boundary where offense(s) occurred
- MCPP Neighborhood: Designated Micro-Community Policing Plans (MCPP) boundary where offense(s) occurred
- Blurred Address: Offense(s) address location blurred to the one hundred block
- Blurred Longitude Coordinate: Offense(s) spatial coordinate blurred to the one hundred block
- Blurred Latitude Coordinate: Offense(s) spatial coordinate blurred to the one hundred block

**$raw_data/Criminal/Tucson `year`.csv**  
These data contain all police cases reported in Tucson from 2010 to 2023 (downloaded 7/2/2024). Currently missing years 2013 and 2017, emailed for data files.

- N: 1,668,669 (dropping empty cases and cases not in Tucson); 1,700,820 (raw)
- SH: 4,007 (dropping empty cases and cases not in Tucson)
- SA: 4,867 (dropping empty cases and cases not in Tucson)
- OBJECTID: Record identifier
- PrimaryKey: Record identifier
- **INCI_ID**: Incident report number
- **DATE_REPT**: Date the incident was reported
- HOUR_REPT: Time the incident was reported
- DATETIME_REPT: Date and time (combined) incident was reported
- MONTH_REPT: Month the incident was reported
- YEAR_REPT: Year the incident was reported
- DOW_REPT: Day of week the incident was reported
- TIME_REPT: Hour the incident was reported
- **DATE_OCCU**: Date the incident occurred
- HOUR_OCCU: Time the incident occurred
- DATETIME_OCCU: Date and time (combined) incident occurred
- MONTH_OCCU: Month the incident occurred
- MONTH_OCCU_STRING: Month the incident occurred (string)
- YEAR_OCCU: Year the incident occurred
- DOW_OCCU: Day of week the incident occurred
- DOW_OCCU_STRING: Day of week the incident occurred (string)
- TIME_OCCU: Hour the incident occurred
- DATE_FND: Date the incident ended
- HOUR_FND: Time the incident ended
- ADDRESS_PUBLIC: Incident location
- X: X-coordinate where the incident occurred (point_x in 2011-2012)
- Y: Y-coordinate where the incident occurred (point_y in 2011-2012)
- TRSQ: NESW quadrant location
- city (2014+: cwity_geo): the city associated to the incident location
- state: the state associated to the incident location
- zip: Zip code where incident occurred
- agency: Agency responsible for handling the incident
- WARD: The ward where the incident occurred
- NHA_NAME: Housing association where incident occurred
- PARCEL_USE_DESC, PARCEL_CATEGORY, PARCEL_GRP, TPD_PARCEL: Descriptions of the premise where the incident occurred
- CENSUSTRACT, CENSUSBLOCK: Census location where the incident occurred
- DIVISION, INITIALS, EMDIVISION (duplicate), DIVISION_NO, DIV_NO (duplicate), DIVSECT, NEIHGBORHD (duplicate), INITIALS: Police division where the incident occurred
- UCRsummary: Code for offense (general)
- **OFFENSE**: Code for offense (specific)
- WEAPON1DESC: Description of first weapon
- WEAPON2DESC: Description of second weapon
- WEAPON_CATEGORY: Category of first weapon
- NHA_NAME: Neighborhood and Housing Association name
- Crime: hierarchy that follows the guidelines of the FBI Uniform Crime Reporting
- CrimeCategory: Category of crime
- **CrimeType**: Type of crime
- UCRVerbose (2014+): Description for crimes identified by the FBI as part of its Uniform Crime Reporting program
- reportedas: What the incident was reported as
- **STATUSDESC**, Statute, StatuteDescription (duplicate): Description of offense
- CLEARANCE_DATE: Date crime was solved
- csstatus, CMStatusDescription, clearance_verbose: Whether crime was solved
- Method, MethodDesc: How crime was solved
- loc_status, secure, replace, webreport, datasource, loc_method: Other metadata variables

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

The two clean datasets containing criminal data are clean_criminal_cases.dta and clean_nibrs_cases.dta

### clean_criminal_cases.dta

The following variables are cleaned separately for each city.

#### Crime type

`crime_type == Sexual assault` if the crime includes physical contact.

- Rape
- Sodomy
- Sexual assault

`crime_type == Sexual harrassment` if the crime does not include physical contact.

- Stalking
- Indecent exposure
- Window peeping
- Public lewdness

`crime_type == Excluded crime` if the crime is not directly affected by the MeToo movement but could be indirectly related to it.

- Bestiality
- Bigamy
- Sex crimes against children
- Domestic/dating violence
- Harrassment of unclear nature
- Incest
- Pornography
- Prostitution
- Registration of sexual offenders

`crime_type == Non-sex crime` for all other crimes.

#### Sexual harassment

`sh == 1` if `crime_type` is Sexual harassment.  
`sh == 0` otherwise

#### Sex-based cases

`sex_cases == 1` if `crime_type` is Sexual harassment or Sexual assault.  
`sex_cases == 0` otherwise.

#### Clearance

`clearance == 1` if the case was cleared by arrest or exception  
`clearance == 0` if the case was not cleared

#### Victim female

`victim_f = 1` if complainant/victim is female  
`victim_f = 0` if complainant/victim is male  
`victim_f = .` if missing data on complainant gender

The following variables are cleaned altogether, after city data is appended together.

#### Overlap

`overlap == 1` if `sex_cases == 1` and case filed before MeToo and resolved after MeToo  
`overlap == 0` if `sex_cases == 1` and case filed before MeToo and resolved before MeToo  
`overlap == .` if `sex_cases == 0`  
`overlap == .` if case filed after MeToo

#### Treat

`post = 1` if file date after MeToo.  
`post = 0` if file date before MeToo.  
`post = .` never

`treat = post*sex_cases`  
`treat = 1` if `overlap == 1` since overlap cases are sex cases AND treated, but definition of post doesn't capture them.

### clean_nibrs_cases.dta

#### Crime type

`crime_type == Sexual assault` if `crime_code` is 111, 112, 113, 114, or 362, leading to:
- Rape
- Sodomy
- Sexual Assault with an Object
- Forcible Fondling
- Statutory Rape

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

#### Sex-based cases

`sex_cases == 1` if `crime_type == Sexual assault`
`sex_cases == 0` if `crime_type ==  Non-sex crime`
`sex_cases == .` if `crime_type ==  Excluded crime`

#### Sexual harassment cases

`sh == .` always, since no sexual harassment cases are reported to NIBRS

#### Clearance

`clearance == 1` if the case was marked as cleared by arrest or cleared by prosecution deciding not to prosecute
`clearance == 0` if the case is not marked as resulting in arrest or exceptional clearance - per FBI this means that the case is marked as not cleared
`clearance == .` if the case was cleared exceptionally for any other reason

#### Victim_f

`victim_f == 1` if any victim of the case is female
`victim_f == 0` if all victims are male
`victim_f == .` if no data is available

#### Court

`court == 1` if the case went to court
`court == 0` otherwise

#### Overlap

`overlap == 1` if `sex_cases == 1` and case filed before MeToo and resolved after MeToo
`overlap == 0` if `sex_cases == 1` and case filed before MeToo and resolved before MeToo
`overlap == .` if `sex_cases == 0`  
`overlap == .` if case filed after MeToo

#### Treat

`post = 1` if file date after MeToo.  
`post = 0` if file date before MeToo.  
`post = .` never

`treat = post*sex_cases`  
`treat = 1` if `overlap == 1` since overlap cases are sex cases AND treated, but definition of post doesn't capture them.
