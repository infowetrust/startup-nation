u analysis34.minimal.dta, clear
keep if incyear<2013
collapse (sum) obs growthz (mean) quality, by(zipcode incyear datastate)
gen recpi = quality * obs
gen reai = growthz / recpi
drop if missing(zipcode)
replace zipcode = trim(itrim(zipcode))
drop if regexm(zipcode,"[A-Za-z]")
drop if regexm(zipcode,"[~!@#$%^&*()_+=-\{}'`;?/.,]")
drop if regexm(zipcode,"-")
drop if regexm(zipcode,"00000")
drop if regexm(zipcode," ")
drop if strlen(zipcode) > 5
save zipcodeshare_new.dta
