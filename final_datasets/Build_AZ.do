\cd ~/projects/reap_proj/final_datasets/
global mergetempsuffix AZdata
global only_DE 0


clear
import delimited using ~/projects/reap_proj/raw_data/Arizona/corext.txt

save AZ.dta, replace

gen dataid = substr(v1,65,9)
gen entityname = trim(substr(v1,74,60))


gen address = trim(substr(v1,134,90))
gen city = trim(substr(v1,224,20))
gen state = substr(v1,244,2)
gen zipcode = substr(v1,246,5)




gen shortname = wordcount(entityname) < 4
gen idate = substr(v1,312,8)
gen type = substr(v1,484,1)
gen jurisdiction = substr(v1,486,2)
gen is_DE = jurisdiction == "DE"

gen potentiallylocal =  inlist(jurisdiction,"AZ","DE")
drop if type == "N"
drop if type == "I"
gen is_corp = inlist(type,"A","F","G","P")
/* Generating Variables */

gen incdate = date(idate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
//type

/** Address for foreign entities is stored somewhere else **/
replace address = trim(substr(v1,747,90)) if is_DE == 1
replace city = trim(substr(v1,837,20)) if is_DE == 1
replace state = substr(v1,857,2) if is_DE == 1
replace zipcode = substr(v1,859,5) if is_DE == 1


keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal
replace state = "AZ" if missing(state) & jurisdiction == "AZ"
gen local_firm = potentiallylocal
gen stateaddress = state
compress
if $only_DE == 1 {
    keep if is_DE == 1
    local N = _N
    di "Using only Delaware firms.  Only DE flag turned on. `N' firms remaining"
}


save AZ.dta,replace

/* Build Director File */
clear

import delimited ~/projects/reap_proj/raw_data/Arizona/offext.txt
save AZ.directors.dta,replace

gen dataid = substr(v1,1,9)
gen role = substr(v1,10,2)
gen fullname = trim(substr(v1,12,30))

keep if inlist(role,"PR","P ")
keep dataid fullname role 
drop if missing(fullname)
save AZ.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u AZ.dta , replace
	tomname entityname
	save AZ.dta, replace

	corp_add_eponymy, dtapath(AZ.dta) directorpath(AZ.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(AZ.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(AZ.dta)
	
	
	# delimit ;
	corp_add_trademarks AZ , 
		dta(AZ.dta) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AZ ARIZONA , 
		dta(AZ.dta) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  AZ ARIZONA , 
		dta(AZ.dta)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 AZ  ,dta(AZ.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(ARIZONA)
	corp_add_mergers AZ  ,dta(AZ.dta) merger(~/projects/reap_proj/data/mergers.dta)  longstate(ARIZONA) 



      corp_add_vc        AZ ,dta(AZ.dta) vc(~/final_datasets/VX.dta) longstate(ARIZONA)
