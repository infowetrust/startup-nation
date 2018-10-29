cd /projects/reap.proj/reapindex/NewMexico

clear 
import delimited using /projects/reap.proj/raw_data/NewMexico/DataSales_06012016/BusinessSP.txt, delim(tab) varname(1)

rename businessname entityname
rename placeofformation jurisdiction
rename businesstype type
drop if regexm(type,"NP")
gen is_corp = inlist(type,"DPRX","DXIC","FPXX")
keep if inlist(jurisdiction,"Delaware","New Mexico")
duplicates drop businessno, force
save NM.dta, replace

clear
import delimited using /projects/reap.proj/raw_data/NewMexico/DataSales_06012016/BusinessAddressSP.txt, delim(tab) varname(1)

gen address = addressline1 + " " + addressline2
replace address = trim(address)
rename statecode state
tostring businessno , replace
merge m:1 businessno using NM.dta
drop if _merge == 1 
drop _merge

rename businessno dataid
gen shortname = wordcount(entityname) < 4
gen is_DE  = 1 if jurisdiction == "Delaware"
gen incdate = date(dateofi,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
rename zip zipcode
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname
replace state = "NM" if missing(state)
compress
drop if is_DE & state != "NM"
save NM.dta,replace

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

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u NM.dta , replace
	tomname entityname
	save NM.dta, replace

	corp_add_eponymy, dtapath(NM.dta) directorpath(NM.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(NM.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(NM.dta)
	
	
	# delimit ;
	corp_add_trademarks NM , 
		dta(NM.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NM NEW MEXICO , 
		dta(NM.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  NM NEW MEXICO , 
		dta(NM.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 NM  ,dta(NM.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(NEW MEXICO)
	corp_add_mergers NM  ,dta(NM.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(NEW MEXICO) 
