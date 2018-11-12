
cd ~/projects/reap_proj/final_datasets/
global mergetempsuffix="WA_Official"


**
** STEP 1: Load the data dump from MA Corporations 

	 clear
	import delimited using /projects/reap.proj/raw_data/Washington/2015_05_26/Corporations.txt,delim(tab) bindquote(nobind) varnames(1)
	keep if inlist(stateofinc,"WA","DE")
	gen incdate = date(dateofinc,"MDY")
	gen incyear = year(date(dateofinc,"MDY"))
	gen deathdate = date(dissolutiondate,"MDY")
	gen deathyear = year(date(dissolutiondate,"MDY"))

	gen is_nonprofit= type == "Nonprofit"
	gen is_corp =category == "REG"
	tostring ubi, replace
	rename (businessname ubi) (entityname dataid)
	gen corpnumber = dataid 
	rename (stateofincorporation alternatezip alternatecity alternateaddress alternatestate) (jurisdiction zipcode city address state)

	keep dataid entityname incdate incyear deathdate deathyear is_corp jurisdiction is_nonprofit address city state zipcode corpnumber
	gen deathtype = ""
	replace state = "WA" if trim(state) == "" & jurisdiction == "WA"

        gen stateaddress = state
        gen local_firm = stateaddress == "WA"

	save WA.dta,replace

*Build Director file
	
	clear
	import delimited using /projects/reap.proj/raw_data/Washington/2013_07_23/GoverningPersonsClean.txt,delim(tab) bindquote(nobind) varnames(1)

	gen fullname = firstname + " " + middlename + " " + lastname
	replace title = "PRESIDENT" if inlist(title,"ALL Officers","Chairman","President")
	replace title = "MANAGER" if inlist(title,"Manager","Partner","Member")
	rename title role
	rename ubi dataid                                        
	replace role = upper(trim(itrim(role)))
	replace fullname =  trim(itrim(fullname))
	replace firstname =  trim(itrim(firstname))
        save ~/migration/datafiles/WA.diraddress.dta , replace

	keep if inlist(role,"PRESIDENT","MANAGER","CEO")
	keep dataid fullname role firstname
	order dataid fullname role
	save WA.directors.dta,replace

	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	clear
	u ~/migration/datafiles/WA.dta
	tomname entityname
	save WA.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/migration/datafiles/WA.dta)

	corp_add_gender, dta(~/migration/datafiles/WA.dta) directors(~/migration/datafiles/WA.directors.dta) names(~/ado/names/NATIONAL.TXT) precision(1)
	corp_add_eponymy, dtapath(~/migration/datafiles/WA.dta) directorpath(~/migration/datafiles/WA.directors.dta)
	
	# delimit ;
	corp_add_trademarks WA , 
		dta(~/migration/datafiles/WA.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WA WASHINGTON , 
		dta(~/migration/datafiles/WA.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WA WASHINGTON , 
		dta(~/migration/datafiles/WA.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		
		

		
		
	# delimit cr	
	corp_add_ipos	 WA  ,dta(~/migration/datafiles/WA.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(WASHINGTON)
	corp_add_mergers WA  ,dta(~/migration/datafiles/WA.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(WASHINGTON)

	corp_add_vc 	 WA  ,dta(~/migration/datafiles/WA.dta) vc(/projects/reap.proj/data/VX.dta) longstate(WASHINGTON)

	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/migration/datafiles/WA.dta)
 
clear
u ~/migration/datafiles/WA.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save WA.dta, replace


