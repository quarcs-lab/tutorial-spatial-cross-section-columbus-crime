** Setup
cls
clear all
macro drop _all
capture log close

set more off
version 15

** Change working directory
cd "/Users/carlos/Github/QuaRCS-lab/tutorial-spatial-cross-section-columbus-crime/RegressionAnalysis"

log using "SPregressions.txt", text replace
**=====================================================
** Program Name: Spatial cross-sectional regressions using the Columbus data 
** Author: Carlos Mendez
** Date: 03-Aug-2022
** --------------------------------------------------------------------------------------------
** Inputs/Ouputs:
* Data files used: W_bin.dta , data.dta

* Data files created as intermediate product: W_st.dta

* Data files created as final product: None

**=====================================================

** Install additional modules
*ssc install spmap
*ssc install shp2dta
*net install sg162, from(http://www.stata.com/stb/stb60)
*net install st0292, from(http://www.stata-journal.com/software/sj13-2)
*net install spwmatrix, from(http://fmwww.bc.edu/RePEc/bocode/s)
*net install splagvar, from(http://fmwww.bc.edu/RePEc/bocode/s)
*ssc install xsmle.pkg
*ssc install xtcsd
*ssc install geo2xy    

**=====================================================
******** Construct W matrix in different formats 
**=====================================================

** Import W from .gal file and row-stadandardize it (not recomendable?)
*spwmatrix import using "Wqueen_fromGeoda.gal", wname(W_st) rowstand  xport(W_st, txt) replace

** Load binary queen contiguity weights matrix
use W_bin.dta, clear

** Create row-standardized W using spmatrix to be used for regressions
spset POLY_ID
spmatrix fromdata  W_st = _0-_48, normalize(row) replace
spmatrix summarize W_st

* Create row-standardized W using spmat to be used for regressions
drop POLY_ID  _ID
spmat dta W_st _0-_48, norm(row)
spmat summarize W_st, links detail
save  W_st.dta, replace

* Create row-standardized W using spwmatrix to be used for LM test
spwmatrix import using "W_st.dta", wname(Wxt_st) dta conn


**=====================================================
******** Load the dataset and prepare for regressions
**=====================================================
use data.dta, clear

spset POLY_ID

label var CRIME "Crime"
label var INC   "Income"
label var HOVAL "House value"


**=====================================================
******** Construct spatial lags and Moran's I regressions
**=====================================================

spgenerate W_CRIME = W_st*CRIME
spgenerate W_INC   = W_st*INC
spgenerate W_HOVAL = W_st*HOVAL

label var W_CRIME "SP lag of Crime"
label var W_INC   "SP lag of Income"
label var W_HOVAL "SP lag of House value"

summarize CRIME W_CRIME INC W_INC HOVAL W_HOVAL

eststo clear
eststo: qui reg W_CRIME CRIME
eststo: qui reg W_INC   INC
eststo: qui reg W_HOVAL HOVAL
esttab, se b(%7.2f) star(* 0.10 ** 0.05 *** 0.01)  stats(r2 aic) mtitles("W_CRIME" "W_INC" "W_HOVAL")
eststo clear


**=====================================================
******** OLS with spatial diagnostics
**=====================================================

reg CRIME INC HOVAL
estat moran, errorlag(W_st)

spatwmat using "W_st.dta", name(W_st4LM) eigenval(W_st4LMeigen) 
qui reg CRIME INC HOVAL
spatdiag, weights(W_st4LM)

**=====================================================
******** SPATIAL models with marginal effects
**=====================================================

**=====================================================**===============**===============
**>>>>>>> SAR
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml dvarlag(W_st)
estat impact

**=====================================================**===============**===============
**>>>>>>> SEM
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml errorlag(W_st)
estat impact

**=====================================================**===============**===============
**>>>>>>> SLX
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL)
estat impact

**=====================================================**===============**===============
**>>>>>>> SDEM
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL) errorlag(W_st)
estat impact

**=====================================================**===============**===============
**>>>>>>> SDM
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
estat impact

**=====================================================**===============**===============
**>>>>>>> SAC
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml dvarlag(W_st) errorlag(W_st)
estat impact

**=====================================================**===============**===============
**>>>>>>> GNS
**=====================================================**===============**===============
spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL) errorlag(W_st)
estat impact

**=====================================================
******** Comparative table of point estimates
**=====================================================
eststo clear

eststo OLS:  qui reg CRIME INC HOVAL
eststo SAR:  qui spregress CRIME INC HOVAL, ml dvarlag(W_st)
eststo SEM:  qui spregress CRIME INC HOVAL, ml errorlag(W_st)
eststo SLX:  qui spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL)
eststo SDEM: qui spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL) errorlag(W_st)
eststo SDM:  qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
eststo SAC:  qui spregress CRIME INC HOVAL, ml dvarlag(W_st) errorlag(W_st)
eststo GNS:  qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL) errorlag(W_st)

esttab, se b(%7.2f) star(* 0.10 ** 0.05 *** 0.01)  stats(ll aic) mtitles("OLS" "SAR" "SEM" "SLX" "SDEM" "SDM" "SAC" "GNS")
eststo clear

**=====================================================
******** Comparative table of marginal effects
**=====================================================
collect clear

quietly spregress CRIME INC HOVAL, ml dvarlag(W_st)
collect: quietly estat impact

quietly spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL)
collect: quietly estat impact

quietly spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
collect: quietly estat impact

quietly spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL) errorlag(W_st)
collect: quietly estat impact

quietly spregress CRIME INC HOVAL, ml dvarlag(W_st) errorlag(W_st)
collect: quietly estat impact

quietly spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL) errorlag(W_st)
collect: quietly estat impact

collect label list cmdset, all

collect style autolevels result b_direct b_indirect  
collect label levels cmdset 1 "SAR" 2 "SLX" 3 "SDM" 4 "SDEM" 5 "SAC" 6 "GNS"
collect style cell, nformat(%7.2f)
collect layout (colname#result) (cmdset) 

**=====================================================
******** Evaluation of the SDM model 
**=====================================================

qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)

* Wald test: Reduce SDM to SAR? (NO if p < 0.05)
test ([W_st]INC = 0) ([W_st]HOVAL = 0)

* Wald test: Reduce SDM to SLX? (NO if p < 0.05)
test ([W_st]CRIME = 0)

* Wald test: Reduce SDM to SEM? (NO if p < 0.05)
testnl ([W_st]INC = -[W_st]CRIME*[CRIME]INC) ([W_st]HOVAL = -[W_st]CRIME*[CRIME]HOVAL)

* LR test Reduce SDM to SAR? (NO if p < 0.05)
eststo clear
eststo SDM: qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
eststo SAR: qui spregress CRIME INC HOVAL, ml dvarlag(W_st)
lrtest SDM SAR


* LR test Reduce SDM to SLX? (NO if p < 0.05)
eststo clear
eststo SDM: qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
eststo SLX: qui spregress CRIME INC HOVAL, ml ivarlag(W_st: INC HOVAL)
lrtest SDM SLX

* LR test Reduce SDM to SEM? (NO if p < 0.05)
eststo clear
eststo SDM: qui spregress CRIME INC HOVAL, ml dvarlag(W_st) ivarlag(W_st: INC HOVAL)
eststo SEM: qui spregress CRIME INC HOVAL, ml errorlag(W_st)
lrtest SDM SEM

**====================END==============================
** Close log file
log close