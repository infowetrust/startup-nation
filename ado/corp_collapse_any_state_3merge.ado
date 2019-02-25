


capture program drop corp_collapse_any_state_3merge
program define corp_collapse_any_state_3merge, rclass
	syntax anything , [outputsuffix(string)] [workingfolder(string)] [extra(string)]

{

    local params = substr("`0'",1, strpos("`0'", ",")-1)
    di "collapsing files: `params'"

    corp_collapse_any_state `params' , outputsuffix(`outputsuffix') workingfolder(`workingfolder') extra(mergerdate_new mergerdate_Z) by(targetsic_Z) nosave

    rename mergerdate mergerdate_old
    gen diffmerger_old = month(mergerdate_old) - month(incdate) + 12*(year(mergerdate_old) - year(incdate))
    gen diffmerger_new = month(mergerdate_new) - month(incdate) + 12*(year(mergerdate_new) - year(incdate))
    gen diffmerger_Z = month(mergerdate_Z) - month(incdate) + 12*(year(mergerdate_Z) - year(incdate))

    drop growthz diffmerger
    gen growthz_old = (inrange(diffmerger_old,6,12*6) & !missing(diffmerger_old) & substr(targetsic, 1,1) != "6" & targetsic != "1041" & targetsic != "1311" ) | inrange(diffipo,6,12*6) & !missing(diffipo)  
    gen growthz_new = (inrange(diffmerger_new,6,12*6) & !missing(diffmerger_new) & substr(targetsic, 1,1) != "6" & targetsic != "1041" & targetsic != "1311" ) | inrange(diffipo,6,12*6) & !missing(diffipo)  
    gen growthz_Z = (inrange(diffmerger_Z,6,12*6) & !missing(diffmerger_Z) & substr(targetsic_Z, 1,1) != "6" & targetsic_Z != "1041" & targetsic_Z != "1311" ) | inrange(diffipo,6,12*6) & !missing(diffipo)  

    di " `workingfolder'`params'.collapsed`ox'.dta"
    save `workingfolder'`params'.collapsed`ox'.dta, replace

}
end
