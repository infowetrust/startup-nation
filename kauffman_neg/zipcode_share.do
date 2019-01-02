// produce zipcode_share
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
u analysis34.minimal.dta, clear
keep zipcode incyear datastate quality obs growthz
keep if incyear < 2013 & incyear > 1987
replace zipcode = trim(itrim(zipcode))
drop if length(zipcode) != 5
// drop if regexm(zipcode,"[~`!@#$%^&*_+-=\':;,-.+*@$!%`()'#` /?a-zA-Z]")
drop if !regexm(zipcode, "[0-9][0-9][0-9][0-9][0-9]")
drop if zipcode == "00000"
collapse (sum) obs growthz (mean) quality, by(zipcode incyear datastate)
drop if missing(zipcode)
gen recpi = obs * quality
gen reai = growthz / recpi 
rename datastate state
rename incyear year 
drop growthz
sort state year
save zipcode_share.dta, replace
