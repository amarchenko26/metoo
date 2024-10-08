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
global data_start "01june2010"
global data_cutoff "01june2023"

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
ssc install coefplot, replace
ssc install addplot, replace
net install parallel, from(https://raw.github.com/gvegayon/parallel/stable) replace
*/

/*******************************************************************************
Run files
*******************************************************************************/

// programs
do "$droot/code/programs/programs.do"

// cleaning files
do "$droot/code/clean/clean_civil/clean_eeoc.do"
do "$droot/code/clean/clean_civil/clean_eeoc_filed.do"
do "$droot/code/clean/clean_civil/clean_ak.do"
do "$droot/code/clean/clean_civil/clean_hi.do"
do "$droot/code/clean/clean_civil/clean_il.do"
do "$droot/code/clean/clean_civil/clean_ky.do"
do "$droot/code/clean/clean_civil/clean_ma.do"
do "$droot/code/clean/clean_civil/clean_mi.do"
do "$droot/code/clean/clean_civil/clean_mn.do"
do "$droot/code/clean/clean_civil/clean_nd.do"
do "$droot/code/clean/clean_civil/clean_pa.do"
do "$droot/code/clean/clean_civil/clean_ri.do"
do "$droot/code/clean/clean_civil/clean_tx.do"
do "$droot/code/clean/clean_civil/clean_wa.do"
do "$droot/code/clean/clean_civil/clean_wi.do"
do "$droot/code/clean/clean_civil/merge_all.do"

// analysis files
do "$droot/code/analysis/analysis_civil/tables.do"
do "$droot/code/analysis/analysis_civil/figures.do"
do "$droot/code/analysis/analysis_civil/sdid.do"
