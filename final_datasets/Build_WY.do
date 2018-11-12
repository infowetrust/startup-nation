
cd ~/final_datasets/

global mergetempsuffix WYmerge

clear
import delimited using "/projects/reap.proj/raw_data/Wyoming/FILING.csv", delim("|") varnames(1) bindquote(loose)
rename mail_* *

rename (state_of_org postal_code filing_id filing_name)(jurisdiction zipcode dataid entityname)
gen address = itrim(trim(addr1 + " " + addr2  + " " + addr3))


replace jurisdiction = "DE" if jurisdiction == "Delaware"
replace jurisdiction = "WY" if jurisdiction == ""
gen potentiallylocal= inlist(jurisdiction,"DE","WY")
 
gen is_nonprofit = filing_type == "NonProfit Corporation"
gen is_corp = strpos(filing_type, "Corporation") >0
drop if is_nonprofit
gen is_DE = jurisdiction == "DE"
gen incdate = date(filing_date,"MDY")
ge incyear = year(incdate)


gen shortname = wordcount(entityname) <= 3
keep dataid entityname incdate incyear   is_corp  is_nonprofit address city state zipcode is_DE shortname potentiallylocal
gen local_firm = potentiallylocal
gen stateaddress = state
save WY.dta,replace

clear
import delimited using "/projects/reap.proj/raw_data/Wyoming/PARTY.csv", delim("|") varnames(1) bindquote(loose)
rename source_id dataid
gen fullname = trim(itrim(first_name + " " + middle_name + " " + last_name))
keep if inlist(party_type,"President","Incorporator","Applicant","Organizer","Member","Manager","Member/Manager","General Partner")
gen role = "CEO" 
keep dataid fullname role
save WY.directors.dta,replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u WY.dta, replace
	tomname entityname
	save WY.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(WY.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(WY.dta)

*	corp_add_gender, dta(WY.dta) directors(WY.directors.dta) names(~/ado/names/WY.TXT)


	corp_add_eponymy, dtapath(WY.dta) directorpath(WY.directors.dta)
	
	# delimit ;
	corp_add_trademarks WY , 
		dta(WY.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WY WYOMING , 
		dta(WY.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WY WYOMING , 
		dta(WY.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 WY ,dta(WY.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(WYOMING)
	corp_add_mergers WY ,dta(WY.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(WYOMING)




 
      corp_add_vc        WY ,dta(WY.dta) vc(~/final_datasets/VX.dta) longstate(WYOMING)
