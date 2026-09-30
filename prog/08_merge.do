/*******************************************************************************
Tasks: 
- merge all data sets to individual-level data 
- generate Kreis-specific means
- reduce to observations that should be imputed
- generate some variables on the neighborhood level 
*******************************************************************************/
***Präambel***
*Log-File
cap log close log_merge
log using "$log\08_merge.log", name(log_merge) replace
*************

***load individual Data
use 		"$data\DM_ind.dta", clear

***merge bio spells
merge 		1:1 pnr welle using "$data\DM_spells.dta", gen(_merge2)
tab 		stig_con _merge2, mis
keep		if _merge2==1 | _merge2==3

***merge HH data
merge 		m:1 hnr welle using "$data\DM_HH.dta", gen(_merge3)
tab 		stig_con _merge3, mis
keep		if _merge3==1 | _merge3==3

	***benefit receipt
	tab1 		alg1abez alg2abez, mis
	tab1 		alg1abez alg2abez, mis nol
	recode 		alg1abez -10/-3=., gen(algI)
	recode 		alg2abez -5=. 2=0, gen(algII)
	gen 		leistbez=.
	replace		leistbez=0 if algI==0 & algII==0
	replace		leistbez=1 if algI==1 & (algII==0 | algII==1)
	replace		leistbez=2 if algI==0 & algII==1
	la var 		leistbez "benefit receipt"
	la def 		leist 0"no benefits" 1"ALGI" 2"ALGII"
	la val 		leistbez leist
	tab 		leistbez algI, mis
	tab 		leistbez algII, mis


*correct obligation to search 
replace 	search=0 if alg2_cur == 0

***merge child data
merge 		m:1 hnr welle using "$data\DM_child.dta", gen(_merge4)
tab 		stig_con _merge4, mis
keep		if _merge4==1 | _merge4==3

*correct data on children
tab1 		age_child child_* kindu25
foreach 	var of varlist child_* {
	replace `var'=0 if kindu25==0
}
tab1 		child_*

***merge generated hh data
merge 		m:1 hnr welle using "$data\DM_HHgen.dta", gen(_merge6)
tab 		stig_con _merge6, mis
keep		if _merge6==1 | _merge6==3

**merge labor market area IDs 
gen kreisnr = kr_id
sort kreisnr
merge 		m:1 kreisnr using "$data\lab_areas2009-15.dta", gen(_merge7)
drop if _merge7==2
drop _merge7

**merge unemployment on county level
merge 		m:1 kreisnr using "$data\LK_AMR_ALQ_2013.dta", gen(_merge7)
drop if _merge7==2
drop _merge7

***generate Kreis-specific means
cap rename kr_id_n kr_id
foreach 	var of varlist 	female child_3 child_4_9 child_10_17 care age unemp_cur_n depindug2 ln_oecdincn search emp_hh_cur pisei friends_num subhealth_prev akt_pol akt_com akt_other {
	cap drop mean_`var'
	bysort kr_id: egen mean_`var'=mean(`var')
}

foreach 	var of varlist educ_kat mig unemp_ep_ord leistbez {
	tab 	`var', gen(`var'_)
	foreach var2 of varlist `var'_* {
		cap drop mean_`var2'
		bysort kr_id: egen mean_`var2'=mean(`var2')
		drop `var2'
	}
}

***reduce dataset to obs that should be imputed
keep 		if welle==7
drop 		if statakt==3 | statakt==4 | age>=65 | educ_kat==.a | stig_con>.

*drop 		if PRE_N<5 | unemp_quo==.
bysort kr_id: egen kr_id_N=count(pnr)
tab 		kr_id_N
drop if 	kr_id_N<5
*286 prs lost

***centering of continious variables
*individual level
foreach 	var of varlist age age2 pisei unemp_cur_n depindug2 ln_hhinc ln_oecdincn hhgr sat_gen sat_health sat_flat sat_std friends_num updown {
	cap drop `var'_c
	sum 	`var'
	gen 	`var'_c=`var'-r(mean)
}

*neighborhood level
cap drop 	n_nh
bysort 		geo_grid_cell: gen n_nh=_n
foreach 	var of varlist PRE_mean PRE_spr PRE_sep unemp_quo mean_* {
	cap drop `var'_c
	sum 	`var' if n_nh==1
	gen 	`var'_c=`var'-r(mean)
}

//merge Raumordnungsregionen (rural vs. urban)
cap drop krs15
gen krs15 = kr_id*1000
merge 		m:1 krs15 using "$orig\Kreiskennziffer_Raumordnungsregion.dta", update
drop if _merge==2
drop _merge

gen urban = (rtyp3==1) 
lab define urban 0 "Rural" 1 "Urban"
lab value urban urban

//mover vs stayer
gen moved = umzug == 1
lab var moved "Moved since last wave"
lab define moved 0 "Stayer" 1 "Mover"
lab value moved moved 
tab moved

//local labor market unemployment quota 
sort kreisnr 
merge m:1 kreisnr using $data\LK_AMR_ALQ_2013.dta, keepusing(alq_amr alq_bula bula)
drop if _merge==2
drop _merge

*county unemployment quota
cap drop highalq
sum alq, d
gen highalq = (alq>r(p50) & alq<.)
lab define higalq 0 "Low unemployment" 1 "High unemployment", modify
lab value highalq higalq
tab highalq
lab var alq "County unemployment"

//other definitions
*SGB II 
gen sgb2_quo = (n_ub2_unemp + n_ub2_emp ) / n 
lab var sgb2_quo "Neighborhood welfare receipt"
sum sgb2_quo

*longtime ue
gen ltunemp_quo = (n_not_emp_1yr ) / n
lab var ltunemp_quo "Neighborhood longterm unemployment" 
sum ltunemp_quo


*wider neighborhood
cap drop wnh_n_not_emp
merge m:1 geo_grid_cell year using "$widenh\GridAB_widernh.dta", keepusing( wnh_n wnh_n_not_emp)
drop if _merge==2 //10% of the sample no wider NH
drop _merge

gen 	alq_wnh = wnh_n_not_emp /wnh_n
replace alq_wnh = alq_wnh*100
sum alq_wnh ,d



***save dataset
save 		"$data\DM_comp.dta", replace


log close log_merge
