***Präambel***
set r 		on

*Log-File
cap log close 
log using "$log\09_imputation.log", replace

*Datensatz laden
use	"$data\DM_comp.dta", clear
**************

*drop if sgb2_quo == . 
drop childnum childsum
	
***overview on missing values
*
tab 		stig_con,m
misstable 	sum stig_con female unemp_ep_ord sgb2_quo unemp_quo ltunemp_quo unemp_cur_n_c ///
			child* care age_c ///
			age2_c search leistbez depindug2_c ln_oecdincn_c ///
			 mig educ_kat akt_pol akt_com akt_other ///
			unemp_quo_c amr mean_female_c mean_unemp_cur_n_c ///
			mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c  ///
			mean_care_c mean_age_c mean_search_c mean_leistbez_2_c ///
			mean_leistbez_3_c mean_depindug2 mean_ln_oecdincn hhgr_c ///
			sat_gen_c sat_health_c sat_flat_c sat_std_c friends_num_c ///
			ger updown_c friends_yn subhealth emp_hh_cur ///
			n_tenure* n_marginal n_parttime n_fulltime tenure_mean n_helpers ///NH variables 
			n_foreign n_educ_low n_educ_high ///
			wnh_n_not_emp wnh_n_not_emp_1yr wnh_n_ub* wnh_tenure_mean wnh_n_helpers ///WNH variables 
			wnh_n_foreign wnh_n_educ_low wnh_n_educ_high ///
			kreisnr alq highalq ///
			if stig_con<.
			
misstable 	sum stig_con female unemp_ep_ord sgb2_quo unemp_quo ltunemp_quo unemp_cur_n_c ///
			child* care age_c ///
			age2_c search leistbez depindug2_c ln_oecdincn_c  ///
			 mig educ_kat akt_pol akt_com akt_other ///
			unemp_quo_c amr mean_female_c mean_unemp_cur_n_c ///
			mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c  ///
			mean_care_c mean_age_c mean_search_c mean_leistbez_2_c ///
			mean_leistbez_3_c mean_depindug2 mean_ln_oecdincn hhgr_c ///
			sat_gen_c sat_health_c sat_flat_c sat_std_c friends_num_c ///
			ger updown_c friends_yn subhealth emp_hh_cur pisei 		///
			n_tenure* n_marginal n_parttime n_fulltime tenure_mean n_helpers ///NH variables 
			n_foreign n_educ_low n_educ_high ///
			wnh_n_not_emp wnh_n_not_emp_1yr wnh_n_ub* wnh_tenure_mean wnh_n_helpers ///WNH variables 
			wnh_n_foreign wnh_n_educ_low wnh_n_educ_high ///
			kreisnr alq 

		
misstable 	sum unemp_cur_n_c depindug2_c ln_oecdincn_c ///
					sat_gen_c sat_health_c friends_num_c updown_c child_3 ///
					child_4_9 child_10_17  search care subhealth pisei ///
					educ_kat unemp_ep_ord mig
					
misstable sum age_c age2_c    akt_pol akt_com ///
			akt_other  amr emp_hh_cur /// 
			mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
			mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
			mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
			mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
			mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
			mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
			mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c
*/

//county information
mixed stig_con  || geo_grid_cell: || kr_id: , mle

preserve
	duplicates drop kr_id, force
	sum kr_id_N, d
restore
	
xtset pnr year

***preparing the data 
set seed	564
mi set 		flong
mi register	imputed stig_con sgb2_quo unemp_quo ltunemp_quo unemp_ep_ord unemp_cur_n_c child_* care search leistbez ///
			depindug2_c ln_oecdincn_c  mig educ_kat sat_gen_c ///
			n_marginal n_parttime tenure_mean n_helpers  daily_wage_med  gini_daily_wage_med ///NH variables 
			n_foreign n_educ_low n_educ_high n_est_close_5yrs n ///
			sat_health_c friends_num_c updown_c friends_yn subhealth pisei female  ///
			wnh_n_not_emp wnh_n_not_emp_1yr  wnh_tenure_mean wnh_n_helpers ///WNH variables 
			wnh_n_foreign wnh_n_educ_low wnh_n_educ_high
mi register regular  ///
			age_c age2_c    akt_pol akt_com ///individual level 
			akt_other  amr emp_hh_cur /// 
			mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
			mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
			mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
			mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
			mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
			mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
			mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c ///
			alq   

***Indikator für MID
cap drop 	ind
gen			ind=1 if stig_con==.
tab			ind stig_con, mis


***Imputation
set more off
mi xtset, clear
mi impute chained 	(pmm, knn(5)) stig_con  unemp_cur_n_c depindug2_c ln_oecdincn_c ///
					sat_gen_c sat_health_c friends_num_c updown_c child_3 ///
					child_4_9 child_10_17  search care subhealth pisei female ///
					unemp_quo ltunemp_quo sgb2_quo ///EV
					n_marginal n_parttime tenure_mean n_helpers n_est_close_5yrs n ///NH variables 
					n_foreign n_educ_low n_educ_high gini_daily_wage_med daily_wage_med ///
					wnh_n_not_emp wnh_n_not_emp_1yr  wnh_tenure_mean wnh_n_helpers ///WNH variables 
					wnh_n_foreign wnh_n_educ_low wnh_n_educ_high ///
					(ologit, augment) educ_kat unemp_ep_ord mig leistbez ///
					= c.age_c c.age2_c  ///
					i.akt_pol i.akt_com i.akt_other  i.amr emp_hh_cur ///
					c.mean_female_c c.mean_child_3_c c.mean_child_4_9_c c.mean_child_10_17_c c.mean_care_c ///
					c.mean_age_c c.mean_unemp_cur_n_c c.mean_depindug2_c c.mean_ln_oecdincn_c c.mean_search_c ///
					c.mean_emp_hh_cur_c c.mean_pisei_c c.mean_friends_num_c ///
					c.mean_educ_kat_2_c c.mean_educ_kat_3_c c.mean_mig_2_c ///
					c.mean_mig_3_c c.mean_unemp_ep_ord_2_c c.mean_unemp_ep_ord_3_c ///
					c.mean_leistbez_1_c c.mean_leistbez_3_c ///
					c.sat_flat_c c.sat_std_c i.ger c.hhgr_c c.mean_akt_pol_c ///
					c.mean_akt_com_c c.mean_akt_other_c ///
					c.alq ///
					, add(50) burnin(100) dots replace  
