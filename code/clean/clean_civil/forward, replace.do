insheet using forward, replace.csv

twoway (scatter r_fhi r_Dhat, mcolor(navy) lcolor(maroon)) (function 0*x^2+.0018775241041527*x+-.0009210434810765, range(-3.71541728639882 3.431105579877949) lcolor(maroon)), graphregion(fcolor(white))  xtitle(r_Dhat) ytitle(r_fhi) legend(off order())
