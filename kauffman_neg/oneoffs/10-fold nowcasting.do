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

