/*"Boyd", "Carter", "Rowan", "Bath", "Montgomery", "Clark", "Madison", "Rockcastle", "Laurel", "Whitley", "Lawrence", "Elliott", "Morgan", "Menifee", "Powell", "Estill", "Jackson", "Wolfe", "Lee", "Owsley", "Clay", "Knox", "Johnson", "Magoffin", "Breathitt", "Perry", "Leslie", "Bell", "Martin", "Floyd", "Knott", "Pike", "Letcher", "Harlan"

"Kenton", "Boone", "Campbell", "Gallatin", "Carroll", "Owen", "Grant", "Pendleton"

"Henderson", "McLean", "Muhlenberg", "Todd", "Union", "Webster", "Hopkins", "Christian", "Crittenden", "Caldwell", "Livingston", "Lyon", "Trigg", "Ballard", "McCracken", "Carlisle", "Graves", "Marshall", "Calloway", "Hickman", "Fulton"

"Harrison", "Bourbon", "Fayette", "Jessamine", "Garrard", "Boyle", "Mercer", "Anderson", "Woodford", "Scott", "Franklin", "Montgomery", "Clark", "Madison"

"Oldham", "Shelby", "Jefferson", "Spencer", "Bullitt", "Nelson", "Washington", "Marion", "Taylor", "Green", "Larue", "Hardin", "Meade" 
*/
cd /user/user1/yl4180/Kentucky/
import excel using FIPS.xls, firstrow clear
save FIPS.dta, replace
import delimited using ZIP.csv, clear
rename county FIPS
destring FIPS, replace
keep zip FIPS
save ZIP.dta, replace
merge m:1 FIPS using FIPS.dta

keep if _merge == 3
drop _merge

drop FIPS

# delimit ;
gen innov_soar = 1 if inlist(County, "Boyd", "Carter", "Rowan", "Bath", "Montgomery", "Clark", "Madison", "Breathitt") | 
inlist(County, "Rockcastle", "Laurel", "Whitley", "Lawrence", "Elliott", "Morgan", "Menifee", "Powell") |
inlist(County, "Estill", "Jackson", "Wolfe", "Lee", "Owsley", "Clay", "Knox", "Johnson", "Magoffin") |
inlist(County, "Perry", "Leslie", "Bell", "Martin", "Floyd", "Knott", "Pike", "Letcher", "Harlan");

gen innov_triED = 1 if inlist(County, "Kenton", "Boone", "Campbell", "Gallatin", "Carroll", "Owen", "Grant", "Pendleton");

# delimit ;
gen innov_TCWK = 1 if inlist(County, "Henderson", "McLean", "Muhlenberg", "Todd", "Union", "Webster", "Hopkins", "Christian") |
inlist(County, "Crittenden", "Caldwell", "Livingston", "Lyon", "Trigg", "Ballard", "McCracken", "Carlisle", "Graves") |
inlist(County, "Marshall", "Calloway", "Hickman", "Fulton");

# delimit ;
gen innov_awesomeinc = 1 if inlist(County, "Harrison", "Bourbon", "Fayette", "Jessamine", "Garrard", "Boyle", "Mercer", "Anderson") |
inlist(County, "Woodford", "Scott", "Franklin", "Montgomery", "Clark", "Madison");

# delimit ;
gen innov_entreprisecorp = 1 if inlist(County, "Oldham", "Shelby", "Jefferson", "Spencer", "Bullitt", "Nelson", "Washington", "Marion") |
inlist(County, "Taylor", "Green", "Larue", "Hardin", "Meade");

drop if innov_soar ==. & innov_triED ==. & innov_TCWK ==. & innov_awesomeinc ==. & innov_entreprisecorp ==.

replace innov_soar = 0 if innov_soar ==.
replace innov_triED = 0 if innov_triED ==.
replace innov_TCWK = 0 if innov_TCWK ==.
replace innov_awesomeinc = 0 if innov_awesomeinc ==.
replace innov_entreprisecorp = 0 if innov_entreprisecorp ==.

gen innov = 1 if innov_soar | innov_triED | innov_TCWK | innov_awesomeinc | innov_entreprisecorp
replace innov = 0 if innov ==.
rename zip zipcode

save innov.dta, replace
export delimited using innov.csv ,replace

use innov.dta, clear;
destring zipcode, replace;
sort zipcode;

#delimit ;
quietly by zipcode: gen dup = cond(_N == 1,0,_n);

drop if dup > 1;
drop dup;

save innovation.dta, replace;
use innovation.dta, clear;
tostring zipcode, replace;
save innovation.dta, replace;





/*********** graphs ****************/

/*

foreach v of varlist innov_* { 
	local region_name =  subinstr("`v'","innov_","",.)
	gen innovq_`region_name' = nowcastingquality if `v' == 1
}

collapse (sum) innov_* innovq_* , by(incyear)
drop if incyear < 1990


set scheme s2mono
line innov_* incyear , legend(label(1 "SOAR")) ytitle(Number of Founded Firms) xtitle(Year of Founding) title("Quantity of Entrepreneurship by RISE Region")

## Quality -adjusted quantity (RECPI)
line innovq_* incyear , 

## RECPI/quantity = quality
line

	
