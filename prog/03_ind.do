/*******************************************************************************
Tasks: 
- prepare individual-level variables 
	(including stigma-consciousness as dependent variable)
*******************************************************************************/

***Präambel***
*Log-File
cap log close log_DM_ind
log using "$log\03_ind.log", name(log_DM_ind) replace

use "$orig_bef\PENDDAT.dta", clear
*************

keep if welle==7
merge 		1:m pnr using "$data\regio_nh.dta", gen(_merge0)
keep 		if _merge0==3
			
***Prejudices
tab 		PSV0200a, mis
tab 		PSV0200a, mis nol
global 		x 1
foreach 	var of varlist PSV0200a-PSV0200e {
	recode 	`var' -9=.a -3=.b -2 -1=., gen(pred$x)
	global 	x=$x+1
}
sum 		pred*
hist 		pred1
alpha 		pred*, item
alpha 		pred* if statakt==1, item
pwcorr 		pred*, star(0.05)
gen			PRE=(100 - pred1 + pred2 + pred3 + pred4 + pred5)/5
sum 		PRE pred*
hist 		PRE, norm percent

***Mean Prejudice per neighborhood
sort 		welle geo_grid_cell
by welle geo_grid_cell: egen PRE_sd=sd(PRE)
by welle geo_grid_cell: egen PRE_mean=mean(PRE)
by welle geo_grid_cell: egen PRE_N=count(PRE)
replace 	PRE_N=. if welle!=7
tab 		PRE_N
/*
collapse 	PRE_N, by(kr_id)
tab 		PRE_N
*/

tab 		geo_grid_cell if PRE_mean==. & welle==7, mis

***exclude Kreise with PRE_N<5 
*drop 		if PRE_N<5

***Coefficient of Variation of Prejudice per NH
gen 		PRE_cv=PRE_sd/PRE_mean
sum 		PRE_cv

***Variety (Spread) of Prejudice per NH
sort 		welle geo_grid_cell PRE
by welle geo_grid_cell: egen PRE_max=max(PRE)
by welle geo_grid_cell: egen PRE_min=min(PRE)
by welle geo_grid_cell: gen dist=PRE-PRE[_n-1]
by welle geo_grid_cell: egen max_dist=max(dist)
by welle geo_grid_cell: egen n_PRE=count(PRE)
sum 		PRE_max PRE_min n_PRE, d
gen 		PRE_spr=(PRE_max-PRE_min)^2/((n-1)*(100-0)*max_dist)
tab 		PRE_spr
sum 		PRE_spr

***Measure of Separation
sort 		welle geo_grid_cell PRE
by welle geo_grid_cell: gen PRE_n=_n
by welle geo_grid_cell: gen temp_PRE_sep=(PRE_n*PRE)-(((2*(PRE_N+1))/(PRE_N-1))*PRE_mean)
by welle geo_grid_cell: egen PRE_sep=total(temp_PRE_sep)
replace 	PRE_sep=(4/(PRE_N*(PRE_N-1)))*PRE_sep
tab 		PRE_sep
sum 		PRE_sep
drop 		temp_PRE_sep

***Stigma-Scale
tab1 		PSV0100a-PSV0100i
sum 		PSV0100a-PSV0100i

tab 		PSV0100a
tab			PSV0100a, nol

local		i 1			
foreach		x of varlist PSV0100a-PSV0100i{
	recode	`x' 1=4 2=3 3=2 4=1 -10=.a -9=.b -3=.c -2 -1=., gen(stigma_`i')
	tab		stigma_`i', mis
	local	i=`i'+1
	disp	`i'
}

label var	stigma_1 "Beziehungen zu Erwerbstätigen schwierig aufrecht zu erhalten"
label var	stigma_2 "Arbeitslosigkeit persönliche Belastung"
label var	stigma_3 "schwierige Situationen im Alltag"
label var	stigma_4 "die meisten haben mehr Vorurteile als zugegeben"
label var	stigma_5 "Arbeitslosen ggü. eher verbunden"
label var	stigma_6 "fühlt sich pers. betroffen von Vorurteilen"
label var	stigma_7 "verheimliche Arbeitslosigkeit"
label var	stigma_8 "vermeide Situationen mit Vorurteilen"
label var	stigma_9 "versuche schnellst möglich Arbeit zu finden"
label def	stigma 4 "Trifft voll und ganz zu" 3 "Trifft eher zu" ///
			2 "Trifft eher nicht zu" 1 "Trifft überhaupt nicht zu"
label val 	stigma_* stigma

tab1 		stigma_*

alpha		stigma_*, d item
factor		stigma_*, pcf
rotate		,blanks(0.4)

alpha		stigma_1-stigma_8, d item
factor		stigma_1-stigma_8, pcf
rotate		,blanks(0.4)

sum			stigma_*

/*
stigma_1 	-> A
stigma_2 	-> B
stigma_3 	-> C
stigma_4 	-> D
stigma_5 	-> E
stigma_6 	-> F
stigma_7 	-> G
stigma_8 	-> H
stigma_9 	-> I
*/

*sum scale (complete)
*i excluded, doesn't fit
gen 		stig_ind=stigma_1+stigma_2+stigma_3+stigma_4+stigma_5+stigma_6+stigma_7+stigma_8
tab 		stig_ind, mis
sum 		stig_ind, d
hist 		stig_ind, norm d

*0/100 normalized
sum			stig_ind
gen 		stig_con=((stig_ind-8)/(40-8))*100
label var 	stig_con "stigma consciousness"
tab			stig_con, mis
foreach var of varlist stigma_*{
	replace stig_con=`var' if `var' == .a | `var' == .b | `var'==.c //MI impute only imputes hard missings  
}
tab			stig_con, mis
sum			stig_con, d
hist 		stig_con, norm d

