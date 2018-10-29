
/**
 ** Build the North Carolina Dataset
 **/


cd ~/final_datasets
global mergetempsuffix="NC_Official"


**
** STEP 1: Load the data dump from NC Corporations 


clear
gen dropme = ""
save NC.dta, replace
forvalues y=1988/2014 {
 clear
    import delimited using "/projects/reap.proj/raw_data/North Carolina/`y'.csv", delim(tab) varnames(1)
    tostring sosid, replace
    safedrop v21
    append using  NC.dta
    save NC.dta, replace

}

clear
u NC.dta, replace
rename sosid dataid
rename corpname entityname
rename prin* *
rename zip zipcode
drop reg*
gen is_corp= type == "BUS"
gen is_nonprofit = type == "NP"
drop if is_nonprofit
gen is_DE = .
keep if citizenship == "D"
split dateformed, limit(2)
drop dateformed dateformed2
gen incdate = date(dateformed1,"MDY")
format incdate %d
gen incyear = year(incdate)
save NC.dta, replace

tab type
	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**
    cd ~/final_datasets/
	u NC.dta, replace
	tomname entityname
	save NC.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/final_datasets/NC.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/NC.dta)

	# delimit ;
	corp_add_trademarks NC , 
		dta(~/final_datasets/NC.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		class(/projects/reap.proj/data/trademarks/classification.dta)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NC NORTH CAROLINA , 
		dta(~/final_datasets/NC.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  NC NORTH CAROLINA , 
		dta(~/final_datasets/NC.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 NC  ,dta(~/final_datasets/NC.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(NORTH CAROLINA)
	corp_add_mergers NC ,dta(~/final_datasets/NC.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(NORTH CAROLINA)
	
	# delimit ;
	corp_add_vc2 	 NC  ,dta(~/final_datasets/NC.dta) 
				vc(~/final_datasets/VC.investors.dta)  longstate(NORTH CAROLINA) dropexisting ;
	# delimit cr
	
	corp_has_last_name, dtafile(~/final_datasets/NC.dta) lastnamedta(~/ado/name/lastnames.dta) num(5000)

        corp_has_first_name, dtafile(~/final_datasets/NC.dta) num(1000)
				

clear
u ~/final_datasets/NC.dta
gen  shortname = wordcount(entityname) <= 3
 save ~/final_datasets/NC.dta, replace

corp_collapse_any_state NC , workingfolder(~/final_datasets/)
