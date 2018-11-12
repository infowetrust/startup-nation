 clear
 cd ~/final_datasets
 
 
 local keepraw = 0
 local dtasuffix = ""
global mergetempsuffix="Ohio_State"
global OH_dta_file OH.dta
global only_DE 0

 set more off
 
 
 clear
 import delimited dataid articlesfilingdoc entityname firmtype x3 x4 filingdate x5  active x6 x7 x8 x9 x10 city state  v1 v v3 v4 v5 v6 v7 v8 v9 z1 z2 z3 z4  using ~/projects/reap_proj/raw_data/Ohio/CORPDATA.BUS, delim("|")
 
 gen is_corp = inlist(firmtype,"CP","CF")
gen is_foreign = inlist(firmtype,"CF","LF")
 gen is_nonprofit = inlist(firmtype,"CN")
 drop if inlist(firmtype,"CN","FN","MO","NR","RN") | inlist(firmtype,"RT","SM","BT","00","CV","UN")

gen zipcode = ""
gen stateaddress = state


 split filingdate ,parse(" ")
 gen incdate = date(filingdate1,"YMD")
 gen incyear = year(incdate)

savesome if !is_foreign using $OH_dta_file , replace 

keep if is_foreign
tomname entityname
save OH.foreign.dta , replace

corp_get_DE_by_name ,dta(OH.foreign.dta) 
keep if is_DE
append using $OH_dta_file

if $only_DE == 1 {
    keep if is_DE == 1
}
keep dataid  entityname incdate incyear is_corp    city state zipcode is_nonprofit is_DE
gen stateaddress  = state

/** There is no address, but we never use it anyways **/
gen address = ""
save $OH_dta_file,replace








 *** DIRECTORS *** 
 
clear 
import delimited dataid numdirector fullname  using ~/projects/reap_proj/raw_data/Ohio/CORPDATA.ASS, delim("|")

/*assume that only the first three directors are important*/
keep if numdirector <= 3


split fullname, parse(" ") limit(2)
rename fullname1 firstname
gen title = "PRESIDENT"
keep dataid title firstname fullname
save OH.directors.dta,replace
	
	
	
*** OLD NAMES ***
	
	
 clear 
 import delimited dataid namechangeddate oldname using ~/projects/reap_proj/raw_data/Ohio/CORPDATA.NAM, delim("|")
 
duplicates drop
save OH.names.dta,replace

	

	
****
*** Step 2: Add Information
****


	
	
	corp_add_names,dta($OH_dta_file) names(OH.names.dta)
	
	
	clear
	u $OH_dta_file

	drop if missing(dataid)
	save $OH_dta_file,replace

	corp_add_gender, dta($OH_dta_file) directors(OH.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath($OH_dta_file) directorpath(OH.directors.dta)
	
	
	
	# delimit ;
	corp_add_patent_applications OH OHIO , 
		dta($OH_dta_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  OH OHIO , 
		dta($OH_dta_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	

	# delimit ;
	corp_add_trademarks OH , 
		dta($OH_dta_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(~/projects/reap_proj/data/trademarks/classification.dta)
		tomonths(12)
		;
	
	# delimit cr	

	corp_add_vc 	 OH  ,dta($OH_dta_file) vc(~/final_datasets/VX.dta) longstate(OHIO) 


	corp_add_ipos	 OH  ,dta($OH_dta_file) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(OHIO) 
	corp_add_mergers OH  ,dta($OH_dta_file) merger(~/projects/reap_proj/data/mergers.dta)  longstate(OHIO) 


*		set trace on
*		set tracedepth 1
	corp_add_industry_dummies , ind(~/nbercriw/industry_words.dta) dta($OH_dta_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($OH_dta_file)

	
	

clear
u $OH_dta_file
gen  shortname = wordcount(entityname) <= 3
 save $OH_dta_file, replace


