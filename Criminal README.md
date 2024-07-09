# MeToo Criminal City Data

## Description of datasets

**$raw_data/Criminal/Austin.csv**  
These data contain all police cases reported in Austin from 2003 to 2024 (downloaded 7/1/2024).
- N: 1,558,273 (years 2010+); 2,477,359 (raw)
- SH: 5,601 (years 2010+)
- Incident number: Incident report number
- Highest Offense Description: Description of crime
- Highest Offense Code: Code for crime
- Family Violence: Family violence indicator (Y/N)
- Occurred Date Time: Date and time (combined) incident occurred
- Occurred Date: Date the incident occurred
- Occurred Time: Time the incident occurred
- Report Date Time: Date and time (combined) incident was reported
- Report Date: Date the incident was reported
- Report Time: Time the incident was reported
- Location Type: General description of the premise where the incident occurred
- Address: Incident location
- Zip code: Zip code where incident occurred
- Council District: Austin city council district where the incident occurred
- APD Sector: APD sector where incident occurred
- APD District: APD district where incident occurred
- PRA: APD police reporting area where incident occurred
- Census Tract: Census tract where incident occurred
- Clearance Status: How/whether crime was solved
  - C: Cleared by Arrest
  - O: Cleared by Exception
  - N: Not cleared
- Clearance Date: Date crime was solved
- UCR Category: Code for the most serious crimes identified by the FBI as part of its Uniform Crime Reporting program
- Category Description: Description for the most serious crimes identified by the FBI as part of its Uniform Crime Reporting program
- X-coordinate: X-coordinate where the incident occurred
- Y-coordinate: Y-coordinate where the incident occurred
- Latitude: Latitude where incident occurred
- Longitude: Longitude where the incident occurred
- Location: 3rd party generated spatial column

**$raw_data/Criminal/Chicago.csv**  
These data contain all police cases reported in Chicago from 2001 to 2024 (downloaded 7/9/2024).
- N: 4,024,193 (years 2010+); 8,101,448 (raw)
- SH: 7,974 (years 2010+)
- ID: Unique identifier for the record
- Case Number: The Chicago Police Department RD Number (Records Division Number), which is unique to the incident
- Date: Date when the incident occurred (best estimate)
- Block: The partially redacted address where the incident occurred, placing it on the same block as the actual address
- IUCR: The Illinois Uniform Crime Reporting code
- Priamry Type: The primary description of the IUCR code
- Description: The secondary description of the IUCR code, a subcategory of the primary description
- Location Description: Description of the location where the incident occurred
- Arrest: Indicates whether an arrest was made (true/false)
- Domestic: Indicates whether the incident was domestic-related as defined by the Illinois Domestic Violence Act (true/false)
- Beat: Indicates the beat where the incident occurred
- District: Indicates the police district where the incident occurred
- Ward: The ward (City Council district) where the incident occurred
- Community Area: Indicates the community area where the incident occurred
- FBI Code: Indicates the crime classification as outlined in the FBI's National Incident-Based Reporting System (NIBRS)
- X Coordinate: The x coordinate of the location where the incident occurred in State Plane Illinois East NAD 1983 projection
- Y Coordinate: The y coordinate of the location where the incident occurred in State Plane Illinois East NAD 1983 projection
- Year: Year the incident occurred
- Updated On: Date and time the record was last updated
- Latitude: The latitude of the location where the incident occurred
- Longitude: The longitude of the location where the incident occurred
- Location: The location where the incident occurred in a format that allows for creation of maps and other geographic operations on this data portal

**$raw_data/Criminal/Denver.csv**  
These data contain all police cases reported in Denver from 2019 to 2024 (downloaded 7/2/2024). (not currently used)
- N:
- SH:
- 

**$raw_data/Criminal/Kansas City `year`.csv**  
These data contain all police cases reported in Kansas City from 2015 to 2024 (downloaded 7/2/2024).
- N:
- SH:
- 

**$raw_data/Criminal/Los Angeles.csv**  
These data contain all police cases reported in Los Angeles from 2005 to 2024 (downloaded 7/2/2024).
- N:
- SH:
- 

**$raw_data/Criminal/Louisville `year`.csv**  
These data contain all police cases reported in Louisville from 2010 to 2024 (downloaded 7/2/2024).
- N:
- SH:
- 

**$raw_data/Criminal/New York City.csv**  
These data contain all police cases reported in New York City from 2006 to 2024 (downloaded 7/2/2024).
- N:
- SH:
- 

**$raw_data/Criminal/Seattle.csv**  
These data contain all police cases reported in Seattle from 2008 to 2024 (downloaded 7/1/2024).
- N: (years 2010+); 1,128,357 (raw)
- SH: (years 2010+)
- Report Number: Primary key/UID for the overall report; one report can contain multiple offenses, as denoted by the Offense ID
- Offense ID: Distinct identifier to denote when there are multiple offenses associated with a single report
- Offense Start DateTime: Start date and time the offense(s) occurred
- Offense End DateTime: End date and time the offense(s) occurred, when applicable
- Report DateTime: Date and time the offense(s) was reported. (Can differ from date of occurrence)
- Group A B: Corresponding offense group
- Crime Against Category: Corresponding offense crime against category
- Offense Parent Group: Corresponding offense parent group
- Offense: Corresponding offense
- Offense Code: Corresponding offense code
- Precinct: Designated police precinct boundary where offense(s) occurred
- Sector: Designated police sector boundary where offense(s) occurred
- Beat: Designated police beat boundary where offense(s) occurred
- MCPP Neighborhood: Designated Micro-Community Policing Plans (MCPP) boundary where offense(s) occurred
- Blurred Address: Offense(s) address location blurred to the one hundred block
- Blurred Longitude Coordinate: Offense(s) spatial coordinate blurred to the one hundred block
- Blurred Latitude Coordinate: Offense(s) spatial coordinate blurred to the one hundred block

**$raw_data/Criminal/Tucson `year`.csv**  
These data contain all police cases reported in Tucson from 2009 to 2024 (downloaded 7/2/2024).
- N:
- SH:
- 

## Variable Definitions Guide

The following variables are cleaned separately for each city.

### Crime type
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

### Sexual harassment
`sh == 1` if `crime_type` is Sexual harassment.  
`sh == 0` otherwise  

### Sex-based cases
`sex_cases == 1` if `crime_type` is Sexual harassment or Sexual assault.  
`sex_cases == 0` otherwise.  

### Clearance
`clearance == 1` if the case was cleared by arrest or exception  
`clearance == 0` if the case was not cleared  

The following variables are cleaned altogether, after city data is appended together. 

### Overlap
`overlap == 1` if `sh == 1` and case filed before MeToo and resolved after MeToo  
`overlap == 0` if `sh == 1` and case filed before MeToo and resolved before MeToo  
`overlap == .` if `sh == 0`  
`overlap == .` if case filed after MeToo  

### Treat
`post = 1` if file date after MeToo.   
`post = 0` if file date before MeToo.    
`post = .` never  

`treat = post*sh`  
`treat = .` if `sex_cases == 1 & sh == 0`, since we don't want the control group to include potentially treated sex cases that are not sexual harassment.  
`treat = 1` if `overlap == 1` since overlap cases are sh AND treated, but definition of post doesn't capture them.  
