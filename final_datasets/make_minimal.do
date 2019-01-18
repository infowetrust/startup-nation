cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
clear
global mergetempsuffix = "_"
global statelist AK AR AZ CA CO FL GA IA ID IL KY MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING
global prepare_mergerfile 0
global prepare_states 0
global append_states 1
global make_minimal 0

set more off
if $prepare_mergerfile == 1{
use  /NOBACKUP/scratch/share_scp/ext_data/mergers.dta , clear
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/mergers.pre2014.dta , replace


use  /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta , clear
rename targetprimarysiccode targetsic
keep if year(dateannounced)  <= 2014
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta , replace


use  /user/user1/yl4180/save/Z_mergers.dta , clear
keep if year(dateannounced)  <= 2014
replace dealvalue = subinstr(dealvalue,",","",.)
replace dealvalue = subinstr(dealvalue,"*","",.)
destring dealvalue, replace force
rename equityvalue __equityvalue 
rename dealvalue equityvalue
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta , replace
}

if $prepare_states == 1{

local n: word count $statelist
forvalues i = 1/`n'{
	local state: word `i' of $statelist
	local longstate: word `i' of $longstatelist
	local longstate= subinstr("`longstate'","_"," ",.)
	
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta, clear
	safedrop dateannounced* targetname enterprisevalue equityvalue x mergeryear mergerdate
	gen ipo = !missing(ipodate) & inrange(ipodate-incdate,0,365*6)
	
	save `state'.only.dta, replace
	save `state'.only.origin.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.pre2014.dta) longstate(`longstate')
	replace targetsic = trim(targetsic)
	gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate acq growthz{
	rename `var' `var'_old
	}
	save `state'.only.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta) longstate(`longstate') 
	replace targetsic = trim(targetsic)
	gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate acq growthz{
	rename `var' `var'_new
	}
	save `state'.only.dta, replace
	
	corp_add_mergers `state' ,dta(`state'.only.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta) longstate(`longstate') 
	replace targetsic = trim(targetsic)
	gen acq = !missing(mergerdate) & inrange(mergerdate-incdate,0,365*6) & substr(targetsic, 1,1) != "6" & !missing(targetsic)
	gen growthz  = ipo | acq
	
	foreach var of varlist equityvalue mergeryear mergerdate acq growthz{
	rename `var' `var'_Z
	}
	save `state'.only.dta, replace
	

}

	
	 }

if $append_states == 1{
	clear
	local n: word count $statelist
	forvalues i = 1/`n'{
	local state: word `i' of $statelist
	u `state'.only.dta,clear
	capture confirm variable eponymous
    	if _rc != 0 {
	        gen eponymous = 0
         }
	
	replace patent_assignment = 0 if missing(patent_assignment)
	replace patent_application = 0 if missing(patent_application)
	replace trademark = 0 if missing(trademark)
	gen patent = max(patent_assignment, patent_application)
	gen patent_noDE = patent & !is_DE
	gen nopatent_DE = !patent & is_DE
	gen patent_and_DE = patent & is_DE
	
	
	gen clust_local = is_Local
	gen clust_high_tech = is_HighTech | is_Chemical
	gen clust_resource_int = is_Energy | is_Agriculture_and_Food | is_Mining
	gen clust_traded_services = is_Services | is_Publishing
	gen clust_traded_manufacturing = is_Auto | is_Clothing | is_Distribution | is_Consuma | is_Paper
	gen clust_traded = max(clust_high_tech, clust_resource_int, clust_traded_services, clust_traded_manufacturing)
	
	gen datastate = "`state'" //run in minimal2
	keep if datastate == state // not in minimal2
	
	keep dataid datastate city zipcode incyear incdate trademark shortname eponymous ipodate mergerdate* is_* growthz* patent patent_noDE nopatent_DE patent_and_DE clust*
	compress
	save `state'.minimal.dta,replace
	}
	clear
	gen a = .
	local n: word count $statelist
	forvalues i = 1/`n'{
		local state: word `i' of $statelist
		di "Adding state `state'"
		append using `state'.minimal.dta, force

		save allstates.minimal2.dta, replace
	}
	drop a
	save allstates.minimal2.dta, replace
	
}

if $make_minimal == 1 {	
	u allstates.minimal.dta, clear

	// rename state datastate //commented in minimal2
	encode datastate, gen(statecode)
	// levelsof datastate, local(states) clean
	
	logit growthz_old eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	esttab using "/user/user1/yl4180/save/Quality Model for All States.csv", pr2 se indicate("State FE=*statecode") replace
	predict quality_old, pr
	logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	esttab using "/user/user1/yl4180/save/Quality Model for All States.csv", pr2 se indicate("State FE=*statecode") append
	predict quality_new, pr
	
	logit growthz_Z eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	esttab using "/user/user1yl4180/save/Quality Model for All State.csv", pr2 se indicate("State FE=*statecode") append
	predict quality_Z, pr
	
	corr quality_old quality_new quality_Z
	
	save allstates.minimal_final.dta, replace
	u allstates.minimal_final.dta, clear
	

}
