 clear
 cd ~/final_datasets
 
 
 local keepraw = 0
 local dtasuffix = ""
global mergetempsuffix="Ohio_State"
 /*
 set more off
 
 
 clear
 import delimited dataid articlesfilingdoc entityname firmtype x3 x4 filingdate x5  active x6 x7 x8 x9 x10 city state  v1 v v3 v4 v5 v6 v7 v8 v9 z1 z2 z3 z4  using /projects/reap.proj/raw_data/Ohio/CORPDATA.BUS, delim("|")
 
 gen is_corp = inlist(firmtype,"CP","CF")
 gen is_nonprofit = inlist(firmtype,"CN")
 drop if inlist(firmtype,"CN","FN","MO","NR","RN") | inlist(firmtype,"RT","SM","BT","00","CV","UN")
 
 split filingdate ,parse(" ")
 gen incdate = date(filingdate1,"YMD")
 gen incyear = year(incdate)
 
 replace state = "OH" if state == ""
 keep if state == "OH" | state == "DE"
 gen is_DE =  state == "DE"
 rename state jurisdiction
 gen state = "OH"

	gen zipcode = ""

	keep dataid  entityname incdate incyear is_corp    city state zipcode is_nonprofit
	save OH.dta,replace



 *** DIRECTORS *** 
 
clear 
import delimited dataid numdirector fullname  using /projects/reap.proj/raw_data/Ohio/CORPDATA.ASS, delim("|")

/*assume that only the first three directors are important*/
keep if numdirector <= 3


split fullname, parse(" ") limit(2)
rename fullname1 firstname
gen title = "PRESIDENT"
keep dataid title firstname fullname
save OH.directors.dta,replace
	
	
	
*** OLD NAMES ***
	
	
 clear 
 import delimited dataid namechangeddate oldname using /projects/reap.proj/raw_data/Ohio/CORPDATA.NAM, delim("|")
 
duplicates drop
save OH.names.dta,replace

	

	
****
*** Step 2: Add Information
****


	
	
	corp_add_names,dta(OH.dta) names(OH.names.dta)
	
	
	clear
	u OH.dta
	tomname entityname
	drop if missing(dataid)
	save OH.dta,replace

	corp_add_gender, dta(~/final_datasets/OH.dta) directors(~/final_datasets/OH.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(OH.dta) directorpath(OH.directors.dta)
	
	# delimit ;
	corp_add_trademarks OH , 
		dta(OH.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/projects/reap.proj/data/trademarks/classification.dta)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications OH OHIO , 
		dta(OH.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  OH OHIO , 
		dta(OH.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	*/
	*corp_add_vc2 	 OH  ,dta(~/final_datasets/OH.dta) vc(~/final_datasets/VC.investors.dta) longstate(OHIO) 


	corp_add_ipos	 OH  ,dta(~/final_datasets/OH.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(OHIO) 
	corp_add_mergers OH  ,dta(~/final_datasets/OH.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(OHIO) 


*		set trace on
*		set tracedepth 1
	corp_add_industry_dummies , ind(~/nbercriw/industry_words.dta) dta(~/final_datasets/OH.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/OH.dta)

	
	

clear
u ~/final_datasets/OH.dta
gen  shortname = wordcount(entityname) <= 3

 save ~/final_datasets/OH.dta, replace


