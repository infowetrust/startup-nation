clear
u sampleKY.dta
gen obs = 1 
collapse (mean) quality (sum) obs, by(longitude latitude incyear)
drop if longitude =="" & latitude ==""
sort obs
save withinKY.dta, replace
sort quality
gen  quality_percentile_global = floor((_n-1)/_N*1000)

replace quality_percentile_global = quality_percentile_global +1 
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly longitude latitude incyear) (o qg qy lon lat year)
safedrop id
egen id = group(lon lat)
keep id year lon lat o qg qy
reshape wide o qg qy , i(id) j(year)
	 	 
foreach v of varlist o* qy* qg* {
        tostring `v' , replace force
        replace `v' = "0" if `v' == "."
    }
