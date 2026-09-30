***Präambel***
set r 		on

*Log-File
cap log close 
log using "$log\09_check_selectivity.log", replace

*Datensatz laden
use	"$data\DM_comp.dta", clear
**************

//flag missings
gen mis_stig = (stig_con>=.)
tab mis_stig, m

regress mis_stig unemp_quo ///
				i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c ///
				i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
				daily_wage_med n urban  n_est_close_5yrs alq  moved ///
				i.subhealth i.mig i.educ_kat 
est sto m_bias


//label 
lab var  unemp_quo "Share of unemployed" 
lab var female "Female, ref. male"
lab define female 0 "Male" 1 "Female"
lab value female female

lab var child_3 "Children below 3"
lab var child_4_9 "Children between 4 & 9"
lab var child_10_17 "Children between 10 & 17"
lab var unemp_cur_n_c "Unemployment duration"
lab define unemp_ep_ord 0 "1 unemployment episode" 1 "2 unemployment episodes" 2 "3+ unemployment episodes"
lab value unemp_ep_ord unemp_ep_ord

lab var age_c "Age"
lab var care "Care responsibility"
lab var mig "Migration background, ref. native German"
lab var stig_con "Stigma consciousness"
lab var subhealth "Poor subjective health"
lab define health 0 "Poor health" 1 "(Very good) health"
lab value subhealth health 
lab define educ_kat 1 "ISCED 1 & 2" 2 "ISCED 3 & 4" 3 "ISCED 5 & 6", modify
lab value educ_kat educ_kat

lab var depindug2_c "Centered household income" 
lab var ln_oecdincn_c "Log. household income" 
lab var search "Job search obligation" 
lab define leistbez 0 "Receives no benefits" 1 "Receives short-term benefits (UB1)" ///
	2 "Receives UBII"
lab value leistbez leistbez
	

lab var n_est_close_5yrs "Firm closures in neighbourhood, last 5 years"
lab var urban "Lives in urban county"
lab var leistbez "Benefit receipt" 
lab var daily_wage_med "Neighborhood mean wage"
lab var n "Number of neighborhood residents"

coefplot m_bias, xline(0) label ///
	drop(_cons)  xtitle("Missing in stigma consciousness")
graph export "${out}\Missing_selectivity.pdf", replace as(pdf)

log close	