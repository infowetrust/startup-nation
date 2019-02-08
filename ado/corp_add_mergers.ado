capture program drop corp_add_mergers

program define corp_add_mergers, rclass
	syntax namelist(min=1 max=2), [DTApath(string)] [NOSave] MERGERpath(string) longstate(string) [nomatchdta(string)]  [skipcollapsed] [storenomatched(string)]

{
    local state="`1'"
	
    if "`dtapath'" == "" {
        local filepath = "/NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta"
    }
    else {
        local filepath = "`dtapath'"
    }
	

    clear
    u `mergerpath'
    rename dateannounced mergerdate
    replace targetstate = upper(trim(itrim(targetstate)))
    keep if targetstate == "`longstate'"
    keep mergerdate match* mfull_name targetname equityvalue targetsic
    gen mergeryear =year(mergerdate)
    save /NOBACKUP/scratch/share_scp/temp/`state'.merger.dta,replace

    if "`storenomatched'" == "" {     
	jnamemerge `filepath' /NOBACKUP/scratch/share_scp/temp/`state'.merger.dta , `skipcollapsed'
    }
    else {
	jnamemerge `filepath' /NOBACKUP/scratch/share_scp/temp/`state'.merger.dta , `skipcollapsed' both
	gen __is_match = incdate != .
	bysort targetname: egen __max_is_match = max(__is_match)
	drop if __max_is_match == 1 & entityname == ""
	// tostring dataid , gen(__str_dataid)
	// drop if __str_dataid == ""
        savesome using `storenomatched' if _mergex == "no match (rightfile)" & __max_is_match == 0 , replace
	drop __is_match __max_is_match 
    }
	
    safedrop _merge _mergex maold
    format mergerdate %d
    
    if "`nosave'" == "" {
        save  `filepath',replace 
    }
}
end
