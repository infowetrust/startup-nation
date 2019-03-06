cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
global mergetempsuffix BuildNM

global NM_dta_file NM.dta

clear 
import delimited using /NOBACKUP/scratch/share_scp/raw_data/NewMexico/DataSales_06012016/BusinessSP.txt, delim(tab) varname(1)

rename businessname entityname
rename placeofformation jurisdiction
rename businesstype type

drop if regexm(type,"NP")
gen is_corp = inlist(type,"DPRX","DXIC","FPXX")
gen potentiallylocal= inlist(jurisdiction,"Delaware","New Mexico")
duplicates drop businessno, force
save $NM_dta_file, replace

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/NewMexico/DataSales_06012016/BusinessAddressSP.txt, delim(tab) varname(1)

gen princ_address = .
replace princ_address = 1 if addresstypedesc == "PrincipalPlaceMailingAddress"
replace princ_address = 2 if addresstypedesc == "CorpForeignPhysicalAddress"
replace princ_address = 3 if addresstypedesc == "PrincipalPlacePhysicalAddress"
replace princ_address = 4 if addresstypedesc == "DomesticStateRegisteredAddress"

bysort businessno (princ_address): gen top = _n == 1
keep if top == 1 | princ == 2
gen address = trim(addressline1 +" "+ addressline2)
rename statecode state
tostring businessno , replace
merge m:1 businessno using $NM_dta_file
keep if _merge == 3
drop _merge

rename businessno dataid
gen shortname = wordcount(entityname) < 4
gen is_DE  = jurisdiction == "Delaware"
gen incdate = date(dateofi,"MDY")
gen incyear = year(incdate)
duplicates tag dataid, gen(tag)
drop if state == "NM" & tag == 1
drop tag
duplicates tag dataid, gen(tag) 
drop if top == 0 & tag == 1
drop tag 

drop if missing(incdate)
drop if missing(entityname)
rename zip zipcode
replace zipcode = substr(zipcode,1,5)
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal
replace state = "NM" if missing(state)
gen stateaddress = state
gen local_firm = inlist(jurisdiction, "New Mexico", "Delaware") & inlist(state, "","NM")
if "$NM_dta_file" == "NM.DE.dta" {
    keep if is_DE == 1
}

save $NM_dta_file,replace

/* Build Director File */
clear
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/

import delimited /NOBACKUP/scratch/share_scp/raw_data/NewMexico/DataSales_06012016/OfficersSP.txt, delim(tab) varname(1)
save NM.directors.dta,replace

tostring businessno , generate(dataid)
gen role = upper(trim(itrim(title)))
gen fullname =firstname + " " +middlename + " " + lastname 
replace fullname = upper(trim(itrim(fullname)))

// keep if inlist(role,"President") for legislator task
keep dataid fullname role 
drop if missing(fullname)
save NM.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u $NM_dta_file , replace
	tomname entityname
	save $NM_dta_file, replace

	corp_add_eponymy, dtapath($NM_dta_file) directorpath(NM.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta($NM_dta_file)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta($NM_dta_file)
	
	
	# delimit ;
	corp_add_trademarks NM , 
		dta($NM_dta_file) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;
	corp_add_patent_applications NM NEW MEXICO , 
		dta($NM_dta_file) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  NM NEW MEXICO , 
		dta($NM_dta_file)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments_all.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	
	

	corp_add_ipos	 NM  ,dta($NM_dta_file) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(NEW MEXICO)
	corp_add_mergers NM  ,dta($NM_dta_file) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(NEW MEXICO) 

      corp_add_vc        NM ,dta($NM_dta_file) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(NEW MEXICO)
