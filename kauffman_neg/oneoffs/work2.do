	clear
	log using table1.log, replace
	u KY.collapsed.dta, clear
	drop if incyear < 1988
	
	gen trade3 = 1 if clust_traded | clust_traded_manufacturing | clust_traded_services
	replace trade3 = 0 if trade3 ==.

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"
	label variable clust~int "Traded Resources Int."
	label variable growthz "Growth"
	label variable trade3 "Traded(3)"
	
#delimit ;
	fsum growthz is_corp is_DE shortname eponymous patent trademark clust_local 
	trade3 clust_resource_int is_biotech is_ecommerce is_medicaldev is_semicond,  
	stat(mean sd) uselabel format(%9.5f);
	log close
	

/*
ssc install sum2docx
sum2docx growthz is_corp is_DE shortname eponymous patent trademark clust_local trade3 clust_resource_int is_biotech is_ecommerce is_medicaldev is_semicond using sum.docx, replace obs mean(%9.5f) sd(%9.5f)
*/

