
cd ~/projects/reap_proj/final_datasets
/*

clear
gen cor_name = ""
save ~/project/reap_proj/final_datasets/FL.dta, replace
forvalues doci=0/10 {
	di "*** loading file cordata`doci' ***"
	clear
	infile using ~/scripts/dct/FL.dct, using(/projects/reap_proj/raw_data/Florida/2017/cordata`doci'.txt)
		
	append using ~/project/reap_proj/final_datasets/FL.dta
	save ~/project/reap_proj/final_datasets/FL.dta, replace
}


clear

use ~/project/reap_proj/final_datasets/FL.dta

gen incdate = date(cor_file_date,"MDY")
gen incyear = year(incdate)

keep if inlist(state_country,"DE","FL","")
keep if inlist(cor_mail_state, "FL","")
replace state_country = "FL" if state_country == ""

gen is_nonprofit = inlist(cor_filing_type,"DOMNP","FORNP")

gen is_corp = inlist(cor_filing_type,"DOMP", "DOMNP","FORP","FORNP")
gen address = trim(itrim(cor_mail_add_1 +" " +  cor_mail_add_2))
rename (state_country cor_number cor_mail_city cor_mail_state cor_mail_zip cor_name) (jurisdiction dataid city state zipcode entityname) 

drop if is_nonprofit
 
keep dataid entityname incdate incyear   is_corp jurisdiction is_nonprofit address city state zipcode
save ~/project/reap_proj/final_datasets/FL.dta,replace

*/

clear
gen fullname = ""
save ~/project/reap_proj/final_datasets/FL.dta, replace

forvalues i=1/5{
	use  /projects/reap_proj/data_share/registries/Florida.dta

	keep cor_number  prin`i'*
	rename prin`i'_* *
	replace princ_name = subinstr(subinstr(subinstr(subinstr(princ_name,",","",.),".","",.),"-","",.),"'","",.)
	replace princ_name = upper(trim(itrim(princ_name)))
	replace princ_name = regexr(princ_name,"[^A-Z ]","")
	
	*princ_name_type == "P" if this is a person, C if a corporation
	drop if length(princ_name) < 4  | princ_state != "FL" 
	
	gen role = "PRESIDENT" if strpos(princ_title,"P")
	replace role = "PRESIDENT" if strpos(princ_title,"C")
	drop if missing(role)
	rename (cor_number princ_name) (dataid fullname)
	keep dataid fullname role
	split fullname, limit(2)
	rename (fullname1 fullname2) (firstname lastname)
	
	append using ~/project/reap_proj/final_datasets/FL.dta, force
	save ~/project/reap_proj/final_datasets/FL.dta, replace
}


	u FL.dta
	tomname entityname
	drop if missing(dataid)
	save FL.dta,replace

	corp_add_gender, dta(~/project/reap_proj/final_datasets/FL.dta) directors(~/project/reap_proj/final_datasets/FL.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(FL.dta) directorpath(FL.dta)
	
	# delimit ;
	corp_add_trademarks FL , 
		dta(FL.dta) 
		trademarkfile(/projects/reap_proj/data/trademarks.dta) 
		ownerfile(/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/projects/reap_proj/data/trademarks/classification.dta)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications FL FLORIDA , 
		dta(FL.dta) 
		pat(/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	# delimit ;
	
	set trace on;
	set tracedepth 1;
	corp_add_patent_assignments  FL FLORIDA 
		, 
		dta(FL.dta)
		pat("/projects/reap_proj/data_share/patent_assignments.dta" "/projects/reap_proj/data_share/patent_assignments2.dta" )
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		

	# delimit cr	
	*corp_add_vc2 	 FL  ,dta(~/project/reap_proj/final_datasets/FL.dta) vc(~/project/reap_proj/final_datasets/VC.investors.dta) longstate(FLORIDA) 

	corp_add_ipos	 FL  ,dta(~/project/reap_proj/final_datasets/FL.dta) ipo(/projects/reap_proj/data/ipoallUS.dta)  longstate(FLORIDA) 
	corp_add_mergers FL  ,dta(~/project/reap_proj/final_datasets/FL.dta) merger(/projects/reap_proj/data/mergers.dta)  longstate(FLORIDA) 


	clear
	u FL.dta
	safedrop firstentityname
	gen firstentityname = entityname
	save FL.dta, replace



	corp_add_industry_dummies , ind(~/nbercriw/industry_words.dta) dta(~/project/reap_proj/final_datasets/FL.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/project/reap_proj/final_datasets/FL.dta)
 
 

clear
u ~/project/reap_proj/final_datasets/FL.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3


 save ~/project/reap_proj/final_datasets/FL.dta, replace


