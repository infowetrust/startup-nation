cd ~/migration/datafiles/
global mergetempsuffix ARMERGE

clear 
import delimited using /projects/reap.proj/raw_data/Arkansas/corp_data.txt, delim(tab)

rename v1 dataid
tostring dataid , replace
gen  entityname = trim(v6)
rename v19 jurisdiction
replace jurisdiction = "AR" if missing(jurisdiction)
rename v2 type
drop if type == 3 | type == 4 | type == 14 | type == 23
drop if type > 25
/* 1 observation*/
duplicates drop dataid , force
gen is_corp = inlist(type,1,2,5,6,13)
keep if inlist(jurisdiction,"DE","AR")

save AR.dta, replace

gen address =trim(v24)

rename v25 city
rename v26 state
rename v27 zipcode

gen shortname = wordcount(entityname) < 4
gen is_DE  = 1 if jurisdiction == "DE"
gen incdate = date(v4,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname
replace state = "AR" if missing(state)
compress
drop if is_DE & state != "AR"
save AR.dta,replace

/* Build Director File */
clear

import delimited /projects/reap.proj/raw_data/Arkansas/corp_officer_data.txt, delim(tab)
save AR.directors.dta,replace

tostring v1 , generate(dataid)
gen role = trim(v4)
gen fullname =v9 + " "+v10+" "+v8

keep if inlist(role,"President")
keep dataid fullname role 
drop if missing(fullname)
save AR.directors.dta, replace
*/

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u AR.dta , replace
	tomname entityname
	save AR.dta, replace

	corp_add_eponymy, dtapath(AR.dta) directorpath(AR.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(AR.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(AR.dta)
	
	
	# delimit ;
	corp_add_trademarks AR , 
		dta(AR.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AR ARKANSAS , 
		dta(AR.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  AR ARKANSAS , 
		dta(AR.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 AR  ,dta(AR.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(ARKANSAS)
	corp_add_mergers AR  ,dta(AR.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(ARKANSAS) 
