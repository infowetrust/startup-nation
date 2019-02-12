*Innovation first
cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
u KY.dta, clear
corp_collapse_any_state KY , workingfolder(/NOBACKUP/scratch/share_scp/scp_private/scp2018/)
drop if incyear < 1990
drop if incyear > 2018
logit growthz eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond if inrange(incyear, 1988,2008), vce(robust) or
predict quality, pr
save KY.minimal.dta, replace

import delimited using /user/user1/yl4180/KY.geocoding.csv, clear
drop if missing(street)
drop if v13 != "KY"
keep dataid county zip
tostring zip, replace
save KY.temp.dta, replace

***********************
clear
u KY.collapsed.RJ.dta
replace zipcode = substr(trim(itrim(zipcode)), 1,5)
drop if incyear < 1990
drop if incyear > 2018
merge m:m zipcode using /user/user1/yl4180/Kentucky/innovation.dta
keep if _merge == 3
drop _merge
save KY_graph.dta, replace

foreach v of varlist innov_* { 
	local region_name =  subinstr("`v'","innov_","",.)
	gen innovq_`region_name' = quality if `v' == 1
}

collapse (sum) innov_* innovq_*, by(incyear)
save KY_graph.dta, replace

rename incyear year
set scheme s2mono
line innov_soar year, lcolor(red) || line innov_triED year, lcolor(blue) || line innov_TCWK year, lcolor(green) || line innov_awesomeinc year, lcolor(purple) || line innov_entreprisecorp year, lcolor(orange) legend(label(1 "SOAR") lab(2 "TriED") lab(3 "TCWK") lab(4 "Awesome Inc.") lab(5 "Enterprise Corp")) ylabel(0 3000 6000 9000 12000, angle(0))  ytitle(Number of Founded Firms) xtitle(Year of Founding) title("Quantity of Entrepreneurship by RISE Region") xlabel(#5)  saving(obs.annual.gph, replace)
graph save /user/user1/yl4180/quantity_innov_yr, replace
***Quality -adjusted quantity (RECPI)
set scheme s2mono
line innovq_soar year, lcolor(red) || line innovq_triED year, lcolor(blue) || line innovq_TCWK year, lcolor(green) || line innovq_awesomeinc year, lcolor(purple) || line innovq_entreprisecorp year, lcolor(orange) legend(label(1 "SOAR") lab(2 "TriED") lab(3 "TCWK") lab(4 "Awesome Inc.") lab(5 "Enterprise Corp")) ylabel(, angle(0)) yscale(range(0 2.4)) ytitle(RECPI) xtitle(Year of Founding) title("Quality-adjusted quantity (RECPI) by RISE Region") xlabel(#5)  saving(recpi.annual.gph, replace)
graph save /user/user1/yl4180/RECPI_innov_yr, replace


