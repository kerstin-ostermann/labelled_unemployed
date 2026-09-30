/*******************************************************************************
Tasks: 
- saving a data set just containing personal, household and year identifer

*******************************************************************************/

***Präambel***
*Log-File
cap log close log_DM_pintdat
log using "$log\01_pintdat.log", name(log_DM_pintdat) replace

use "$orig_bef\PENDDAT.dta", clear
*************

***Interviewdatum Welle 7 pro Person
tab1 		pintjahr pintmon, nol
gen 		pintdat_n=ym(pintjahr, pintmon)
format 		%tm pintdat_n

keep 		if welle==7
display "Number of observations: "_N
keep 		pnr hnr pintdat_n pintjahr pintmon

save 		"$data\pintdat_w7.dta", replace

log close 	log_DM_pintdat
