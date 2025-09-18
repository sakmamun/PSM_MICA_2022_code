
cd "G:\MICS_Datasets"

copy "https://github.com/sakmamun/PSM_MICA_2022/raw/75f8a7c45f7fc478c853e4ebac6e8a6087da8e92/mergeddatase_hh_fs.dta", replace
use "mergeddatase_hh_fs.dta", clear

* Set survey design
svyset psu [pweight = hhweight], strata(stratum) vce(linearized)
***************
rename hh1 cluster
rename hh2 hhID
rename hh6 area
rename hh7 div
rename hh7a district
rename hh48 hhnumber
rename hc11 ownComputer
rename hc12 ownMobile
rename hc13 ownInternet
rename hc16 ownland
rename cb3 age
rename pr5 hasHomework
rename hl4 gender
rename pr7 hasSMC
label var melevel "mothers' education level"

***********************
* EXPLORATORY ANALYSIS OF DATA
*
************************
*Basic Summary Statistics

summarize hhnumber hhage ownlan hasSMC, detail												
												
graph box _y [pweight = hhweight], by(_treat)						// Boxplot

*Distribution plot (For continuous variables (hhnumber, hhage)
histogram hhnumber, percent title("Distribution of Household Number") 
histogram hhage, percent title("Distribution of Household Age") 

* Distribution plot (For categorical variables)
graph bar (percent), over(helevel) title("Education Level Distribution")
graph bar (percent), over(melevel) title("Mother's Education Distribution") 
graph bar (percent), over(ownlan) title("Land Ownership Distribution")
graph bar (percent), over(hasSMC) title("SMC Availability Distribution")
#############################################################################################
* Propensity Score Mathing Estimation
#####################################################################################

ssc install psmatch2  															// Install if not already installed
psmatch2 (hhhelp) helevel melevel hhnumber ownlan hasSMC hhage ///      		//* without gender subset
         ,out(numeracy_score) common
pstest helevel melevel hhnumber ownlan hasSMC hhage, both



* Export treatment effect estimates
asdoc psmatch2 (hhhelp) helevel melevel hhnumber ownlan hasSMC hhage ///      	//* without gender subset
         ,out(numeracy_score) common

asdoc pstest helevel melevel hhnumber ownlan hasSMC hhage, ///					* Save pstest balance table to Word
		both replace title(Balance Diagnostics after PSM)

		
		
	
twoway (kdensity _pscore if hhhelp == 1) (kdensity _pscore if hhhelp == 0), ///
legend(label(1 "Treated") label(2 "Control")) ///
title("Propensity Score Distribution") ///
xtitle("Propensity Score") ytitle("Density") ///
note("Kernel density plot by treatment status")



asdoc psmatch2 (hhhelp) helevel melevel hhnumber ownlan hasSMC hhage ///      * Subset of data for Male (gender =1)
         if gender==1, out(numeracy_score) common
asdoc pstest helevel melevel hhnumber ownlan hasSMC hhage, ///					* Save pstest balance table to Word
		both replace title(Balance Diagnostics after PSM)


twoway (kdensity _pscore if hhhelp == 1) (kdensity _pscore if hhhelp == 0), ///
legend(label(1 "Treated") label(2 "Control")) ///
title("Propensity Score Distribution") ///
xtitle("Propensity Score") ytitle("Density") ///
note("Kernel density plot by treatment status")


asdoc psmatch2 (hhhelp) helevel melevel hhnumber ownlan hasSMC hhage ///      * Subset of data for Female (gender =2)
         if gender==2, out(numeracy_score) common 
asdoc pstest helevel melevel hhnumber ownlan hasSMC hhage, ///					* Save pstest balance table to Word
		both replace title(Balance Diagnostics after PSM)
*#############################################################################
psmatch2 (hhhelp) i.helevel i.melevel hhnumber ownlan hasSMC hhage ///      
         , out(numeracy_score) common
estimates store _all
psmatch2 (hhhelp) i.helevel i.melevel hhnumber ownlan hasSMC hhage ///      
         if gender==1, out(numeracy_score) common
estimates store _m
psmatch2 (hhhelp) i.helevel i.melevel hhnumber ownlan hasSMC hhage ///      
         if gender==2, out(numeracy_score) common
estimates store _f

asdoc esttab _all _m _f

*%###############################################################
		 
twoway (kdensity _pscore if hhhelp == 1) (kdensity _pscore if hhhelp == 0), ///
legend(label(1 "Treated") label(2 "Control")) ///
title("Propensity Score Distribution") ///
xtitle("Propensity Score") ytitle("Density") ///
note("Kernel density plot by treatment status")

*******************************************************************************
* ROBUSTNESS CHECK of the Estimation
********************************************************************************
            
* 1:1 Nearest neighbors matching: without gender subset

asdoc psmatch2 hhhelp i.helevel i.melevel hhnumber ownland hasSMC hhage, ///
	  outcome(numeracy_score) ///
      neighbor(1) ///
      common ///
	  caliper(0.2) ///
      ate
estimates store _nn


asdoc psmatch2 hhhelp i.helevel i.melevel hhnumber ownland hasSMC hhage if gender ==1, ///
	  outcome(numeracy_score) ///
      neighbor(1) ///
      common ///
	  caliper(0.2) ///
      ate
estimates store _mnn



asdoc psmatch2 hhhelp i.helevel i.melevel hhnumber ownland hasSMC hhage if gender ==2, ///
	  outcome(numeracy_score) ///
      neighbor(1) ///
      common ///
	  caliper(0.2) ///
      ate
estimates store _fnn

* Check balance
pstest helevel melevel hhnumber ownlan hasSMC hhage, both graph
pstest helevel melevel hhnumber ownlan hasSMC hhage, both						// Check balance

***********
twoway (kdensity _pscore if hhhelp == 1) (kdensity _pscore if hhhelp == 0), ///
legend(label(1 "Treated") label(2 "Control")) ///
title("Propensity Score Distribution") ///
xtitle("Propensity Score") ytitle("Density") ///
note("Kernel density plot by treatment status")
**********
esttab  _nn _mnn _fnn