gen _merge_nh = 0 
replace _merge_nh = 1 if geo_grid_cell!=.
tab _merge_nh if stig_con<.

***Gender
tab			zpsex
tab			zpsex,nol
recode		zpsex 1=0 2=1 -2 -4=., gen(female)
label var	female "Gender (1=female)"
tab 		female

***Age
codebook	palter
sum			palter, d
recode		palter -2/-1=., gen(age)
hist		age, norm d
sum			age, d
gen			age_c=age-r(mean)
gen			age2=age*age
sum 		age2
gen			age2_c=age2-r(mean)
label var	age "age"
label var	age_c "age (centered)"
label var	age2 "Alter sqared"
label var	age2_c "Alter sqared (centered)"

***höchster Bildungsabschluss Befragte/r
tab			isced97, nol
tab 		isced97
recode		isced97 -8 -4 -2 -1=. -5=.a, gen(educ)
*-5 Filter for pupils
recode		educ 1 2=1 3 4 5=2 6 7 8=3, gen(educ_kat)
la var 		educ_kat "educational level"
la def		educ_kat_lab 1 "ISCED 1 und 2" 2 "ISCED 3 und 4" 3 "ISCED 5 und 6"
la val 		educ_kat educ_kat_lab
tab 		educ_kat isced97, mis

***Citizenship
tab1		PMI0400
tab			PMI0400, nol
recode		PMI0400 -2/-1=. 2=0 1=1 , gen(ger)
la var 		ger "German Citizenship"

***Legal status
tab			famstand
tab			famstand, nol
recode 		famstand -8/-2=. 1 4 5=0 2 3=1, gen(marry)
label var	marry "married/reg. relationship"
tab			marry famstand, mis

***Obligation to search for a job
tab 		PSU0100
tab 		PSU0100, nol
tab			PSU0100 statakt
tab 		PSU0100 fb_vers
recode		PSU0100 -10=.a -9 -4 -3 -2 -1=. 1=1 2 3=0, gen(search)
label var	search "has to search for a job"
tab			search PSU0100, mis

***occupations prestige of parents(based on oppucation at age of 15 of the respondent)
tab1		misei1 visei1
tab			misei1, nol
tab			misei1 welle
*-3 = Filter for not employed, coded as 0
recode		misei1 -10 -9 -5=. -3=0, gen(misei_n)
recode		visei1 -10 -9 -5=. -3=0, gen(visei_n)
gen			pisei=misei_n
replace		pisei=visei_n if visei_n>misei_n & visei_n<.
label var	pisei "parents' ISEI"
sum			pisei, d
gen 		pisei_c=pisei-r(mean)

