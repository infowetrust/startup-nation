cd /NOBACKUP/scratch/share_scp/scp_private/scp2018/

global mergetempsuffix TN    

clear

import delimited  /NOBACKUP/scratch/share_scp/raw_data/Tennessee/2018/FILING.txt,delim("|")


rename control_no dataid
rename filing_name entityname

drop if inlist(filing_type,"Nonprofit Corporation","Reserved Name","Foreign Registered Name")


rename filing_type type

gen is_corp = inlist(type,"For-profit Corporation")
gen address = principle_addr1 + principle_addr2 + principle_addr3
gen city = principle_city
gen addrstate = principle_state
gen zip5 = principle_postal_code

replace address = mail_addr1 + mail_addr2 +mail_addr3 if missing(address)
replace city = mail_city if missing(city)
replace addrstate = mail_state if missing(addrstate)
replace zip5 = mail_postal_code if missing(zip5)
replace zip5 = substr(zip5,1,5)

gen country = principle_country
gen jurisdiction = formation_locale
replace jurisdiction = "TENNESSEE" if missing(jurisdiction) & country == "USA" 
keep if country == "USA" | missing(country)
gen is_DE = jurisdiction == "DELAWARE"

gen local_firm= inlist(jurisdiction,"TENNESSEE","DELAWARE") & addrstate == "TN" | missing(addrstate)


/* Generating Variables */

gen incdate = date(filing_date,"MDY")
gen incyear = year(incdate)

gen shortname = wordcount(entityname) < 4

drop if missing(incdate)
drop if missing(entityname)


replace country = "USA" if missing(country)
keep dataid entityname incdate incyear type is_DE jurisdiction country zip5 addrstate city address is_corp shortname local_firm
tostring dataid, replace
compress
rename zip5 zipcode
rename addrstate state
save TN.dta , replace

/* Build Director File  */
clear
import delimited data using /NOBACKUP/scratch/share_scp/raw_data/Tennessee/2018/PARTY.txt, delim("|")
save TN.directors.dta,replace

rename data dataid
gen fullname = trim(itrim(first_name + " "+ middle_name + " "+ last_name))
rename individual_title role
//No specified role

keep dataid fullname role 
drop if missing(fullname)
tostring dataid, replace
save TN.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u TN.dta , replace
	tomname entityname
	save TN.dta, replace

	corp_add_eponymy, dtapath(TN.dta) directorpath(TN.directors.dta)

	replace eponymous = 0

       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(TN.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(TN.dta)
	
	
	# delimit ;
	corp_add_trademarks TN , 
		dta(TN.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications TN TENNESSEE , 
		dta(TN.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  TN TENNESSEE , 
		dta(TN.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
;
	# delimit cr	

	

	corp_add_ipos	 TN  ,dta(TN.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(TENNESSEE) 
	corp_add_mergers TN  ,dta(TN.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(TENNESSEE) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	save TN.dta, replace
	compress
	duplicates drop
	save TN.dta, replace
	
