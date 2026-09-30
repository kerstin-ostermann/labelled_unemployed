/*******************************************************************************
Tasks: 
- merge grid cell data on residential and workplace neighborhood composition (GridAB)
- merge wider neighborhood information (surrounding grids)
- create unemployment rate variables 
- prepare unemployment rate on county level 
*******************************************************************************/

***Präambel***
*Log-File
cap log close 
log using "$log\02_nh.log", name(log_DM_nh) replace
*************
set 		more off
*use 		"$data\Kreiskennziffer_Arbeitsmarktregionen.dta", clear

***PASS-ADIAB 7518 (v1)
use "${data}\pass_gridab_w7.dta", clear
tab year

//merge GridAB
sort geo_grid_cell year 

replace year = 2012
merge m:1 geo_grid_cell year  using "$orig\GridAB_home_cens.dta"
tab _merge
drop if _merge==2
count if _merge==1 
display "How many PASS resp. are not merged: " (r(N)/_N)*100 "%"

//merge est_close information 
sort geo_grid_cell
merge m:1 geo_grid_cell year  using "$orig\GridAB_work_all_cens5.dta", keepusing(n_est_close_5yrs) gen(_mergeEST)
drop if _merge==2
drop _mergeEST

replace n_est_close_5yrs = 0 if n_est_close_5yrs==. //those with missing have no companies in the neighborhood

*merge wider NH
merge m:1 geo_grid_cell year using "$widenh\GridAB_widernh.dta", gen(_merge_wnh)
drop if _merge_wnh==2
drop _merge_wnh

//cities with high and low income inequality
//Gini auf Gitterzellen-basis berechnen
* sort
sort year county  daily_wage_med

* compute auxiliary income and totals
by year county : gen g_wage = _n * daily_wage_med
by year county : egen total_g_wage = total(g_wage)
by year county : egen total_wage = total(daily_wage_med)

by year county : gen N = _N

* compute Gini coefficient = ([2* Summe(i*x(i))] / [_N * Summe(x(i))] ) - [(_N+1)/_N]
cap drop gini_daily_wage_med
by year county : gen gini_daily_wage_med = (2 * total_g_wage) / (N * total_wage) - ((N + 1) / N)

* set infinitesimal small negative values to zero (they should be zero but for computational reasons they are not)
replace gini_daily_wage_med = 0 if gini_daily_wage_med > -0.7 & gini_daily_wage_med < 0

* remove auxiliary variable 
drop g_wage total_g_wage total_wage

*check
sum gini_daily_wage_med if year==2012

*Gini-Koeffizient umbenennen
	lab var gini_daily_wage_med "Städtischer Gini-Koeffizient, Medianlöhne"

rename _merge _merge_nh
keep if _merge_nh ==3
replace year = 2013

*restrict variables
keep pnr year geo_grid_cell ///
	county lab_area n n_emp n_regemp n_not_emp n_not_emp_1yr ///
	n_ub1* n_ub2*  yearly_inc* daily_inc* daily_wage*  gini* daily_wage_med n_est_close_5yrs ///
	n_tenure* n_marginal n_parttime n_fulltime tenure_mean n_helpers n_foreign n_educ_low n_educ_high ///NH variables for imputation
	wnh_n_not_emp wnh_n_not_emp_1yr wnh_n_ub* wnh_tenure_mean wnh_n_helpers wnh_n_foreign wnh_n_educ_low wnh_n_educ_high //WNH variables (imputation and robustness check)
	
rename county kr_id_n
rename lab_area amr

***Variablen labeln
la var		kr_id_n "Kreiskennziffer"
la var 		amr "Arbeitsmarktregion (2014)"

***calculate share of unemployed and fulltime working people: check
gen 		sh_fulltime = n_fulltime / n_emp 
gen 		sh_ft_onall = n_fulltime / n 

gen 		unemp_quo = n_not_emp /n
la var 		unemp_quo "Unemployment quota in grid"
sum 		unemp_quo, d
hist 	unemp_quo

*centering
gen 		unemp_quo_c=unemp_quo-r(mean)

***save  current dataset
save 		"$data\regio_nh.dta", replace

********************************************************************************
//unemployment on labor market area level 
********************************************************************************
use "$data\LK_ALQ_2013.dta", clear 

gen krs15 = kreisnr *1000

//Göttingen
replace krs15 =3152000 if krs15==3159000

//merge
merge m:1  krs15 using ${orig}\Kreiskennziffer_Arbeitsmarktregionen.dta
drop if _merge==2

*local labor market areas
keep alq kreisnr amr 
bys amr: egen alq_amr = mean(alq)
sum alq_amr, d

*states
gen bula = int(kreisnr /1000)
bys bula: egen alq_bula = mean(alq)
sum alq_bula, d


save "$data\LK_AMR_ALQ_2013.dta", replace 





log close 	log_DM_nh
