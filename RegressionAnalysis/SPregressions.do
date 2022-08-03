** Setup
cls
clear all
macro drop _all
capture log close

set more off
version 15

** Change working directory
cd "/Users/carlos/Github/QuaRCS-lab/tutorial-spatial-cross-section-columbus-crime/simple"

log using "SPregressions.txt", text replace
**=====================================================
** Program Name: Spatial cross-sectional regressions using the Columbus data 
** Author: Carlos Mendez
** Date: 03-Aug-2022
** --------------------------------------------------------------------------------------------
** Inputs/Ouputs:
* Data files used:

* Data files created as intermediate product:

* Data files created as final product:

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



** Import W from .gal file and row-stadandardize it

spwmatrix import using "Wqueen_fromGeoda.gal", wname(W_st) rowstand  xport(W_st, txt) replace

insheet using "W_st.txt", delim(" ") clear
drop in 1
rename v1 POLY_ID
save "W_st.dta", replace
*spmatrix  import W_st using "W_st.txt", replace


spmatrix  dir

* Alternative: Import W import from .dta file
*spmat dta W m*, normalize(row)
*spmat summarize W, links detail


**  Import data
*use "data", clear




** Close log file
log close

**====================END==============================
   