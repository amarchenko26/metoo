/*******************************************************************************

 Author: Anya Marchenko, Brown University, marchenko@brown.edu
 Date: 1 April 2024

 This is the Master .do file which runs the MeToo project 

*******************************************************************************/

 
clear all
version 18.0

set graphics off 
set scheme plotplainblind  

/*******************************************************************************
Define globals
*******************************************************************************/

global sh_color "amber" 
global no_sh_color "dark gray"


/*******************************************************************************
Define folders
*******************************************************************************/

// UPDATE WITH YOUR PATH TO RUN PROJECT
gl droot "/Users/anyamarchenko/Documents/GitHub/metoo" 

// DON'T TOUCH
gl raw_data "$droot/data/raw"
gl clean_data "$droot/data/clean"
gl figures "$droot/output/figures"


/*******************************************************************************
Required packages - uncomment to install
*******************************************************************************/

/*
ssc install binscatter 
ssc install outreg (for frmttable) 
*/


/*******************************************************************************
Run files
*******************************************************************************/

// cleaning files
do "$drootbaby/code/clean/clean_ma_cases.do"
do "$drootbaby/code/clean/merge_state_data.do"


// analysis files
do "$drootbaby/code/analysis/figures.do"