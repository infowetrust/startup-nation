
cd /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/
u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.dta,clear
keep if year(dateannounced)  < 2019 & year(dateannounced)  > 1999
drop if financial_merger==1 | oil_mining_merger == 1
destring equityvalue, replace force
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta, replace

rename equityvalue equityvalue_Z
collapse (sum) equityvalue_Z

gen id =1

save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equityvalue_Z.dta, replace

************

u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta,clear
keep if year(dateannounced)  < 2019 & year(dateannounced)  > 1999
drop if financial_merger==1 | oil_mining_merger == 1
destring equityvalue, replace force
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.post2000.dta, replace

rename equityvalue equityvalue_new
collapse (sum) equityvalue_new
gen id =1
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equityvalue_new.dta, replace
***********
global mergetempsuffix "_"

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.post2000.dta /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta 
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic _mergex)
rename equityvalue equityvalue_new
collapse (sum) equityvalue_new if _mergex == "no match", by(_mergex)
gen id = 1
rename equityvalue_new equity_nomatch_new
merge 1:1 id using equityvalue_new.dta
drop _merge
gen misspct_new = equity_nomatch_new / equityvalue_new
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equitystats.dta, replace

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.post2000.dta
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic _mergex)
rename equityvalue equityvalue_Z
collapse (sum) equityvalue_Z if _mergex == "no match", by(_mergex)
gen id = 1
rename equityvalue_Z equity_nomatch_Z
merge 1:1 id using equityvalue_Z.dta
drop _merge 
gen misspct_Z = equity_nomatch_Z / equityvalue_Z
append using /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equitystats.dta
drop id
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equitystats.dta, replace
export delimited using /user/user1/yl4180/save/equitystats.csv, replace

********* Match rate of collapsed file ************
/**************** MATCH RATE for NEW*************
cd /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/
u mergers_2018.dta, clear
keep if year(dateannounced)  < 2015 & year(dateannounced)  > 1987
drop if financial_merger==1 | oil_mining_merger == 1

destring equityvalue, replace force
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
rename equityvalue equityvalue_new
collapse (sum) equityvalue_new

gen id =1

save equityvalue_new.dta, replace

****** allstates *****
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
u allstates.minimal.dta, clear
destring equityvalue_new, replace force
drop if inlist(targetsic, "1041", "1311")
drop if substr(targetsic, 1,1) != "6"
collapse (min) mergerdate_new (max) equityvalue_new , by(dataid targetsic)
collapse (sum) equityvalue_new
rename equityvalue_new collapsed_new 

gen id = 1

save equityvalue_newcollapsed.dta, replace
merge 1:1 id using /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equityvalue_new.dta
gen ratio = collapsed_new / equityvalue_new
drop _merge 
save ratio_new.dta, replace



**************** MATCH RATE for Z*************
cd /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/
u Z_mergers.dta, clear
keep if year(dateannounced)  < 2015 & year(dateannounced)  > 1987
drop if financial_merger==1 | oil_mining_merger == 1

destring equityvalue, replace force
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
rename equityvalue equityvalue_Z
collapse (sum) equityvalue_Z

gen id =1

save equityvalue_Z.dta, replace
*************************
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
u allstates.minimal.dta, clear
destring equityvalue_Z, replace force
drop if inlist(targetsic_Z, "1041", "1311")
drop if substr(targetsic_Z, 1,1) != "6"
collapse (min) mergerdate_Z (max) equityvalue_Z , by(dataid targetsic)
collapse (sum) equityvalue_Z
rename equityvalue_Z collapsed_Z 

gen id = 1

save equityvalue_Zcollapsed.dta, replace
merge 1:1 id using /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/equityvalue_Z.dta
gen ratio = collapsed_Z / equityvalue_Z
drop _merge 
save ratio_Z.dta, replace

********
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
global statelist AK AR AZ CA CO FL GA IA ID IL KY LA MA ME MI MN MO NC ND NJ NM NY OH OK OR RI SC TN TX UT VA VT WA WI WY


foreach state in $statelist{
	u `state'.dta, clear
	keep if !missing(mergerdate) | !missing(mergerdate_new) | !missing(mergerdate_Z)
	keep entityname
	gen datastate = "`state'"
	save `state'.merger.dta, replace
	}

clear
gen a = .
foreach state in $statelist{
	append using `state'.merger.dta
	di "adding `state'"
	compress
	save allstates.merger.dta, replace
	}
drop a
compress
tomname entityname
drop entityname
duplicates drop 
save allstates.merger.dta, replace

*********** equityvalue : new mergers*********/
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta, clear
collapse (max) equityvalue, by(targetname targetsic)
collapse (sum) equityvalue 
rename equityvalue tot_equityvalue_new
gen id = 1
save tot_equityvalue_new.dta, replace

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta allstates.merger.dta
collapse (max) equityvalue, by(targetname targetsic _mergex)
keep if _mergex == "no match"
collapse (sum) equityvalue
rename equityvalue nomatch_equityvalue_new
gen id = 1
save nomatch_equityvalue_new.dta, replace

