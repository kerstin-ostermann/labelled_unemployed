***Präambel***
*Log-File
cap log close 
log using "$log\12_description.log", replace

*Datensatz laden
use	"$data\IMP.dta", clear

//Harmonize labels 
lab var sgb2_quo "Share of welfare receivers" 
lab var  unemp_quo "Share of unemployed" 
lab var ltunemp_quo "Share of long-term unemployed"

********************************************************************************
//dependent variable: stigma consciousness
sum stig_con, d


//central independent variable
pwcorr sgb2_quo unemp_quo ltunemp_quo

//neighborhood unemployment
preserve
	duplicates drop geo_grid_cell, force
	sum unemp_quo sgb2_quo ltunemp_quo,d
restore 

gen has_child = (child_3==1 | child_4_9 == 1 | child_10_17==1)
lab var has_child "Has children, ref. no children"
tab has_child

gen high_educ = educ_kat==3
lab var high_educ "University degree"
tab high_educ

//how many live in neighborhoods with more than 30% unemployed?
cap drop unemp_quoa30
gen unemp_quoa30 = unemp_quo>=0.3 & unemp_quo<.
misum unemp_quoa30
lab var unemp_quoa30 "Grids with unemployment share above 30\%"

lab var urban "Lives in urban county"

sum daily_inc_gini
 
//grid cells with high and low inequality
egen p33 = pctile(daily_inc_gini), p(33)
egen p66 = pctile(daily_inc_gini), p(66)
egen p75 = pctile(daily_inc_gini), p(75)
 
cap drop high_gini
gen high_gini = (daily_inc_gini>p66 & daily_inc_gini<.)
lab define highgini 0 "Low inquality" 1 "High inequality", modify
lab value high_gini highgini
lab var high_gini "High income inequality"

cap drop highalq
sum alq, d
gen highalq = (alq>r(p50) & alq<.)
lab define higalq 0 "Low unemployment" 1 "High unemployment", modify
lab value highalq higalq
lab var highalq "Lives in high unemployment county"
tab highalq

lab var female "Female, ref. male"
lab var age "Age"
lab var care "Care obligations, no care obligations"
lab var mig "Migration background, ref. native German"
lab var stig_con "Stigma consciousness"

********************************************************************************
**#individuals
*sample description
misum  stig_con female has_child care age mig high_educ ///
		sgb2_quo unemp_quo  ltunemp_quo high_gini highalq  ///
				urban 
est sto d_samplei

preserve
	gen counter = (_mi_m==1)
	keep counter kreisnr
	collapse (sum) counter, by(kreisnr)
	sum counter
	
	display _N
restore	
			
/* brocken do it by hand
*check here 
esttab d_samplei ,  cells(mean(fmt(3)) sd(fmt(2))) label ///
		mtitle("Analysis sample") 
		
//export table
esttab d_samplei    using "${out}/Description_individuals.tex", replace label  ///
		stats(N, fmt(%18.0g)  labels("\midrule Observations")) ///
		cells(mean(fmt(3)) sd(fmt(2)))  ///
		mtitle("Analysis sample")  booktabs nonum  noobs
*/
********************************************************************************
**##neighborhoods	
duplicates drop geo_grid_cell _mi_m, force

*sample description
misum  sgb2_quo unemp_quo  ltunemp_quo unemp_quoa30 ///
		n daily_wage_med urban high_gini 


		

********************************************************************************
**#compare to GridAB
use "${orig}\GridAB_home_cens.dta", clear

keep if year==2012

drop if n_not_emp==.

gen unemp_quo = n_not_emp /n
gen sgb2_quo = (n_ub2_unemp + n_ub2_emp ) / n 
gen ltunemp_quo = n_not_emp_1yr /n

sum daily_inc_gini
 
//grid cells with high and low inequality
egen p33 = pctile(daily_inc_gini), p(33)
egen p66 = pctile(daily_inc_gini), p(66)
egen p75 = pctile(daily_inc_gini), p(75)

cap drop high_gini
gen high_gini = (daily_inc_gini>p66 & daily_inc_gini<.)
lab define highgini 0 "Low inquality" 1 "High inequality", modify
lab value high_gini highgini


lab var unemp_quo "Share of unemployed"
lab var sgb2_quo "Share of welfare receivers"
lab var ltunemp_quo "Share of long-term unemployed"

//how many live in neighborhoods with more than 30% unemployed?
cap drop unemp_quoa30
gen unemp_quoa30 = unemp_quo>=0.3 & unemp_quo<.
sum unemp_quoa30
lab var unemp_quoa30 "Grids with unemployment share above 30\%"



*sample description
estpost sum   ///
		sgb2_quo unemp_quo  ltunemp_quo unemp_quoa30  ///
		n daily_wage_med  high_gini
est sto d_gridab

lab var n "Total number of residents"
lab var daily_wage_med "Mean wage"
lab var high_gini "High income inequality"


esttab d_gridab  ,  cells(mean(fmt(3)) sd(fmt(2))) label ///
		mtitle("GridAB") 
/*check here 
esttab d_gridab d_samplenh ,  cells(mean(fmt(3)) sd(fmt(2))) label ///
		mtitle("GridAB" "Grids in sample") 
		
//export table
esttab d_gridab  d_samplenh using "${out}/Description_nh.tex", replace  ///
		stats(N, fmt(%18.0g) labels("\midrule Observations")) ///
		mtitle("GridAB" "Grids in sample") ///
		title("Comparison all grid cells in Germany and grid cells in the analysis sample") ///
		cells(mean(fmt(3)) sd(fmt(2))) label booktabs nonum  f noobs
*/		
log close 