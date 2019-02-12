 clear
 cd /NOBACKUP/scratch/share_scp/scp_private/scp2018/
 local keepraw = 0
 local dtasuffix
 di "Suffix : `dtasuffix'"
global mergetempsuffix="migration.CA"
 
 set more off
 

	clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/California/CA_CORPHISTORY, using(/NOBACKUP/scratch/share_scp/raw_data/California/2018/CORPHISTORY.TXT)
	keep if transactioncode == "AMDT"
	gen namechangeddate = date(transactiondate,"YMD")
	save CAtempnames.dta,replace


	clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/California/CA_CORPMASTER,  using(/NOBACKUP/scratch/share_scp/raw_data/California/2018/CORPMASTER.TXT)
	gen ord = _n
	recast long ord 
	gen dataid = ord
	
	gen incdate = date(incdate_str,"YMD")
	format incdate %d
	gen incyear = year(incdate)
	gen is_corp = 1
	
	replace jurisdiction_state = "DE" if jurisdiction_state == "DELAWARE"
	replace jurisdiction_state = "CA" if jurisdiction_state == ""

	gen address = trim(itrim(upper(address1 + " " + address2)))
	
	
	rename (jurisdiction_state state_county)(jurisdiction state)
	replace state  = "CA" if missing(state)
        gen stateaddress = state

	sort incdate entityname 
	gen is_nonprofit= corptaxbase == "N" & !missing(corptaxbase)
	
        gen local_firm = inlist(jurisdiction, "DE", "CA") & state == "CA"
        replace local_firm =  0 if !(state == "CA")
	
	
	preserve
	keep dataid corpnumber entityname incdate incyear  is_corp jurisdiction  address city state zipcode is_nonprofit stateaddress local_firm
	save CA`dtasuffix'.dta,replace



	restore
	preserve
	keep presidentname dataid 
	rename presidentname fullname
	split fullname, parse(" ") limit(2)
	rename fullname1 firstname
	gen title = "PRESIDENT"
	keep dataid title firstname fullname
	replace fullname = trim(itrim(fullname))
	tostring dataid, replace
	drop if missing(fullname)
	save CA.directors.dta,replace
	
	
	clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/California/CA_CORPHISTORY,  using(/NOBACKUP/scratch/share_scp/raw_data/California/2018/CORPHISTORY.TXT)
	keep if transactioncode == "AMDT"
	gen namechangeddate = date(transactiondate,"YMD")
	save CAtempnames.dta,replace



	restore
	merge m:m corpnum using CAtempnames.dta
	keep if _merge == 3
	drop _merge
	rename newcorpname oldname
	keep dataid oldname namechangeddate
	duplicates drop
	tostring dataid, replace format(%12.0f)
	save CA.names.dta,replace

	** LLCs
	local keepraw = 0
	clear

	infile using /NOBACKUP/scratch/share_scp/raw_data/California/CA_LPMASTER, using(/NOBACKUP/scratch/share_scp/raw_data/California/2018/LPMASTER.TXT)
	rename id corpnumber
        gen llcid = corpnumber
        gen ord = _n
	recast long ord 
	gen dataid = 15000000 + ord
	
	
	gen incdate = date(incdate_str,"YMD")
	gen incyear = year(incdate)
	gen is_corp = 0
	drop calif* jurisdiction_state2
	rename mail* *
	sort incdate entityname 
	rename jurisdiction_state jurisdiction
	replace jurisdiction = "CA" if jurisdiction == ""

	** Final Data Drops

        gen local_firm = inlist(jurisdiction,"CA","DE") & (state == "CA" | state == "")
        replace local_firm = 0 if !(state == "CA" | state == "")
	
	preserve
	keep dataid llcid entityname incdate incyear  is_corp jurisdiction  address city state zipcode
	
	*Line Added
	replace entityname = regexr(entityname,"WHICH WILL DO .*$","")
	
	append using CA`dtasuffix'.dta
	tostring dataid, replace format(%12.0f)
	compress
	save CA`dtasuffix'.dta,replace
	

	restore

	keep dataid manager1 manager2 registeredagent
	rename (registeredagent) (manager3)
	tostring dataid, replace format(%12.0f)
	duplicates drop dataid, force
	reshape long manager, i(dataid) j(managernum)
	gen title = "MANAGER"
	rename manager fullname
	split fullname, parse(" ") limit(2)
	rename fullname1 firstname
	keep dataid title firstname fullname
	replace fullname = trim(itrim(fullname))
	replace firstname = trim(itrim(firstname))
	append using CA.directors.dta
	save CA.directors.dta,replace
	
	
	 clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/California/CA_CORPHISTORY,  using(/NOBACKUP/scratch/share_scp/raw_data/California/2018/CORPHISTORY.TXT)
	keep if transactioncode == "MERG"
	drop if strpos(comment, "OUTGOING")
	rename (corpnumber namecorpnumber) (histmergedintoid histmergedid)
	gen histmergerdate = date(transactiondate,"YMD") 
	drop if missing(histmergedid)
	save CA.recapitalizations.dta, replace

	
****
*** Step 2: Add Information
****


	
	
	corp_add_names,dta(CA`dtasuffix'.dta) names(CA.names.dta)
	*corp_add_recapitalizations,dta(~/migration/datafiles/CA.dta) merger(CA.recapitalizations.dta) matchvariable(corpnumber)
	
	
	clear
	u CA`dtasuffix'.dta
	tomname entityname
	drop if missing(dataid)
	save CA`dtasuffix'.dta,replace



	//corp_add_eponymy, dtapath(CA`dtasuffix'.dta) directorpath(CA.directors.dta)
	
	# delimit ;
	corp_add_trademarks CA , 
		dta(CA`dtasuffix'.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	

	# delimit ;
	corp_add_patent_applications CA CALIFORNIA , 
		dta(CA`dtasuffix'.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  CA CALIFORNIA , 
		dta(CA`dtasuffix'.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	//corp_add_vc2 	 CA  ,dta(~/migration/datafiles/CA.dta) vc(~/migration/datafiles/VC.investors.withequity.dta) longstate(CALIFORNIA) 

	corp_add_ipos	 CA  ,dta(CA`dtasuffix'.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(CALIFORNIA) 
	
	corp_add_mergers CA  ,dta(CA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(CALIFORNIA) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(CA`dtasuffix'.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(CA`dtasuffix'.dta)

	
	

clear
u CA`dtasuffix'.dta

gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
duplicates drop
compress
 save CA`dtasuffix'.dta, replace


