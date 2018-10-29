cd ~/projects/reap_proj/final_datasets/
global mergetempsuffix NYmerge_finaldatasets

clear
import delimited using ~/projects/reap_proj/raw_data/New_York/Active_Corporations_Online/Active_Corporations__Beginning_1800_06_26_2018.csv

gen incdate = date(initialdosfilingdate,"MDY")
gen incyear = year(incdate)


keep if incyear >= 1988

/** Do not use the address for the corporation agents **/
bysort registeredagentname: egen num_of_times = sum(1) if registeredagentname != ""
gen dos_info_lawyers_address = num_of_times > 100 & num_of_times != .

foreach v of varlist dosprocess* {
    replace `v' = "" if dos_info_lawyers_address == 1
}

gen address1 = ""
gen address2 = ""
gen zipcode  = ""
gen state    = ""
gen city     = ""

/** Get address in the following priority: location, ceo address, **/ 
foreach prefix in location ceo dosprocess {
    foreach v in address1 address2 zip state city {
        replace `v' = `prefix'`v'  if `v' == ""
    }
}

keep if inlist(jurisdiction, "DELAWARE","NEW YORK","")
gen is_DE = jurisdiction == "DELAWARE"
gen address =  address1 + address2


/** States come in long format, make them short two-letter versions **/
rename state longstate
replace longstate =  itrim(trim(longstate))
shortstate longstate , gen(state)
replace state = longstate if state  == "" & longstate != ""


/**only 5 digit zipcodes **/
replace zipcode = substr(itrim(trim(zipcode)), 1,5)


rename (ïdosid currententityname) (dataid entityname)
gen is_corp = strpos(entitytype, "CORPORATION")
keep entityname incdate incyear is_DE address zipcode state city dataid is_corp


save NY.dta , replace




clear
import delimited using "~/projects/reap_proj/raw_data/New_York/Aug2015/us_ny_export_for_mit_2015-08-24.csv", delim(",") varnames(1) bindquote(loose)

rename (company_number name headquarters_address_*) (dataid entityname *)

foreach v of varlist *postal_code { 
    tostring `v' , replace
    replace `v' = "" if `v' == "."
}


bysort agent_name: egen num_of_times = sum(1) if agent_name != ""
gen dos_info_lawyers_address = num_of_times > 100 & num_of_times != .

foreach v of varlist registered_* {
    replace `v' = "" if dos_info_lawyers_address 
}

foreach prefix in registered_address_ mailing_address_ {
    foreach v in street_addr locality region postal_code {
        replace `v' = `prefix'`v' if postal_code == ""

    }
    tostring `prefix'in_full, replace
    replace postal_code = word(`prefix'in_full,-1) if postal_code == ""
}

rename (street_addr postal_code region locality) (address zipcode state city)


gen incdate = date(incorporation_date, "YMD")
gen incyear = year(incdate)
gen is_corp = strpos(company_type,"CORPORATION") > 0
gen is_nonprofit = strpos(company_type,"NOT-FOR-PROFIT") > 0

rename home_jurisdiction jurisdiction


replace jurisdiction = trim(upper(subinstr(jurisdiction,"us_","",.)))
gen is_DE = jurisdiction == "DE"

keep if inlist(jurisdiction,"","DE","NY")
replace state = "NY" if state == "" & jurisdiction == "NY"

/** these are only the inactive  ones **/
//drop if current_status == "Active"


/**only 5 digit zipcodes **/
replace zipcode = substr(itrim(trim(zipcode)), 1,5)


keep dataid entityname incdate incyear is_corp address city state zipcode is_DE current_status

gen second_file = 1
append using NY.dta 

replace second_file = 0 if second_file ==.
bysort dataid (second_file): gen keepme = _n == 1
keep if keepme == 1
drop keepme second_file
save NY.dta,replace




gen shortname = wordcount(entityname) <= 3
gen corpnumber = dataid

gen local_firm= state == "NY"
gen stateaddress = state

save NY.dta , replace



**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u NY.dta, replace
	tomname entityname
	save NY.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(NY.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(NY.dta)





	# delimit ;
	corp_add_trademarks NY , 
		dta(NY.dta) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NY NEW YORK , 
		dta(NY.dta) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;

	corp_add_patent_assignments  NY NEW YORK , 
		dta(NY.dta)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta" "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 NY ,dta(NY.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta) longstate(NEW YORK)
	corp_add_mergers NY ,dta(NY.dta) merger(~/projects/reap_proj/data/mergers.dta)  longstate(NEW YORK)
	corp_add_vc2 	 NY ,dta(NY.dta) vc(~/final_datasets/VC.investors.dta) longstate(NEW YORK)

