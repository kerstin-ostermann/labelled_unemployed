/*******************************************************************************
Tasks: 
- prepare information on children
*******************************************************************************/

***Präambel***
*Log-File
cap log close log_child
log using "$log\06_child.log", name(log_child) replace

*Datensatz laden
use "$orig_bef\KINDER.dta", clear
*************

***age of children in HH
tab 			alter, mis
tab 			alter, mis nol
recode 			alter -8 -4 -2 -1=., gen(age_child)
drop 			alter

***restrict data on wave 7 only
drop 			if welle!=7

***number of children per HH
bysort hnr: 	gen childnum=_n
bysort hnr: 	gen childsum=_N
tab1 			childnum childsum

***Indicators for children under 4 years, between 4 and 9 as well as 10 and 17 years
gen 			child_3=0
replace 		child_3=1 if age_child<4
forvalue		x=1(1)7 {
	bysort hnr: replace child_3=1 if age_child[_n+`x']<4
}

gen 			child_4_9=0
replace 		child_4_9=1 if age_child>=4 & age_child<10
forvalue		x=1(1)7 {
	bysort hnr: replace child_4_9=1 if age_child[_n+`x']>=4 & age_child[_n+`x']<10
}

gen 			child_10_17=0
replace 		child_10_17=1 if age_child>=10 & age_child<18
forvalue		x=1(1)7 {
	bysort hnr: replace child_10_17=1 if age_child[_n+`x']>=10 & age_child[_n+`x']<18
}

***Keep only the first row of HH to creat a HH-level dataset
keep 			if childnum==1
tab1 			child_*

save			"$data\DM_child.dta", replace

log close 		log_child
