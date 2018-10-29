
cd ~/final_datasets/
global mergetempsuffix = "alaska_official"

clear
import delimited using /projects/reap.proj/raw_data/Alaska/CorporationsDownload.CSV, delim(",") varnames(1)

rename (entitynumber legalname) (dataid entityname)
keep if homecountry == "UNITED STATES" | homecountry == ""

rename entitymailing* *
gen is_DE = homestate == "DELAWARE"
keep if inlist(homestate,"ALASKA","DELAWARE")
drop entityphys* registered*
rename zip zipcode
rename stateprovince state
keep if state == "AK" | state == ""
gen is_corp = strpos(corptype,"Corporation") > 0

drop if inlist(corptype, "Name Reservation","Business Name Registration")
gen is_nonprofit = strpos(corptype,"Nonprofit")
drop if is_nonprofit
gen incdate = date(akformeddate,"MDY")
gen incyear = year(incdate)
gen address = address1 + " " + address2
drop address1 address2
gen shortname = wordcount(entityname) <= 3
save ~/final_datasets/AK.dta, replace


clear
import delimited using /projects/reap.proj/raw_data/Alaska/OfficialsDownload.csv, delim(",") varnames(1)
rename parententitynumber dataid

keep if inlist(officialtitle,"Member","President","Manager","Owner","Incorporator","General Manager")
gen is_individual = length(officialfirstname) > 0
drop if !is_individual
rename (officialfirst officiallast) (firstname lastname)
gen fullname = itrim(trim(firstname + " " + lastname))
gen title = "President"

keep fullname title firstname lastname dataid
save ~/final_datasets/AK.directors.dta, replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

    cd ~/final_datasets/
        
    u AK.dta, replace
	tomname entityname
	save AK.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/AK.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/AK.dta)

*	corp_add_gender, dta(~/final_datasets/AK.dta) directors(~/final_datasets/AK.directors.dta) names(~/ado/names/NATIONAL.TXT)


	corp_add_eponymy, dtapath(~/final_datasets/AK.dta) directorpath(~/final_datasets/AK.directors.dta)
	
	# delimit ;
	corp_add_trademarks AK , 
		dta(~/final_datasets/AK.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AK ALASKA , 
		dta(~/final_datasets/AK.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  AK ALASKA , 
		dta(~/final_datasets/AK.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 AK ,dta(~/final_datasets/AK.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(ALASKA)
	corp_add_mergers AK ,dta(~/final_datasets/AK.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(ALASKA)

corp_add_vc2 	 AK  ,dta(~/final_datasets/AK.dta) vc(~/final_datasets/VC.investors.dta) longstate(ALASKA) 




 



