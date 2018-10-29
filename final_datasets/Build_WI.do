cd ~/final_datasets/

clear 
infile using WI.dct 
drop if dataid == ""
drop if strpos(entityname,"CORPORATION NAME") == 1
gen for_llc = strpos(corptype,"Foreign LLC") > 0 | strpos(corptype,"Foreign Limited") > 0
gen foreign = strpos(corptype,"Foreign" ) > 0
gen is_corp = strpos(corptype, "Business") > 0 | strpos(corptype,"Corpora") > 0 | foreign & !for_llc


tomname entityname
savesome if !foreign using WI.local.dta ,replace
savesome if foreign using WI.foreign.dta , replace


corp_get_DE_by_name , dta(WI.foreign.dta)
keep if is_DE

gen local_firm= state == "WI"
append using WI.local.dta
save WI.dta , replace
 


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u WI.dta , replace
	tomname entityname
	save WI.dta, replace

	corp_add_eponymy, dtapath(WI.dta) directorpath(WI.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(WI.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(WI.dta)
	
	
	# delimit ;
	corp_add_trademarks WI , 
		dta(WI.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WI WISCONSIN , 
		dta(WI.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  WI WISCONSIN , 
		dta(WI.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 WI  ,dta(WI.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(WISCONSIN)
	corp_add_mergers WI  ,dta(WI.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(WISCONSIN) 
