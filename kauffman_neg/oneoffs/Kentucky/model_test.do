	#delimit ;	
	u KY2.collapsed.dta,clear;
	************ Quality ***************
	
	safedrop rsort;
    safedrop trainingyears trainingsample;

    gen rsort = runiform();
    gen trainingyears = inrange(incyear,1988,2008);
    by trainingyears (rsort), sort: gen trainingsample = _n/_N <= .7;
    replace trainingsample = 0 if !trainingyears;
	keep if trainingyears & !trainingsample;
	sort quality;
	
	keep if _n/_N >= .99;
	collapse (sum) growthz;
	local numtop1 = growthz[1];


	u KY2.collapsed.dta,clear;
	order growthz quality;
	sort growthz;
	local N=_N;
	gen percentile=floor(_n/_N*20)/20;
	replace percentile = .95 if percentile == 1;
	collapse (sum) growthz, by(percentile);
	egen totalgrowth = sum(growthz);
	sort percentile;
	local sharetop1 = substr(string(round(`numtop1'/totalgrowth,.01)),1,3);
	local sharetop5 = substr(string(round(growthz[_N]/totalgrowth,.01)),1,3);
	local sharetop10 = substr(string(round((growthz[_N] + growthz[_N-1])/totalgrowth,.01)),1,3);
	
	
	gen percentsuc = growthz[_n]/totalgrowth;
	di "Share top 1%: `sharetop1'";
	di "Share top 5%: `sharetop5'";
	di "Share top 10%: `sharetop10'";
	
	
	graph twoway bar percentsuc percentile, 
			text(.6 .35 "Share of realized growth" "---------------------------" "Top 1%: `sharetop1'"
						 "Top 5%: `sharetop5'" "Top 10%: `sharetop10'", justification(left)) 
			barwidth(.04) xlabel(0(.05).95) ytitle("Percent of realized growth events")
			title("Estimated Entrepreneurial Quality Percentile vs. Incidence" "of Realized Growth Outcomes (30% 1988-2008 Test Sample)", size(medium)) 
			saving("accuracy_test.gph",replace)
			xtitle("Percent Realized Growth Events") ytitle("Percentile");
			
	************ Quality(nowcasting) ***************
	#delimit ;		
	u KY2.collapsed.dta, clear;
	sort nowcastingquality;
	keep if _n/_N >= .99;
	collapse (sum) growthz;
	local numtop1 = growthz[1];

	u KY2.collapsed.dta,replace;
	sort growthz;
	local N=_N;
	gen percentile=floor(_n/_N*20)/20;
	replace percentile = .95 if percentile == 1;
	collapse (sum) growthz, by(percentile);
	egen totalgrowth = sum(growthz);
	sort percentile;
	local sharetop1 = substr(string(round(`numtop1'/totalgrowth,.01)),1,3);
	local sharetop5 = substr(string(round(growthz[_N]/totalgrowth,.01)),1,3);
	local sharetop10 = substr(string(round((growthz[_N] + growthz[_N-1])/totalgrowth,.01)),1,3);
	
	
	gen percentsuc = growthz[_n]/totalgrowth;
	di "Share top 1%: `sharetop1'";
	di "Share top 5%: `sharetop5'";
	di "Share top 10%: `sharetop10'";
	
	
	graph twoway bar percentsuc percentile, 
			text(.6 .35 "Share of realized growth" "---------------------------" "Top 1%: `sharetop1'"
						 "Top 5%: `sharetop5'" "Top 10%: `sharetop10'", justification(left)) 
			barwidth(.04) xlabel(0(.05).95) ytitle("Percent of realized growth events")
			title("Estimated Entrepreneurial Quality Percentile vs. Incidence" "of Realized Growth Outcomes (30% 1988-2008 Test Sample)", size(medium)) 
			saving("accuracy_test.gph",replace)
			xtitle("Percent Realized Growth Events") ytitle("Percentile");
			
