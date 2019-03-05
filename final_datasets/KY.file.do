
clear 
//import delimited using "/user/user1/yl4180/save/KY_lat_lon.csv", varname(1)
//save KY_lat_lon.dta, replace

cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
u KY_lat_lon.dta, clear

replace dataid = trim(dataid)

replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11
replace dataid = "0" + dataid if strlen(dataid) < 11

keep if v13 == "KY"
drop if missing(street)
replace v12 = trim(itrim(upper(v12)))
//replace city = trim(itrim(upper(city)))
//drop if city != v12
//tostring zip, replace
// drop if zip != zipcode

save KY_lat_lon_only.dta,replace

merge m:m dataid using KY.collapsed.RJ.dta

keep if _merge ==3
drop _merge
drop if missing(longitude) & missing(latitude)
keep if incyear >= 2015
keep dataid address city state zipcode quality incyear
duplicates drop
compress
save KY.file.dta,replace

sort quality
gen  quality_percentile_global = floor((_n-1)/_N*100)

replace quality_percentile_global = quality_percentile_global +1 
rename (quality_percentile_global incyear) (qg year)

/*
bysort incyear (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
replace quality_percentile_yearly = quality_percentile_yearly +1

rename (obs quality_percentile_global quality_percentile_yearly incyear) (o qg qy year)
safedrop id
egen id = group(longitude latitude)
keep id year longitude latitude o qg qy
reshape wide o qg qy , i(id) j(year)
	 	 
gen datastate = "KY"
order id datastate latitude longitude
	
*/
foreach v of varlist year quality qg {
        tostring `v' , replace force
        replace `v' = "0" if `v' == "."
 }

save KY.file.dta,replace

merge m:m dataid using /NOBACKUP/scratch/share_scp/scp_private/scp2018/KY.dta, keepus(entityname)
keep if _merge ==3
drop _merge
duplicates drop
compress
drop quality
order dataid entityname qg address city state zipcode year

merge m:m dataid using /NOBACKUP/scratch/share_scp/scp_private/scp2018/KY.directors.dta

drop role 
drop if _merge == 2
drop _merge
rename fullname manager
rename qg quality
order dataid entityname quality address city state zipcode year manager
sort quality year
duplicates drop
compress
save KY.file.dta, replace

outsheet using /user/user1/yl4180/save/KY.file.csv, names comma replace


