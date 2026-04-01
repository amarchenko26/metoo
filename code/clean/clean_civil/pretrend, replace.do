insheet using pretrend, replace.csv

twoway (scatter r_dhi r_fhat, mcolor(navy) lcolor(maroon)) (function 0*x^2+-.0001826083293861*x+-.0002986511119958, range(-3.619961050472718 3.424080400577967) lcolor(maroon)), graphregion(fcolor(white))  xtitle(r_fhat) ytitle(r_dhi) legend(off order())
