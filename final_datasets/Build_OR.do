clear
cd ~/projects/reap_proj/final_datasets/

clear
import delimited using "~/projects/reap_proj/raw_data/Oregon/2017/Record_Layout_Info/ENTITY_DB_EXTRACT_2017-07-05 09-32-59.TXT", delim(tab) varnames(1)

rename entityrsn dataid
gen corp_number = dataid
gen incdate = date(registrationdate,"MDY")
gen incyear = year(incdate)

rename jurisdiction jurisdictionraw
gen jurisdiction = "" if inlist(jurisdictionraw,"OREGON","")
replace jurisdiction = "DE" if jurisdictionraw == "DELAWARE"
gen is_DE = jurisdiction == "DE"


** These are only "doing business" names, and not necessary

drop if inlist(bustype, "ASSUMED BUSINESS NAME", "RESERVED NAME", "REGISTERED NAME","ACT OF GOVERNMENT")
gen is_nonprofit = strpos(bustype,"NONPROFIT") > 0
gen is_corp = strpos(bustype, "CORPORATION") > 0

tostring dataid, replace
duplicates drop dataid, force
save OR.dta, replace


clear
import delimited using "~/projects/reap_proj/raw_data/Oregon/2017/Record_Layout_Info/REL_ASSOC_NAME_DB_EXTRACT_2017-07-05 09-37-44.TXT", delim(tab) varnames(1)
keep if inlist(associatednametype,"PRINCIPAL PLACE OF BUSINESS","MAILING ADDRESS")
gen mainoffice = associatednametype == "PRINCIPAL PLACE OF BUSINESS"

rename entityrsn dataid
gsort dataid -mainoffice

* Keep the Principal address when possible,  mailing address only of principal doesn't exist 
by dataid: gen hasbestaddress = _n == 1
keep if hasbestaddress

rename (v11 v13) (mailaddress2 zipcode2)

gen address = trim(itrim(mailaddress + " " + mailaddress2))

keep dataid address zipcode city state country
tostring dataid, replace
merge 1:1 dataid using OR.dta

/* What gets dropped here is the address for all the ASSUMED NAME type of registrations */
drop if _merge == 1
drop _merge

drop if country != "UNITED STATES OF AMERICA"
drop if state != "OR"
save OR.dta, replace


clear
import delimited using "~/projects/reap_proj/raw_data/Oregon/2017/Record_Layout_Info/REL_ASSOC_NAME_DB_EXTRACT_2017-07-05 09-37-44.TXT", delim(tab) varnames(1)

keep if inlist(associatednametype,"PARTNER","PRESIDENT","GENERAL PARTNER","MANAGER")

rename (entityrsn associatednametype individualname) (dataid title fullname)
keep dataid title fullname
save OR.directors.dta, replace


/*
 * This section adds the historic names of firms. It does so directly rather than using  corp_add_names due to the structure of the data. 
 */
clear
import delimited using "~/projects/reap_proj/raw_data/Oregon/2017/Record_Layout_Info/NAME_DB_EXTRACT_2017-07-05 09-23-24.txt", delim(tab) varnames(1)


keep if nametype == "ENTITY NAME"
gen namestartdate = date(startdate,"MDY")
drop if missing(namestartdate)
rename entityrsn dataid
sort dataid namestartdate
by dataid:gen firstname = _n == 1
/*
 This would only keep the first name, but ideally, for matching, we should keep all of them. However, we might be inconsistent in how we're measuring entrepreneurship.
 keep if firstname
*/
    
rename busname entityname
gen originalname = entityname if firstname
keep entityname dataid originalname

merge m:1 dataid using OR.dta
drop if _merge == 1
drop _merge
save OR.dta, replace

	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**
    
       clear
       u OR.dta, replace
       tomname entityname
      save OR.dta, replace


        corp_add_eponymy, dtapath(~/final_datasets/OR.dta) directorpath(~/final_datasets/OR.directors.dta)
corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/OR.dta)
      corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/OR.dta)

      
      # delimit ;
      corp_add_trademarks OR , 
            dta(~/final_datasets/OR.dta) 
            trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
            ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
            var(trademark) 
            frommonths(-12)
            tomonths(12)
            class(~/projects/reap_proj/data/trademarks/classification.dta)
            statefileexists;
      
      
      # delimit ;
      corp_add_patent_applications OR OREGON , 
            dta(~/final_datasets/OR.dta) 
            pat(~/projects/reap_proj/data_share/patent_applications.dta) 
            var(patent_application) 
            frommonths(-12)
            tomonths(12)
            statefileexists;
      
      corp_add_patent_assignments  OR OREGON , 
            dta(~/final_datasets/OR.dta)
            pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta")
            frommonths(-12)
            tomonths(12)
            var(patent_assignment)
            statefileexists;
      
      # delimit cr      
      corp_add_ipos  OR ,dta(~/final_datasets/OR.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta) longstate(OREGON)
      corp_add_mergers OR ,dta(~/final_datasets/OR.dta) merger(~/projects/reap_proj/data/mergers.dta) longstate(OREGON) 
      

      corp_add_vc2 OR  ,dta(~/final_datasets/OR.dta) vc(~/final_datasets/VC.investors.withequity.dta)  longstate(OREGON) dropexisting 


corp_has_last_name, dtafile(~/final_datasets/OR.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
        corp_has_first_name, dtafile(~/final_datasets/OR.dta) num(1000)
        corp_name_uniqueness, dtafile(~/final_datasets/OR.dta)


clear
u ~/final_datasets/OR.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
gen has_unique_name = uniquename <= 5
 save ~/final_datasets/OR.dta, replace




clear
u ~/final_datasets/OR.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save ~/final_datasets/OR.dta, replace

corp_collapse_any_state OR
