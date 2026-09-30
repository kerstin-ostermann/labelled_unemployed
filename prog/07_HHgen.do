/*******************************************************************************
Tasks: 
- generate number of household members being employed
*******************************************************************************/

***Präambel***
*Log-File
cap log close log_HHgen
log using "$log\07_HHgen.log", name(log_HHgen) replace

use "$orig_bef\PENDDAT.dta", clear
*************

**How many household members are employed?
tab 		statakt
tab			statakt, nol
recode		statakt -10=0 -9 -5=. 1 12=1 2/11=0, gen(emp)
label var	emp "employed/self-employed"
tab			emp statakt, mis 

collapse	(sum) emp, by(hnr welle) 
gen			emp_hh_cur=emp if welle == 7
recode		emp_hh_cur 1/99=1
label var	emp_hh_cur "Employed in hh (1=yes)"
tab1 		emp_hh_cur

***save dataset
save		"$data\DM_HHgen.dta", replace
keep 		if welle==7
keep 		hnr welle emp_hh_cur

log close 	log_HHgen