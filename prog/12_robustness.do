***Präambel***
*Log-File
cap log close 
log using "$log\11_robustness.log", replace

*Datensatz laden
use	"$data\analysed.dta", clear

***define globals
global 		level 				geo_grid_cell
global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c ///
								i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
								daily_wage_med n urban  n_est_close_5yrs alq  moved
global 		control_ind 		i.subhealth i.mig i.educ_kat 
 


********************************************************************************
**# other nesting structures
********************************************************************************
foreach unit in wnh amr bula {
sum alq_`unit'  if _mi_m==1 
}

lab define high_alo 0 "Low unemployment" 1 "High unemployment"

//wider neighborhoods (3x3km), local labor markets [amr] or states [bula]
foreach unit in wnh amr bula {
	
	cap drop highalq_`unit'
	sum alq_`unit', d
	gen highalq_`unit' = (alq_`unit'>8.6 & alq_`unit'<.) //county cutoff
	lab value highalq_`unit' high_alo
	tab highalq_`unit'
	/*
	//compare individuals living in high unemployemnt vs low unemployment counties
	foreach ub in unemp sgb2 ltunemp {
	
		**triple interaction: squared UE and urban vs rural
		foreach level in 99.9 {
		cap drop 	ind
		mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
					mixed stig_con i.highalq_`unit'##c.`ub'_quo##c.`ub'_quo $model_ind1_new  $control_ind ///
					|| kreisnr: c.`ub'_quo##c.`ub'_quo || $level:  ///
					, mle difficult   covariance(unstructured) 
		est store 	m_nh`ub'_alq
		}
		
		*margins plot
		mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0.1 (0.1) 0.5)) by(highalq_`unit') cmdmargins
		marginsplot, x(`ub'_quo) recast(line)   yline(0) title(" ") ///
			ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
			xlabel(,labsize(vlarge)) xtitle(,size(vlarge))

		graph save "${out}\nested\marginsplot_`ub'q2_`unit'highalq.gph", replace	
		
		
	}
	*/
	grc1leg2 "${out}\nested\marginsplot_sgb2q2_`unit'highalq.gph" ///
					"${out}\nested\marginsplot_unempq2_`unit'highalq.gph" ///
					"${out}\nested\marginsplot_ltunempq2_`unit'highalq.gph", ycommon col(3)  xsize(15) ysize(6) ///
				 legscale(medium)
				 

	graph export "${out}\marginsplot_`unit'alq.png", as(png) replace
	graph export "${out}\marginsplot_`unit'alq.pdf", as(pdf) replace

}

********************************************************************************
**# gini split at the median 
********************************************************************************
//simple sample split
cap drop high_gini
sum daily_inc_gini, d
gen high_gini = (daily_inc_gini>r(p50) & daily_inc_gini<.)
lab value high_gini highgini
tab high_gini

