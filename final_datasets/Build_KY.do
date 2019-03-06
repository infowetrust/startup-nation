cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
global mergetempsuffix KYmaster

clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Kentucky/2018/AllCompanies20180831.txt,delim(tab)

rename v1 dataid
rename v4 entityname

/* Non Profit */
drop if v41=="N"

save KY.dta, replace

rename v9 type
gen is_corp = 1 if regexm(type,"CO")
replace is_corp = 0 if missing(is_corp)
drop if regexm(type,"NP")
gen address = v18 + " " + v19 + " "+v20 + " "+v21
gen city = v22
gen state = v23
gen zipcode = v24

replace state = trim(itrim(state))
replace city = upper(trim(itrim(city)))
replace zipcode = trim(itrim(substr(zipcode,1,5)))
replace address = upper(trim(itrim(address)))


gen shortname = wordcount(entityname) < 4

rename v8 jurisdiction 
replace jurisdiction = "KY" if missing(jurisdiction) 
replace jurisdiction = trim(itrim(upper(jurisdiction)))
keep if inlist(jurisdiction, "DE", "KY")
gen is_DE = 1 if jurisdiction == "DE"

gen local_firm= inlist(jurisdiction,"KY","DE") & inlist(state, "", "KY")

/* Generating Variables */

gen incdate = date(v28,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

tostring dataid, replace
tostring v2, replace
drop if inlist(v2, "01", "02", "03", "04", "10") | inlist(v2, "11", "12", "13", "14", "15") | inlist(v2, "17", "18", "20", "21", "22")

replace dataid = dataid + v2+ substr(v3,4,2)
//keep if incyear < 2019 & incyear > 1987
keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname local_firm

duplicates drop
compress
gen stateaddress = state
save KY.dta,replace


* Build Director File *
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Kentucky/2018/AllOfficers20180831.txt , delim(tab)
save KY.directors.dta,replace

rename v4 role
replace role = upper(trim(role))
keep if inlist(role,"P","V","N","L","C","E","Z","3")
tostring v1, format(%12.0f) replace
forvalues i = 1/7{
replace v1 = "0"+v1 if strlen(v1) < 7
}

tostring v2,format(%12.0f) replace
replace v2 = "0"+v2 if strlen(v2) < 2
drop if inlist(v2, "01", "02", "03", "04", "10") | inlist(v2, "11", "12", "13", "14", "15") | inlist(v2, "17", "18", "20", "21", "22")

tostring v3,format(%12.0f) replace
gen dataid = v1 + v2 + substr(v3,4,2)

rename (v5 v6 v7) (firstname middlename lastname)

	replace lastname = subinstr(lastname,"."," ",.)
	replace lastname = subinstr(lastname,"*"," ",.)
	replace lastname = subinstr(lastname,","," ",.)
	replace lastname = upper(trim(itrim(lastname)))
	
	
	replace firstname = subinstr(firstname,"."," ",.)
	replace firstname = subinstr(firstname,"*"," ",.)
	replace firstname = subinstr(firstname,","," ",.)
	replace firstname = upper(trim(itrim(firstname)))
	
	replace middlename = subinstr(middlename,"."," ",.)
	replace middlename = subinstr(middlename,"*"," ",.)
	replace middlename = subinstr(middlename,","," ",.)
	replace middlename = upper(trim(itrim(middlename)))
	
	
	gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(fullname))

keep dataid fullname role 
drop if missing(fullname)
compress
save KY.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	clear
	u KY.dta , replace
	tomname entityname
	save KY.dta ,replace
	
	corp_add_eponymy, dtapath(KY.dta) directorpath(KY.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(KY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(KY.dta)
	
	
	# delimit ;
	corp_add_trademarks KY , 
		dta(KY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications KY KENTUCKY , 
		dta(KY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	corp_add_patent_assignments KY KENTUCKY , 
		dta(KY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 KY  ,dta(KY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(KENTUCKY) 
	corp_add_mergers KY  ,dta(KY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(KENTUCKY) 
	corp_add_vc 	 KY  ,dta(KY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(KENTUCKY)
	compress
	duplicates drop
	save KY.dta, replace
