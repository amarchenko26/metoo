# MeToo Project README

## File guide

### On GitHub
#### README Files
- **$droot/Civil README.md**: Read me file for civil complaint data. Contains variable definitions, description of datasets by state.
   - Currently contains information on EEOC filed cases (2011-2017) (excluded from analysis), EEOC court cases (2010-2022) (excluded from analysis), AK, CA, DE, FL, GA (unusable), HI, IL, KY, MA, MD (unusable), MI, MN (unsuable), MT, NC, ND, NY, PA (unusable), RI, TX, WA, WI.
#### Python Files
- **$droot/code/clean/python/ocr.py**: Converts RI raw data PDFs into .txt format.
- **$droot/code/clean/python/txt_to_csv_ri.py**: Converts RI .txt files into .csv format.
- **$droot/code/clean/python/pdf_to_csv_state.py**: Converts CA, FL, IL, NY, TX raw data PDF into .csv format.
- **$droot/code/clean/python/clean_il_names.py**: Identifies gender of complainant in IL raw data based on complainant name.
#### Do Files
- **$droot/run_project.do**: Runs the entire MeToo project. Defines global variables, downloads packages, runs programs, clean, and analysis .do files.
- **$droot/code/programs/programs.do**: Runs programs, including for time series plots, balance tables, and creating time to treat variables.
#### Clean Do Files
- **$droot/code/clean/clean_civil/clean_`state_abbrev`.do**: Cleans raw/converted data of state `state_abbrev`.
  - Includes EEOC filed cases (2011-2017) (excluded from analysis), EEOC court cases (2010-2022) (excluded from analysis), AK, CA, DE, FL, GA (unusable), HI, IL, KY, MA, MD (unusable), MI, MN (unsuable), MT, NC, ND, NY, PA (unusable), RI, TX, WA, WI.
- **$droot/code/clean/clean_civil/merge_all.do**: Merges all cleaned state and EEOC data into one .dta file based on variable definitions in $droot/Civil README.md.
#### Analysis Do Files
- **$droot/code/analysis/analysis_civil/figures.do**: Creates figures based on civil data in MeToo project.
  - Includes tabulations, omega plot, event studies, time series, DIDs, placebo plots, duration plots, beta-hat.
- **$droot/code/analysis/analysis_civil/tables.do**: Creates tables based on civil data in MeToo project.
  - Includes DIDs, selection table, summary table, balance tables, duration and outcome correlation, unit trends, overlap placebo regression.

### On DropBox
- **$droot/data/raw/`state_abbrev`**: Contains folder with raw data of state `state_abbrev`.
  - Some states contain subfolders/multiple files for extracted files/PDFs if a Python code was needed to convert the data format (AK, CA, FL, IL, NY, RI, TX)
  - Some states contain multiple files based on jurisdiction (FL, GA, KY, ND, SC)
- **$droot/data/clean/clean_`state_abbrev`.dta**: Contains cleaned data of state `state_abbrev` after running $droot/code/clean/clean_civil/clean_`state_abbrev`.do.
- **$droot/data/clean/clean_cases.dta**: Contains cleaned data of merged dataset after running $droot/code/clean/clean_civil/merge_all.do.

### On Google Drive
- **MeToo/FOIA Requests (2023-24)/EEOC Correspondence (2023)**: Documents all correspondence with EEOC with regards to FOIA requests, including requests, determinations, appeals.
- **MeToo/FOIA Requests (2023-24)/State Correspondence (2024)/`state_abbrev`**: Documents all correspondence with state `state_abbrev` with regards to FOIA requests, including requests, acknowledgments, responses, clarifications, attached files.
- **MeToo/FOIA Requests (2023-24)/State FOIA Requests (2023)**: Documents copies of all FOIA requests sent to individual states based on contact information in MeToo/FOIA Requests (2023-24)/FOIA tracker.
- **MeToo/FOIA Requests (2023-24)/FOIA Tracker**: Tracks where civil complaint data was collected from, including agency websites, individual contact information, FOIA status, data notes.
- **MeToo/FOIA Requests (2023-24)/FOIA call script**: Sample dialogue to use when making a FOIA request via phone call.
- **MeToo/FOIA Requests (2023-24)/data protocol**: Steps to follow after receiving FOIA data.
- **MeToo/Complaint flow**: Diagram of civil complaint outcomes.
- **MeToo/MeToo RA Tasks**: Running list of tasks to complete each weekly meeting.

### On OverLeaf
- **$droot/output/figures**: Contains figures in .png format after running $droot/code/analysis/analysis_civil/figures.do.
- **$droot/output/tables**: Contains tables in .tex format after running $droot/code/analysis/analysis_civil/tables.do.

### Files currently not in use
#### On GitHub
- **$droot/Criminal README.md**: Read me file for criminal complaint data. Contains variable definitions
   - Currently contains information on Austin, Chicago, Denver, Kansas City, Los Angeles, Louisville, New York City, Seattle, Tucson, and federal NIBRS data.
- **$droot/code/clean/python/pdf_to_csv_eeoc.py**: Code to convert EEOC court case raw data PDF into .csv format.
- **$droot/code/clean/python/severity_rankings.py**: Code to classify PA, RI raw data cases by severity rankings.
- **$droot/code/clean/python/il_text_analysis.py**: Code to classify IL raw data cases by severity rankings.
- **$droot/code/clean/python/webscrape_pdfs.py**: Code to scrape AK, IL, MI websites for case file PDFs.
- **$droot/code/clean/clean_criminal/clean_`city_name`.do**: Cleans raw data of city `city_name`.
- **$droot/code/clean/clean_criminal/merge_city_all.do**: Merges all cleaned city criminal data into one .dta file based on variable definitions in $droot/Criminal README.md.
- **$droot/code/analysis/analysis_criminal/figures_city.do**: Creates figures based on civil data in MeToo project.
  - Includes event studies, time series.
- **$droot/code/analysis/analysis_criminal/tables_city.do**: Creates tables based on civil data in MeToo project.
  - Includes event studies, time series.
- **$droot/code/analysis/analysis_criminal/figures_nibrs.do**: Creates figures based on civil data in MeToo project.
  - Includes DIDs, summary table, balance table.
- **$droot/code/analysis/analysis_criminal/tables_nibrs.do**: Creates tables based on civil data in MeToo project.
  - Includes DIDs, summary table, balance table.

#### On DropBox
- **$droot/data/raw/Criminal**: Folder with raw data of criminal complaints.
- **$droot/data/clean/clean_`city_name`.dta**: Contains cleaned data of city `city_name` after running $droot/code/clean/clean_criminal/clean_`city_name`.do.
- **$droot/data/clean/clean_criminal_cases.dta**: Contains cleaned data of merged dataset after running $droot/code/clean/clean_criminal/merge_city_all.do.

#### On Google Drive
- **MeToo/FOIA Requests (2023-24)/City Criminal Data Tracker**: Tracks where criminal complaint data was collected from, including agency websites, data notes.

## Future To-Dos
- Usable raw data on SC is available but hasn't been cleaned and incorporated into the project yet.

## Contact

Contact maggie_jiang@alumni.brown.edu for questions.
