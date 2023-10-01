//Group3- Doedit solutions Ass2
cls
clear all
use "/Users/asparuhrangelov/Downloads/rlab_data_assignment2/ifrsdata.dta"
//Q2 First regression
reg liquidity ifrs, r cluster(company)

sum liquidity if year<=2004 & ifrs==1
sum liquidity if year>2004 & ifrs==1
sum liquidity if year<=2004 & ifrs==0
sum liquidity if year>2004 & ifrs==0

gen post = (year >= 2005) 
replace post = 0 if  year <= 2004
//creating the 'post' variable such that it indicates 1 for observations with 
//year >=2005, and 0 otherwise

gen postifrs = post*ifrs
//creating interaction variable for post and ifrs#i

reg liquidity ifrs postifrs, r cluster(company)
reg liquidity ifrs post postifrs, r cluster(company)
//regressions with interaction term

gen logmv = ln(mv)
gen loganalysts = ln(analysts)
//log variables generation


reg liquidity ifrs post leverage sdroe logmv loganalysts roe paydividends postifrs, r cluster(company) 
//complete regression with difference-in-difference and controls

//Q3
cls
clear all 
global path "/Users/asparuhrangelov/Downloads/rlab_data_assignment2"
use "$path/announcements.dta"
ren cyear year
ren rdq anndate
ren periodenddate datadate //so that they match with the naming of the other dataset
sort symbol datadate
save "$path/announcements_sorted.dta", replace

//With the subsequent commands we merge the datasets
use "$path/analysts.dta"
sort symbol datadate
merge symbol using "$path/announcements_sorted.dta"
keep if _merge==3
drop _merge
sort crspcode anndate
//we also don't need empty observations, so we drop them
drop if forecast==.
drop if datadate==.
save "$path/stagetwo.dta", replace
//mergiing analyst and anouncement with stock returns
use "$path/stockreturns"
sort crspcode anndate
merge crspcode using "$path/stagetwo.dta"
keep if _merge==3
drop _merge
sort compustatcode year
save "$path/stagethree.dta", replace
//Here we do final merging...
use "$path/big4.dta"
sort compustatcode year
merge compustatcode using "$path/stagethree.dta"
keep if _merge==3
drop _merge
save "$path/everything", replace

//Now, we drop all remaining empty observations that are NOT needed
//and do winsoriszing 
use "$path/everything"
drop if prccq==. | prccq<2.5
drop if earnings==.
drop if bhar01==.

//We set the extremely high observations in bhar01 equal to the respective quantiles
sum bhar01,d
return list //here we check the respective porcentiles of bhar01
replace bhar01=r(p1) if bhar01 <r(p1)
replace bhar01=r(p99) if bhar01>r(p99)

//Here we generate the surprise variable 
gen surprise= (earnings-forecast)/prccq
drop if surprise < -0.05 | surprise > 0.05

//Here we do first regression in a)
reg bhar01 surprise, r cluster(symbol) 

//Now we turn to the Difference-in-difference regression in b
gen big4=1
replace big4=0 if big4auditor==0

//Create the interaction variable 
gen big4surprise = big4*surprise

reg bhar01 surprise big4 big4surprise, r cluster(symbol) 

//Now, generation of quantiles, according to the code from tutorial 1
egen pctiles=cut(surprise),group(5)

//And the final regression, again, based on the code from tutorial 1
gen coeff=.
forvalues i = 0/4 {
	reg bhar01 surprise if pctiles == `i', r cluster(symbol) 
    di _b[surprise]
	replace coeff=_b[surprise] if pctiles ==`i'
}
graph bar (mean) coeff, over(pctiles)
//bar chart for the question
