cls
**=====================================================
** Program Name:  Spatial regression for cross-sectional data
** Author: Carlos Mendez
** Date: 2022-02-20
** --------------------------------------------------------------------------------------------
** Inputs/Ouputs:
* Data files used:

* Data files created as intermediate product:

* Data files created as final product:

**=====================================================

** 0. Change working directory
cd "/Users/carlos/Github/QuaRCS-lab/tutorial-spatial-cross-section-columbus-crime"

** 1. Setup
clear all
macro drop _all
capture log close
set more off
version 17

** 2. Open log file
log using "DO_spatial_cross_sectionsV3.txt", text replace

** 3. Install modules
*ssc install estout, replace all
*ssc install outreg2, replace all
*ssc install reghdfe, replace all * INFO: http://scorreia.com/software/reghdfe/
*net install gr0009_1, from (http://www.stata-journal.com/software/sj10-1) replace all
*net install tsg_schemes, from("https://raw.githubusercontent.com/asjadnaqvi/Stata-schemes/main/schemes/") replace all
*set scheme white_tableau, permanently
*set scheme gg_tableau, permanently

*ssc install spmap
*ssc install shp2dta
*net install sg162, from(http://www.stata.com/stb/stb60)
*net install st0292, from(http://www.stata-journal.com/software/sj13-2)
*net install spwmatrix, from(http://fmwww.bc.edu/RePEc/bocode/s)
*net install splagvar, from(http://fmwww.bc.edu/RePEc/bocode/s)
*ssc install xsmle.pkg
*ssc install xtcsd
*ssc install geo2xy    
*ssc install palettes      
*ssc install colrspace

** 4a. Import W matrix from .dta file (create_W_using_PySAL)
import delimited "https://gist.github.com/cmg777/1021c13f244a2ad2cb0f0a59f19bcd5d/raw/c28927b2c8d68a91f35afc530d829ad11f3fab82/df_ids_AND_WqueenMatrix.csv", case(preserve) clear
*import delimited "df_ids_AND_WqueenMatrix", case(preserve) clear
drop v1

spset polyID
spmatrix fromdata WqueenSt = v*, normalize(row) replace
spmatrix summarize WqueenSt

** Import dataset with variables (Source: https://geodacenter.github.io/data-and-lab/columbus/)
use "https://github.com/quarcs-lab/data-open/raw/master/Columbus/columbus/columbusDbase.dta", clear
spset id

* Add labels
label var CRIME "Crime"
label var INC   "Income"
label var HOVAL "House value"

** OLS model
reg CRIME INC HOVAL
eststo OLS


** Test for spatial dependence in the residuals
qui reg CRIME INC HOVAL
estat moran, errorlag(WqueenSt)

** Taxanomy of spatial models
collect clear

* SAR/SLM model
qui spregress CRIME INC HOVAL, ml dvarlag(WqueenSt)
eststo SAR
collect: qui estat impact

* SEM model
qui spregress CRIME INC HOVAL, ml errorlag(WqueenSt)
eststo SEM
collect: qui estat impact

* SLX model
qui spregress CRIME INC HOVAL, ml ivarlag(WqueenSt: INC HOVAL)
eststo SLX
collect: qui estat impact

* SDM model 
qui spregress CRIME INC HOVAL, ml dvarlag(WqueenSt) ivarlag(WqueenSt: INC HOVAL)
eststo SDM
collect: qui estat impact

* SDEM model
qui spregress CRIME INC HOVAL, ml ivarlag(WqueenSt: INC HOVAL) errorlag(WqueenSt)
eststo SDEM
collect: qui estat impact

* SARAR/SAC model
qui spregress CRIME INC HOVAL, ml dvarlag(WqueenSt) errorlag(WqueenSt)
eststo SARAR
collect: qui estat impact

* GNS model
qui spregress CRIME INC HOVAL, ml dvarlag(WqueenSt) ivarlag(WqueenSt: INC HOVAL) errorlag(WqueenSt)
eststo GNS
collect: qui estat impact

* Comparative results
esttab OLS SAR SEM SLX SDM SDEM SARAR GNS, label b(%7.2f)  star(* 0.10 ** 0.05 *** 0.01) stats(ll aic)  mtitle("OLS" "SAR" "SEM" "SLX" "SDM" "SDEM" "SARAR" "GNS")
*eststo clear

** Direct and indirect effects

collect label list cmdset, all
collect style autolevels result b_direct b_indirect  
collect label levels cmdset  1 "SAR" 2 "SEM" 3 "SLX" 4 "SDM" 5 "SDEM" 6 "SARAR" 7 "GNS"
collect style cell, nformat(%7.2f)
collect layout (colname#result) (cmdset) 


** Model selection

* LR test:  SDM becomes SAR? (If p < 10%, No)
lrtest SDM SAR

* LR test: SDM becomes SEM? (If p < 10%, No)
lrtest SDM SEM

* LR test: SDM becomes SLX? (If p < 10%, No)
lrtest SDM SLX

* Wald test: SDM becomes SAR?  (If p < 10%, No)
test ([WqueenSt]INC = 0) ([WqueenSt]HOVAL = 0)

* Wald test: SDM becomes SEM?  (If p < 10%, No)
testnl ([WqueenSt]INC = -[WqueenSt]CRIME*[CRIME]INC) ([WqueenSt]HOVAL = -[WqueenSt]CRIME*[CRIME]HOVAL)

* Wald test: SDM becomes SLX?  (If p < 10%, No)
test ([WqueenSt]CRIME = 0)

* LM tests (W created using spatwmat)
spatwmat using "WqueenBin.dta", name(WqueenSt_from_spatwmat) eigenval(eWqueenSt_from_spatwmat) standardize
qui reg CRIME INC HOVAL
spatdiag, weights(WqueenSt_from_spatwmat)

** 99. Close log file
log close

**====================END==============================
 