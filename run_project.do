/*******************************************************************************

 Author: Anya Marchenko, Brown University, marchenko@brown.edu
 Date: 1 April 2024

 This is the Master .do file which runs the MeToo project 

*******************************************************************************/

clear all
version 18.0

set graphics off 
set scheme cblind1  
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

if "`c(username)'" == "anyamarchenko"{
	gl droot "/Users/anyamarchenko/Documents/GitHub/metoo" 
}
if "`c(username)'" == "maggie"{
	gl droot = "/Users/maggie/Desktop/metoo"
}
if "`c(username)'"=="jacobhirschhorn"{
	gl droot = "/Users/jacobhirschhorn/Desktop/College/metoo"
}


/* Make sure you have Dropbox folder with data stored within /metoo, like /metoo/data
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
ssc install estout
ssc install schemepack, replace //for graph schemes, https://github.com/asjadnaqvi/stata-schemepack?tab=readme-ov-file
ssc install balancetable
ssc install binscatter 
ssc install outreg // for frmttable 
ssc install winsor
ssc install sdid, replace // for synthetic DiD, https://github.com/Daniel-Pailanir/sdid
ssc install honestdid, replace // https://github.com/mcaceresb/stata-honestdid
include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"

*/

/*******************************************************************************
Run files
*******************************************************************************/

// programs
do "$droot/code/programs/programs.do"

// cleaning files
do "$droot/code/clean/clean_eeoc.do"
do "$droot/code/clean/clean_ma.do"
do "$droot/code/clean/clean_eeoc_filed.do"
do "$droot/code/clean/merge_all.do"

// analysis files
do "$droot/code/analysis/tables.do"
do "$droot/code/analysis/figures.do"