foreach ub in unemp sgb2 ltunemp {
foreach level in 99.9 {
cap drop 	ind
mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
			mixed stig_con i.high_gini##c.`ub'_quo##c.`ub'_quo $model_ind1_new ///
			$control_ind || kreisnr: c.`ub'_quo##c.`ub'_quo || $level: ///
			, mle difficult   covariance(unstructured) 
est store 	m_nh`ub'_gini_total
}

mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0.1 (0.1) 0.6)) by(high_gini) cmdmargins
marginsplot, x(`ub'_quo) recast(line)   yline(0) title("") ///
			ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
			xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
graph save "${out}\gini\marginsplot_`ub'q2_gini50", replace	
}

grc1leg2 "${out}\gini\marginsplot_sgb2q2_gini50.gph" ///
				"${out}\gini\marginsplot_unempq2_gini50.gph" ///
				"${out}\gini\marginsplot_ltunempq2_gini50.gph", ycommon col(3)  xsize(15) ysize(6) ///
				 legscale(medium)
graph export "${out}\robustness\marginsplot_gini50.pdf", as(pdf) replace	

//Only for one dimension: sanctioning by others
*Norm enforcement: Compare individuals from high and low inequality neihgborhoods

global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c ///
								i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
								daily_wage_med n urban  n_est_close_5yrs alq 

foreach ub in unemp sgb2 ltunemp {
foreach level in 99.9 {
cap drop 	ind
mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
			mixed stigma_6 i.high_gini##c.`ub'_quo##c.`ub'_quo $model_ind1_new ///
			$control_ind ///
			|| kreisnr: c.`ub'_quo##c.`ub'_quo || $level: ///
			, mle difficult  covariance(unstructured) 
est store 	m_nh`ub'_gini_total
}

mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.5)) by(high_gini) cmdmargins
marginsplot, x(`ub'_quo) recast(line)   yline(0) title("") ///
		ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
		xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
graph save "${out}\robustness\stigma6_marginsplot_`ub'q2_gini", replace	
}

*average marginal effects plot
grc1leg2 "${out}\robustness\stigma6_marginsplot_sgb2q2_gini.gph" ///
				"${out}\robustness\stigma6_marginsplot_unempq2_gini.gph" ///
				"${out}\robustness\stigma6_marginsplot_ltunempq2_gini.gph", ycommon col(3)  xsize(15) ysize(5) ///
				legscale(medium)
				
graph export "${out}\robustness\stigma6_marginsplot_gini.pdf", as(pdf) replace	


********************************************************************************
**# social identity or personal experiences
tab stigma_6,nol
gen dstigma_6 = stigma_6>2 & stigma_6<.
replace dstigma_6=. if stigma_6==.
tab dstigma_6, mis

foreach ub in sgb2 unemp ltunemp  {

	**Total
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed dstigma_6 c.`ub'_quo##c.`ub'_quo $model_ind1_new  ///
				$control_ind || kreisnr: c.`ub'_quo##c.`ub'_quo || $level: ///
				, mle difficult  covariance(unstructured) 
	est store 	m_nh`ub'_total
	}

	mimrgns, dydx(`ub'_quo) at(`ub'_quo = (0 (0.1) 0.5))  cmdmargins
	marginsplot, x(`ub'_quo) recast(line)   yline(0) title(" ") ///
			ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(vlarge)) ///
			xlabel(,labsize(vlarge)) xtitle(,size(vlarge))
		 
	
	graph save "${out}\robustness\dstigma6_`ub'q2", replace	
	
}

grc1leg2 "${out}\robustness\dstigma6_sgb2q2" ///
			"${out}\robustness\dstigma6_unempq2" ///
			"${out}\robustness\dstigma6_ltunempq2" ///
					, ycommon col(3)  xsize(15) ysize(6) 
					
graph export "${out}\robustness\dstigma6_ALLq2.pdf", replace as(pdf)



********************************************************************************
**# further robustness checks
global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c ///
								i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
								daily_wage_med n urban  n_est_close_5yrs alq high_gini moved
								
lab var unemp_quo "Unemployment"
								
//individuals living in small vs. large grids
cap drop med_n
sum n , d
gen med_n = n > r(p50)
lab define med_n 0 "< median" 1 "> median"
lab value med_n med_n

**triple interaction: squared UE and size
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con i.med_n##c.unemp_quo##c.unemp_quo $model_ind1_new  $control_ind ///
				|| kreisnr: c.unemp_quo##c.unemp_quo || $level: ///
				, mle difficult  covariance(unstructured) 
	est store 	m_nhunemp_size
	}	
	*margins plot
	mimrgns, dydx(unemp_quo) at(unemp_quo = (0 (0.1) 0.5)) by(med_n) cmdmargins
	marginsplot, x(unemp_quo) recast(line)   yline(0) title("A: Neighborhood size") ytitle("Average marginal effect")

	graph save "${out}\robustness\marginsplot_unempq2_NHsize.gph", replace	
	



global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez daily_wage_med n high_gini alq n_est_close_5yrs moved

//individuals living in in urban or rural regions 
tab urban

	**triple interaction: squared UE and urban vs rural
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con i.urban#c.unemp_quo##c.unemp_quo  $model_ind1_new  $control_ind  ///
				|| kreisnr: c.unemp_quo##c.unemp_quo || $level:  ///
				, mle difficult covariance(unstructured)   
	est store 	m_nhltunemp_urban
	}
	
	*margins plot
	mimrgns, dydx(unemp_quo) at(unemp_quo = (0 (0.1) 0.5)) by(urban) cmdmargins
	marginsplot, x(unemp_quo) recast(line)   yline(0) title("B: Urbanity") ytitle("Average marginal effect")

	graph save "${out}\robustness\marginsplot_unempq2_urban.gph", replace	
	

