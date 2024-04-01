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

// for colors
global sh_color "133 2 249" //purple for women
global no_sh_color "0 196 170" //green for men


/*******************************************************************************
Define folders
*******************************************************************************/

gl droot "/Users/anyamarchenko/Documents/GitHub/metoo" // UPDATE THIS

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

do "$drootbaby/code/clean/clean_ma_cases.do"



