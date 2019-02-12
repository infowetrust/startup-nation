	clear
	log close
	log using table3.log, replace
	u MA.collapsed.dta, clear
	drop if incyear < 1988
	safedrop rsort
    safedrop trainingyears trainingsample

    gen rsort = runiform()
    gen trainingyears = inrange(incyear,1988,2008)
    by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7
    replace trainingsample = 0 if !trainingyears

    label variable haslastname "Firm Name has Last Name"
    label variable haspropername "Firm Name has Proper Name"

/*	
	eststo clear
 
	# delimit ;
        eststo: logit growthz is_corp is_DE
		if trainingsample, vce(robust) or;

    # delimit ;
        eststo: logit growthz shortname eponymous
                        if trainingsample, vce(robust) or;

    # delimit ;
        eststo: logit growthz patent trademark
                        if trainingsample, vce(robust) or;
						
	# delimit ;
		eststo: logit growthz is_corp is_DE  
						shortname eponymous 
                    clust_local clust_resource_int clust_traded  
					is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                    if trainingsample, vce(robust) or;
					
	save MA2.collapsed.dta, replace;
		use KY.collapsed.dta, clear;
		
	drop if incyear < 1988;
	label variable haslastname "Firm Name has Last Name";
    label variable haspropername "Firm Name has Proper Name";
	label variable clust~int "Traded Resources Intensive";
	label variable patent_noDE "Patent Only";
	label variable nopatent_DE "Delaware Only";
	label variable patent_and_DE "Patent and Delaware";
	
		predict nowcastingquality, pr;
	save KY2.collapsed.dta, replace;
		use MA2.collapsed.dta, clear;
		
	# delimit ;
		eststo: logit growthz is_corp 
							shortname eponymous
							trademark
							patent_noDE nopatent_DE patent_and_DE
							clust_local clust_resource_int clust_traded
							is_biotech is_ecommerce is_IT is_medicaldev is_semicond
							if trainingsample, vce(robust) or;
							
		save MA2.collapsed.dta, replace;
		use KY2.collapsed.dta, clear;
		predict quality, pr;
	save KY2.collapsed.dta, replace;
		use MA2.collapsed.dta, clear;
		
	# delimit ;
		esttab, replace title("Growth Predictive Model - Logit Regression on IPO or Acquisition Within 6 Years")
			refcat(is_corp "Corporate Governance Measures" patent "Intellectual Property Measures" clust_local "US CMP Cluster Dummies" is_ecommerce "US CMP High-Tech Clusters",label(" "))
			pr2 eform se label noabbrev
			mgroup(" " "Preliminary Model" " " "Nowcasting (up to real-time)" "Full (2 year lag)", pattern(1 1 1 1 1))
			nodep nomtitles
			nonotes
			addnotes(" " "We estimates a logit model with Growth as the dependent variable. Growth is a binary indicator equal to 1 if a firm achieves IPO or acquisition within 6 years and 0 otherwise. Growth is only defined for firms born in the cohorts of 1988 to 2012. This model forms the basis of our entrepreneurial quality estimates, which are the predicted values of the model. Incidence ratios reported; Robust standard errors in parenthesis. * p<0.05 ** p<0,01 *** p<0.001");
	# delimit ;
		esttab using table3.rtf, replace title("Growth Predictive Model - Logit Regression on IPO or Acquisition Within 6 Years")
			 order(is_corp is_DE shortname eponymous patent trademark patent_noDE nopatent_DE patent_and_DE clust_local clust_resource_int clust_traded is_biotech is_ecommerce is_IT is_medicaldev is_semicond) gap
			refcat(is_corp "Corporate Governance Measures" shortname "Name-Based Measures" patent "Intellectual Property Measures" patent_noDE "Patent - Delaware Interaction" clust_local "US CMP Cluster Dummies" is_biotech "US CMP High-Tech Clusters",label(" "))
			pr2 eform se label noabbrev
			mgroup(" " "Preliminary Model" " " "Nowcasting (up to real-time)" "Full (2 year lag)", pattern(1 1 1 1 1))
			nodep nomtitles
			nonotes
			addnotes(" " "We estimates a logit model with Growth as the dependent variable. Growth is a binary indicator equal to 1 if a firm achieves IPO or acquisition within 6 years and 0 otherwise. Growth is only defined for firms born in the cohorts of 1988 to 2012. This model forms the basis of our entrepreneurial quality estimates, which are the predicted values of the model. Incidence ratios reported; Robust standard errors in parenthesis. * p<0.05 ** p<0,01 *** p<0.001");
			compress
log close
*/
****************************************************** Table **************************************************
ssc install outreg2
 # delimit ;
			logit growthz is_corp is_DE
		if trainingsample, vce(robust) or;
			outreg2 using 1.doc, replace ctitle(Model 1) se eform label drop(growthz)  title("dfdfsfsdf") addnote("fdsfdfdsf") addstat(Pseudo R-squared,`e(r2_p)'); 
 # delimit ;			
 
				logit growthz shortname eponymous
                        if trainingsample, vce(robust) or;
						outreg2 using 1.doc, append ctitle(Model 2) se eform label drop(growthz) addstat(Pseudo R-squared,`e(r2_p)');
# delimit ;

		logit growthz patent trademark
                        if trainingsample, vce(robust) or;
						outreg2 using 1.doc, append ctitle(Model 3) se eform label drop(growthz) addstat(Pseudo R-squared, `e(r2_p)');
# delimit ;

						logit growthz is_corp is_DE  
						shortname eponymous 
                    clust_local clust_resource_int clust_traded  
					is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                    if trainingsample, vce(robust) or;
					order(is_corp is_DE shortname eponymous patent trademark patent_noDE nopatent_DE patent_and_DE clust_local clust_resource_int clust_traded is_biotech is_ecommerce is_IT is_medicaldev is_semicond);
					outreg2 using 1.doc, append ctitle(Model 4) se eform label nocons drop(growthz) addstat(Pseudo R-squared, `e(r2_p)');
# delimit ;

						logit growthz is_corp 
							shortname eponymous
							trademark
							patent_noDE nopatent_DE patent_and_DE
							clust_local clust_resource_int clust_traded
							is_biotech is_ecommerce is_IT is_medicaldev is_semicond
							if trainingsample, vce(robust) or;
							order(is_corp is_DE shortname eponymous patent trademark patent_noDE nopatent_DE patent_and_DE clust_local clust_resource_int clust_traded is_biotech is_ecommerce is_IT is_medicaldev is_semicond);
							
							
					outreg2 using 1.doc, append ctitle(Model 5) se eform label drop(growthz) addstat(Pseudo R-squared, `e(r2_p)');
log close
