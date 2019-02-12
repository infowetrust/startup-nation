//no it count
clear
gen obs = .
save k_fold_result.dta, replace
global datafile "KY2.collapsed.dta"
capture confirm variable fold


clear
gen iteration = .
save k_fold_result.dta , replace

forvalues testfold = 0/9{
    u $datafile, replace
	bsample 
	
	drop if missing(quality)
    sort quality
    gen percentile = _n/_N

    /* top 1% analysis */
    gen top1 = percentile >= .99
    qui: sum growthz
    local totgrowth `r(sum)'
    qui: sum growthz if top1
    local top1growth `r(sum)'
    local sharetop1 = `top1growth'/`totgrowth'
    
	di "Share of Top 1 Percent: `sharetop1'"
    
	replace percentile = floor(_n/_N*20)/20
    replace percentile = .95 if percentile == 1
    safedrop obs
    gen obs = 1
    collapse (sum)obs  growthz, by(percentile)
    egen tot = sum(growthz)
    gen sharegrowth = growthz/tot
    gen sharetop1 = `sharetop1'
	local sharetop5 = sharegrowth[_N]
	local sharetop10 = sharegrowth[_N] + sharegrowth[_N-1]
	
    gen iteration = `testfold'
    append using k_fold_result.dta
    save k_fold_result.dta , replace
}



collapse (min) minshare = sharegrowth (max) maxshare=sharegrowth (p50) medshare =sharegrowth medtop1=sharetop1, by(percentile)

sum medtop1
local top1 = round(`r(mean)',.01)

set scheme s1mono
# delimit ;
graph twoway bar medshare percentile, 
			text(.6 .35 "Share of realized growth" "---------------------------" "Top 1%: `top1'"
						 , justification(left)) 
			barwidth(.04) xlabel(0(.05).95) ytitle("Percent of realized growth events")
			title("Model Out of Sample Accuracy ", size(medium))  note("summary of 10 random bootstrap samples")
			saving("test_quality.gph",replace)
			xtitle("Percentile") ytitle("Share of All Growth Firms")
		|| rcap minshare maxshare percentile , 
		legend(off);
graph save test_quality, replace

clear
gen obs = .
save k_fold_result.dta, replace
global datafile "KY2.collapsed.dta"
capture confirm variable fold

***************************** Nowcasting test ****************************************
clear
gen iteration = .
save k_fold_result.dta , replace

forvalues testfold = 0/9{
    u $datafile, replace
	bsample 
	
	drop if missing(nowcastingquality)
    sort nowcastingquality
    gen percentile = _n/_N

    /* top 1% analysis */
    gen top1 = percentile >= .99
    qui: sum growthz
    local totgrowth `r(sum)'
    qui: sum growthz if top1
    local top1growth `r(sum)'
    local sharetop1 = `top1growth'/`totgrowth'
    
	di "Share of Top 1 Percent: `sharetop1'"
    
	replace percentile = floor(_n/_N*20)/20
    replace percentile = .95 if percentile == 1
    safedrop obs
    gen obs = 1
    collapse (sum)obs  growthz, by(percentile)
    egen tot = sum(growthz)
    gen sharegrowth = growthz/tot
    gen sharetop1 = `sharetop1'
	local sharetop5 = sharegrowth[_N]
	local sharetop10 = sharegrowth[_N] + sharegrowth[_N-1]
	
    gen iteration = `testfold'
    append using k_fold_result.dta
    save k_fold_result.dta , replace
}



collapse (min) minshare = sharegrowth (max) maxshare=sharegrowth (p50) medshare =sharegrowth medtop1=sharetop1, by(percentile)

sum medtop1
local top1p = round(`r(mean)',.01)

set scheme s1mono
# delimit ;
graph twoway bar medshare percentile, 
			text(.6 .35 "Share of realized growth" "---------------------------" "Top 1%: `top1p'"
						 , justification(left)) 
			barwidth(.04) xlabel(0(.05).95) ytitle("Percent of realized growth events")
			title("Model Out of Sample Accuracy (Nowcasting)", size(medium))  note("summary of 10 random bootstrap samples")
			saving("test_nowcasting.gph",replace)
			xtitle("Percentile") ytitle("Share of All Growth Firms")
		|| rcap minshare maxshare percentile , 
		legend(off);
graph combine test_quality.gph test_nowcasting.gph, row(2) saving(combine);

/*
forvalues num = 0/9{
u k_fold_result, clear
keep if foldno == `num'
keep percentile sharegrowth sharetop1 
rename sharegrowth sharegrowth_`num'
rename sharetop1 sharetop1_`num'
save merge_`num'.dta, replace
}

forvalues number = 8(-1)0{
merge 1:1 percentile using merge_`number'.dta
drop _merge
save kmerge, replace
}
order sharegrowth_1 sharegrowth_2 sharegrowth_3 sharegrowth_4 sharegrowth_5 sharegrowth_6 sharegrowth_7 sharegrowth_8 sharegrowth_9
safedrop sharegrowth_median
egen sharegrowth_median = rowmedian(sharegrowth_1 sharegrowth_2 sharegrowth_3 sharegrowth_4 sharegrowth_5 sharegrowth_6 sharegrowth_7 sharegrowth_8 sharegrowth_9)
safedrop sharegrowth_max
egen sharegrowth_max = rowmax(sharegrowth_1 sharegrowth_2 sharegrowth_3 sharegrowth_4 sharegrowth_5 sharegrowth_6 sharegrowth_7 sharegrowth_8 sharegrowth_9)
safedrop sharegrowth_min
egen sharegrowth_min = rowmin(sharegrowth_1 sharegrowth_2 sharegrowth_3 sharegrowth_4 sharegrowth_5 sharegrowth_6 sharegrowth_7 sharegrowth_8 sharegrowth_9)
order sharegrowth_median sharegrowth_max sharegrowth_min

order sharetop1_1 sharetop1_2 sharetop1_3 sharetop1_4 sharetop1_5 sharetop1_6 sharetop1_7 sharetop1_8 sharetop1_9
safedrop sharetop1_median
egen sharetop1_median = rowmedian(sharetop1_1 sharetop1_2 sharetop1_3 sharetop1_4 sharetop1_5 sharetop1_6 sharetop1_7 sharetop1_8 sharetop1_9)
safedrop sharetop1_max
egen sharetop1_max = rowmax(sharetop1_1 sharetop1_2 sharetop1_3 sharetop1_4 sharetop1_5 sharetop1_6 sharetop1_7 sharetop1_8 sharetop1_9)
safedrop sharetop1_min
egen sharetop1_min = rowmin(sharetop1_1 sharetop1_2 sharetop1_3 sharetop1_4 sharetop1_5 sharetop1_6 sharetop1_7 sharetop1_8 sharetop1_9)
order percentile sharegrowth_median sharegrowth_max sharegrowth_min sharetop1_median sharetop1_max sharetop1_min

#delimit ;	
local sharetop1 = substr(string(round(sharetop1_median,.01)),1,3);
*/
