
/*
CREATE TABLE [dbo].[Corporation] (
    [CorporationID] [int] NOT NULL ,
    [EntityID] [int] NOT NULL ,
    [CorporationTypeID] [int] NOT NULL ,
    [CorporationStatusID] [int] NOT NULL ,
    [CorporationNumber] [varchar] (15) NOT NULL ,
    [Citizenship] [varchar] (1) NOT NULL ,
    [DateFormed] [datetime] NULL ,
    [DissolveDate] [datetime] NULL ,
    [Duration] [varchar] (50) NULL ,
    [CountyOfIncorporation] [varchar] (30) NULL ,
    [StateOfIncorporation] [varchar] (2) NULL ,
    [CountryOfIncorporation] [varchar] (30) NULL ,
    [Purpose] [varchar] (255) NULL ,
    [Profession] [varchar] (50) NULL ,
    [RegisteredAgentName] [varchar] (500) NULL
    ) ON [PRIMARY]
GO


import delimited corpid entityid corporationtypeid corporationnumber citizenship dateformed dissolvedate duration countyofinc stateofin purpose provession registeredagentname 
using ~/projects/reap_proj/raw_data/Missouri/2017/CorpDAta_new
*/


cd ~/projects/reap_proj/final_datasets/
    
/**
 ** Jorge's code starts here
 **/

 clear
import delimited corpid entityid corporationtypeid corporationstatusid corporationnumber citizenship dateformed dissolvedate duration countyofinc stateofinc countryofinc purpose profession registeredagentname using "~/projects/reap_proj/raw_data/Missouri/2017/Corporation.txt", delimiters(",") stringcols(_all) bindquote(loose)


drop if v16 != ""
drop v*
    
/*Keep only local or delaware*/
 keep if citizenship == "D" | stateofinc == "DE"
  
drop if missing(dateformed)
gen incdate =dofc(clock(dateformed,"YMD hms"))
gen incyear = year(incdate)
save MO.dta, replace






clear
import delimited corporationtypeid corporationtype using "~/projects/reap_proj/raw_data/Missouri/2017/CorporationType.txt", delimiters(",") stringcols(_all)

merge 1:m corporationtypeid using MO.dta
drop if _merge == 1
replace corporationtype = "Gen. For Profit Corporation" if _merge == 2
drop _merge


keep if inlist(corporationtype, "Limited Liability Company","","LLP","Limited Partnership","Professional Corporation","Close Corporation","Gen. For Profit Corporation")

gen is_corp = strpos(corporationtype,"Corporation") > 0
save MO.dta, replace



clear
import delimited nametypeid nametype  using "~/projects/reap_proj/raw_data/Missouri/2017/NameType.txt", delimiters(",") stringcols(_all)

save ~/temp/nametypes.dta, replace

clear
import delimited corporationnameid corpid name nametypeid title salutation prefix lastname middlename firstname suffix  using "~/projects/reap_proj/raw_data/Missouri/2017/CorporationName.txt", delimiters(",") stringcols(_all)

merge m:1 nametypeid using ~/temp/nametypes.dta
drop _merge

/* keep only the first name of the firm */
sort corpid corporationnameid
by corpid: gen first = _n == 1
keep if first
keep corpid name
rename name entityname

merge 1:m corpid using MO.dta
keep if _merge == 3
drop _merge
save MO.dta, replace

clear
u MO.dta

rename corpid dataid
gen is_DE = stateofinc == "DE"



save MO.dta, replace



clear
import delimited addresstypeid description  using ~/projects/reap_proj/raw_data/Missouri/2017/AddressType.txt, delimiters(",") stringcols(_all)
save addresstypes.dta, replace

clear
import delimited addressid corporationid addresstypeid addr1 addr2 addr3 city state zipcode county country  using ~/projects/reap_proj/raw_data/Missouri/2017/Address.txt, delimiters(",") stringcols(_all)

sort corporationid addresstypeid
by corporationid: gen first = _n == 1
keep if first
drop first
gen address = trim(itrim(addr1 + " " + addr2 + " " +addr3))
rename corporationid dataid
merge 1:m dataid using MO.dta


keep if _merge == 3
drop _merge
keep if state == "MO"
save MO.dta, replace



clear
import delimited partytypeid partytype  using ~/projects/reap_proj/raw_data/Missouri/2017/PartyType.txt, delimiters(",") stringcols(_all)

save partytypes.dta , replace


clear
import delimited xid  officerid partytypeid   using ~/projects/reap_proj/raw_data/Missouri/2017/OfficerPartyType.txt, delimiters(",") stringcols(_all)

merge m:1 partytypeid using partytypes.dta
keep if _merge == 3
drop _merge
save partytypes.dta, replace

 
clear
import delimited officerid corpid mr salutation fullname  address v7 v8 city state zipcode country using ~/projects/reap_proj/raw_data/Missouri/2017/Officer.txt, delimiters(",") stringcols(_all)
merge m:m officerid using partytypes.dta
keep if _merge == 3
drop _merge
keep if inlist(partytype,"CEO","Manager","Member/Manager","President","Chairman","Partner","Organizer")

rename partytype title
rename corpid dataid
keep dataid title fullname
save MO.directors.dta, replace




    

**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

        clear
        u MO.dta
	tomname entityname
	save MO.dta, replace
corp_add_eponymy, dtapath(MO.dta) directorpath(MO.directors.dta)
corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(MO.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(MO.dta)
	
	# delimit ;
	corp_add_trademarks MO , 
		dta(MO.dta) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications MO MISSOURI , 
		dta(MO.dta) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

/* No Observations */	
	corp_add_patent_assignments  MO MISSOURI , 
		dta(MO.dta)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	corp_add_ipos	 MO ,dta(MO.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta) longstate(MISSOURI)
	corp_add_mergers MO ,dta(MO.dta) merger(~/projects/reap_proj/data/mergers.dta) longstate(MISSOURI)








corp_add_vc2 MO ,dta(MO.dta) vc(~/final_datasets/VC.investors.dta) longstate(MISSOURI)



corp_has_last_name, dtafile(MO.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
corp_has_first_name, dtafile(MO.dta) num(1000)
corp_name_uniqueness, dtafile(MO.dta)

clear
u MO.dta
gen has_unique_name = uniquename <= 5
save MO.dta, replace




clear
u MO.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
save MO.dta, replace


!~/projects/reap_proj/chown_reap_proj.sh ~/projects/reap_proj/final_datasets/MO.dta
!cp  ~/projects/reap_proj/final_datasets/MO.dta ~/final_datasets/
