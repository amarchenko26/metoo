/*******************************************************************************

 Author: Anya Marchenko, Brown University, marchenko@brown.edu
 Date: 1 April 2024

 This is the Master .do file which runs the MeToo project 

*******************************************************************************/

 
clear all
version 18.0

set graphics off 
set scheme plotplainblind  
pause on // type end or q in command to resume code after pause

/*******************************************************************************
Define globals
*******************************************************************************/

global sh_color "amber" 
global no_sh_color "dark gray"
global metoo "15oct2017"

/*******************************************************************************
Define folders
*******************************************************************************/

// UPDATE WITH YOUR PATH TO RUN PROJECT
gl droot "/Users/anyamarchenko/Documents/GitHub/metoo" 

/*Make sure you have Dropbox folder with data stored within /metoo, like /metoo/data
Dropbox access granted separately, email Anya */

// DON'T TOUCH
gl raw_data 	"$droot/data/raw"
gl clean_data 	"$droot/data/clean"
gl figures 		"$droot/output/figures"
gl tables 		"$droot/output/tables"


/*******************************************************************************
Required packages - uncomment to install
*******************************************************************************/

/*
ssc install balancetable
ssc install binscatter 
ssc install outreg // for frmttable 
ssc install winsor
ssc install sdid, replace // for synthetic DiD, https://github.com/Daniel-Pailanir/sdid
ssc install honestdid, replace // https://github.com/mcaceresb/stata-honestdid
*/

/*******************************************************************************
Run files
*******************************************************************************/

// programs
do "$droot/code/programs/time_to_treat.do"

stop 

// cleaning files
do "$droot/code/clean/clean_ma.do"
do "$droot/code/clean/clean_eeoc_filed.do"
do "$droot/code/clean/merge_state_data.do"

// analysis files
do "$droot/code/analysis/tables.do"
do "$droot/code/analysis/figures.do"
