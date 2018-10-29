
cd /projects/reap.proj/reapindex/Louisiana



clear 
xmluse /projects/reap.proj/raw_data/Louisiana/Filings.xml , doctype(dta)

rename v1 dataid
rename v5 entityname
rename v7 dateinc
rename v10 jurisdiction
keep if inlist(jurisdiction,"Delaware","Minnesota")
rename v3 type
gen is_corp=1 if type == 43 | type == 66

save MN1.dta, replace

clear
u MN_raw.dta,replace
keep if v2 == 03
compress
save MN3.dta, replace

rename v1 dataid
gen address = trim(v9 + v10)
gen city = v11
gen state = v12
gen zipcode = v13
drop if missing(address)
duplicates drop dataid, force
merge 1:1 dataid using MN1.dta
drop if _merge == 1 
drop _merge

gen shortname = wordcount(entityname) < 4
gen is_DE  = 1 if jurisdiction == "Delaware"
gen incdate = date(dateinc,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname
replace state = "MN" if missing(state)
compress
drop if is_DE & state != "MN"
save MN.dta,replace

/*
No director file
/* Build Director File */
clear

import delimited /projects/reap.proj/raw_data/NewMexico/DataSales_06012016/OfficersSP.txt, delim(tab) varname(1)
save NM.directors.dta,replace

tostring businessno , generate(dataid)
gen role = title
gen fullname =firstname + " " +middlename + " " + lastname 

keep if inlist(role,"President")
keep dataid fullname role 
drop if missing(fullname)
save NM.directors.dta, replace
*/
*/
**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u MN.dta , replace
	tomname entityname
	save MN.dta, replace
/*
	corp_add_eponymy, dtapath(MN.dta) directorpath(MN.directors.dta)
*/
	gen eponomous = 0
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(MN.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(MN.dta)
	
	
	# delimit ;
	corp_add_trademarks MN , 
		dta(MN.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications MN MINNESOTA , 
		dta(MN.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  MN MINNESOTA , 
		dta(MN.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 MN  ,dta(MN.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(MINNESOTA)
	corp_add_mergers MN  ,dta(MN.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(MINNESOTA) 
