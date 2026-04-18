********************************************************************************
* meta_analysis.do
* Paper:   Exley & Nielsen (2024), AER 114(3): 851-885

* HOW TO RUN:
*   1. Set the cd path below to your local replication folder
*   2. Ensure Data/main_eval.dta exists
*   3. Ensure Output/ subfolder exists
*   4. Run: do meta_analysis.do
*
* OUTPUTS:
*   Data/meta_dataset.dta   — meta-analysis dataset (15 subgroups)
*   Output/forest_plot.png  — Figure 1 in the paper
********************************************************************************

clear all
set more off

* ← CHANGE THIS PATH TO YOUR LOCAL FOLDER
cd "/Users/gracehou/Desktop/JunxiaHou-ECN726-ExleyNielsen_Replication"

use "Data/main_eval.dta", clear

* Keep only the Gender-Known treatments (Baseline, Attention, Calculation)
keep if gknown == 1
count

* Create high_crt variable
gen high_crt = (crt >= 2) if crt != .

* REPLICATION CHECK — must get bfemale = 10.49
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale, robust

* SUBGROUP REGRESSIONS
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if female == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if male == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if young == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if old == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if high_crt == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if high_crt == 0, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if base_pn == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if base_pn == 0, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if educLow == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if educHigh == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if incomeLow == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if incomeHigh == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if favor_dem == 1, robust
reg post bfemale t_attn t_calc t_attnXbfemale t_calcXbfemale if wfavor_rep == 1, robust


* ============================================================
* BUILD META-DATASET
* ============================================================

clear

input str25 subgroup float delta_hat float se_hat float n_obs float d_female float d_old float d_low_crt float d_base_neglect float d_low_educ float d_low_income float d_republican

"Full_Sample"        10.49  1.78  1210   0  0  0  0  0  0  0
"Female_Evaluators"  11.56  2.27   669   1  0  0  0  0  0  0
"Male_Evaluators"     9.31  3.02   507   0  0  0  0  0  0  0
"Young_Evaluators"    9.19  2.32   691   0  0  0  0  0  0  0
"Old_Evaluators"     12.04  2.74   519   0  1  0  0  0  0  0
"High_CRT"           10.10  2.36   662   0  0  0  0  0  0  0
"Low_CRT"            10.82  2.71   548   0  0  1  0  0  0  0
"BRN_Yes"            12.66  3.19   358   0  0  0  1  0  0  0
"BRN_No"              9.51  2.14   852   0  0  0  0  0  0  0
"Low_Education"      11.20  2.61   572   0  0  0  0  1  0  0
"High_Education"      9.90  2.45   638   0  0  0  0  0  0  0
"Low_Income"         11.33  3.00   531   0  0  0  0  0  1  0
"High_Income"         9.94  2.20   679   0  0  0  0  0  0  0
"Democrat"            9.78  2.15   826   0  0  0  0  0  0  0
"Republican"         11.81  3.17   384   0  0  0  0  0  0  1

end

* Compute inverse-variance weights
gen weight = 1 / (se_hat^2)

* Save
save "Data/meta_dataset.dta", replace

* Verify
list subgroup delta_hat se_hat n_obs



* ============================================================
* META-REGRESSION
* ============================================================

use "Data/meta_dataset.dta", clear

* Weighted meta-regression (weight = 1/SE^2)
* Each indicator = 1 for the "lower/different" group, 0 for reference
* Reference group = Male, Young, High CRT, No BRN, High Educ, High Income, Democrat
reg delta_hat d_female d_old d_low_crt d_base_neglect d_low_educ d_low_income d_republican [aweight=weight]



* ============================================================
* FOREST PLOT
* ============================================================

use "Data/meta_dataset.dta", clear

gen y_pos = .
replace y_pos = 15 if subgroup == "Male_Evaluators"
replace y_pos = 14 if subgroup == "Female_Evaluators"
replace y_pos = 12 if subgroup == "Young_Evaluators"
replace y_pos = 11 if subgroup == "Old_Evaluators"
replace y_pos = 9  if subgroup == "High_CRT"
replace y_pos = 8  if subgroup == "Low_CRT"
replace y_pos = 6  if subgroup == "BRN_No"
replace y_pos = 5  if subgroup == "BRN_Yes"
replace y_pos = 3  if subgroup == "High_Education"
replace y_pos = 2  if subgroup == "Low_Education"
replace y_pos = 0  if subgroup == "High_Income"
replace y_pos = -1 if subgroup == "Low_Income"
replace y_pos = -3 if subgroup == "Democrat"
replace y_pos = -4 if subgroup == "Republican"

drop if subgroup == "Full_Sample"

gen ci_lo = delta_hat - 1.96 * se_hat
gen ci_hi = delta_hat + 1.96 * se_hat

twoway (rcap ci_lo ci_hi y_pos, horizontal lcolor(gs8) lwidth(thin)) (scatter y_pos delta_hat, msymbol(square) mcolor(navy) msize(medium)), xline(1.74, lcolor(red) lpattern(dash) lwidth(medium)) ylabel(15 "Male" 14 "Female" 12 "Young" 11 "Old" 9 "High CRT" 8 "Low CRT" 6 "No BRN" 5 "BRN" 3 "High Educ" 2 "Low Educ" 0 "High Income" -1 "Low Income" -3 "Democrat" -4 "Republican", angle(0) labsize(small) nogrid) xlabel(0(2)22, labsize(small)) xtitle("Expected Performance Gap (pp)", size(small)) ytitle("") title("Internal Meta-Analysis: Expected Performance Gap by Subgroup", size(medsmall)) note("Red dashed line = true performance gap (1.74 pp). Squares = point estimates. Lines = 95% CI.", size(vsmall)) legend(off) graphregion(color(white)) ysize(6) xsize(8)

graph export "Output/forest_plot.png", replace width(1200)
