

cd ~/migration/datafiles/

global mergetempsuffix Montana
global only_DE 0

/**
 ** Jorge's code starts here
 **/

 clear
import delimited corpid entityid corporationtypeid corporationstatusid corporationnumber citizenship dateformed dissolvedate duration countyofinc stateofinc countryofinc purpose profession registeredagentname using "~/projects/reap_proj/raw_data/Missouri/Corporation.txt", delimiters(",") stringcols(_all) bindquote(loose)


drop if v16 != ""
drop v*
    
/*Keep only local or delaware*/

gen jurisdiction = stateofinc
replace jurisdiction = "MO" if citizenship == "D"

if $only_DE == 1 {
    keep if jurisdiction == "DE"
}

drop if missing(dateformed)
gen incdate =dofc(clock(dateformed,"YMD hms"))
gen incyear = year(incdate)


save MO.dta, replace






clear
import delimited corporationtypeid corporationtype using "~/projects/reap_proj/raw_data/Missouri/CorporationType.txt", delimiters(",") stringcols(_all)

merge 1:m corporationtypeid using MO.dta
drop if _merge == 1
replace corporationtype = "Gen. For Profit Corporation" if _merge == 2
drop _merge


keep if inlist(corporationtype, "Limited Liability Company","","LLP","Limited Partnership","Professional Corporation","Close Corporation","Gen. For Profit Corporation")

gen is_corp = strpos(corporationtype,"Corporation") > 0
save MO.dta, replace



clear
import delimited nametypeid nametype  using "~/projects/reap_proj/raw_data/Missouri/NameType.txt", delimiters(",") stringcols(_all)

save ~/temp/nametypes.dta, replace

clear
import delimited corporationnameid corpid name nametypeid title salutation prefix lastname middlename firstname suffix  using "~/projects/reap_proj/raw_data/Missouri/CorporationName.txt", delimiters(",") stringcols(_all)

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
import delimited addresstypeid description  using ~/projects/reap_proj/raw_data/Missouri/AddressType.txt, delimiters(",") stringcols(_all)
save addresstypes.dta, replace


clear
import delimited addressid corporationid addresstypeid addr1 addr2 addr3 city state zipcode county country  using ~/projects/reap_proj/raw_data/Missouri/Address.txt, delimiters(",") stringcols(_all)

destring addresstype, replace

gen address_order     = 1 if addresstype == 3 | addresstype == 1003
replace address_order = 2 if addresstype == 6
replace address_order = 3 if addresstype == 9

bysort corporationid (address_order): gen first = _n == 1
keep if first
drop first
gen address = trim(itrim(addr1 + " " + addr2 + " " +addr3))
rename corporationid dataid
merge 1:m dataid using MO.dta


keep if _merge == 3
drop _merge

gen stateaddress = state
gen potentiallylocal = is_DE | jurisdiction == "MO"


if $only_DE == 1 {
    keep if is_DE == 1
}

duplicates drop

save MO.dta, replace



clear
import delimited partytypeid partytype  using ~/projects/reap_proj/raw_data/Missouri/PartyType.txt, delimiters(",") stringcols(_all)

save partytypes.dta , replace


clear
import delimited xid  officerid partytypeid   using ~/projects/reap_proj/raw_data/Missouri/OfficerPartyType.txt, delimiters(",") stringcols(_all)

merge m:1 partytypeid using partytypes.dta
keep if _merge == 3
drop _merge
save partytypes.dta, replace


clear
import delimited officerid corpid mr salutation fullname  using ~/projects/reap_proj/raw_data/Missouri/Officer.txt, delimiters(",") stringcols(_all)
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








corp_add_vc MO ,dta(MO.dta) vc(~/final_datasets/VX.dta) longstate(MISSOURI)





clear
u MO.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
save MO.dta, replace



    
