/*******************************************************************************
Tasks: 
- prepare spell data (such as unemployment durations)
*******************************************************************************/

***Präambel***
*Log-File
cap log close log_spells
log using "$log\04_spells.log", name(log_spells) replace

use "$orig_bef\bio_spells.dta", clear
*************

***merge interview date for w7
merge 		m:1 pnr using "$data\pintdat_w7.dta"

***Missing values
tab1		bjahr ejahr bmonat emonat
tab 		bjahr, nol
foreach 	var of varlist bmonat bjahr emonat ejahr {
	recode	`var' -8/-1=.
}

***Last interview Wave 7: Sept 2013
***All spells censored at month of interview or Sept 2013
gen 		start=ym(bjahr, bmonat)
gen			stop=ym(ejahr, emonat)
format 		%tm start stop
drop 		if start>pintdat_n & start!=.
drop 		if start<=pintdat_n & start>ym(2013, 9)  & start!=.
replace 	stop=pintdat_n if stop>pintdat_n & stop!=.
replace 	stop=ym(2013, 9) if (stop>ym(2013, 9) & stop!=.) ///
			| (ejahr>2013 & ejahr!=.)

***Sorting
sort		pnr spellnr
drop		if spelltyp != 2

***********************************
drop		if start==. | stop==.
***********************************

drop		if stop < start

***duration of spells
gen			spell_d=stop-start+1 //without +1 duration=0 if same month
label var	spell_d "duration of spell"

tab			spell_d BIO0600
sum			spell_d

*right censored data
tab			BIO0600
tab			BIO0600, nol
recode		BIO0600 -4=. -3=.a -2/-1=. 2=0, gen(censored)
tab			censored, mis

br			start bmonat bjahr  stop emonat ejahr spell_d censored zensiert

***duration of current unemployment (here only if registered)
tab			spelltyp
tab			spelltyp, nol
gen			unemp_cur=spell_d if spelltyp == 2 ///
			& ((stop>=pintdat_n & stop!=.) | (stop>=ym(2013, 1) & pintdat_n==. & stop!=.))
label var	unemp_cur "Dauer akt. Arbeitslosigkeit"

tab			unemp_cur
sum			unemp_cur, d
*hist		unemp_cur, norm

*sum up overlapping spells of the same type
bysort pnr:	egen n_pnr=count(pnr)
sum 		n_pnr
sort 		pnr spellnr

gen 		unemp_cur_n=unemp_cur
forvalue 	x=1(1)12 {
	by pnr:	replace unemp_cur_n=unemp_cur_n+spell_d[_n-`x'] if ///
			(start <= stop[_n-`x'] & stop[_n-`x']!=.)
}
			
label var	unemp_cur_n "Dauer akt. Arbeitslosigkeit"
corr		unemp_cur unemp_cur_n, m
sum			unemp_cur_n, d

*rescale: months -> years
replace		unemp_cur=unemp_cur/12
replace		unemp_cur_n=unemp_cur_n/12

***Number of unemployment episodes
gen			unemp_ep=0
gen			spell_alo=1 if spelltyp == 2
bysort pnr: replace unemp_ep=sum(spell_alo)
label var	unemp_ep "Anzahl Arbeitslosigkeitsperioden"
br			pnr spelltyp spell_alo start stop spell_d unemp_ep

***Correct number of unemployment episodes if overlaping
/*
forvalue 	x=1(1)12 {
	br 		pnr spelltyp spell_alo start stop spell_d unemp_ep if ///
			start <= stop[_n-`x'] & stop[_n-`x']!=. & pnr==pnr[_n-`x']
	sleep	1000
}
*/
gen 		unemp_ep_n=unemp_ep
forvalue 	x=1(1)12 {
	by pnr:	replace unemp_ep_n=unemp_ep_n-1 if ///
			start <= stop[_n-`x'] & stop[_n-`x']!=. & pnr==pnr[_n-`x']
}
corr		unemp_ep unemp_ep_n, m
sum			unemp_ep*, d
tab1		unemp_ep*
hist		unemp_ep, norm

***keep only last row per case and no cases with missing value on current duration
bysort pnr:	drop if (spellnr < spellnr[_n+1] & spellnr[_n+1] < .) //| unemp_cur_n==.

***Number of unemployment episodes - categories
tab1		unemp_ep*
recode 		unemp_ep_n 1=0 2=1 3/12=2, gen(unemp_ep_ord)
la def 		aloord 0"1 AL-Episode" 1"2 AL-Episoden" 2"3 oder mehr AL-Episoden"
la val 		unemp_ep_ord aloord
la var 		unemp_ep_ord "Arbeitslosigkeitsperioden (ord.)"
tab 		unemp_ep unemp_ep_ord

***wave indicator
gen			welle=7 if unemp_cur != .
replace		welle=7 if (unemp_ep < . & stop==pintdat_n & stop!=.) 
replace		welle=7 if (unemp_ep<. & (pintdat_n==. | stop==.) & ejahr==2013)

drop		if welle == .

sort		pnr
bysort pnr:	egen n_pnr2=count(pnr)
sum 		n_pnr2
drop 		n_pnr2		

***keep only relevant variables
keep		pnr welle unemp_cur* unemp_ep* censored

save		"$data\DM_spells.dta", replace

log close 	log_spells
