cd ~/projects/reap_proj/final_datasets/
global mergetempsuffix NYmerge


clear
import delimited using "/projects/reap.proj/raw_data/New York/Aug2015/us_ny_export_for_mit_2015-08-24.csv", delim(",") varnames(1) bindquote(loose)

rename (company_number name headquarters_address_*) (dataid entityname *)

foreach v of varlist *postal_code { 
    tostring `v' , replace
    replace `v' = "" if `v' == "."
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
replace state = "NY" if state == "" & jurisdiction == "NY"
gen local_firm= inrange(jurisdiction,"DE","NY") & state == "NY"
gen stateaddress = state


** it is possible to register some through the ZIP Code if the y have no state
gen zip5 = substr(zipcode, 1,5)
destring zip5, replace force
replace state = "NY" if inrange(zip5, 10001, 14925) & state == ""

gen shortname = wordcount(entityname) <= 3
gen corpnumber = dataid

keep dataid corpnumber entityname incdate incyear is_corp  is_nonprofit address city state zipcode is_DE shortname jurisdiction local_firm stateaddress
save NY.dta,replace

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
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NY NEW YORK , 
		dta(NY.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;

	corp_add_patent_assignments  NY NEW YORK , 
		dta(NY.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta" "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 NY ,dta(NY.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(NEW YORK)
	corp_add_mergers NY ,dta(NY.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(NEW YORK)
	corp_add_vc 	 NY ,dta(NY.dta) vc(~/final_datasets/VX.dta) longstate(NEW YORK)

corp_has_last_name, dtafile(NY.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
corp_has_first_name, dtafile(NY.dta) num(1000)
corp_name_uniqueness, dtafile(NY.dta)

clear
u NY.dta
gen has_unique_name = uniquename <= 5
save NY.dta, replace


clear
u NY.dta
gen  shortname = wordcount(entityname) <= 3
 

 save NY.dta, replace
