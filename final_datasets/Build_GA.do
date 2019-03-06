cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/

global mergetempsuffix "GA_Official"


clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Georgia/bizEntityData.txt, delim(tab) varnames(1)

rename (bizentityid businessname foreignstate) (corp_number entityname jurisdiction)
gen dataid = corp_number
tab modeltype
gen is_corp = modeltype == "Corp" | strpos(modeltype,"Corporation") > 1
gen is_nonprofit = qualifier == "NonProfit" | strpos(modeltype,"Non-Profit") > 1

//gen incdate = date(commencementdate,"MDY")
//gen incyear = year(incdate)

gen incdate = date(effectivedate,"MDY")
gen incyear = year(incdate)

gen incdateDE = date(foreigndateoforganization,"MDY")
gen incyearDE = year(incdateDE)

gen is_domestic = locale == "Domestic"		
 tab locale		
 tab qualifier
tab jurisdiction

gen is_DE = jurisdiction == "DE"

gen local_firm = is_domestic | !is_domestic & is_DE
keep if !is_nonprofit
keep dataid corp_number is_nonprofit is_corp is_DE incdate incyear entityname jurisdiction is_domestic local_firm incdateDE incyearDE

save GA.dta, replace

* Import the Address of Each Firm *

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Georgia/bizEntityAddressData.txt, delim(tab) varnames(1)
gen orderid = _n		 

 duplicates drop		
 keep if officetype == "Principal Office"		
 rename bizentityid dataid		

  * Keep the first address on file *		
 by dataid (orderid), sort: gen keepme = _n == 1		
 keep if keepme		

  gen address = trim(itrim(line1 + " " + line2))		
 rename zip zipcode		
 keep dataid address city state zipcode country		 
		
 merge 1:1 dataid using GA.dta		
 drop if _merge != 3
 keep if inlist(country,"USA","","United States")
replace local_firm = 0 if ! inlist(state,"GA","")
 keep if inlist(jurisdiction, "DE", "GA")
 replace local_firm = 1  if state == "GA" | state =="" 
foreach var of varlist city state address jurisdiction {
replace `var' = trim(itrim(upper(`var')))
}
keep dataid entityname city state zipcode address is_corp is_DE is_nonprofit incdate incyear local_firm jurisdiction incdateDE incyearDE
gen stateaddress = state
save GA.dta, replace


clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Georgia/bizOfficersPartnersOrganizersData.txt, delim(tab) varnames(1)

rename bizentityid dataid

gen fullname = upper(trim(itrim(firstname + " " + middlename + " " + lastname)))
replace firstname = trim(itrim(upper(firstname)))
drop if missing(fullname) | missing(firstname) | missing(lastname)
drop if strpos(fullname, "INAVLID") | strpos(fullname, "*") | inlist(fullname, "NO NAME ON", "NO CEO NAME", "NOT NAMED", "NO NAME ENTERED")
keep if inlist(businesscontacttype, "CEO","Organizer","Incorporator","General Partner")
rename businesscontacttype role
replace role = upper(trim(itrim(role)))
keep dataid fullname role firstname
order dataid fullname role


save GA.directors.dta, replace



 *
 * Step 2: Add Measures
 *
 *
    



 clear
u GA.dta
gen shortname = wordcount(entityname) <= 3
tomname entityname
duplicates drop
compress
save GA.dta, replace


corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(GA.dta)
        corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(GA.dta)

**        corp_add_gender, dta(GA.dta) directors(GA.directors.dta) names(~/ado/names/GA.TXT)



        corp_add_eponymy, dtapath(GA.dta) directorpath(GA.directors.dta) //not finish

        # delimit ;
        corp_add_trademarks GA , 
                dta(GA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
        
        
        # delimit ;
        corp_add_patent_applications GA GEORGIA , 
                dta(GA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
        
        corp_add_patent_assignments  GA GEORGIA , 
                dta(GA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
        
        # delimit cr    
        corp_add_ipos    GA ,dta(GA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(GEORGIA)
        corp_add_mergers GA ,dta(GA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta) longstate(GEORGIA)
        corp_add_vc 	 GA  ,dta(GA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(GEORGIA)


*        corp_add_vc2     GA  ,dta(GA.dta) vc(VC.investors.withequity.dta)  longstate(GEORGIA) dropexisting 
*	corp_has_last_name, dtafile(GA.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
*        corp_has_first_name, dtafile(GA.dta) num(1000)
*        corp_name_uniqueness, dtafile(GA.dta)


clear
u GA.dta
duplicates drop
compress
//gen has_unique_name = uniquename <= 5
 save GA.dta, replace