merge 1:1 id using tot_equityvalue_new.dta
drop _merge
gen misspct_new = nomatch_equityvalue_new / tot_equityvalue_new

save new_ratio.dta, replace

********** observations: new mergers **********
u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta, clear
collapse (max) equityvalue, by(targetname targetsic)
gen obs  = 1
collapse (sum) obs
rename obs tot_obs_new
gen id = 1
save tot_obs_new.dta, replace

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.pre2014.dta allstates.merger.dta
collapse (max) equityvalue, by(targetname targetsic _mergex)
keep if _mergex == "no match"
gen obs = 1
collapse (sum) obs
rename obs nomatch_obs_new
gen id = 1
save nomatch_obs_new.dta, replace

merge 1:1 id using tot_obs_new.dta
drop _merge
gen misspct_new = nomatch_obs_new / tot_obs_new

save new_obs_ratio.dta, replace

********** equityvalue : Zmergers ******
u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta, clear
collapse (max) equityvalue, by(targetname targetsic)
collapse (sum) equityvalue 
rename equityvalue tot_equityvalue_Z
gen id = 1
save tot_equityvalue_Z.dta, replace

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta allstates.merger.dta
collapse (max) equityvalue, by(targetname targetsic _mergex)
keep if _mergex == "no match"
collapse (sum) equityvalue
rename equityvalue nomatch_equityvalue_Z
gen id = 1
save nomatch_equityvalue_Z.dta, replace

merge 1:1 id using tot_equityvalue_Z.dta
drop _merge
gen misspct_Z = nomatch_equityvalue_Z / tot_equityvalue_Z

save Z_ratio.dta, replace
append using new_ratio.dta
save equityvalue_ratio.dta, replace
********** observations: Z mergers **********
u /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta, clear
collapse (max) equityvalue, by(targetname targetsic)
gen obs  = 1
collapse (sum) obs
rename obs tot_obs_Z
gen id = 1
save tot_obs_Z.dta, replace

jnamemerge /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/Z_mergers.pre2019.dta allstates.merger.dta
collapse (max) equityvalue, by(targetname targetsic _mergex)
keep if _mergex == "no match"
gen obs = 1
collapse (sum) obs
rename obs nomatch_obs_Z
gen id = 1
save nomatch_obs_Z.dta, replace

merge 1:1 id using tot_obs_Z.dta
drop _merge
gen misspct_Z = nomatch_obs_Z / tot_obs_Z

save Z_obs_ratio.dta, replace
append using new_obs_ratio.dta
save obs_ratio.dta, replace
append using equityvalue_ratio.dta
save ratio.dta, replace
export delimited using /user/user1/yl4180/save/ratio.csv, replace

