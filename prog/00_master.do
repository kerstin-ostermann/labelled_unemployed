/*
Master file 
Paper: Labelled Unemployed: Neighbourhood composition and the enforcement of employment norms
Authors: Kerstin Ostermann, Sebastian Lang
Published in Work, Employment and Society

Last year of code adaptation: 2026
contact: Kerstin Ostermann, Kerstin.ostermann@uni-bielefeld.de

*/

***Präambel***
clear all
cap log close _all

set 		more off
set 		rmsg on

global		path "[insert your path here]"
global 		orig_bef \\IAB\dfs\017\Ablagen\D01700-IAB-Projekte\D01700-Projekte-FDZ\Datensaetze\_Endprodukte\PASS\PASS_0622_v1
global 		orig "${path}\Daten\orig"
global		data "${path}\Daten"
global 		prog "${path}\prog"
global 		log  "${path}\log"
global 		out  "${path}\out"


***Define personal adopath
adopath ++ "${path}\prog"
adopath + "N:\Ablagen\D01700-Allgemein\STATA\bocode" 

set scheme plotplainblind

**************


do 			"$prog\01_pintdat.do"
do 			"$prog\02_nh.do"
do 			"$prog\03_ind.do"
do 			"$prog\04_spells.do"
do 			"$prog\05_hh.do"
do 			"$prog\06_child.do"
do 			"$prog\07_HHgen.do"
do 			"$prog\08_merge.do"
do			"$prog\09_check_selectivity.do"
do			"$prog\10_imputation.do"

***models
do 			"$prog\11_main.do"
do 			"$prog\12_robustness.do"

**description
do 			"$prog\13_sample_description.do"
 

