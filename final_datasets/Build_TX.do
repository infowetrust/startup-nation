set more off
cd /NOBACKUP/scratch/share_scp/scp_private/scp2018/
global mergetempsuffix="TX_Official"
/*
/* Change this to create test samples */
global dtasuffix 


**
** STEP 1: Load the data dump from TX Corporations 
**
**
clear

infile using /NOBACKUP/scratch/share_scp/raw_data/Texas/2018/TX02.dct, using(/NOBACKUP/scratch/share_scp/raw_data/Texas/2018/02_TexasClean.txt)

drop if filing_number == "" |filing_number == "0000000000"
save TX.pre.dta, replace

clear
infile using /NOBACKUP/scratch/share_scp/raw_data/Texas/2018/TX03.dct, using(/NOBACKUP/scratch/share_scp/raw_data/Texas/2018/03_TexasClean.txt)
drop if filing_number == "" |filing_number == "0000000000"
merge 1:1 filing_number using TX.pre.dta
drop if _merge == 1
drop _merge 
save TX.pre.dta, replace 




clear
       use TX.pre.dta

	replace foreign_state = "TX" if missing(foreign_state)

        gen address = trim(itrim(upper(address1 + " " + address2)))

        replace state = "TX" if state == "" & foreign_state == "TX"

	gen is_nonprofit= inlist(corp_type_id,"08","09")

	gen incdate = date(creation_date,"YMD") 
	gen incdateDE = date(foreign_formation_date,"YMD")
	gen incyear = year(incdate)

	gen is_corp =inlist(corp_type_id,"01","02","03","04")
	rename (name filing_number) (entityname dataid)
	rename (foreign_state zip_code   ) (jurisdiction zipcode   )
	gen corpnumber = dataid
	foreach var of varlist state city country jurisdiction{
	replace `var' = trim(itrim(upper(`var')))
	}
	keep if inlist(country, "USA", "")
	gen stateaddress = state
	//missing state maybe companies from other countries !!
        gen local_firm = state == "TX" & inlist(jurisdiction,"TX","DE")


keep dataid corpnumber entityname incdate incyear  is_corp jurisdiction is_nonprofit address city state zipcode incdateDE stateaddress local_firm
	save TX$dtasuffix.dta,replace



	clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/Texas/2018/TX08.dct, using(/NOBACKUP/scratch/share_scp/raw_data/Texas/2018/08_TexasClean.txt)
	rename filingnumber dataid
	drop if dataid == "0000000000"
	gen fullname = trim(itrim(upper(firstname + " " + middlename + " " +lastname)))
	replace officertitle = upper(trim(itrim(officertitle)))
	replace officertitle = "MANAGER" if officertitle == "MANAGING MEMBER" | officertitle == "MEMBER" | officertitle == "MANAGING DIRECTOR"
	replace officertitle = "CEO" if officertitle == "CHIEF EXECUTIVE OFFICER" | officertitle == "CHAIRMAN" 
	replace officertitle = "PRESIDENT" if officertitle == "OWNER"
	rename officertitle role
	keep dataid fullname role firstname
	save TX.directors.dta,replace


	** Names
	clear
	infile using /NOBACKUP/scratch/share_scp/raw_data/Texas/2018/TX09.dct, using(/NOBACKUP/scratch/share_scp/raw_data/Texas/2018/09_TexasClean.txt)
	rename filingnumber dataid
	drop if dataid == "0000000000"
	destring nametypeid ,replace
	destring namestatusid ,replace
	drop if namestatusid ==1
	drop if nametypeid !=1
	gen namechangeddate = date(creationdatestr,"YMD")
	keep dataid oldname namechangeddate
	duplicates drop


	save TX.names.dta,replace



	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	corp_add_names, dta(TX$dtasuffix.dta) names(TX.names.dta) nosave
	u TX$dtasuffix.dta , replace
	tomname entityname
	save TX$dtasuffix.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(TX$dtasuffix.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(TX$dtasuffix.dta)
	corp_add_gender, dta(TX$dtasuffix.dta) directors(TX.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(TX$dtasuffix.dta) directorpath(TX.directors.dta)
	
	# delimit ;
	corp_add_trademarks TX , 
		dta(TX$dtasuffix.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications TX TEXAS , 
		dta(TX$dtasuffix.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;
	
	corp_add_patent_assignments  TX TEXAS , 
		dta(TX$dtasuffix.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
*/
	corp_add_ipos	 TX ,dta(TX$dtasuffix.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(TEXAS)
	corp_add_mergers TX ,dta(TX$dtasuffix.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta) longstate(TEXAS)
      corp_add_vc        TX ,dta(TX.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(TEXAS)


//corp_has_last_name, dtafile(TX$dtasuffix.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
//corp_has_first_name, dtafile(TX$dtasuffix.dta) num(1000)
//corp_name_uniqueness, dtafile(TX$dtasuffix.dta)

/*
clear
u TX$dtasuffix.dta
gen has_unique_name = uniquename <= 5
save TX$dtasuffix.dta, replace
*/

clear
u TX$dtasuffix.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
save TX$dtasuffix.dta, replace



u TX$dtasuffix.dta, replace
gen zip2 = substr(zipcode,1,2)
replace zip2 = "" if regexm(zip2,"[^0-9]")
destring zip2, replace
gen region = "So Texas (AUS/SAT)" if zip2 == 78
replace region = "Dallas/Houston" if inlist(zip2, 77,76)
replace region = "Other Texas" if zip2 == 79

compress
duplicates drop
 save TX$dtasuffix.dta, replace