global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
								daily_wage_med n urban  n_est_close_5yrs alq high_gini moved


//living in rural east-german counties?
cap drop east
gen east = (kr_id>10000 & kr_id<.)
lab define east 0 "West" 1 "East", modify
lab value east east


**triple interaction: squared UE and east vs west
	foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con i.east##c.unemp_quo##c.unemp_quo $model_ind1_new  $control_ind ///
				|| kreisnr: c.unemp_quo##c.unemp_quo || $level:  ///
				, mle difficult  covariance(unstructured) 
	est store 	m_nhltunemp_east
	}
	
	*margins plot
	mimrgns, dydx(unemp_quo) at(unemp_quo = (0 (0.1) 0.5)) by(east) cmdmargins
	marginsplot, x(unemp_quo) recast(line)   yline(0) title("C: Region: East or West") ytitle("Average marginal effect")

	graph save "${out}\robustness\marginsplot_unempq2_east.gph", replace	
	
global 		model_ind1_new 		i.female child_* care c.age_c##c.age_c c.unemp_cur_n_c i.unemp_ep_ord depindug2_c ln_oecdincn_c search ib1.leistbez ///
								daily_wage_med n urban  n_est_close_5yrs alq high_gini east

//movers vs stayers
*Total
foreach level in 99.9 {
cap drop 	ind
mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
			mixed stig_con i.moved##c.unemp_quo##c.unemp_quo $model_ind1_new  ///
			$control_ind || kreisnr: c.unemp_quo##c.unemp_quo || $level: ///
			, mle difficult  covariance(unstructured) 
est store 	r_nhltunemp_moved
}

mimrgns, dydx(unemp_quo) at(unemp_quo = (0 (0.1) 0.5)) by(moved)   cmdmargins
marginsplot, x(unemp_quo) recast(line)   yline(0) title("D: Relocation in previous year") ytitle("Average marginal effect")

	 
graph save "${out}\robustness\R_moved_marginsplot_unempq2", replace	


//combine all
graph combine  "${out}\robustness\marginsplot_unempq2_NHsize" ///
				"${out}\robustness\marginsplot_unempq2_urban" ///
				"${out}\robustness\marginsplot_unempq2_east" ///
				"${out}\robustness\R_moved_marginsplot_unempq2"  ///
					, ycommon col(2)   

graph export "${out}\R_marginsplot_subgroups_unemp.pdf", replace as(pdf)
		
********************************************************************************
**# on county level
lab var alq "County unemployment quota"
sum alq, d
foreach level in 99.9 {
	cap drop 	ind
	mi estimate	, dots saving(miest_nh_total, replace) post esample(ind) errorok level(`level'): ///
				mixed stig_con c.alq##c.alq $model_ind1_new  || kreisnr: ///
				, mle difficult  covariance(unstructured) 
	est store 	m_alq
	}
	
	*margins plot
	mimrgns, dydx(alq) at(alq = (2 (2) 20))  cmdmargins
	marginsplot, x(alq) recast(line)   yline(0) title("County-level analysis") ///
			ylabel(,labsize(vlarge)) ytitle("Average marginal effect",size(large)) ///
			xlabel(,labsize(vlarge)) xtitle(,size(large))
	
graph save "${out}\R_marginsplot_unempq2_krs",  replace		
graph export "${out}\robustness\R_marginsplot_unempq2_krs.pdf", as(pdf) replace	



log close
