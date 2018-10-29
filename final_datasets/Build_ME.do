cd /projects/reap.proj/reapindex/Maine

clear
import delimited using /projects/reap.proj/raw_data/Maine/corp_all_new_20160607.csv , delim(",")

save ME.dta, replace

rename v1 dataid
rename v34 entityname

gen address = v39 + " " + v40
gen city = v41
gen state = v42
gen zipcode = v44

gen shortname = wordcount(entityname) < 4

gen jurisdiction = v6
gen is_DE = jurisdiction == "DE"

keep if inlist(jurisdiction,"ME","DE")

/* Generating Variables */

gen incdate = date(v2,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
//type
gen is_corp = 1 if regexm(entityname,"CORP")
replace is_corp = 1 if regexm(entityname,"INC")
gen country = "USA"
keep dataid entityname incdate incyear is_DE jurisdiction country zipcode state city address is_corp shortname country
replace state = "ME" if missing(state)
compress
drop if is_DE & state != "ME"
save ME.dta,replace
/* None
/* Build Director File */
clear

import delimited /projects/reap.proj/raw_data/Virginia/5_officers.csv, delim(",") varname(1)
save VA.directors.dta,replace

rename dirccorpid dataid
gen fullname = dircfirstname + dircmiddlename + dirclastname
rename dirctitle role
keep if regexm(role,"PRES")
drop if regexm(role,"VICE")
drop if regexm(role,"PAS")

keep dataid fullname role 
drop if missing(fullname)
save VA.directors.dta, replace
*/

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u ME.dta , replace
	tomname entityname
	save ME.dta, replace
	gen eponymous = 0
	//corp_add_eponymy, dtapath(ME.dta) directorpath(ME.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(ME.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(ME.dta)
	
	
	# delimit ;
	corp_add_trademarks ME , 
		dta(ME.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications ME MAINE , 
		dta(ME.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  ME MAINE , 
		dta(ME.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 ME  ,dta(ME.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(MAINE) 
	corp_add_mergers ME  ,dta(ME.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(MAINE) 
