
cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
global mergetempsuffix="MA_Official"


global dtasuffix


/*
**
** STEP 1: Load the data dump from MA Corporations 
*/
	clear
	import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Massachusetts/2018/CorpData.txt", delim(",") varnames(1) 

	gen incdate = date(dateoforganization,"MDY") 
	gen incyear = year(incdate)
	gen is_corp = regexm(entitytypedescriptor,"Corporation")
	gen incdateDE = date(jurisdictiondate,"MDY")
        gen stateaddress = state

	* Drop a few bad items (12 in dataid and 75 in incyear of 900K)
	drop if length(dataid) != 6
	drop if missing(incyear)
	
        replace jurisdictionstate = "MA" if jurisdictionstate == ""
	gen local_firm =  inlist(jurisdictionstate,"MA","DE") & inlist(state, "", "MA")
	gen address = trim(itrim(addr1 + " " + addr2))

	rename (jurisdictionstate postalcode) (jurisdiction zipcode)

	gen is_nonprofit = regexm(entitytypedescriptor, "Nonprofit")
	replace is_nonprofit = 1 if regexm(entitytypedescriptor, "Religious")


	rename fein corpnumber
	keep dataid entityname incdate incyear corpnumber jurisdiction is_corp is_nonprofit address city state zipcode  incdateDE stateaddress local_firm
	
	save MA$dtasuffix.dta,replace


* Create files for name changes
* We could add mergers here but then that could definitely make a mess of having the outcome as inputs
*
	clear
	import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Massachusetts/2018/CorpNameChange.txt",delim(",") varnames(1)
	drop if length(dataid) != 6

	rename (oldentityname namechangedate) (oldname namechangeddatestr)
	gen namechangeddate = date(substr(trim(namechangeddatestr),1,10),"YMD")
	keep if !missing(namechangeddate)
	keep dataid oldname namechangeddate
	save MA.names.dta,replace
	
	
	
	
	
**
**
**


*Build Director file
	clear
	import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Massachusetts/2018/CorpIndividualExport.txt",delim(",") varnames(1)
        save MA.diraddress.dta , replace
        gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(regexr(fullname," +"," ")))
	rename individualtitle role
	replace role = upper(trim(itrim(role)))
	keep if inlist(role,"PRESIDENT","MANAGER","CEO")
	keep dataid fullname role firstname
	order dataid fullname role
	save MA.directors.dta,replace

 
	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	corp_add_names, dta(MA$dtasuffix.dta) names(MA.names.dta) nosave
	tomname entityname
	save MA$dtasuffix.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(MA$dtasuffix.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(MA$dtasuffix.dta)



***     This part has an error right now
***	corp_add_gender, dta(MA$dtasuffix.dta) directors(MA.directors.dta) names(~/ado/names/MA.TXT)


	corp_add_eponymy, dtapath(MA$dtasuffix.dta) directorpath(MA.directors.dta)
	
	# delimit ;
	corp_add_trademarks MA , 
		dta(MA$dtasuffix.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
*/	
	# delimit ;
	corp_add_patent_applications MA MASSACHUSETTS , 
		dta(MA$dtasuffix.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  MA MASSACHUSETTS , 
		dta(MA$dtasuffix.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 MA  ,dta(MA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(MASSACHUSETTS) 
	corp_add_mergers MA  ,dta(MA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(MASSACHUSETTS) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
*	corp_add_vc2  MA  ,dta(MA$dtasuffix.dta) vc(VC.investors.withequity.dta)  longstate(MASSACHUSETTS) dropexisting 
	corp_add_vc MA  ,dta(MA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(MASSACHUSETTS)


	
	//corp_has_last_name
				

clear
u MA$dtasuffix.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
 save MA$dtasuffix.dta, replace
