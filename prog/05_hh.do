/*******************************************************************************
Tasks: 
- prepare household level variables (such as household income, deprivation)
*******************************************************************************/
***Präambel***
*Log-File
cap log close log_HH
log using "$log\05_HH.log", name(log_HH) replace

*Datensatz laden
use "$orig_bef\HHENDDAT.dta", clear
*************

***Deprivation***
*ab HLS0100a bis HLS2600a
*deprivation index: ungewichtet depindug2 gewichtet depindg2
tab 		depindug2, mis
tab			depindug2, mis nol
recode 		depindug2 -5=.
			
***HH income***
*open answer: HEK0600
*categorized ab: HEK0800
*generated: hhinckat oder hhincome
tab			hhincome if hhincome < 1
tab			hhincome if hhincome < 1, nol
recode		hhincome -8/-1=. 
sum			hhincome, d
hist		hhincome, norm
*Atention: zeros -> all values +1, then ln
gen			ln_hhinc=ln(hhincome+1)
hist		ln_hhinc, norm
sum			ln_hhinc, d

*categorization
tab 		hhinckat, mis
tab			hhinckat, mis nol
recode 		hhinckat -4/-1=. 2 3=2 4 5=3 6=4 7 8 9 13=5 10/12=., gen(hhinckat_1)
la def		kat_1 1"less than 500" 2"500-999" 3"1000-1999" 4"2000-2999" 5"3000 and more"
replace 	hhinckat_1=1 if hhincome<500
replace 	hhinckat_1=2 if hhincome>=500 & hhincome<=999
replace 	hhinckat_1=3 if hhincome>=1000 & hhincome<=1999
replace 	hhinckat_1=4 if hhincome>=2000 & hhincome<=2999
replace 	hhinckat_1=5 if hhincome>=3000
tab 		hhinckat_1

***household equivalent income (new OECD standard)
tab 		oecdincn if oecdincn<1
tab 		oecdincn if oecdincn<1, nol
tab 		oecdincn hhincome if oecdincn<1 | hhincome<1, mis

*drop cases with hhincome==0 | oecdincn==0
drop 		if hhincome==0 | oecdincn==0

sum 		oecdincn, d
hist 		oecdincn, norm
gen 		ln_oecdincn=ln(oecdincn)
hist 		ln_oecdincn, norm

***size of household
tab 		HA0100, mis
gen 		hhgr=HA0100

***ALGII***
tab 		alg2abez
tab 		alg2abez, nol
recode		alg2abez -5=. 2=0, gen(alg2_cur)
label var	alg2_cur "ALGII cur."

***children in HH
tab 		kindu25, mis
tab 		kindu25, mis nol
recode 		kindu25 -9=.

***size of town measure
tab 		bik, mis
tab 		bik, nol mis
recode 		bik -9/-2=. 1/2=1 3=2 4/6=3 7/10=4, gen(bikkat)
la var 		bikkat "Size of town"
la def 		bikkat 1 "rural community" 2 "small town" 3 "medium-sized town" 4 "large city"
la val 		bikkat bikkat

*save current status
save		"$data\DM_HH.dta", replace


log close 	log_HH
