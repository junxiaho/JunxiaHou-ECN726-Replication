set more off
capture log close

clear all
clear matrix

// Install the estout package
// Derived from https://github.com/gslab-econ/template/blob/master/config/config_stata.do

program main
    local ssc_packages "estout"

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }
	
    capture confirm file $adobase/plus/m/moremata.hlp
        if _rc != 0 {
        cap ado uninstall moremata
        ssc install moremata
        }

end

main                

mata: mata mlib index


***************************************************************
*************************************************************** 
** locals
local out "Output/"
local data "Data/"


** import raw data
local import_worker_long "import_worker_long.dta"
local import_worker "import_worker.dta"
local import_main_eval "import_main_eval.dta"
local import_top_half "import_top_half.dta"
local import_extended "import_extended.dta"
local import_alt "import_alt.dta"
local import_full "import_full.dta"
local import_prof "import_prof.dta"
local import_extended_qlevel "import_extended_qlevel.dta"
local import_extended_wbeliefs "import_extended_wbeliefs.dta"
local import_evaluator_demo "import_evaluator_demo.dta"
local import_evaluator_known "import_evaluator_known.dta"
local import_worker_undergrad "import_worker_undergrad.dta"

** export clean data
local worker_long "`data'worker_long.dta"
local worker "`data'worker.dta"
local main_eval "`data'main_eval.dta"
local top_half "`data'top_half.dta"
local extended "`data'extended.dta"
local alt "`data'alt.dta"
local full "`data'full.dta"
local prof "`data'prof.dta"
local extended_qlevel "`data'extended_qlevel.dta"
local extended_wbeliefs "`data'extended_wbeliefs.dta"
local evaluator_demo "`data'evaluator_demo.dta"
local evaluator_known "`data'evaluator_known.dta"
local worker_undergrad "`data'worker_undergrad.dta"

*********************************************************************
***************************************************************
******* Cleaning Worker Study Data  
clear  
clear matrix  
use `import_worker'

***Count of how many workers dropped in Worker Study 
count if gender !="Woman" &  gender !="Man" & t_inc==1 

***Count of how many workers dropped in Worker (Strategic Iccentives) Study 
count if gender !="Woman" &  gender !="Man" & t_emp==1

**Dropping workers who do not idenify as a man or woman 
drop if gender !="Woman" &  gender !="Man"

tab gender 
tab gender if t_inc ==1 

****Gender 
g female = 0 
replace female = 1 if gender=="Woman" 

g male = 0 
replace male = 1 if gender=="Man"

g all = 1 
g subject = _n 

** classifying workers with performances in the middle 
tab num_overall if t_inc == 1 
tab num_overall if t_emp == 1 

g middle = 0 
replace middle = 1 if num_overall >= 3 & num_overall <= 6

** creating dummy variables the number of quesitons answered correctly 
forvalues i = 0(1)10{
g ncorr`i' = 0
replace ncorr`i' = 1 if num_overall == `i' 	
label variable ncorr`i' "Score=`i'"	
}

**calculating truth values 
forvalues i =0(1)10 {
g main_eval`i' = 0
replace main_eval`i' = 1 if main_eval >=`i' 
label variable main_eval`i' "Score of `i' indicative of poor performance"
}

g tind_10 = 0
forvalues i =0(1)10{
	g temp2`i' = .
foreach t in  inc emp { 
	summarize main_eval`i'   if t_`t' == 1 
	replace temp2`i' = `r(mean)' if t_`t' == 1  	
	replace tind_10 = temp2`i' if num_overall==`i'  & t_`t' == 1 
}
}


*** We randomly selected 50 men and 50 women for each treamtent and found that the median performance was 5, so cutoff =5 
g  tind_12 = 0 
g cutoff = 5 
foreach t in  inc emp { 
	sum num_overall if  t_`t' == 1 , detail 	
	replace tind_12 = 1 if  num_overall >= cutoff    & t_`t' == 1 
}

label variable  tind_10 "Truth(Individual chance of having a poor performance)"
label variable  tind_12 "Truth(Individual in top half)"

tab tind_10
tab tind_12 

** modal region was the south 
tab region if t_inc == 1 
g typical_r = 0 
replace typical_r = 1 if region == "Southeast"
replace typical_r = 1 if region == "Southwest"

** modal job is working full time 
tab job_full if t_inc ==1 
g typical_j = 0 
replace typical_j = 1 if job_full == "Working full-time"

** modal education involved at least some college 
tab educ if t_inc == 1 
g typical_e = 0 
replace typical_e = 1 if  educ_num >= 4

** modal generation in the us in 2022 were millenials who were between the ages of 26-40
g typical_a = 0 
replace typical_a = 1 if age >= 26 & age <= 40

** modal participant thus defined as follows 
g typical = 1
replace typical = 0 if typical_r == 0
replace typical = 0 if typical_j == 0
replace typical = 0 if typical_e == 0
replace typical = 0 if typical_a == 0
  
****Creating indicatores for over/underconfident given actual performance 
g under_10 = 0 if pred_10 == 0
replace under_10 = 1 - tind_10 if pred_10 == 1 

g over_10 = 0 if pred_10 == 1
replace over_10 = tind_10 if pred_10 == 0 

label variable under_10 "Given poor peformace self-evaluation, chance of being underconfident"
label variable over_10 "Given poor peformace self-evaluation, chance of being overconfident"

**** pred 12 (top half) 
g under_12 = 0 if pred_12 == 1
replace under_12 = tind_12 if pred_12 == 0

g over_12 = 0 if pred_12 == 0
replace over_12 = 1 - tind_12 if pred_12 == 1 

label variable under_12 "Given top half self-evaluation, chance of being underconfident"
label variable over_12 "Given top half self-evaluation, chance of being overconfident"
  
save `worker', replace 

***** Creating Long worker dataset 
clear
clear matrix
use `worker'

reshape long   pred_    ///
	, i(subject) j(decision)

save `worker_long'	, replace 


*********************************************************************
***************************************************************
******* Cleaning Main Evaluator Study Data 
clear  
clear matrix  
use `import_main_eval'

g all = 1 
g subject = _n 

***Create belief gap variables 
g gap_prior = prior - 47.79  if bmale == 1 
replace gap_prior = prior - 49.53   if bfemale == 1 

g gap_over = over - 39.06  if bmale == 1 
replace gap_over = over - 15.35  if bfemale ==1 

g gap_under = under - 52.14  if bmale == 1 
replace gap_under = under - 74.80   if bfemale == 1 

g gap_bayes = bayes - 47.79  if bmale == 1 
replace gap_bayes = bayes - 49.53   if bfemale == 1 

g gap_post = post - 47.79  if bmale == 1 
replace gap_post = post - 49.53   if bfemale == 1 

**Additional incentivized bonus questions 
g base_pn = 0 
replace base_pn = 1 if bonus_2 == 80 
label variable base_pn "Base Rate: Pure Neglect" 

g bayes_dist = abs(bonus_1 - 75)
label variable bayes_dist "Bayesian Updating: Dist from Truth" 

g base_dist = abs(bonus_2 - 41) 
label variable base_dist "Base Rate: Dist from Truth" 

g crt = bonus_3 + bonus_4 + bonus_5 
label variable crt "CRT score (out of 3)"

*** Creating interaction with B(F) variables
foreach i in  t_attn  t_calc   base_pn  gunknown  { 
g `i'Xbfemale = `i'*bfemale	
}
label variable t_attnXbfemale "Attention*B(F)"
label variable t_calcXbfemale "Calculation*B(F)"
label variable base_pnXbfemale "Base Rate: Pure Neglect*B(F)"
label variable gunknownXbfemale "Unknown Gender*B(F)"


***followup survey questions    
g female = 0 
replace female = 1 if gender=="Female" 
replace female = 1 if gender=="Woman" 

g male = 0 
replace male = 1 if gender=="Male"
replace male = 1 if gender=="Man"

g ogender = 0 
replace ogender = 1 if male==0 & female ==0
tab gender

g educLow = 0 
replace educLow = 1 if educ_num <= 5 

g educHigh = 1 - educLow

g incomeLow = 0
replace incomeLow = 1 if income == "Less than $10,000"
replace incomeLow = 1 if income == "$10,000 - $24,999"
replace incomeLow = 1 if income == "$25,000 - $49,999"
replace incomeLow = 1 if income == "I'd prefer not to state." 

g incomeHigh = 1 - incomeLow

g young = 0 
replace  young = 1 if age <=35

g old = 0 
replace old = 1 - young 
 
g favor_dem = 0
replace favor_dem = 1 if feel_dem > feel_rep 

g wfavor_rep = 1 - favor_dem 


g women_over = 0 
replace women_over = 1 if strpos(conf_gender, "Men are less confident") > 0
label variable women_over "In general, women more confident"

g women_under = 0 
replace women_under = 1 if strpos(conf_gender, "Women are less confident") > 0
label variable women_under "In general, women less confident"

g women_same = 0 
replace women_same = 1  if women_under ==0 & women_over==0
label variable women_same "In general, men and women same"

*** CONF STEM 
g womenSTEM_over = 0 
replace womenSTEM_over = 1 if strpos(conf_gender_stem, "Men are less confident") > 0
label variable womenSTEM_over "In STEM, women more confident"

g womenSTEM_under = 0 
replace womenSTEM_under = 1 if strpos(conf_gender_stem, "Women are less confident") > 0
label variable womenSTEM_under "In STEM, women less confident"

g womenSTEM_same = 0 
replace womenSTEM_same = 1  if womenSTEM_under == 0 & womenSTEM_over == 0
label variable womenSTEM_same "In STEM, men and women same"

****  
g self_adjust = 3 
replace self_adjust = 1 if strpos(conf_adjust, "Far too little") > 0 
replace self_adjust = 2 if strpos(conf_adjust, "Slightly too little") > 0 
replace self_adjust = 4 if strpos(conf_adjust, "Slightly too much") > 0 
replace self_adjust = 5 if strpos(conf_adjust, "Far too much") > 0 

g self_uadjust = 0 
replace self_uadjust = 1 if strpos(conf_adjust, "Far too little") > 0 
replace self_uadjust = 1 if strpos(conf_adjust, "Slightly too little") > 0 
label variable self_uadjust "I adjusted too little"

g self_oadjust = 0 
replace self_oadjust = 1 if strpos(conf_adjust, "Far too much") > 0 
replace self_oadjust = 1 if strpos(conf_adjust, "Slightly too much") > 0 
label variable self_oadjust "I adjusted too much"

