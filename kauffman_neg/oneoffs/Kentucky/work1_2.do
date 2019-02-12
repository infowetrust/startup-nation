	clear
	log close
	log using table3_MA.log, replace
	u MA.collapsed.dta, clear
	drop if incyear < 1988
	safedrop rsort
    safedrop trainingyears trainingsample

    gen rsort = runiform()
    gen trainingyears = inrange(incyear,1995,2008)
    by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
    replace trainingsample = 0 if !trainingyears

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"
	label variable clust~int "Traded Resources Intensive"

		logit growthz is_corp is_DE if trainingsample, vce(robust) or
		
	use KY.collapsed.dta, clear
	drop if incyear < 1988
	safedrop rsort
    safedrop trainingyears trainingsample

    gen rsort = runiform()
    gen trainingyears = inrange(incyear,1995,2008)
    by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
    replace trainingsample = 0 if !trainingyears

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"
	label variable clust~int "Traded Resources Intensive"
	predict quaility_KY, pr

        logit growthz shortname eponymous if trainingsample, vce(robust) or
		 
use KY.collapsed.dta, clear
drop if incyear < 1988
	safedrop rsort
    safedrop trainingyears trainingsample

    gen rsort = runiform()
    gen trainingyears = inrange(incyear,1995,2008)
    by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
    replace trainingsample = 0 if !trainingyears

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"
	label variable clust~int "Traded Resources Intensive"
	predict quaility2_KY, pr

logit quaility2_KY shortname eponymous 
