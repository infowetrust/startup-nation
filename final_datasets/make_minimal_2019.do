cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
clear
global mergetempsuffix = "_"
//global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
global statelist IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
//global longstatelist ALASKA ARKANSAS ARIZONA CALIFORNIA COLORADO FLORIDA GEORGIA IOWA IDAHO ILLINOIS KENTUCKY LOUISIANA MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING
global longstatelist IOWA IDAHO ILLINOIS KENTUCKY LOUISIANA MASSACHUSETTS MAINE MICHIGAN MINNESOTA MISSOURI NORTH_CAROLINA NORTH_DAKOTA NEW_JERSEY NEW_MEXICO NEW_YORK OHIO OKLAHOMA OREGON RHODE_ISLAND SOUTH_CAROLINA TENNESSEE TEXAS UTAH VIRGINIA VERMONT WASHINGTON WISCONSIN WYOMING
global prepare_mergerfile 0
global prepare_states 1
global fix_local_firm 0
global collapse_states 1
global make_minimal 1
global audit_table 1
global audit_compare 0
global yuting 0

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
keep if year(dateannounced)  <= 2018
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
	//safedrop dateannounced* targetname enterprisevalue equityvalue equityvalue_old equityvalue_new equityvalue_Z x mergeryear mergeryear_old mergeryear_new mergeryear_Z mergerdate mergerdate_old mergerdate_new mergerdate_Z ipo growthz_old growthz_new growthz_Z acq acq_old acq_new acq_Z
	safedrop dateannounced* targetname enterprisevalue equityvalue_new mergeryear_new mergerdate_new x growthz_new
	rename (equityvalue mergerdate mergeryear) (equityvalue_old mergerdate_old mergeryear_old)
	//gen ipo = !missing(ipodate) & inrange(ipodate-incdate,0,365*6)
	compress
	duplicates drop
	save `state'.dta, replace
	
	
	corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta) longstate(`longstate') 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	rename (equityvalue_old mergerdate_old mergeryear_old) (equityvalue mergerdate mergeryear) 

	compress
	duplicates drop
	save `state'.dta, replace
	
	//corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2014.dta) longstate(`longstate') 
	//replace targetsic = trim(targetsic)

	//foreach var of varlist equityvalue mergeryear mergerdate {
	//rename `var' `var'_Z}
	//compress
	//duplicates drop
	//save `state'.dta, replace
	
	//corp_add_mergers `state' ,dta(`state'.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.pre2014.dta) longstate(`longstate')
	//replace targetsic = trim(targetsic)
	//compress
	//duplicates drop
	//save `state'.dta, replace
	

}

	
	 }

if $fix_local_firm == 1{
global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY

	clear
	foreach state in $statelist{
	u `state'.dta, clear
	replace state = trim(itrim(state))
	capture confirm variable jurisdiction
	if _rc == 0 {
	safedrop local_firm
	replace jurisdiction = trim(itrim(upper(jurisdiction)))
	replace jurisdiction = "`state'" if missing(jurisdiction)
	gen local_firm= inlist(jurisdiction, "`state'","DE") & inlist(state, "`state'" ,"")
	}
	else {
	safedrop local_firm
	replace state = upper(trim(itrim(state)))
	gen local_firm = inlist(state, "`state'","")
	}
	save `state'.dta, replace
	}
	}
if $collapse_states == 1{
	clear
	global statelist
	global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
	foreach state in $statelist{
	u `state'.dta,clear
	capture confirm variable eponymous
    	if _rc != 0 {
	        gen eponymous = 0
         }
	save `state'.dta, replace
	corp_collapse_any_state_3merge `state', workingfolder(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/) 
	gen datastate = "`state'" 
	save `state'.collapsed.dta, replace
	}

	clear
	global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY
	gen a = .
	foreach state in $statelist{
		di "Adding state `state'"
		append using `state'.collapsed.dta, force
		save allstates.minimal.dta, replace
	}
	drop a
	compress
	duplicates drop
	drop if incyear < 1988 | incyear > 2014
	save allstates.minimal.dta, replace
	
}
if $audit_table == 1{

****** Bystate*****
clear
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg


u analysis34.minimal.dta,clear
safedrop obs
gen obs  =1
drop if incyear > 2014 | incyear<1988
collapse (sum) obs, by(datastate)
gen file = "old"
save bystate.dta , replace

u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/allstates.minimal.dta, clear
safedrop obs
gen obs  =1
drop if incyear > 2014 | incyear<1988
collapse (sum) obs, by(datastate)
gen file = "new"
append using bystate.dta 
save bystate.dta , replace


use bystate.dta , replace
reshape wide obs , i(datastate) j(file) string
gen diff_new = obsnew - obsold
gen ratio = abs(diff_new/obsold)
sort ratio 

save minimal_state.dta, replace

export delimited using /user/user1/yl4180/save/minimal_state.csv, replace
}
if $make_minimal == 1 {	
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets

	u allstates.minimal.dta, clear
	
	
	encode datastate, gen(statecode)
	// levelsof datastate, local(states) clean
	
	eststo clear
	eststo: logit growthz_old eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	predict quality_old, pr
	
	eststo: logit growthz_new eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	predict quality_new, pr
	
	//added below, try to replace qualitynow for the last couple of years
	//logit growthz_new eponymous shortname is_corp is_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	//predict qualitynow, pr
	//replace quality_new = qualitynow if inrange(incyear, 2014, 2018)
	//
	
	eststo: logit growthz_Z eponymous shortname is_corp nopatent_DE patent_noDE patent_and_DE trademark clust_local clust_traded is_biotech is_ecommerce is_medicaldev is_semicond i.statecode if inrange(incyear, 1988,2008), vce(robust) or
	esttab using "/user/user1/yl4180/save/Quality Model for All_State.csv", pr2 se eform indicate("State FE=*statecode") replace
	predict quality_Z, pr
	
	replace quality_old = 0 if missing(quality_old)
	replace quality_new = 0 if missing(quality_new)
	replace quality_Z = 0 if missing(quality_Z)
	
	corr quality_old quality_new quality_Z
	
	save allstates.minimal.dta, replace
}

if $yuting == 1{
	do Yu-ting_minimal.do
	}


if $audit_compare == 1{
************** audit **************
cd /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg
global statelist NJ
//OR,NY,RI, VT, WA, IA, UT, VA, TN, SC. CO, NJ has other states
//NY states name contain longstate
//WI jurisdiction crappy, GA, SC has other juris
//KY dataid completely different, WI dataid totally wrong
//Unknown: ME, TX, CA
u analysis34.minimal.dta,clear
foreach state in $statelist {
savesome if datastate == "`state'" using `state'.m.dta, replace
}

foreach state in $statelist {
u `state'.m.dta, clear
merge m:m dataid using /NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta
savesome if _merge == 1 using `state'.missing.dta
keep if _merge == 3
drop _merge
save `state'.merge.dta, replace
}


}

