
cd ~/projects/reap_proj/final_datasets
global mergetempsuffix="MA_Official"


global dtasuffix 

**
** STEP 1: Load the data dump from MA Corporations 

	clear
	import delimited using "~/projects/reap_proj/raw_data/Massachusetts/CorpData.txt", delim(",") varnames(1) 

	gen incdate = date(dateoforganization,"MDY") 
	gen incyear = year(incdate)
	gen is_corp = strpos(entitytypedescriptor,"Corporation") > 0
        gen is_llc  = strpos(entitytypedescriptor, "Limited Liability") > 0
        gen incdateDE = date(jurisdictiondate,"MDY")
	

	* Drop a few bad items (12 in dataid and 75 in incyear of 900K)
	drop if length(dataid) != 6
	drop if missing(incyear)

	replace inactivedate = regexr(inactivedate," .*","")
	
	replace jurisdictionstate = "MA" if jurisdictionstate == ""
	keep if inlist(jurisdictionstate,"MA","DE")
	gen address = addr1 + " " + addr2

	rename (jurisdictionstate postalcode) (jurisdiction zipcode)

	gen is_nonprofit = regexm(entitytypedescriptor, "Nonprofit")
	replace is_nonprofit = 1 if regexm(entitytypedescriptor, "Religious")

	rename inactivetype deathtype
	rename fein corpnumber
	keep dataid entityname incdate incyear corpnumber is_llc  jurisdiction is_corp is_nonprofit address city state zipcode deathtype incdateDE
	
	replace deathtype = "MERGER" if deathtype == "M"
	replace deathtype = "INVOLUNTARY DISSOLUTION" if deathtype == "I"
	replace deathtype = "VOLUNTARY DISSOLUTION" if deathtype == "V"
	replace deathtype = "CANCELLED" if deathtype == "C"
	replace deathtype = "CANCELLED" if deathtype == "C"
	replace deathtype = "CANCELLED" if deathtype == "C"
	replace deathtype = "CANCELLED" if deathtype == "C"
	
	save ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta,replace


* Create files for name changes
* We could add mergers here but then that could definitely make a mess of having the outcome as inputs
*
	clear
	import delimited using "/projects/reap_proj/raw_data/Massachusetts/CorpNameChange.txt",delim(",") varnames(1)
	drop if length(dataid) != 6

	rename (oldentityname namechangedate) (oldname namechangeddatestr)
	gen namechangeddate = date(substr(trim(namechangeddatestr),1,10),"YMD")
	keep if !missing(namechangeddate)
	keep dataid oldname namechangeddate
	save ~/projects/reap_proj/final_datasets/MA.names.dta,replace
	
	
	
	
**
** Create a death date as the last time 18 months elapsed without a filing
**
	clear
	import delimited using "~/projects/reap_proj/raw_data/Massachusetts/CorpDetailExport.txt", delimit(",") varnames(1)
	gen lastdocumentdate = date(substr(submitdate,1,10),"YMD")
	gsort dataid -lastdocumentdate
	by dataid: keep if _n == 1
	
	gen deathdate = lastdocumentdate + 365*1.5
	gen deathyear = year(deathdate)
	
	** The firm has not died if it submitted aything in the last 18 months
	replace deathdate = . if lastdocumentdate > (date("2014/11/24","MDY") - 365*1.5)
	merge 1:m dataid using ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta
	drop if _merge == 1
	drop _merge
	save ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta, replace
	
	
**
**
**


*Build Director file
	clear
	import delimited using "~/projects/reap_proj/raw_data/Massachusetts/CorpIndividualExport.txt",delim(",") varnames(1)
	gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(regexr(fullname," +"," ")))
	rename individualtitle role
	replace role = upper(trim(itrim(role)))
	keep if inlist(role,"PRESIDENT","MANAGER","CEO")
	keep dataid fullname role firstname
	order dataid fullname role
	save ~/projects/reap_proj/final_datasets/MA.directors.dta,replace


** Drop foreign firms 
	clear 
	u ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta
	keep if state == "MA" | state == ""
	save ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta, replace
	
	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	corp_add_names, dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) names(~/projects/reap_proj/final_datasets/MA.names.dta) nosave
	tomname entityname
	save MA$dtasuffix.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta)

	corp_add_gender, dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) directors(~/projects/reap_proj/final_datasets/MA.directors.dta) names(~/ado/names/MA.TXT)


	corp_add_eponymy, dtapath(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) directorpath(~/projects/reap_proj/final_datasets/MA.directors.dta)
	
	# delimit ;
	corp_add_trademarks MA , 
		dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) 
		trademarkfile(/projects/reap_proj/data/trademarks.dta) 
		ownerfile(/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		class(/projects/reap_proj/data/trademarks/classification.dta)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications MA MASSACHUSETTS , 
		dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) 
		pat(/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  MA MASSACHUSETTS , 
		dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta)
		pat("/projects/reap_proj/data_share/patent_assignments.dta" "/projects/reap_proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 MA MASSACHUSETTS ,dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) ipo(/projects/reap_proj/data/ipoallUS.dta)
	corp_add_mergers MA MASSACHUSETTS ,dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) merger(/projects/reap_proj/data/mergers.dta)
	

	corp_add_vc2 	 MA  ,dta(~/projects/reap_proj/final_datasets/MA$dtasuffix.dta) vc(~/projects/reap_proj/final_datasets/VC.investors.withequity.dta)  longstate(MASSACHUSETTS) dropexisting 

	
	corp_has_last_name
				

clear
u ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save ~/projects/reap_proj/final_datasets/MA$dtasuffix.dta, replace
