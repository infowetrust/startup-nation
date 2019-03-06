cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

************* Keep only DE/KY firm from 1988 to 2018 ***********
u KY.dta, clear
replace state = trim(itrim(state))
replace city = upper(trim(itrim(city)))
replace zipcode = trim(itrim(zipcode))
replace address = upper(trim(itrim(address)))
keep if jurisdiction == "KY" | jurisdiction =="DE"
keep if state == "KY"
keep if incyear < 2019 & incyear > 1987
duplicates drop
compress
save KY.RJ.dta, replace

**** address ******
/*
u KY.RJ.dta, clear
keep if state == "KY"
keep if jurisdiction == "KY" | jurisdiction =="DE"
keep if incyear < 2019 & incyear > 1987
keep dataid address city state zipcode

replace zipcode = substr(zipcode, 1,5)
duplicates drop
save KY.address.dta, replace
export delimited using "/user/user1/yl4180/save/KY.address.csv", replace
*/

******* Collapse *******

corp_collapse_any_state KY.RJ , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/scp2018/)

****** train before 2011 ********
/*
u KY.RJ.collapsed.dta, clear
gen rsort = runiform()
gen trainingyears = inrange(incyear,1988,2011)
by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
replace trainingsample = 0 if !trainingyears
*/
********** logit ******
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal.dta, clear

*** full model ****
logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2008), vce(robust) or
u KY.RJ.collapsed.dta,clear
predict quality, pr
save KY.RJ.collasped.dta, replace
u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal.dta, clear

logit growthz_new eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2008), vce(robust) or
u KY.RJ.collapsed.dta, clear
predict qualitynow, pr
save KY.RJ.collapsed.dta, replace
replace quality = qualitynow if inrange(incyear, 2016, 2018)

********* Geocoding + KY.file *********/

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

merge m:m dataid using KY.RJ.collapsed.dta

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