***recognized disability
tab			PG0500
tab			PG0500, nol
recode		PG0500 -3/-1=. 1 3=1 2=0,gen(sp_needs)
la var		sp_needs "recognized disability"

***psych. problems: PG1100 
tab			PG1100
tab			PG1100, nol
recode		PG1100 -3/-1=. 1=0 2 3 4 5=1,gen(ment_prob)
la var		ment_prob "few to strong psych. problems (Ref. none)"

***subj. health
tab 		PG1200, mis
tab			PG1200, mis nol
recode 		PG1200 -3 -2 -1=. 1=5 2=4 3=3 4=2 5=1, gen(subhealth)
la var 		subhealth "subjective health"
la def		health 5"very good" 4"good" 3"satisfying" 2"bad" 1"very bad"
la val 		subhealth health

***subj. health - previous wave
sort 		pnr welle
gen 		subhealth_prev=.
bysort pnr: replace subhealth_prev=subhealth[_n-1]
la var 		subhealth_prev "subjective health (previous wave)"
la val 		subhealth_prev health
br 			pnr welle subhealth*

***reduce complexity of data
*categorize subjective health
tab 		subhealth_prev
recode 		subhealth_prev 1/3=0 4/5=1
recode 		subhealth 1/3=0 4/5=1
la def 		health2 0 "very bad/bad/satisfying" 1 "good/very good"
la val 		subhealth_prev subhealth health2
tab 		subhealth_prev


***Care work for relatives/friends
tab 		PP0110, mis
tab 		PP0110, mis nol
recode 		PP0110 -9=.a -2 -1=. 2=0, gen(care)
tab 		PP0110 care, mis nol

***Migration background
tab 		migration, mis
tab 		migration, mis nol
tab1 		PMI0200, mis
tab1 		PMI0200, mis nol
tab1 		PMI1000a PMI1000b PMI1000c PMI1000d PMI1000e PMI1000f, mis
recode 		migration -10/-1=. 1=0 2=1 3=2 4=3, gen(mig)
recode 		mig 3=0 //zu wenig Fälle auf 3
la def 		mig 0"no mogration background" 1"migration background 1st gen." ///
			2"migration background 2nd gen." 3"migration background 3rd gen." 
la val 		mig mig
la var 		mig "migration background"
tab 		mig migration, mis

***life satisfaction (general, health, flat, standard of living)
tab 		PA1000
tab 		PA1000, nol
recode 		PA1000 -2/-1=., gen(sat_gen)

tab 		PA0100
tab 		PA0100, nol
recode 		PA0100 -8/-1=., gen(sat_health)

tab 		PA0200
tab 		PA0200, nol
recode 		PA0200 -8/-1=., gen(sat_flat)

tab 		PA0300
tab 		PA0300, nol
recode 		PA0300 -8/-1=., gen(sat_std)

***subjective social position
tab			PA0900
tab			PA0900, nol
recode 		PA0900 -2/-1=., gen(updown)
label var	updown "subj. soziale Position"
hist		updown, norm

***close friends and relatives outside the household
tab 		PSK0100
tab 		PSK0100, nol
tab 		PSK0200
tab	 		PSK0200, nol
recode 		PSK0100 -10=. -2/-1=. 2=0, gen(friends_yn)
recode 		PSK0200 -10 -8=. -3=0 -2/-1=., gen(friends_num)
replace 	friends_num=0 if friends_yn==0
replace 	friends_num=. if friends_yn==.
sum 		friends_num

***Activity in community, club, church...
tab1 		PSK0400a-PSK0400e if welle==7
tab1 		PSK0400a-PSK0400e if welle==7, nol
mvdecode 	PSK0400a-PSK0400e, mv(-5/-1=.)

recode 		PSK0400a 2=0, gen(akt_pol)
replace 	akt_pol=1 if PSK0400b==1
la var 		akt_pol "activity in union/party"

recode 		PSK0400c 2=0, gen(akt_com)
replace 	akt_com=1 if PSK0400d==1
la var 		akt_com "activity in club/church organization"

recode 		PSK0400e 2=0, gen(akt_other)
la var 		akt_other "activity in other organization"




***Restrict on only wave 7 
keep 		if welle==7

***save Dataset
save 		"$data\DM_ind.dta", replace

log close log_DM_ind