g self_aadjust = 0 
replace self_aadjust = 1 if self_oadjust == 0 & self_uadjust == 0
label variable self_aadjust "I accurately adjusted"

*** 
g emp_adjust = 2 
replace emp_adjust = 1 if strpos(belief_emp, "need") > 0 
replace emp_adjust = 3 if strpos(belief_emp, "too much") > 0 

g emp_uadjust = 0 
replace emp_uadjust = 1 if strpos(belief_emp, "need") > 0 
label variable emp_uadjust "Emplyoers adjust too little"

g emp_oadjust = 0 
replace emp_oadjust = 1 if strpos(belief_emp, "too much") > 0 
label variable emp_oadjust "Emplyoers adjust too much"

g emp_aadjust = 0 
replace emp_aadjust = 1 if emp_oadjust == 0 & emp_uadjust == 0
label variable emp_aadjust "Emplyoers accurately adjust"

save `main_eval', replace 

*/
*********************************************************************
***************************************************************
******* Cleaning Evaluator (Full Distribution) Study 
clear 
clear matrix
use `import_full'

g all = 1 
g subject = _n 

*** Creating gap variables 
g gap_prior = prior - 47.39  if bmale == 1 
replace gap_prior = prior - 53.08   if bfemale == 1 

g gap_over = over - 32.04  if bmale == 1 
replace gap_over = over - 13.52  if bfemale == 1 

g gap_bayes = bayes - 47.39 if bmale == 1 
replace gap_bayes = bayes -  53.08   if bfemale == 1 

g gap_under = under - 47.67  if bmale == 1 
replace gap_under = under - 63.66  if bfemale == 1 

g gap_post = post - 47.39 if bmale == 1 
replace gap_post = post -  53.08   if bfemale == 1 

save `full', replace 

*/


*********************************************************************
***************************************************************
******* Cleaning  Evaluator (Top Half Attention) Study Data 
clear 
clear matrix
use `import_top_half'
	
g all = 1 
g subject = _n 
	
g gap_prior = prior - 48.41  if bmale == 1 
replace gap_prior = prior - 46.34   if bfemale == 1 

g gap_over = over -  32.31   if bmale == 1 
replace gap_over = over - 13.64 if bfemale == 1 

g gap_under = under - 39.34  if bmale == 1 
replace gap_under = under - 59.65  if bfemale == 1 

g gap_post =post - 48.41   if bmale == 1 
replace gap_post = post -  46.34   if bfemale == 1 

g gap_bayes = bayes - 48.41 if bmale == 1 
replace gap_bayes = bayes - 46.34   if bfemale == 1 

	
save `top_half', replace 
*/
*********************************************************************
***************************************************************
******* Cleaning  Evaluator (Professional) Study 
clear 
clear matrix
use `import_prof'
	
g all = 1 
g subject = _n 

g gap_over = over - 43.73  if bmale == 1 
replace gap_over = over - 40.57  if bfemale == 1 

g gap_under = under - 23.22  if bmale == 1 
replace gap_under = under - 58.17  if bfemale == 1 

g gap_prior = prior - 27.35  if bmale == 1 
replace gap_prior = prior - 29.27   if bfemale == 1 

g gap_post =post - 27.35  if bmale == 1 
replace gap_post = post - 29.27  if bfemale == 1 

g gap_bayes = bayes - 27.35 if bmale == 1 
replace gap_bayes = bayes - 29.27  if bfemale == 1 

save `prof', replace 

*/

*********************************************************************
***************************************************************
***Cleaning  Evaluator (Alternative Questions) Study Data	
clear
clear matrix
use `import_alt'

g all = 1 
g subject = _n 

local t1 "3+"
local t2 "5+"
local t3 "7+"
local t4 "poor performance (main self-eval)"
local t5 "poor-2"
local t6 "top half"

foreach i in 1 2 3 4 5 6 { 	
label variable prior_`i' "Prior of `t`i''"
label variable post_`i' "Posterior of `t`i''"
label variable bayes_`i' "Bayes Posterior of `t`i''"
label variable over_`i' "Percent Overconfident of `t`i''"
label variable under_`i' "Percent Underconfident of `t`i''"
} 


reshape long  prior_ post_ over_  under_ bayes_ /// 
	, i(subject) j(decision)
	
rename prior_  b_1
rename post_  b_2
rename over_  b_3
rename under_  b_4	
rename bayes_  b_5	
			
reshape long b_  ///
	, i(subject decision) j(btype)

g prior = 0 
replace prior = 1 if btype == 1 

g post = 0 
replace post = 1 if btype == 2

g over = 0  
replace over =1 if btype == 3

g under = 0 
replace  under = 1 if btype == 4 

g bayes = 0 
replace bayes = 1 if btype == 5

label variable prior "Prior"
label variable post "Posterior"
label variable over "Given low perf, overconfident"
label variable under "Given high perf, underconfident"
label variable bayes "Bayes Posterior"

keep  b_ decision prior post under over bayes  ///
	bfemale bmale  subject /// 

save `alt', replace 

*/

*********************************************************************
***************************************************************/
******* Cleaning Worker (Undergraduate) Study 
clear
clear matrix
use `import_worker_undergrad'

g all = 1 
g subject = _n 

g gyear23 = 0 
replace gyear23 = 1 if ygrad == "2023" 

forvalues i = 0(1)10{
g ncorr`i' = 0
replace ncorr`i' = 1 if num_overall == `i' 	
label variable ncorr`i' "Score=`i'"	
}

 label variable pred_12 "Binary (poor, main self-evaluation)"
 label variable pred_13 "Percent Chance (poor, main self-evaluation)"
 
reshape long  pred_    ///
	, i(subject) j(decision)


save `worker_undergrad', replace 

*/



**********************************************************
***************************************************************
******* Cleaning Evaluator (Additional Demographics) Study
clear
clear matrix
use `import_evaluator_demo'

g all = 1 
g subject = _n 

*** Creating gap variables 
g gap_over = over - 62.63  if bmale == 1 
replace gap_over = over - 10.35 if bfemale == 1 

g gap_under  = under - 37.60  if bmale == 1 
replace gap_under  = under - 69.97 if bfemale == 1 

g gap_prior = prior - 43.12 if bmale == 1
replace gap_prior = prior - 35.35 if bfemale == 1

g gap_post = post - 43.12 if bmale == 1
replace gap_post = post - 35.35 if bfemale == 1

g gap_bayes = bayes - 43.12 if bmale == 1  
replace gap_bayes = bayes - 35.35 if  bfemale == 1
		
rename prior  b_1
rename post  b_2
rename over  b_3
rename under  b_4	
rename bayes  b_5	

rename gap_prior   gap_b_1
rename  gap_post   gap_b_2
rename  gap_over   gap_b_3
rename  gap_under  gap_b_4	
rename  gap_bayes   gap_b_5
		
reshape long b_  gap_b_  ///
	, i(subject) j(btype)

g prior = 0 
replace prior = 1 if btype == 1 

g post = 0 
replace post = 1 if btype == 2

g over = 0  
replace over = 1 if btype == 3

g under = 0 
replace  under = 1 if btype == 4 

g bayes = 0 
replace bayes = 1 if btype == 5

label variable prior "Prior"
label variable post "Posterior"
label variable over "Given low perf, overconfident"
label variable under "Given high perf, underconfident"
label variable bayes "Bayes Posterior"

		
save `evaluator_demo', replace 
*/



**********************************************************
***************************************************************
******* Cleaning Evaluator (Known Performance) Study
clear
clear matrix
use `import_evaluator_known'

g all = 1 
g subject = _n 

g gap_over = over -  58.82  if bmale == 1 
replace gap_over = over -  32.14 if bfemale == 1 

g gap_under = under -  41.18 if bmale == 1 
replace gap_under = under - 67.86 if bfemale == 1 

g  gap_prior = prior - 39.69  if bmale == 1 
replace gap_prior = prior - 39.69 if bfemale == 1 

g  gap_post = post - 39.69  if bmale == 1 
replace gap_post = post -  39.69 if bfemale == 1 

g  gap_bayes = bayes - 39.69 if bmale == 1 
replace gap_bayes = bayes - 39.69 if  bfemale == 1 
		
rename prior  b_1
rename post  b_2
rename over  b_3
rename under  b_4	
rename bayes  b_5	

rename gap_prior   gap_b_1
rename  gap_post   gap_b_2
rename  gap_over   gap_b_3
rename  gap_under  gap_b_4	
rename  gap_bayes   gap_b_5
		
reshape long b_  gap_b_  ///
	, i(subject) j(btype)

g prior = 0 
replace prior = 1 if btype == 1 

g post = 0 
replace post = 1 if btype == 2

g over = 0  
replace over = 1 if btype == 3

g under = 0 
replace  under = 1 if btype == 4 

g bayes = 0 
replace bayes = 1 if btype == 5

label variable prior "Prior"
label variable post "Posterior"
label variable over "Given low perf, overconfident"
label variable under "Given high perf, underconfident"
label variable bayes "Bayes Posterior"

		
save `evaluator_known', replace 
*/


*****************************************
***************************************************************
clear
clear matrix
use `import_extended'

g all = 1 
g subject = _n 

