****** By City******
clear
u KY_merged2.dta
drop if strpos(outputaddress,"KY") == 0
gen obs = 1
replace city = subinstr(city,","," ",.)
replace city = subinstr(city,"-"," ",.)
replace city = subinstr(city,"."," ",.)

gen cap_city = strtrim(stritrim(strupper(city)))

*keep if cap_city == ""

collapse (mean) quality=nowcastingquality (sum) obs, by(incyear cap_city)
*collapse (mean) quality=nowcastingquality (sum) obs, by(longitude latitude incyear cap_city)
sort cap_city incyear

save KY_city.dta, replace

import delimited using https://simplemaps.com/static/data/us-cities/uscitiesv1.4.csv, clear
keep if state_id == "KY"
save KYcitygeo.dta, replace

keep city lat lng
gen cap_city = strtrim(stritrim(strupper(city)))
drop city
save KYcitygeo.dta, replace

use KY_city.dta, clear
merge m:1 cap_city using KYcitygeo.dta
keep if _merge == 3
drop _merge
rename (lat lng) (latitude longitude)
save by_city_geo.dta,replace

sort quality
gen  quality_percentile_global = floor((_n-1)/_N*1000)

replace quality_percentile_global = quality_percentile_global +1 
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly cap_city incyear) (o qg qy city year)
safedrop id
egen id = group(longitude latitude)
keep id year city longitude latitude o qg qy
reshape wide o qg qy , i(id) j(year)
	 	 

gen datastate = "KY"
order id datastate city latitude longitude
	
	
foreach v of varlist o* qy* qg* {
        tostring `v' , replace force
        replace `v' = "0" if `v' == "."
 }
tostring latitude longitude, replace force
save KY_city.dta, replace

outsheet using ~/Desktop/scp_private-master/KY_geocode/KY_city.csv, names comma replace
