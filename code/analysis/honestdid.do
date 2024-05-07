/*******************************************************************************
Honest DiD implementing Rambachan & Roth (2021)

package honestdid from: https://github.com/mcaceresb/stata-honestdid

*******************************************************************************/

use "$clean_data/clean_cases.dta", replace

/*******************************************************************************
Prep data 
*******************************************************************************/

drop if ym < 606 // drop cases before Jan 2010

/*******************************************************************************
Do honestdid
*******************************************************************************/



honestdid, coefplot cached
honestdid, coefplot cached xtitle(Mbar) ytitle(95% Robust CI)
graph export "$figures/honest_did.png", replace