**** Ga[ if in Baseline Treatment 
g gap_overm = overm - 39.06  if t_inc == 1 
g gap_overf = overf - 15.35 if t_inc == 1 

g gap_underm = underm - 52.14 if t_inc == 1 
g gap_underf = underf - 74.80 if t_inc == 1 

g gap_priorm = priorm - 47.79 if t_inc == 1 
g gap_priorf = priorf - 49.53 if t_inc == 1 

g gap_avgpostm = avgpostm - 47.79 if t_inc == 1 
g gap_avgpostf = avgpostf - 49.53 if t_inc == 1 

g gap_bayesm = bayesm - 47.79 if t_inc == 1 
g gap_bayesf = bayesf - 49.53 if t_inc == 1

**** Ga[ if in Strategic Incentives Treatment 
replace gap_overm = overm -  37.15 if t_emp == 1 
replace gap_overf = overf - 25.59 if t_emp == 1 

replace gap_underm = underm - 50.65 if t_emp == 1 
replace gap_underf = underf - 73.55 if t_emp == 1 

replace gap_priorm = priorm - 49.53 if t_emp == 1 
replace gap_priorf = priorf -  50.97 if t_emp == 1 

replace gap_avgpostm = avgpostm -  49.53 if t_emp == 1 
replace gap_avgpostf = avgpostf -  50.97 if t_emp == 1 

replace gap_bayesm = bayesm -  49.53 if t_emp == 1 
replace gap_bayesf = bayesf - 50.97 if t_emp == 1  


***** Creating differences 
foreach i in avgpost prior  { 
g wvm_`i' = `i'f - `i'm	 if both == 1 

g wvm_`i'Bias = 0 if both ==1 
replace  wvm_`i'Bias = 1 if  wvm_`i' >0   & both == 1 

g wvm_`i'Equal = 0 if both ==1 
replace  wvm_`i'Equal = 1 if  wvm_`i' == 0   & both == 1 

g wvm_`i'Opp = 0 if both ==1 
replace  wvm_`i'Opp = 1 if  wvm_`i' < 0   & both == 1 

label variable wvm_`i' "`i': B(F)-B(M)"
label variable wvm_`i'Bias "`i': B(F) $>$ B(M)"
label variable wvm_`i'Opp "`i': B(F) $<$ B(M)"
label variable wvm_`i'Equal "`i': B(F) $=$ B(M)"
}

save `extended', replace 


************************************************************
**************************************************************
***For the Evaluator (Extended Study), reshaping the data to the subject-questoin level (one observation for all of subjects beliefs about men and one observation for all of the subjects beliefs about womene)  
clear
clear matrix
use `extended'

foreach d in prior avgpost bayes over under  ///
	gap_prior gap_avgpost gap_bayes gap_over gap_under   {
rename 	`d'm  `d'0
rename 	`d'f  `d'1
}

reshape long prior avgpost bayes over under  ///
	gap_prior gap_avgpost gap_bayes gap_over gap_under /// 
	, i(subject) j(bfemale)

drop if prior ==. 

g bmale = 1 - bfemale 	

save `extended_qlevel', replace 
*/

************************************************************
**************************************************************
***For the Evaluator (Extended Study), creating a long version 
clear
clear matrix
use `extended'

reshape long  postm_   postf_ sem_ sef_  scorem_ scoref_  ///
	, i(subject) j(order)

foreach d in post se score    {
rename 	`d'm_  `d'0
rename 	`d'f_  `d'1
}

reshape long  post se id score   ///
	, i(subject order) j(bfemale)

tab score, gen(FEscore)
	
save `extended_wbeliefs', replace 

****************************************************************************
***************************************************************
****  Table 1

clear
clear matrix  
use `worker_long'

keep if t_inc == 1

local st_inc  "Incentivized for accuracy" 

foreach t in all middle  {

regress  pred_    female  /// 
	ncorr* /// 
	if decision == 10  & `t' == 1 /// 
	,constant vce(robust)  
eststo r10`t'

regress  pred_    female /// 
	if decision == 10  & `t' == 1 /// 
	,constant vce(robust)  
eststo r10a`t'

}

* using `out'regMain10_`s'.tex ///

esttab r10aall  r10all /// 
	r10amiddle	r10middle       /// 
	 using `out'Table1.tex ///
 	, b(3) se(3) label  /// 
	title("Self-Evaluations in the \textit{Baseline} treatment of the \textit{Worker Study}") /// 
	mgroups( "All" "Middle" , pattern(  1 0 1  0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ( "No Fe" "PFE"   "No FE" "PFE"   ) ///
	nogaps nonumbers compress /// 
 	 star(* 0.10 ** 0.05 *** 0.01 )  /// 
	addnote("Robust SEs")  replace




*****************************************************
**************************************************************
***Table 2 	

clear
clear matrix
use `main_eval' 

keep if t_base == 1 & gknown == 1  & all == 1 

foreach d in gap_prior gap_over gap_under  gap_bayes gap_post  ///
	bayes post  prior   under over { 

regress  `d'   bfemale   /// 
	,constant vce(robust)  
eststo r`d'1

regress  `d'   bfemale bmale  //// 
	,noconstant vce(robust)  
eststo r`d'2

}

foreach a in 1 2  { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

 label variable bmale "B(M)"

***using `out'reg`a'_t_base_gknown_all.tex ///

esttab  rprior`a'  rover`a'  runder`a'   rbayes`a'  rpost`a'    ///
	 using `out'Table2_PanelA_`name`a''.tex ///
 	, `text`a'' label  /// 
	title("Evaluators' Beliefs in the \textit{Baseline treatment} of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
	mgroups(  ""   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

**using `out'regGap`a'_t_base_gknown_all.tex ///

esttab  rgap_prior`a'  rgap_over`a'  rgap_under`a'  rgap_bayes`a'  rgap_post`a'  /// 
using `out'Table2_PanelB_`name`a''.tex ///
 	, `text`a'' label  /// 
	title("Evaluators' Beliefs in the \textit{Baseline treatment} of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
	mgroups(  ""   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
	addnote("SEs are robust")  replace
}	

*****************************************************
*************************************************************
** Table 3 

clear
clear matrix
use `main_eval' 

keep if gknown == 1

label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"
label variable t_base "Baseline"

foreach d in prior over under bayes post ///
gap_prior gap_over gap_under  gap_bayes gap_post { 
regress `d' bfemale t_attnXbfemale t_calcXbfemale ///
				t_base t_attn t_calc ///
, noconstant vce(robust)  
eststo r`d'1
}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

local table_name = "Table3" // "reg1_all_gknown_all.tex", "regGap1_all_gknown_all.tex"

esttab  rprior1  rover1  runder1   rbayes1  rpost1 ///
	using `out'`table_name'_PanelA.tex ///
 	, `text1' label  /// 
	title("Evaluators' Beliefs in the \textit{Baseline, Attention, and Calculation} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
	mgroups(  ""   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace

esttab  rgap_prior1  rgap_over1  rgap_under1  rgap_bayes1  rgap_post1 /// 
 	using `out'`table_name'_PanelB.tex ///
 	, `text1' label  /// 
	title("Evaluators' Beliefs in the \textit{Baseline, Attention, and Calculation} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
	mgroups(  ""   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
	addnote("SEs are robust")  replace

*****************************************************
*************************************************************
** Table 4 

foreach d in post gap_post { 

clear
clear matrix
use `main_eval'

keep if all == 1 

label variable bfemale "\$\Delta$"
label variable gunknownXbfemale "\$\Delta$ * Unknown Gender"

foreach z in t_base t_attn t_calc { 

regress `d' bfemale  gunknownXbfemale ///
	gunknown `z' /// 
	if `z' == 1 /// 
	,noconstant vce(robust)  
eststo r`z'1

}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

if "`d'" == "post" {
	local table_name "Table4_PanelA.tex" 
	local table_title "Evaluators' Posterior Beliefs about Workers according to whether or not they are in a \textit{Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel A}"
	*`out'regByV1_`d'_all.tex 
}
else if "`d'" == "gap_post" {
	local table_name "Table4_PanelB.tex" 
	local table_title "Evaluators' Posterior Beliefs about Workers according to whether or not they are in a \textit{Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel B}"
	*`out'regByV1_`d'_all.tex 
}

esttab  rt_base1  rt_attn1  rt_calc1    /// 
	 using `out'`table_name' ///
 	, `text1' label  /// 
	title("`table_title'") /// 
	mgroups(  ""   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Base"   "Attn"    "Calc"  "All" ) ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace

}

*****************************************************
*************************************************************
** Table 5

foreach s in t_base t_attn t_calc { 

clear
clear matrix
use `main_eval'

keep if `s' == 1 & gknown == 1 

**Demen variables 
foreach x in  crt  base_dist bayes_dist      {
summarize `x' , detail
replace `x' = `x' - `r(mean)'
g `x'Xbfemale = `x'*bfemale 
}

label variable crt "Demeaned CRT score"
label variable base_dist "Base Rate: Demeaned error in base rate" 
label variable bayes_dist "Bayesian Updating: Demeaned error in Bayesian updating" 

label variable crtXbfemale "B(F)*Demeaned CRT score"
label variable base_distXbfemale "B(F)*Base Rate: Demeaned error in base rate" 
label variable bayes_distXbfemale "B(F)*Bayesian Updating: Demeaned error in Bayesian updating" 


**Run regressions 

label variable bfemale "\$\Delta$"
label variable crtXbfemale "\$\Delta$*Demeaned CRT score"
label variable base_pnXbfemale "\$\Delta$*Base Rate: Pure Neglect"
label variable base_distXbfemale "\$\Delta$*Base Rate: Demeaned error in base rate"
label variable bayes_distXbfemale "\$\Delta$*Bayesian Updating: Demeaned error in Bayesian updating"

regress gap_post bfemale crt crtXbfemale /// 
	`s' ///
	,noconstant vce(robust) 
eststo rgap_post2

regress gap_post bfemale base_pn base_pnXbfemale /// 
`s' /// 
	,noconstant vce(robust) 
eststo rgap_post3

regress gap_post bfemale base_dist base_distXbfemale /// 
`s' ///
	,noconstant vce(robust) 
eststo rgap_post4

regress gap_post bfemale bayes_dist bayes_distXbfemale /// 
`s' /// 
	,noconstant vce(robust) 
eststo rgap_post5

if "`s'" == "t_base" {
	local table_name "Table5_PanelA.tex" 
	local table_title "By cognitive ability measures: evaluators' posterior beliefs about workers in \textit{Evaluator Study} in the \textit{Baseline, Attention, and Calculation} treatments: \textbf{Panel A}"
	*`out'regGapByF_`s'_gknown_all.tex 
	}
else if "`s'" == "t_attn" {
	local table_name "Table5_PanelB.tex" 
	local table_title "By cognitive ability measures: evaluators' posterior beliefs about workers in \textit{Evaluator Study} in the \textit{Baseline, Attention, and Calculation} treatments: \textbf{Panel B}"
	*`out'regGapByF_`s'_gknown_all.tex 
}
else if "`s'" == "t_calc" {
	local table_name "Table5_PanelC.tex" 
	local table_title "By cognitive ability measures: evaluators' posterior beliefs about workers in \textit{Evaluator Study} in the \textit{Baseline, Attention, and Calculation} treatments: \textbf{Panel C}"
	*`out'regGapByF_`s'_gknown_all.tex 
} 

esttab rgap_post2 rgap_post3 rgap_post4 rgap_post5 ///
	using `out'`table_name' ///
 	, b(2) se(2) label  /// 
	title("`table_title'") /// 
	mgroups(  "Post"   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	nomtitles /// 
	order(bfemale crtXbfemale base_pnXbfemale base_distXbfemale bayes_distXbfemale) /// 
	nogaps nonumbers compress /// 
 	 star(* 0.10 ** 0.05 *** 0.01 )  /// 
addnote("SEs are robust")  replace

}


*****************************************************
*************************************************************
** Table 6

clear
clear matrix
use `main_eval'

keep if gknown == 1 

label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$*Attention"
label variable t_calcXbfemale "\$\Delta$*Calculation"

foreach z in male female { 
		
regress post bfemale t_attnXbfemale t_calcXbfemale /// 
t_base t_attn t_calc ///
	if `z' == 1 /// 
	,noconstant vce(robust)  
eststo `z'1

}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

local table_name = "Table6.tex" // "regByDemA1_post_gknown.tex"

esttab  male1 female1  /// 
	 using `out'`table_name' ///
 	, `text1' label  /// 
	title("By demographics: evaluators' posterior beliefs about workers in \textit{Evaluator Study} when gender is known") /// 
	mgroups(  "Degraphics"   , pattern( 1 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Male" "Female"  ) ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace

*****************************************************
**************************************************************
** Table 7

clear
clear matrix
use `top_half'

keep if t_attn == 1  & all == 1 

foreach d in gap_prior gap_over gap_under  gap_bayes gap_post  ///
	prior  bayes post     under over      { 
		
regress  `d'   bfemale   /// 
	,constant vce(robust)  
eststo r`d'1

regress  `d'   bfemale bmale   ///  
	,noconstant vce(robust)  
eststo r`d'2

}

foreach a in 1 2  { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

* using `out'reg`a'_t_attn_all.tex

esttab  rprior`a'  rover`a'  runder`a'   rbayes`a'  rpost`a'    ///
	 using `out'Table7_PanelA_`name`a''.tex   /// 
 	, `text`a'' label  /// 
	title("Evaluators' Beliefs' in the \textit{Evaluator (Attention, Top Half) Study}: \textbf{Panel A}") /// 
	mgroups(  "Predictinos"   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace


if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_attn_all.tex

esttab  rgap_prior`a'  rgap_over`a'  rgap_under`a'  rgap_bayes`a'  rgap_post`a'  /// 
	 using `out'Table7_PanelB_`name`a''.tex   /// 
 	, `text`a'' label  /// 
	title("Evaluators' Beliefs' in the \textit{Evaluator (Attention, Top Half) Study}: \textbf{Panel B}") /// 
	mgroups(  "Predictinos"   , pattern( 1 0 0 0 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Prior"   "Overconf"    "Underconf"  "Bayes Post" "Post" ) ///
	nogaps nonumbers compress /// 
	addnote("SEs are robust")  replace

}


*/
****************************************
****************************************
* Figure 1

clear
clear matrix
use `main_eval'

keep if t_base == 1 & gknown == 1 

**** 
local tgap_prior `"Prior Belief - Truth:" "% chance of poor performance" "before self-eval info is provided"' 
local tgap_post `"Posterior Belief - Truth:" "% chance of poor performance" "before self-eval info is provided"' 

local tprior `"Prior Belief:" "% chance of poor performance" "before self-eval info is provided"'  
local tpost `"Posterior Belief:" "% chance of poor performance" "after self-eval info is provided"' 

foreach d in prior post { 

local nameprior "PanelA"
local namepost "PanelB"

cumul `d' if bfemale == 1 , gen(`d'F)
cumul `d' if bmale == 1 , gen(`d'M)
sort `d'F `d'M

twoway  line `d'M `d' if bmale == 1 /// 
 , fcolor(ltblue ) lcolor(blue ) lwidth(vthick) lpattern(shortdash) /// 
 legend(label(1 "B(Male)")) /// 
 || line `d'F `d' if bfemale == 1 /// 
 , fcolor(none) lcolor(black) lwidth(vthick) lpattern(solid) /// 
 legend(label(2 "B(Female)")) /// 
 xtitle("`t`d''", size(large)) /// 
 ytitle("CDF ", size(large)) /// 
  legend(off) /// 
 legend(cols(2)) legend(order( 2 1 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) 
 
 graph export `out'Figure1_`name`d''.pdf, replace 

 }

*****************************************
***************************************************************
*** FIGURE 2 

clear
clear matrix
use `extended'

keep if t_inc == 1  

collapse (mean) wvm_priorBias  (mean) wvm_priorEqual  (mean) wvm_priorOpp  ///
	(mean) wvm_avgpostBias  (mean) wvm_avgpostEqual  (mean) wvm_avgpostOpp 
	
	
foreach i in wvm_priorBias  wvm_priorEqual  wvm_priorOpp ///
	wvm_avgpostBias  wvm_avgpostEqual  wvm_avgpostOpp{ 
		replace `i' = `i'*100 
	} 

local twvm_prior "% chance of poor performance"
	
	g gainGroup = 1 
	g gainGroup2 = 4 
	g gainGroup3 = 7
	g gainGroup4 = 2 
  g gainGroup5 = 5
	g gainGroup6 = 8
	
	g label = 50 

	
	twoway bar wvm_priorBias  gainGroup, color(eltblue)  lcolor(eltblue) /// 
		|| bar wvm_priorEqual  gainGroup2, color(eltblue)  lcolor(eltblue) /// 
		||  bar wvm_priorOpp  gainGroup3, color(eltblue)  lcolor(eltblue) /// 
		||  bar wvm_avgpostBias  gainGroup4, color(black)  lcolor(black) /// 
		|| bar wvm_avgpostEqual  gainGroup5, color(black)  lcolor(black) /// 
		||  bar wvm_avgpostOpp  gainGroup6, color(black)  lcolor(black) /// 
		ylabel(0 "0" 20 "20" 40 "40" 60 "60" 80 "80" , labsize(medium)) ///		
		xlabel(1.5 "Women worse" 4.5 "No gender diff"  7.5 "Men worse" , labsize(large) noticks) /// 
		xtitle("") ///
		ytitle("Percent", size(large)) ///
		graphregion(color(white)) bgcolor(white) ///
		legend(order(1 4)) legend(position(6)) ///
		legend(margin(none)) legend(size(large))  ///
		legend(label(1 "Prior Belief" ) label(4 "Posterior Belief" )) ///
		xsize(6) ysize(4)

graph export `out'Figure2.pdf, replace /// wvm_prior graph__t_inc
	
****************************************
****************************************
* APPENDIX B
****************************************
****************************************

***********************************
******* FIGURE B1 *****************
***********************************

clear
clear matrix
use `main_eval'  

keep if t_base == 1 & gknown == 1 

*** OTHER 
local tprior "Prior: believed chance of poor performance" 
local tpost "Posterior: believed chance of poor performance" 
local yprior "0(5)30"
local ypost "0(5)40"

foreach d in prior post { 
 
summarize `d' if bmale == 1, detail
local AvgM = round(r(mean),0.01) 
 

* `out'barM_`d'_gknown_t_base.pdf, replace 
 twoway histogram `d' if bmale == 1 /// 
 , fcolor(ltblue ) lcolor(ltblue ) gap(50) width(5) discrete percent /// 
 legend(label(1 "Male Participants")) xlabel(0(10)100) ylabel(`y`d'') /// 
 xtitle("`t`d''", size(medium)) /// 
 ytitle("Percent ", size(medium)) /// 
 legend(cols(2)) legend(order( 2 1 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 subtitle(Avg = `AvgM', size(huge)) /// 
 xsize(4) ysize(4)  
 graph export `out'FigureB1_`d'_Men.pdf, replace 

summarize `d' if bfemale == 1, detail
local AvgF = round(r(mean),0.01) 

* `out'barF_`d'_gknown_t_base.pdf, replace 
 twoway histogram `d' if bfemale == 1 /// 
 , fcolor(black ) lcolor(black ) gap(50) width(5) discrete percent /// 
 legend(label(1 "Female Participants")) xlabel(0(10)100) ylabel(`y`d'') /// 
 xtitle("`t`d''", size(medium)) /// 
 ytitle("Percent ", size(medium)) /// 
 legend(cols(2)) legend(order( 2 1 ) ) /// 
 subtitle(Avg = `AvgF', size(huge)) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) 
 
 graph export `out'FigureB1_`d'_Women.pdf, replace 
 
 
 }
 


***********************************
******* FIGURE B2 *****************
***********************************

clear
clear matrix
use `main_eval'  

keep if t_base == 1 & gknown == 1 

*** OTHER 
local tover `"Chance of being overconfident," "given poor performance"' 
local tunder `"Chance of being underconfident," "given good performance"' 
local yover "0(5)15"
local yunder "0(5)20"

foreach d in over under { 
 
summarize `d' if bmale == 1, detail
local AvgM = round(r(mean),0.01)  

* `out'barM_`d'_gknown_t_base.pdf, replace 
 twoway histogram `d' if bmale == 1 /// 
 , fcolor(ltblue ) lcolor(ltblue ) gap(50) width(5) discrete percent /// 
 legend(label(1 "Male Participants")) xlabel(0(10)100) ylabel(`y`d'') /// 
 xtitle("`t`d''", size(medium)) /// 
 ytitle("Percent ", size(medium)) /// 
 legend(cols(2)) legend(order( 2 1 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 subtitle(Avg = `AvgM', size(huge)) /// 
 xsize(4) ysize(4) saving(gM, replace) 
 
 graph export `out'FigureB2_`d'_Men.pdf, replace 

summarize `d' if bfemale == 1, detail
local AvgF = round(r(mean),0.01) 

* `out'barF_`d'_gknown_t_base.pdf, replace 
 twoway histogram `d' if bfemale == 1 /// 
 , fcolor(black ) lcolor(black ) gap(50) width(5) discrete percent /// 
 legend(label(1 "Female Participants")) xlabel(0(10)100) ylabel(`y`d'') /// 
 xtitle("`t`d''", size(medium)) /// 
 ytitle("Percent ", size(medium)) /// 
 legend(cols(2)) legend(order( 2 1 ) ) /// 
 subtitle(Avg = `AvgF', size(huge)) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) saving(gF, replace)
 
 graph export `out'FigureB2_`d'_Women.pdf, replace 
 
 
 }


*****************************************************
*****************************************************
*** TABLE B1 ****************************************
*****************************************************
*****************************************************

clear 
clear matrix
use `worker_long'

keep if t_inc == 1 & all == 1 

foreach j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 { 

regress pred_ female  /// 
	ncorr* /// 
	if decision == `j' /// 
	,noconstant vce(robust) 
eststo r`j'a

} 

local table_name = "TableB1" //  using `out'`name`z''1_`s'_`t'.tex /// using `out'`name`z''2_`s'_`t'.tex /// using `out'`name`z''3_`s'_`t'.tex ///

esttab r1a r2a r3a r4a r5a r6a r7a /// 
  using `out'`table_name'_A.tex ///
  , b(2) se(2) label /// 
title("Self-Evaluations in the Worker Study: \textbf{Panel A: Self-Evaluations about Absolute Performance (Q\# = 0-3C)}") /// 
 mgroups("Abs" "3+" "5+" "7+" , pattern( 1 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("0" "1B" "1C" "2B" "2C" "3B" "3C" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("Robust SEs") replace
 

esttab r12a r13a ///
 r14a r15a r16a r17a /// 
  using `out'`table_name'_B.tex ///
  , b(2) se(2) label /// 
 title("Self-Evaluations in the Worker Study: \textbf{Panel B: Self-Evaluations (Q\# 4B-6C) about Relative Performance}") /// 
 mgroups( "top half overall" "top half rel to women" "top half rel to men" , pattern( 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "4B" "4C" "5B" "5C" "6B" "6C" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("Robust SEs") replace

esttab r8a r9a r10a r11a /// 
  using `out'`table_name'_C.tex ///
  , b(2) se(2) label /// 
title("Self-Evaluations in the Worker Study: \textbf{Panel C: Self-Evaluations (Q\# 7B-8C) about Subjective Performance}") /// 
 mgroups( "poor performance" "poor math and science skills" , pattern( 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "7B" "7C" "8B" "8C" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("Robust SEs") replace


*****************************************************
*****************************************************
***TABLE B2
*****************************************************
*****************************************************

clear
clear matrix
use `main_eval' 

keep if t_attn == 1 & gknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over { 

regress `d' bfemale  /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale  /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"


* using `out'reg`a'_t_attn_gknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' ///
  using `out'TableB2_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluator’ Beliefs in the \textit{Attention} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_attn_gknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
 using `out'TableB2_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluator' Beliefs in the \textit{Attention} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 



*****************************************************
*****************************************************
***TABLE B3
*****************************************************
*****************************************************

clear
clear matrix
use `main_eval' 

keep if t_calc == 1 & gknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over { 

regress `d' bfemale  /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale  /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

local name1 "Delta"
local name2 "Level"

foreach a in 1 2 { 

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

*  using `out'reg`a'_t_calc_gknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' ///
  using `out'TableB3_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Calculation} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_calc_gknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
  using `out'TableB3_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Calculation} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 

*****************************************************
**************************************************************
*** TABLE B4
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval' 

keep if t_base == 1 & gunknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over { 

regress `d' bfemale  /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale  /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

local name1 "Delta"
local name2 "Level"

foreach a in 1 2 { 


if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"


local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

*  using `out'reg`a'_t_base_gunknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' /// 
  using `out'TableB4_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
 mgroups( "Predictinos" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_base_gunknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
  using `out'TableB4_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 

*****************************************************
**************************************************************
*** TABLE B5
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval' 

keep if t_attn == 1 & gunknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over { 

regress `d' bfemale  /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale  /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

local name1 "Delta"
local name2 "Level"

foreach a in 1 2 { 

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

*  using `out'reg`a'_t_attn_gunknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' /// 
  using `out'TableB5_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Attention, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace


* using `out'regGap`a'_t_attn_gunknown_all.tex ///

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
  using `out'TableB5_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Attention, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 

*****************************************************
**************************************************************
*** TABLE B6
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval' 

keep if t_calc == 1 & gunknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over { 

regress `d' bfemale  /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale  /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

local name1 "Delta"
local name2 "Level"

foreach a in 1 2 { 

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

*  using `out'reg`a'_t_calc_gunknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' /// 
  using `out'TableB6_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Calculation, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_calc_gunknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
  using `out'TableB6_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Calculation, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") ///  
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 

*****************************************************
**************************************************************
*** TABLE B7
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval' 

keep if all == 1 & gunknown == 1 & all == 1 

foreach d in gap_prior gap_over gap_under gap_bayes gap_post ///
 bayes post prior under over  { 

label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"

regress `d' bfemale   t_attnXbfemale t_calcXbfemale ///
	t_base t_attn t_calc /// 
	,noconstant vce(robust) 
eststo r`d'1

}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

* using `out'reg1_all_gunknown_all.tex 

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

esttab rprior1 rover1 runder1 rbayes1 rpost1 ///
using `out'TableB7_PanelA`name`a''.tex ///
  , `text1' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender, Attention, Unknown Gender} and \textit{Calculation, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel A}") ///
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap1_all_gunknown_all.tex 

esttab rgap_prior1 rgap_over1 rgap_under1 rgap_bayes1 rgap_post1 /// 
 using `out'TableB7_PanelB`name`a''.tex ///
  , `text1' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender, Attention, Unknown Gender} and \textit{Calculation, Unknown Gender} treatment of the \textit{Evaluator Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace



****************************************
****************************************
* APPENDIX C
****************************************
****************************************

**************************************************************
**************************************************************
*** FIGURE C1
**************************************************************
**************************************************************

foreach z in prior under over bayes { 

clear
clear matrix
use `main_eval'

keep if t_base == 1 & gknown == 1 

local tprior `"Prior Belief:" "% chance of poor performance"' 
local tover `"Overconfidence Belief:" "% chance of being overconfident," "given poor performance evaluation"' 
local tunder `"Underconfidence Belief:" "% chance of being underconfident," "given good performance evaluation"' 
local tbayes `"Implied Bayesian Posterior Belief:" "% chance of poor performance"' 
local tself_adjust `"I accounted for gender gap" "(1=too little, 5 = too much)"'
local temp_adjust `"Employers account for gender gap" "(1=too little, 3 =too much)"'

collapse (mean) post (sum) all /// 
 , by(bfemale `z')
 
local figure_name = "Figure_C1" //  `out'scatter_t_base_gknown_`z'.pdf 

twoway scatter post `z' [weight=all] /// 
 if bfemale == 1 /// 
 , color(black) msize(vsmall) msymbol(O) /// 
 legend(label(1 "B(Female)")) ///  
 || scatter post `z' [weight=all] /// 
 if bfemale == 0 /// 
 , color(blue) msize(medium) msymbol(X) /// 
 legend(label(2 "B(Male)")) /// 
 || lfit post `z' [weight=all] /// 
 if bfemale == 1 /// 
 ,color(black) lwidth(thick) lpattern(solid) ///
 || lfit post `z' [weight=all] /// 
 if bfemale == 0 /// 
 ,color(blue) lwidth(thick) lpattern(shortdash) ///
 xtitle("`t`z'' ", size(medium)) /// 
 ytitle("Posterior Belief:" "% chance of poor performance") /// 
 ylabel(0(20)100) ///
 legend(off) legend(cols(2)) legend(order(1 2 3 4 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) /// 
 
 graph export `out'`figure_name'_`z'.pdf, replace 

}




**************************************************************
**************************************************************
*** FIGURE C2
**************************************************************
**************************************************************

foreach z in prior under over bayes { 

clear
clear matrix
use `main_eval'

keep if t_attn == 1 & gknown == 1 

local tprior `"Prior Belief:" "% chance of poor performance"' 
local tover `"Overconfidence Belief:" "% chance of being overconfident," "given poor performance evaluation"' 
local tunder `"Underconfidence Belief:" "% chance of being underconfident," "given good performance evaluation"' 
local tbayes `"Implied Bayesian Posterior Belief:" "% chance of poor performance"' 
local tself_adjust `"I accounted for gender gap" "(1=too little, 5 = too much)"'
local temp_adjust `"Employers account for gender gap" "(1=too little, 3 =too much)"'

collapse (mean) post (sum) all /// 
 , by(bfemale `z')
 
local figure_name = "Figure_C2" //  `out'scatter_t_attn_gknown_`z'.pdf 

twoway scatter post `z' [weight=all] /// 
 if bfemale == 1 /// 
 , color(black) msize(vsmall) msymbol(O) /// 
 legend(label(1 "B(Female)")) ///  
 || scatter post `z' [weight=all] /// 
 if bfemale == 0 /// 
 , color(blue) msize(medium) msymbol(X) /// 
 legend(label(2 "B(Male)")) /// 
 || lfit post `z' [weight=all] /// 
 if bfemale == 1 /// 
 ,color(black) lwidth(thick) lpattern(solid) ///
 || lfit post `z' [weight=all] /// 
 if bfemale == 0 /// 
 ,color(blue) lwidth(thick) lpattern(shortdash) ///
 xtitle("`t`z'' ", size(medium)) /// 
 ytitle("Posterior Belief:" "% chance of poor performance") /// 
 ylabel(0(20)100) ///
 legend(off) legend(cols(2)) legend(order(1 2 3 4 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) /// 
 
 graph export `out'`figure_name'_`z'.pdf, replace 

}


*/

**************************************************************
**************************************************************
*** FIGURE C3
**************************************************************
**************************************************************

foreach z in prior under over bayes { 

clear
clear matrix
use `main_eval'

keep if t_calc == 1 & gknown == 1 

local tprior `"Prior Belief:" "% chance of poor performance"' 
local tover `"Overconfidence Belief:" "% chance of being overconfident," "given poor performance evaluation"' 
local tunder `"Underconfidence Belief:" "% chance of being underconfident," "given good performance evaluation"' 
local tbayes `"Implied Bayesian Posterior Belief:" "% chance of poor performance"' 
local tself_adjust `"I accounted for gender gap" "(1=too little, 5 = too much)"'
local temp_adjust `"Employers account for gender gap" "(1=too little, 3 =too much)"'

collapse (mean) post (sum) all /// 
 , by(bfemale `z')
 
local figure_name = "Figure_C3" //  `out'scatter_t_calc_gknown_`z'.pdf 

twoway scatter post `z' [weight=all] /// 
 if bfemale == 1 /// 
 , color(black) msize(vsmall) msymbol(O) /// 
 legend(label(1 "B(Female)")) ///  
 || scatter post `z' [weight=all] /// 
 if bfemale == 0 /// 
 , color(blue) msize(medium) msymbol(X) /// 
 legend(label(2 "B(Male)")) /// 
 || lfit post `z' [weight=all] /// 
 if bfemale == 1 /// 
 ,color(black) lwidth(thick) lpattern(solid) ///
 || lfit post `z' [weight=all] /// 
 if bfemale == 0 /// 
 ,color(blue) lwidth(thick) lpattern(shortdash) ///
 xtitle("`t`z'' ", size(medium)) /// 
 ytitle("Posterior Belief:" "% chance of poor performance") /// 
 ylabel(0(20)100) ///
 legend(off) legend(cols(2)) legend(order(1 2 3 4 ) ) /// 
 graphregion(color(white)) bgcolor(white) ///
 xsize(4) ysize(4) /// 
 
 graph export `out'`figure_name'_`z'.pdf, replace 

}



*****************************************************
**************************************************************
*** TABLE C1
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval'

keep if gknown == 1 

label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"
 
foreach z in women_under women_same ///
women_over womenSTEM_under womenSTEM_same ///
womenSTEM_over  { 
 
regress post bfemale t_attnXbfemale t_calcXbfemale t_attn t_calc /// 
 if `z' == 1 /// 
 ,constant vce(robust) 
eststo `z'1
}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

local table_name = "TableC1.tex" // using `out'regByConf1_post_gknown.tex ///

** 
esttab  women_under1 women_same1 women_over1 ///
 womenSTEM_under1 womenSTEM_same1 womenSTEM_over1 ///
 using `out'`table_name' ///
  , `text1' label /// 
 title("By believed gender differences in confidence: evaluators' posterior beliefs about workers in \textit{Evaluator Study} when gender is known") /// 
 mgroups( "General Confidence Diff" "STEM Confidence Diff" , pattern( 1 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "W under" "No diff" "W over" "W under" "No diff" "W over" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace



*****************************************************
**************************************************************
*** TABLE C2
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval'

keep if gknown == 1 
 
foreach z in self_uadjust self_oadjust self_aadjust { 
 
label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"


regress post bfemale t_attnXbfemale t_calcXbfemale t_attn t_calc /// 
 if `z' == 1 /// 
 ,constant vce(robust) 
eststo `z'1

}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

local table_name = "TableC2.tex" // using `out'regByAdjust1_post_gknown.tex ///

** BY BELIEVED ADJUSTMENT 
esttab   self_aadjust1 self_oadjust1 self_uadjust1 ///
 using `out'`table_name' ///
 , `text1' label /// 
 title("By believed accuracy: evaluators' posterior beliefs about workers in \textit{Evaluator Study} when gender is known") /// 
 mgroups( "I accounted:" , pattern( 1 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "Just right" "Too much" "Too litte" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

*****************************************************
**************************************************************
*** TABLE C3
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval'

keep if gknown == 1 
 
foreach z in emp_aadjust emp_oadjust emp_uadjust { 
 
 
label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"

 
regress post bfemale t_attnXbfemale t_calcXbfemale t_attn t_calc /// 
 if `z' == 1 /// 
 ,constant vce(robust) 
eststo `z'1

}

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "

local table_name = "TableC3.tex" // using `out'regByEmp1_post_gknown.tex ///

** BY EMP BELIEFS 
esttab emp_aadjust1 emp_oadjust1 emp_uadjust1 /// 
 using `out'`table_name' ///
 , `text1' label /// 
 title("By beliefs about employers: evaluators' posterior beliefs about workers in \textit{Evaluator Study} when gender is known") /// 
 mgroups( "Employers account:" , pattern( 1 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "Just right" "Too much" "Too litte" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace


*****************************************************
**************************************************************
*** TABLE C4
*****************************************************
**************************************************************

clear
clear matrix
use `main_eval'

keep if gknown == 1 
 
foreach z in educLow educHigh ///
	incomeLow incomeHigh    /// 
	young old  favor_dem wfavor_rep  { 
  
label variable bfemale "\$\Delta$"
label variable t_attnXbfemale "\$\Delta$ * Attention"
label variable t_calcXbfemale "\$\Delta$ * Calculation"

regress post bfemale t_attnXbfemale t_calcXbfemale t_attn t_calc /// 
 if `z' == 1 /// 
 ,constant  vce(robust) 
eststo `z'

}

local table_name = "TableC4.tex" // using `out'regByDemA1_post_gknown.tex ///

*using `out'regByDemB`a'_`d'_`s'.tex ///

esttab  educLow educHigh ///
	incomeLow incomeHigh    /// 
	young old ///
	 favor_dem wfavor_rep   ///
	   using `out'`table_name' ///
 	, b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)  label  /// 
	title("By more demographics: evaluators' posterior beliefs about workers in \textit{Evaluator Study} when gender is known") /// 
	mgroups(  ""   , pattern( 1 0 0  0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	mtitles ("Low Ed" "High Dd"  "Low I" "High I" "Young" "Old"  "Fav D" "Fav R") ///
	nogaps nonumbers compress /// 
addnote("SEs are robust")  replace




****************************************
****************************************
* APPENDIX D
****************************************
****************************************

**************************************************************
**************************************************************
*** TABLE D1
**************************************************************
**************************************************************

foreach t in 1 2 3 4 5 6 { 

clear
clear matrix
use `alt'


**** LABEL MAIN 
local t1 "3+"
local t2 "5+"
local t3 "7+"
local t4 "poor eval"
local t5 "poor skills-eval"
local t6 "top half"

keep if  decision == `t'

foreach d in prior post under over bayes { 


regress  b_ bfemale bmale  /// 
	if `d' ==1  /// 
	,noconstant vce(cluster subject)  
eststo r`d'0

regress  b_ bfemale  /// 
	if `d' ==1  /// 
	,constant vce(cluster subject)  
eststo r`d'


}

if `t' == 1 {
	local table_panel "C"
	}

if `t' == 2 {
	local table_panel "D" 
	}

if `t' == 3 {
	local table_panel "E" 
	}
if `t' == 4 {
	local table_panel "B" 
	}

if `t' == 5 {
	local table_panel "A" 
	}

if `t' == 6 {
	local table_panel "F" 
	}

local table_name = "tableD1_`table_panel'_Level.tex" // using `out'reg0_all_`t'.tex

label variable bfemale "B(F)"
label variable bmale "B(M)"

local table_title "Evaluators' Beliefs in the \textit{Evaluator (Alternative Questions)} Study"

esttab rprior0 rover0 runder0 rbayes0 rpost0 ///
 using `out'`table_name' ///
  , nostar b(2) not label /// 
 title("`table_title': \textbf{Panel `table_panel'}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

local table_name = "tableD1_`table_panel'_Delta.tex" // using `out'reg_all_`t'.tex 

label variable bfemale "\$\Delta$"

esttab rprior rover runder rbayes rpost ///
   using `out'`table_name' ///
  , b(2) se(2) label /// 
  title("`table_title': \textbf{Panel `table_panel'}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
addnote("SEs are robust") replace

} 


*****************************************************
*****************************************************
*** TABLE D2
*****************************************************
*****************************************************

clear
clear matrix
use `full'

foreach d in prior over under bayes post ///
  gap_prior gap_over gap_under gap_bayes gap_post { 
 
regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

*using `out'reg`a'_all_all.tex ///

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' ///
 using `out'TableD2_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
title("Evaluators' Beliefs' in the \textit{Evaluator (Full Distribution) Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_all_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
 using `out'TableD2_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs' in the \textit{Evaluator (Full Distribution) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace

}

*****************************************************
*****************************************************
*** TABLE D3
*****************************************************
*****************************************************

clear 
clear matrix
use `worker_undergrad'
 
local sall "Among all participants"

foreach t in all gyear23 {

regress pred_ female /// 
 ncorr* /// 
 if decision == 12 & `t' == 1 /// 
 ,noconstant vce(robust) 
eststo r12`t'

regress pred_ female  /// 
 if decision == 12 & `t' == 1 /// 
 ,constant vce(robust) 
eststo r12a`t'

}

local table_name = "Table_D3.tex" //  using `out'regMain12_all.tex ///
esttab r12aall r12all /// 
 r12agyear23 r12gyear23 /// 
  using `out'`table_name' ///
  , b(3) se(3) label /// 
 title("Self-Evaluations in the \textit{Baseline} treatment of the \textit{Worker (Undergraduates) Study}") /// 
 mgroups( "All Workers" "Available Pool of Workers" , pattern( 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "" "" "" "" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("Robust SEs") replace

*****************************************************
*****************************************************
*** TABLE D4
*****************************************************
*****************************************************

clear
clear matrix
use `prof'

keep if t_base == 1 & gknown == 1 

foreach d in prior over under bayes post ///
gap_prior gap_over gap_under gap_bayes gap_post { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale //// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

* using `out'reg`a'_t_base_gknown_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' ///
  using `out'TableD4_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline} Treatment of the \textit{Evaluator (Professional Evaluators) Study}: \textbf{Panel A}") /// 
 mgroups( "Predictinos" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_base_gknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
using `out'TableD4_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
  title("Evaluators' Beliefs in the \textit{Baseline} Treatment of the \textit{Evaluator (Professional Evaluators) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 


*****************************************************
*****************************************************
*** TABLE D5
*****************************************************
***************************************************** 

clear
clear matrix
use `prof'


keep if t_base == 1 & gunknown == 1 

foreach d in prior over under bayes post ///
gap_prior gap_over gap_under gap_bayes gap_post { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale //// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

* using `out'reg`a'_t_base_gunknown_all.tex ///

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

esttab rprior`a' rover`a' runder`a' rbayes`a' rpost`a' ///
 using `out'TableD5_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender} Treatment of the \textit{Evaluator (Professional Evaluators) Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace


if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_base_gunknown_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_post`a' /// 
 using `out'TableD5_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline, Unknown Gender} Treatment of the \textit{Evaluator (Professional Evaluators) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 



*****************************************************
*****************************************************
*** TABLE D6
*****************************************************
*****************************************************

clear
clear matrix
use `extended_qlevel'

 
keep if t_inc == 1 & single == 1  

label variable bfemale "B(F)"
label variable bmale "B(M)"

foreach d in prior over under bayes avgpost ///
 gap_prior gap_over gap_under gap_bayes gap_avgpost { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

* using `out'reg`a'_t_inc_single_all.tex ///

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

esttab rprior`a' rover`a' runder`a' rbayes`a' ravgpost`a' ///
   using `out'TableD6_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline} Treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel A}") ///
 mgroups( "Predictinos" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"
* using `out'regGap`a'_t_inc_single_all.tex ///


esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_avgpost`a' /// 
  using `out'TableD6_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs in the \textit{Baseline} Treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel B}") ///
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 


*****************************************************
*****************************************************
*** TABLE D7
*****************************************************
*****************************************************

clear
clear matrix
use `extended_wbeliefs'

keep if t_inc == 1 & single == 1 

regress post bfemale /// 
 ,constant vce(cluster subject) 
eststo rpost1aall

regress post bfemale /// 
 FEscore* /// 
 ,noconstant vce(cluster subject) 
eststo rpost2aall

local table_name = "Table_D7.tex" //  using `out'regInd_t_inc_single.tex ///

label variable bfemale "\$\Delta$"

esttab  rpost1aall ///
 rpost2aall ///
  using `out'`table_name' ///
  , b(2) se(2) label /// 
 title("Evaluators' Beliefs about Specific Workers in the \textit{Baseline} Treatment of the \textit{Evaluator Study}") ///
 mgroups("No FE" "FE" , pattern( 1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 order(bfemale ) ///
 mtitles ("All" "All" "All" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("SEs clustered at subject level") replace


 
*****************************************************
*****************************************************
*** TABLE D8
*****************************************************
*****************************************************

clear 
clear matrix
use `worker_long'

keep if t_emp == 1
 
foreach t in all middle {

regress pred_ female /// 
 ncorr* /// 
 if decision == 10 & `t' == 1 /// 
 ,constant vce(robust) 
eststo r10`t'

regress pred_ female /// 
 if decision == 10 & `t' == 1 /// 
 ,constant vce(robust) 
eststo r10a`t'

}

local table_name = "Table_D8.tex" //  using `out'regMain10_t_emp.tex ///

esttab r10aall r10all /// 
 r10amiddle r10middle /// 
  using `out'`table_name' ///
  , b(3) se(3) label /// 
 title("Self-Evaluations in the \textit{Strategic Incentives} treatment of the \textit{Worker Study}") /// 
 mgroups( "All" "Available" , pattern( 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ( "No FE" "FE" "No FE" "FE" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("Robust SEs") replace


*****************************************************
*****************************************************
*** TABLE D9
*****************************************************
*****************************************************

clear
clear matrix
use `extended_qlevel'

keep if t_emp == 1 & single == 1 

label variable bfemale "B(F)"
label variable bmale "B(M)"

foreach d in prior over under bayes avgpost ///
 gap_prior gap_over gap_under gap_bayes gap_avgpost { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

local name1 "Delta"
local name2 "Level"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"
* using `out'reg`a'_t_emp_single_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' ravgpost`a' ///
 using `out'TableD9_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs' about Workers in the \textit{Strategic Incentives} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel A}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_emp_single_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_avgpost`a' /// 
 using `out'TableD9_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
 title("Evaluators' Beliefs' about Workers in the \textit{Strategic Incentives} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 

*****************************************************
*****************************************************
*** TABLE D10
*****************************************************
*****************************************************

clear
clear matrix
use `extended_qlevel'

keep if t_inc == 1 & both == 1 

label variable bfemale "B(F)"
label variable bmale "B(M)"

foreach d in prior over under bayes avgpost ///
 gap_prior gap_over gap_under gap_bayes gap_avgpost ///
  { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 


if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"


local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 

* using `out'reg`a'_t_inc_both_all.tex ///

local name1 "Delta"
local name2 "Level"


esttab rprior`a' rover`a' runder`a' rbayes`a' ravgpost`a' ///
   using `out'TableD10_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
title("Evaluators' Beliefs' about Workers in the \textit{Joint Evaluations} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel A}") //// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace


if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_inc_both_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_avgpost`a' /// 
 using `out'TableD10_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
title("Evaluators' Beliefs' about Workers in the \textit{Joint Evaluations} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 


*****************************************************
*****************************************************
*** TABLE D11
*****************************************************
*****************************************************

clear
clear matrix
use `extended_qlevel'

keep if t_emp == 1 & both == 1 

label variable bfemale "B(F)"
label variable bmale "B(M)"

foreach d in gap_prior gap_over gap_under gap_bayes gap_avgpost ///
 bayes avgpost prior under over  { 

regress `d' bfemale /// 
 ,constant vce(robust) 
eststo r`d'1

regress `d' bfemale bmale /// 
 ,noconstant vce(robust) 
eststo r`d'2

}

foreach a in 1 2 { 

local text1 "b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) "
local text2 "nostar b(2) not" 


if "`a'" == "1" {
  label variable bfemale "\$\Delta$"
}

if "`a'" == "2" {
  label variable bfemale "B(F)"
}

label variable bmale "B(M)"

local name1 "Delta"
local name2 "Level"

* using `out'reg`a'_t_emp_both_all.tex ///

esttab rprior`a' rover`a' runder`a' rbayes`a' ravgpost`a' ///
  using `out'TableD11_PanelA_`name`a''.tex ///
  , `text`a'' label /// 
title("Evaluators' Beliefs' about Workers in the \textit{Joint Evaluations, Strategic Incentives} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel A}") /// 
 mgroups( "Predictinos" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
addnote("SEs are robust") replace

local table_name = "Table_D11_PanelB_`a'"

if "`a'" == "1" {
  label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
}

if "`a'" == "2" {
  label variable bfemale "B(F) - Truth(F)"
}

label variable bmale "B(M) - Truth(M)"

* using `out'regGap`a'_t_emp_both_all.tex ///

esttab rgap_prior`a' rgap_over`a' rgap_under`a' rgap_bayes`a' rgap_avgpost`a' /// 
 using `out'TableD11_PanelB_`name`a''.tex ///
  , `text`a'' label /// 
title("Evaluators' Beliefs' about Workers in the \textit{Joint Evaluations, Strategic Incentives} treatment of the \textit{Evaluator (Extended) Study}: \textbf{Panel B}") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf" "Underconf" "Bayes Post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs are robust") replace
} 



*****************************************************
*****************************************************
*** TABLE D12 (Evaluator Additional Demographic Study)
*****************************************************
*****************************************************

foreach y in b_ gap_b_ { 

clear
clear matrix
use `evaluator_demo'

*keep if decision == 1 

foreach t in prior over under bayes post { 

regress `y' bfemale bmale /// 
 if `t' == 1 /// 
 ,noconstant vce(cluster subject) 
eststo r`t'0

regress `y' bfemale /// 
 if `t' == 1 /// 
 ,constant vce(cluster subject) 
eststo r`t'

}


if "`y'" == "b_" {
	local table_name "TableD12_PanelA_Level"
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Additional Demographics) Study}: \textbf{Panel A}"
	label variable bfemale "B(F)"
	label variable bmale "B(M)"
	}
else if "`y'" == "gap_b_" {
	label variable bfemale "B(F) - Truth(F)"
	label variable bmale "B(M) - Truth(M)"
	local table_name "TableD12_PanelB_Level" 
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Additional Demographics) Study}: \textbf{Panel B}"
}

* using `out'reg1a`y'all.tex ///

esttab rprior0 rover0 runder0 rbayes0 rpost0 /// 
  using `out'`table_name'.tex ///
  , not nostar label b(2) /// 
 title("`table_title'") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf." "Undercon." "Bayes post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs clustered at subject level") replace
 

if "`y'" == "b_" {
	local table_name "TableD12_PanelA_Delta"
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Additional Demographics) Study}: \textbf{Panel A}"
	label variable bfemale "\$\Delta$"
	label variable bmale "B(M)"
	}
else if "`y'" == "gap_b_" {
	label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
	local table_name "TableD12_PanelB_Delta" 
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Additional Demographics) Study}: \textbf{Panel B}"
}

*  using `out'reg1`y'all.tex /// 

esttab rprior rover runder rbayes rpost /// 
 using `out'`table_name'.tex ///
 , b(2) se(2) label /// 
 title("`table_title'") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf." "Undercon." "Bayes post" "Post" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("SEs clustered at subject level") replace

}



*****************************************************
*****************************************************
*** TABLE D13 (Evaluator Known Performance)
*****************************************************
*****************************************************

foreach y in b_ gap_b_ { 

clear
clear matrix
use `evaluator_known'

*keep if decision == 3 

foreach t in prior over under bayes post { 

regress `y' bfemale bmale /// 
 if `t' == 1 /// 
 ,noconstant vce(cluster subject) 
eststo r`t'0

regress `y' bfemale /// 
 if `t' == 1 /// 
 ,constant vce(cluster subject) 
eststo r`t'
}

if "`y'" == "b_" {
	local table_name "TableD13_PanelA_Level.tex"
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Known Performance) Study}: \textbf{Panel A}"
	label variable bfemale "B(F)"
	label variable bmale "B(M)"
	}
else if "`y'" == "gap_b_" {
	label variable bfemale "B(F) - Truth(F)"
	label variable bmale "B(M) - Truth(M)"
	local table_name "TableD13_PanelB_Level.tex" 
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Known Performance) Study}: \textbf{Panel B}"
}



*  using `out'reg3a`y'all.tex ///

esttab rprior0 rover0 runder0 rbayes0 rpost0 /// 
  using `out'`table_name' ///
  , not nostar label b(2) /// 
 title("`table_title'") /// 
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf." "Undercon." "Bayes post" "Post" ) ///
 nogaps nonumbers compress /// 
 addnote("SEs clustered at subject level") replace
 
if "`y'" == "b_" {
	local table_name "TableD13_PanelA_Delta.tex"
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Known Performance) Study}: \textbf{Panel A}"

	label variable bfemale "\$\Delta$"
	label variable bmale "B(M)"
	}
else if "`y'" == "gap_b_" {
	label variable bfemale "\$\Delta$ - Truth(\$\Delta$)"
	local table_title "Evaluators' Beliefs' in the \textit{Evaluator (Known Performance) Study}: \textbf{Panel B}"
	local table_name "TableD13_PanelB_Delta.tex" 
}



* using `out'reg3`y'all.tex /// 
 
esttab rprior rover runder rbayes rpost /// 
 using `out'`table_name' ///
 , b(2) se(2) label /// 
 title("`table_title'") ///  
 mgroups( "" , pattern( 1 0 0 0 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) /// 
 mtitles ("Prior" "Overconf." "Undercon." "Bayes post" "Post" ) ///
 nogaps nonumbers compress /// 
   star(* 0.10 ** 0.05 *** 0.01 ) /// 
 addnote("SEs clustered at subject level") replace

} 


*****************************************************
*****************************************************
*** FIGURE D1
*****************************************************
*****************************************************
*****************************************************
foreach s in t_inc    { 
foreach t in  single   { 

clear
clear matrix
use `extended_wbeliefs'

keep if `s' ==1 & `t' ==1 


collapse (mean) post  (sum) all /// 
	, by(bfemale se)
	
sort se 	
	
twoway scatter post se  [weight=all]  /// 
	if bfemale==1 /// 
	, color(black)  msize(vsmall) msymbol(O) /// 
	legend(label(1 "B(Female)")) /// 	
	|| scatter post se   [weight=all]  /// 
	if bfemale==0 /// 
	, color(blue)  msize(medium)  msymbol(X) /// 
	legend(label(2 "B(Male)")) ///  
	|| lfit post se  [weight=all]  /// 
	if bfemale==1 /// 
	,color(black)  lwidth(thick) lpattern(solid)  ///
	|| lfit post se  [weight=all]  /// 
	if bfemale==0 /// 
	,color(blue)  lwidth(thick) lpattern(dash)  ///
	xtitle("Worker Self-Evaluations:" "% chance that own performance is poor", size(medium))   /// 
	ytitle("Average Predictor Belief:" "% chance that worker performance is poor") /// 
	legend(cols(2)) legend(order(1 2 3 4) )  /// 
	graphregion(color(white)) bgcolor(white) ///
	xsize(4) ysize(4) legend(position(bottom)) /// 
	
 graph export `out'FigureD1.pdf, replace 


 
}
}

*/ 

*****************************************************
*****************************************************
*** FIGURE D2
*****************************************************
*****************************************************

clear
clear matrix
use `extended'

keep if t_emp == 1 

collapse (mean) wvm_priorBias (mean) wvm_priorEqual (mean) wvm_priorOpp ///
 (mean) wvm_avgpostBias (mean) wvm_avgpostEqual (mean) wvm_avgpostOpp 
 
 
foreach i in wvm_priorBias wvm_priorEqual wvm_priorOpp ///
 wvm_avgpostBias wvm_avgpostEqual wvm_avgpostOpp{ 
 replace `i' = `i'*100 
 } 

local twvm_prior "% chance of poor performance"
 
 g gainGroup = 1 
 g gainGroup2 = 4 
 g gainGroup3 = 7
 g gainGroup4 = 2 
 g gainGroup5 = 5
 g gainGroup6 = 8
 
 g label = 50 

 twoway bar wvm_priorBias gainGroup, color(eltblue) lcolor(eltblue) /// 
 || bar wvm_priorEqual gainGroup2, color(eltblue) lcolor(eltblue) /// 
 || bar wvm_priorOpp gainGroup3, color(eltblue) lcolor(eltblue) /// 
 || bar wvm_avgpostBias gainGroup4, color(black) lcolor(black) /// 
 || bar wvm_avgpostEqual gainGroup5, color(black) lcolor(black) /// 
 || bar wvm_avgpostOpp gainGroup6, color(black) lcolor(black) /// 
 ylabel(0 "0" 20 "20" 40 "40" 60 "60" 80 "80" , labsize(medium)) /// 
 xlabel(1.5 "Women worse" 4.5 "No gender diff" 7.5 "Men worse" , labsize(large) noticks) /// 
 xtitle("") ///
 ytitle("Percent", size(large)) ///
 graphregion(color(white)) bgcolor(white) ///
 legend(order(1 4)) legend(position(6)) ///
 legend(margin(none)) legend(size(large)) ///
 legend(label(1 "Prior Belief" ) label(4 "Posterior Belief" )) ///

 
 graph export `out'FigureD2.pdf, replace

*/
 *********************************************************
**************************************************************
***  Calculating Truth Values for Workers in Baseline Treatment  when z=t_inc and in Strategic Incentives Treatment when z=t_emp  


foreach s in  middle all   ncorr5 typical       { 
foreach z in   t_inc t_emp   {

if ("`z'" == "t_emp" & "`s'" != "middle") {
        continue
}

clear
clear matrix
use `worker'

sum tind_12 

keep if `z' ==1  & `s' ==1 

**** TOP HALF
foreach g in male female { 
	
*Underconfident
g under12`g' = under_12 if `g' ==1 
g tgood12`g' = tind_12 if `g' ==1 

 sum under12`g' 

egen num_tunder12`g' = sum(under12`g') 
egen den_tunder12`g' = sum(tgood12`g') 

g t`g'_under12 =   num_tunder12`g'/ den_tunder12`g'
label variable  t`g'_under12 "Truth(`g', chance underconfident if top half )"

*Overconfident
g over12`g' = over_12 if `g' ==1 
g tbad12`g' = 1-tind_12 if `g' ==1 

egen num_tover12`g' = sum(over12`g') 
egen den_tover12`g' = sum(tbad12`g') 

g t`g'_over12 =   num_tover12`g'/ den_tover12`g'
label variable t`g'_over12 "Truth(`g', chance overconfident if top half)"
}

*Truth Gaps 
foreach a in  12  {
g tgap_over`a' = tfemale_over`a' - tmale_over`a'
label variable tgap_over`a' "Truth(F-M, chance overconfident if not top half)"

g tgap_under`a' = tfemale_under`a' - tmale_under`a'
label variable tgap_under`a' "Truth(F-M, chance underconfident if top half)"

sum   tind_`a' if female ==1 
g tfemale_`a' = `r(mean)'

sum   tind_`a' if male ==1 
g tmale_`a' = `r(mean)'

g tgap_`a' = tfemale_`a'  -   tmale_`a'
}

label variable tfemale_12 "Truth(F,chance of top half)"
label variable tmale_12 "Truth(M,chance of top half)"
label variable tgap_12 "Truth(F-M,chance of top half)"

**** POOR PERFROMANCE 
foreach g in male female { 
*Underconfident 	
g under10`g' = under_10 if `g' ==1 
g tgood10`g' = 1-tind_10 if `g' ==1 

egen num_tunder10`g' = sum(under10`g') 
egen den_tunder10`g' = sum(tgood10`g') 

g t`g'_under10 =   num_tunder10`g'/ den_tunder10`g'
label variable t`g'_under10 "Truth(`g', chance underconfident if good perfromance)"

*Overconfident
g over10`g' = over_10 if `g' ==1 
g tbad10`g' = tind_10 if `g' ==1 

egen num_tover10`g' = sum(over10`g') 
egen den_tover10`g' = sum(tbad10`g') 

g t`g'_over10 =   num_tover10`g'/ den_tover10`g'
label variable t`g'_over10 "Truth(`g', chance overconfident if poor performance)"
}

*Truth Gaps 
foreach a in  10  {
g tgap_over`a' = tfemale_over`a' - tmale_over`a'
label variable tgap_over`a' "Truth(F-M, chance overconfident if poor performance)"

g tgap_under`a' = tfemale_under`a' - tmale_under`a'
label variable tgap_under`a' "Truth(F-M, chance underconfident if good performance)"

sum   tind_`a' if female ==1 
g tfemale_`a' = `r(mean)'

sum   tind_`a' if male ==1 
g tmale_`a' = `r(mean)'

g tgap_`a' = tfemale_`a'  -   tmale_`a'
}

label variable tfemale_10 "Truth(F,chance of poor performance)"
label variable tmale_10 "Truth(M,chance of poor performance)"
label variable tgap_10 "Truth(F-M,chance of poor performance)"

*************** GETTING LOOP READY 
local st_inc  "in the Baseline Treatments" 
local st_emp   "in the Strategic Icentives Treatments" 

local xall "Among all workers"
local xncorr5 "Among workers who got 5 right"
local xmiddle "Among workers with performances in the middle"
local xtypical "Among workers with demographics that match Evaluator (Additional Demographic) Study"

foreach i in  all    { 

estpost summarize tfemale_10 tmale_10 tgap_10 /// 
	tfemale_over10 tmale_over10 tgap_over10 ///
	tfemale_under10 tmale_under10  tgap_under10  ///
	if `i' ==1 ///
	, detail 
eststo `i'0

estpost summarize tfemale_12 tmale_12 tgap_12 /// 
	tfemale_over12 tmale_over12 tgap_over12 ///
	tfemale_under12 tmale_under12  tgap_under12  ///
	if `i' ==1 ///
	, detail 
eststo `i'tophalf

}

esttab all0     /// 
	 	using `out'desTruth_`z'_`s'.tex /// 
	,label  cells("mean(fmt(4))") ///
mgroups(    "All"    , pattern(1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	title("`x`s'', `s`z'': Truth Values (Need to be multipled by 100)")  replace 


if ("`z'"!="t_inc" | "`s'"!="middle") {
        continue
      }

esttab alltophalf     /// 
	 	using `out'desTruthTopHalf_`z'_`s'.tex /// 
	,label  cells("mean(fmt(4))") ///
mgroups(    "All"    , pattern(1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	title("`x`s'', `s`z'': Truth Values (Need to be multipled by 100)")  replace 
		
		
}	
}

*/



************************************************************
**************************************************************
*** Calculating Truth Values for workers in Worker (Undergraduate) Study 

clear
clear matrix
use `worker_undergrad'

keep if gyear23==1 

**** POOR : CALCULATING THE TRUTH FOR OVER/UNDER CONFIDENT 
foreach g in male female { 
*Underconfident
g under12`g' = under_12 if `g' ==1 
g tgood12`g' = 1-tind_12 if `g' ==1 

egen num_tunder12`g' = sum(under12`g') 
egen den_tunder12`g' = sum(tgood12`g') 

g t`g'_under12 =   num_tunder12`g'/ den_tunder12`g'
label variable  t`g'_under12 "Truth(`g', chance underconfident if good performance)"


*Overconfident
g over12`g' = over_12 if `g' ==1 
g tbad12`g' = tind_12 if `g' ==1 

egen num_tover12`g' = sum(over12`g') 
egen den_tover12`g' = sum(tbad12`g') 

g t`g'_over12 =   num_tover12`g'/ den_tover12`g'
label variable t`g'_over12 "Truth(`g', chance overconfident if poor performance)"
}


foreach a in 12 {
g tgap_over`a' = tfemale_over`a' - tmale_over`a'
label variable tgap_over`a' "Truth(F-M, chance overconfident if poor performance)"

g tgap_under`a' = tfemale_under`a' - tmale_under`a'
label variable tgap_under`a' "Truth(F-M, chance underconfident if good performance)"

sum   tind_`a' if female ==1 
g tfemale_`a' = `r(mean)'

sum   tind_`a' if male ==1 
g tmale_`a' = `r(mean)'

g tgap_`a' = tfemale_`a'  -   tmale_`a'
}

label variable tfemale_12 "Truth(F,chance of poor performance)"
label variable tmale_12 "Truth(M,chance of poor performance)"
label variable tgap_12 "Truth(F-M,chance of poor performance)"


estpost summarize tfemale_12 tmale_12 tgap_12 /// 
	tfemale_over12 tmale_over12 tgap_over12 ///
	tfemale_under12 tmale_under12  tgap_under12  ///
	, detail 
eststo all 


esttab all     /// 
	 	using `out'desTruth_WorkerUndergrad.tex /// 
	,label  cells("mean(fmt(4))") ///
mgroups(    "All"    , pattern(1 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  /// 
	title("Truth Values for workers in Worker (Undergraduate) Study (Need to be multipled by 100) ")  replace 
	

	

*/	

















