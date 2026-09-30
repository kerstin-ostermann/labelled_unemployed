***Präambel***
*Log-File
cap log close 
log using "$log\10_rsmodels.log", replace

*Datensatz laden
use	"$data\IMP.dta", clear

/*Robustness: same year grid cell infos (instead of lagged)
log using "$log\10_models_sameyear.log", replace
use	"$data\IMP_sameyear.dta", clear
global 		out  "${path}\out\sameyear"
*/
************************
*LEVEL NEIGHORHOOD ID***
************************

***Arbeitsverzeichnis auf global log legen
cd 			$log


***define globals
global 		level 				geo_grid_cell
global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c ///
								c.unemp_cur_n_c i.unemp_ep_ord depindug2_c ///
								ln_oecdincn_c search ib1.leistbez daily_wage_med ///
								n urban  n_est_close_5yrs
global 		control_ind 		i.subhealth i.mig i.educ_kat i.moved


*drop if unemp_quo==.

//Harmonize labels 
lab var sgb2_quo "Share of welfare receivers" 
lab var  unemp_quo "Share of unemployed" 
lab var ltunemp_quo "Share of long-term unemployed"
*
***nullmodel
**Total
foreach level in 95 99 99.9 {
mi estimate	, dots saving(miest_null_total, replace) post errorok level(`level'): ///
			mixed stig_con  || kreisnr: ||  $level: ///
			, mle difficult covariance(unstructured)    
est store 	m_null_total
}

***add individual level information
**Total
foreach level in 99.9 {
mi estimate	, dots saving(miest_ind_total, replace) post errorok level(`level'): ///
			mixed stig_con $model_ind1_new ///
			$control_ind || kreisnr:   ||  $level: ///
			, mle difficult covariance(unstructured)   
est store 	m_ind_total
}

***Main analysis: Add Neighborhood Unemployment as Variable 
 
foreach ub in   sgb2 unemp ltunemp {

	**Total
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con c.`ub'_quo##c.`ub'_quo $model_ind1_new  ///
				$control_ind || kreisnr:  c.`ub'_quo##c.`ub'_quo || $level: ///
				, mle difficult  covariance(unstructured)  
	est store 	m_nh`ub'_total
	}

	mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.5))  cmdmargins
	marginsplot, x(`ub'_quo) recast(line)   yline(0) title(" ") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
		 
	graph save "${out}\marginsplot_`ub'q2", replace	

	mimrgns,  at(`ub'_quo = (0 (0.1) 0.5))  cmdmargins
	marginsplot, x(`ub'_quo) recast(bar) plotopts(barwidth(0.05) bc(grey%20)) ///
		 ciopts(color(black%40)) yscale(range(40 70)) ylabel(40 (10) 70, labsize(vlarge)) ///
		title(" ") ///
		ylabel(,labsize(vlarge)) ytitle("Predicted stigma consciousness",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
	
	graph save "${out}\PREDmarginsplot_`ub'q2", replace

}

*marginal effects
graph combine "${out}\marginsplot_sgb2q2" "${out}\marginsplot_unempq2" "${out}\marginsplot_ltunempq2", ycommon col(3)  xsize(15) ysize(5)
graph export "${out}\marginsplot_ALLq2.pdf", replace as(pdf)

*predictions
graph combine "${out}\PREDmarginsplot_sgb2q2" "${out}\PREDmarginsplot_unempq2" "${out}\PREDmarginsplot_ltunempq2", ycommon col(3)  xsize(15) ysize(5)
graph export "${out}\PREDmarginsplot_ALLq2.pdf", replace as(pdf)
graph export "${out}\PREDmarginsplot_ALLq2.png", replace as(png)


//table 
esttab m_null_total m_nhsgb2_total m_nhunemp_total   m_nhltunemp_total ///
	using "${out}\NH_short.tex", replace  booktabs ///
	order(*_quo) nobase label mtitle("Null model" "welfare receivers" "unemployed"  "long term unemployed") ///
	title("Multilevel results of neighborhood unemployment on stigma consciousness of the unemployed \label{tab-nh}") ///
	stats(N, fmt(0) labels("Number of persons")) ///
	drop(*female *child_* *care *age* *unemp_cur_n_c *unemp_ep_ord ///
		*depindug2_c *ln_oecdincn_c *search *leistbez *daily_wage_med ///
		*n *urban  *n_est_close_5yrs *subhealth *mig *educ_kat *moved) 
	

********************************************************************************
*standardize
********************************************************************************
cap drop d_subheath*
tab subhealth, gen(d_subhealth)

cap drop d_mig*
tab mig, gen(d_mig)

cap drop d_educ_kat*
tab educ_kat, ge(d_educ_kat)

foreach var of varlist stig_con sgb2_quo unemp_quo  ltunemp_quo ///
		female child_3 child_4_9 child_10_17 care age_c unemp_cur_n_c unemp_ep_ord ///
		depindug2_c ln_oecdincn_c search leistbez daily_wage_med n urban n_est_close_5yrs ///
		d_subhealth* d_mig* d_educ_kat* { 
cap drop sd_`var'
bys _mi_m: egen sd_`var' = std(`var')
}

lab var sd_sgb2_quo "Share of welfare receivers"
lab var sd_unemp_quo "Share of unemployed"
lab var sd_ltunemp_quo "Share of long-term unemployed"

global 		sd_model_ind1_new 	sd_female sd_child_* sd_care c.sd_age_c##c.sd_age_c sd_unemp_cur_n_c sd_unemp_ep_ord sd_depindug2_c sd_ln_oecdincn_c sd_search sd_leistbez sd_daily_wage_med sd_n sd_urban  sd_n_est_close_5yrs
global 		sd_control_ind 		sd_d_subhealth1 sd_d_mig2 sd_d_mig3 sd_d_educ_kat2 sd_d_educ_kat3


***Main analysis: Add Neighborhood Unemployment as Variable 
foreach ub in sgb2 unemp  ltunemp {
	
	**Total
	cap drop 	ind	
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(99.9): ///
				mixed sd_stig_con c.sd_`ub'_quo##c.sd_`ub'_quo $sd_model_ind1_new  ///
				$sd_control_ind || kreisnr:  c.sd_`ub'_quo##c.sd_`ub'_quo || $level: ///
				, mle difficult  covariance(unstructured)  
		
	est store 	sd_m_nh`ub'_total

	mimrgns, dydx(sd_`ub'_quo) at(sd_`ub'_quo = (-1.5 (0.5) 2))  cmdmargins
	marginsplot, x(sd_`ub'_quo) recast(line)   yline(0) title(" ") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
	
	graph save "${out}\std\marginsplot_sd_`ub'q2", replace
	graph export "${out}\std\marginsplot_sd_`ub'q2.png", as(png) replace	
	graph export "${out}\std\marginsplot_sd_`ub'q2.svg", as(svg) replace	

	*with LM FE
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(99.9): ///
				mixed sd_stig_con c.sd_`ub'_quo##c.sd_`ub'_quo $sd_model_ind1_new  ///
				$sd_control_ind i.lab_area ///
				|| kreisnr:  c.sd_`ub'_quo##c.sd_`ub'_quo || $level: ///
				, mle difficult  covariance(unstructured)  
	est store 	sd_llm_nh`ub'_total
	
	mimrgns, dydx(sd_`ub'_quo) at(sd_`ub'_quo = (-1.6 (0.4) 1.6))  cmdmargins
	marginsplot, x(sd_`ub'_quo) recast(line)   yline(0) title(" ") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
	
	graph save "${out}\std\marginsplot_sd_`ub'q2_LLMFE", replace
	graph export "${out}\std\marginsplot_sd_`ub'q2_LLMFE.png", as(png) replace	
	graph export "${out}\std\marginsplot_sd_`ub'q2_LLMFE.svg", as(svg) replace		

}

sum sd_sgb2_quo sd_unemp_quo sd_ltunemp_quo,d
*welfare coefs: base: -0.056, sq. 0.031. 
* UE			base: -0.060 , sq. 0.037
*lt-UE:			base: -0.055, sq. 0.040
display -0.056 + 0.031*(-0.124)  //-.059844
display -0.060 + 0.037*(-0.083) //-0.063
display -0.055 + 0.040*(-0.093)  //-0.058

graph combine "${out}\std\marginsplot_sd_sgb2q2" "${out}\std\marginsplot_sd_unempq2" "${out}\std\marginsplot_sd_ltunempq2", ycommon col(3)  xsize(15) ysize(5)
graph export "${out}\std\marginsplot_sd_ALLq2.png", replace as(png)
graph export "${out}\std\marginsplot_ALLq2.pdf", replace as(pdf)


graph combine "${out}\std\marginsplot_sd_sgb2q2_LLMFE" "${out}\std\marginsplot_sd_unempq2_LLMFE" "${out}\std\marginsplot_sd_ltunempq2_LLMFE", ycommon col(3)  xsize(15) ysize(5)
graph export "${out}\std\marginsplot_sd_ALLq2_LLMFE.png", replace as(png)
graph export "${out\std}\marginsplot_ALLq2_LLMFE.pdf", replace as(pdf)

*table 
esttab sd_m_nhsgb2_total sd_m_nhunemp_total sd_m_nhltunemp_total	 ///
	using ${out}\std\table_sd_quo.tex, replace booktabs ///
	 order(*_quo)   ///
	coeflabels(sd_female "Female, ref. male" sd_child_3 "Children below 3" sd_child_4_9 "Children between 4 and 9" ///
	sd_child_10_17 "Children between 10 and 17" sd_care "Care responsibility" sd_age_c "Age" ///
	sd_a unemp_cur_n_c "Duration of present unemployment" ///
	sd_unemp_ep_ord "Number of unemployment episodes" sd_depindug2_c "Deprivation index" ///
	sd_depindug2_c "Centered household income" sd_ln_oecdincn_c "Log. household income" ///
	sd_search "Job search obligation" sd_leistbez "Benefit receipt" sd_daily_wage_med "Neighborhood mean wage" ///
	sd_n "Number of neighborhood residents" sd_urban "Lives in urban county" ///
	sd_n_est_close_5yrs "Firm closures in neighborhood, last 5 years" unemp_cur_n_c "Unemployment duration" ///
	sd_d_subhealth_1 "Poor subjective health" sd_d_mig_2 "1st gen. migrant" sd_d_mig_3 "2nd gen. migrant" ///
	sd_d_educ_kat_2 "Med. education" sd_d_educ_kat_3 "High education" ///
	c.sd_age_c##c.sd_age_c "Age squared") ///
	nobase label mtitle("welfare receivers" "unemployed" "long-term unemployed") ///
	title("Robustness check: Standardized values \label{tab-rob-sd}") ///
	stats(N, fmt(0) labels("Number of persons")) 
	
	
********************************************************************************
*nested
********************************************************************************
global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez daily_wage_med n urban  n_est_close_5yrs
global 		control_ind 		i.subhealth i.mig i.educ_kat

preserve
	keep amr 
	duplicates drop
	display _N
restore

preserve
	keep bula 
	duplicates drop
	display _N
restore

preserve
	duplicates drop geo_grid_cell, force
	gen N = 1
	collapse (sum) N , by(kreisnr)
	sum N
restore

lab define nested 0 "Low county unemployment" 1 "High county unemployment"
lab value highalq nested


//compare individuals living in high unemployemnt vs low unemployment counties
foreach ub in unemp sgb2 ltunemp {
	**triple interaction: squared UE and urban vs rural
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con i.highalq##c.`ub'_quo##c.`ub'_quo $model_ind1_new ///
				|| kreisnr: c.`ub'_quo##c.`ub'_quo || $level:  ///
				, mle difficult covariance(unstructured)  
	est store 	m_nh`ub'_alq
	}
	
	*margins plot
	mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.5)) by(highalq) cmdmargins
	marginsplot, x(`ub'_quo) recast(line)   yline(0) title(" ") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))

	graph save "${out}\marginsplot_`ub'q2_highalq.gph", replace	
	
}
sum alq if highalq==0 & _mi_m==1

grc1leg2 "${out}\marginsplot_sgb2q2_highalq.gph" ///
				"${out}\marginsplot_unempq2_highalq.gph" ///
				"${out}\marginsplot_ltunempq2_highalq.gph", ycommon col(3)  xsize(15) ysize(6) ///
				 legscale(medium)
graph export "${out}\marginsplot_krsalq.pdf", as(pdf) replace	
graph export "${out}\marginsplot_krshalq.svg", as(svg) replace					


********************************************************************************
*side-by-side
********************************************************************************
//Heterogeneity: Compare individuals from high and low inequality neihgborhoods
sum daily_inc_gini
 
//grid cells with high and low inequality
egen p33 = pctile(daily_inc_gini), p(33)
egen p66 = pctile(daily_inc_gini), p(66)
egen p75 = pctile(daily_inc_gini), p(75)

//simple sample split
cap drop high_gini
gen high_gini = (daily_inc_gini>p66 & daily_inc_gini<.)
lab define highgini 0 "Low-inquality neighbourhood" 1 "High-inequality neighbourhood", modify
lab value high_gini highgini

foreach ub in unemp sgb2 ltunemp {

foreach level in 99.9 {
cap drop 	ind
mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
			mixed stig_con i.high_gini##c.`ub'_quo##c.`ub'_quo $model_ind1_new ///
			$control_ind ///
			|| kreisnr: c.`ub'_quo##c.`ub'_quo || $level: ///
			, mle difficult  covariance(unstructured) 
est store 	m_nh`ub'_gini_total
}

mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.4)) by(high_gini) cmdmargins
marginsplot, x(`ub'_quo) recast(line)   yline(0) title("") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
graph save "${out}\gini\marginsplot_`ub'q2_gini", replace	

}

//smaller window for long-term unemployment (due to finite sample)
est restore m_nhltunemp_gini_total

mimrgns, dydx(ltunemp_quo) at(ltunemp_quo = (0 (0.1) 0.4)) by(high_gini) cmdmargins
marginsplot, x(ltunemp_quo) recast(line)   yline(0) title("(C) Long-term unemployment", size(huge)) ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
graph save "${out}\gini\marginsplot_ltunemp40q2_gini", replace	


//average marginal effects
grc1leg2  "${out}\gini\marginsplot_sgb2q2_gini.gph" ///
				"${out}\gini\marginsplot_unempq2_gini.gph" ///
				"${out}\gini\marginsplot_ltunemp40q2_gini.gph", ycommon col(3)  xsize(15) ysize(6) ///
				 legscale(medium)
graph export "${out}\gini\marginsplot_gini.pdf", as(pdf) replace	



*save
save	"$data\analysed.dta", replace

/*
//add other regional information			
	***Add LLM FE --> not enough obs (coef similar size but base coef insign.)
	**Total
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con c.`ub'_quo##c.`ub'_quo $model_ind1_new  ///
				$control_ind i.lab_area || $level: ///
				, mle difficult  
	est store 	m_nhllm`ub'_total
	}

	mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.6))  cmdmargins
	marginsplot, x(`ub'_quo) recast(line)   yline(0) title(" ")  ///
		yscale(range(-100 300)) ylabel(-100 (100) 300) 

	graph save "${out}\marginsplot_`ub'q2_LLMFE", replace	
	graph export "${out}\marginsplot_`ub'q2_LLMFE.pdf", as(png) replace	
	graph export "${out}\marginsplot_`ub'q2_LLMFE.svg", as(svg) replace	

*robustness: other spatial controls
esttab m_nhunemp_total m_nhlkunemp_total m_nhllmunemp_total ///
	using "${out}\NH_otherspatial.tex", replace booktabs ///
	nobase label indicate("LLM FE = *lab_area" ///
	"Individual controls = *female *child_* *care *age_c *unemp_cur_n_c *unemp_ep_ord *depindug2_c *ln_oecdincn_c *search *leistbez  *subhealth *mig *educ_kat")  ///
	mtitle("Main" "(1) + county UE" "(1) + LLM FE") ///
	title("Robustness check: Controlling for broader economical context \label{tab-rob-lm}") ///
	stats(N, fmt(0) labels("Number of persons" "R$^2$")) 
	
}
*/

log close 
	
