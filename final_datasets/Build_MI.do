
clear
cd ~/final_datasets

import delimited using /projects/reap.proj/raw_data/Michigan/Michigan_19Aug2015.csv, delim(",") bindquote(strict) varnames(1)
rename (name company_number) (entityname corp_number)
gen dataid = corp_number
gen is_corp = strpos(company_type,"Corporation") > 0
gen is_nonprofit= strpos(company_type,"Nonprofit") > 0

drop *in_full
rename headquarters_address_* *

foreach v in street_addr postal_code locality region{
    di "More address info: `v'"
    replace `v' = registered_address_`v' if missing(`v')
    replace `v' = mailing_address_`v' if missing(`v')
}

drop registered_address* mailing_address*
rename postal_code zipcode
rename street_addr address
gen incdate= date(incorporation_date,"YMD")

drop if is_nonprofit
rename home_jurisdiction jurisdiction
replace jurisdiction = "MI" if inlist(jurisdiction,"","us_mi")
replace jurisdiction = "DE" if inlist(jurisdiction,"","us_de")

keep if inlist(jurisdiction,"","MI","DE")
tab region

keep if inlist(region, "","MI")
 /* This is just defined manually */
gen city = locality
gen state = "MI"
gen incyear = year(incdate)

drop if missing(incyear)
save MI.dta, replace

        
**
**
** STEP 2: Add variables. These variables are within the first year
**              and very similar to the ones used in "Where Is Silicon Valley?"
**
**      

    clear
    u MI.dta, replace
        tomname entityname
        save MI.dta, replace
        corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/MI.dta)
        corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/MI.dta)

        
        # delimit ;
        corp_add_trademarks MI , 
                dta(~/final_datasets/MI.dta) 
                trademarkfile(/projects/reap.proj/data/trademarks.dta) 
                ownerfile(/projects/reap.proj/data/trademark_owner.dta)
                var(trademark) 
                frommonths(-12)
                tomonths(12)
                class(/projects/reap.proj/data/trademarks/classification.dta)
                statefileexists;
        
        
        # delimit ;
        corp_add_patent_applications MI MICHIGAN , 
                dta(~/final_datasets/MI.dta) 
                pat(/projects/reap.proj/data_share/patent_applications.dta) 
                var(patent_application) 
                frommonths(-12)
                tomonths(12)
                statefileexists;
        
        corp_add_patent_assignments  MI MICHIGAN , 
                dta(~/final_datasets/MI.dta)
                pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
                frommonths(-12)
                tomonths(12)
                var(patent_assignment)
        	statefileexists;
	
	# delimit cr	
corp_add_ipos MI  ,dta(~/final_datasets/MI.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(MICHIGAN)
corp_add_mergers MI  ,dta(~/final_datasets/MI.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(MICHIGAN)
corp_add_vc2  MI  ,dta(~/final_datasets/MI.dta) vc(~/final_datasets/VC.investors.withequity.dta)  longstate(MICHIGAN) dropexisting 

corp_name_uniqueness, dtafile(~/final_datasets/MI.dta)
corp_has_first_name ,dta(~/final_datasets/MI.dta) num(5000)
corp_has_last_name ,dta(~/final_datasets/MI.dta) num(1000)



				

clear
u ~/final_datasets/MI.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
gen has_unique_name = uniquename <= 5
 save ~/final_datasets/MI.dta, replace