//
***drop cases with initially missing stig_con 
*drop 		if ind==1



***save data
save 		"$data\IMP.dta", replace
					
/***Konvergenzdiagnostik einzeln
**Imputation für female==1
use 				"$data\DM_comp.dta", clear
*preparing the data
set seed	564
mi set 		flong
mi register	imputed unemp_ep_ord unemp_cur_n_c child_* care search leistbez ///
			depindug2_c ln_oecdincn_c subhealth_prev mig educ_kat sat_gen_c ///
			sat_health_c friends_num_c updown_c friends_yn subhealth pisei
mi register regular age_c age2_c    akt_pol akt_com ///
			akt_other  amr emp_hh_cur /// 
			mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
			mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
			mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
			mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
			mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
			mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
			mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c
			
*imputation
mi xtset, clear
mi impute chained 	(pmm, knn(5)) unemp_cur_n_c depindug2_c ln_oecdincn_c ///
					sat_gen_c sat_health_c friends_num_c updown_c child_3 ///
					child_4_9 child_10_17 subhealth_prev search care subhealth pisei ///
					(ologit, augment) educ_kat unemp_ep_ord mig leistbez ///
					= age_c age2_c    akt_pol akt_com ///
					akt_other  amr emp_hh_cur /// 
					mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
					mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
					mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
					mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
					mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
					mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
					mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c if female==1 ///
					, add(50) burnin(100) dots replace force savetrace(trace_imputation_f.dta, replace)

**Imputation for female==0
use 				"$data\DM_comp.dta", clear
*preparing the data
set seed	564
mi set 		flong
mi register	imputed unemp_ep_ord unemp_cur_n_c child_* care search leistbez ///
			depindug2_c ln_oecdincn_c subhealth_prev mig educ_kat sat_gen_c ///
			sat_health_c friends_num_c updown_c friends_yn subhealth pisei
mi register regular age_c age2_c    akt_pol akt_com ///
			akt_other  amr emp_hh_cur /// 
			mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
			mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
			mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
			mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
			mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
			mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
			mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c

*imputation
mi xtset, clear
mi impute chained 	(pmm, knn(5)) unemp_cur_n_c depindug2_c ln_oecdincn_c ///
					sat_gen_c sat_health_c friends_num_c updown_c child_3 ///
					child_4_9 child_10_17 subhealth_prev search care subhealth pisei ///
					(ologit, augment) educ_kat unemp_ep_ord mig leistbez ///
					= age_c age2_c    akt_pol akt_com ///
					akt_other  amr emp_hh_cur /// 
					mean_female_c mean_child_3_c mean_child_4_9_c mean_child_10_17_c mean_care_c ///
					mean_age_c mean_unemp_cur_n_c mean_depindug2_c mean_ln_oecdincn_c mean_search_c ///
					mean_emp_hh_cur_c mean_pisei_c mean_friends_num_c  ///
					mean_educ_kat_2_c mean_educ_kat_3_c mean_mig_2_c ///
					mean_mig_3_c mean_unemp_ep_ord_2_c mean_unemp_ep_ord_3_c ///
					mean_leistbez_1_c mean_leistbez_3_c mean_akt_pol_c ///
					mean_akt_com_c mean_akt_other_c sat_flat_c sat_std_c ger hhgr_c if female==0 ///
					, add(50) burnin(100) dots replace force savetrace(trace_imputation_m.dta, replace)

***convergence diagnostics - male
use "$data\trace_imputation_m.dta", clear

***reshape data
reshape 			long @_mean @_sd, i(iter m) j(var) string


***calculate means and standard deviations per interation
rename 				_* est*
bysort iter var:	egen mean_mean=mean(estmean)
bysort iter var:	egen mean_sd=mean(estsd)

***plot means and standard deviations over interations
twoway				line mean_mean iter, lcol(red) sort ///
					|| line mean_sd iter, yaxis(2) lcol(blue) sort ///
					||, by(var, yrescale) 
graph save 			"$plots\convergence_m.gph", replace
graph export 		"$plots\convergence_m.png", replace

***convergence diagnostics - female
use "$data\trace_imputation_f.dta", clear

***reshape data
reshape 			long @_mean @_sd, i(iter m) j(var) string


***calculate means and standard deviations per interation
rename 				_* est*
bysort iter var:	egen mean_mean=mean(estmean)
bysort iter var:	egen mean_sd=mean(estsd)

***plot means and standard deviations over interations
twoway				line mean_mean iter, lcol(red) sort ///
					|| line mean_sd iter, yaxis(2) lcol(blue) sort ///
					||, by(var, yrescale) 
graph save 			"$plots\convergence_f.gph", replace
graph export 		"$plots\convergence_f.png", replace

***END
log close 	log_imputation
