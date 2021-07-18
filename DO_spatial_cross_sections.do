* SPATIAL ECONOMETRICS with cross-sectional data (Before and after Stata 15)

* Clean your environment
clear all
macro drop _all
set more off
cls
version 15

* Change working directory
  * to the location of this .do file


* Manually download the data (A shapefile that includes the variables) and store it in a data folder
  * Source: https://geodacenter.github.io/data-and-lab/columbus/


* Install packages
* ssc install spmap
* ssc install shp2dta
* ssc install sppack
* ssc install spregcs

* Learn more about the following commands
*help spatwmat
*help spreg
*help spmat
*help spregcs
*help spatreg


* Use the shp2dta package to convert a shape file into 2 stata datasets (dBase and coordinates)
shp2dta using "columbus.shp", database("columbusDbase.dta") coordinates("columbusCoor.dta") genid(id) replace

* Load and describe the stata Dbase file
use "columbusDbase.dta", clear
describe

* Plot a map
*spmap CRIME using "columbusCoor.dta", id(id) legend(size(small) position(11)) clmethod(custom) clbreaks(0 15 30 45 60 75) fcolor(Blues) title("Property crimes per thousand households") note("Columbus, Ohio 1980 neighorhood data" "Source: Anselin (1988)")
*graph save   "mapCrime.gph", replace
*graph export "mapCrime.png", replace


* Generate spatial weights matrices with spmat package
spmat contiguity Wqueen  using "columbusCoor.dta", id(id)
spmat contiguity WqueenS using "columbusCoor.dta", id(id) normalize(row)

* Summarize spatial weights matrices
spmat summarize Wqueen
spmat summarize Wqueen, links

spmat summarize WqueenS
spmat summarize WqueenS, links

* Export matrix from an spmat object to a Mata object
spmat getmatrix Wqueen   mataWqueen
spmat getmatrix WqueenS  mataWqueenS

* Display Mata matrices
mata
mataWqueen
mataWqueenS
end

*** Export W matrix (created with spmat) to stata file (that is, .dta)

* Export weight matrix to .txt file (with no id column)
spmat export Wqueen  using "Wqueen_fromStata_spmat.txt",  noid replace
spmat export WqueenS using "WqueenS_fromStata_spmat.txt", noid replace

* Import .txt weight matrix and save it at .dta (stata) data file
import delimited "Wqueen_fromStata_spmat.txt", delimiter(space) rowrange(2) clear
save             "Wqueen_fromStata_spmat.dta", replace

import delimited "WqueenS_fromStata_spmat.txt", delimiter(space) rowrange(2) clear
save             "WqueenS_fromStata_spmat.dta", replace


* [IMPORTANT] Import .dta weight matrix with spatwmat package
spatwmat using "Wqueen_fromStata_spmat.dta", name(Wqueen_fromStata_spatwmat)
matrix list Wqueen_fromStata_spatwmat

* [IMPORTANT] Import .dta weight matrix with spatwmat package, standardize it, and store eigen values
spatwmat using "Wqueen_fromStata_spmat.dta", name(WqueenS_fromStata_spatwmat) eigenval(eWqueenS_fromStata_spatwmat) standardize
matrix list WqueenS_fromStata_spatwmat

* Import .dta weights matrix with spmatrix (official function from Stata15)
use "Wqueen_fromStata_spmat.dta", clear
gen id = _n
order id, first
spset id
spmatrix fromdata WqueenS_fromStata15 = v*, normalize(row) replace
spmatrix summarize WqueenS_fromStata15


* Global Moran's I of the dependent variable
spatgsa CRIME, w(WqueenS_fromStata_spatwmat) moran



* (0) Fit OLS model:  No spatial lags
use "columbusDbase.dta", clear
spset id
regress CRIME INC HOVAL
estat moran, errorlag(WqueenS_fromStata15)


* LM Spatial diagnostics of regression residuals
reg CRIME INC HOVAL
spatdiag, weights(WqueenS_fromStata_spatwmat)


* (1) SAR/SLM: Spatial lag model (using 3 alternative packages)

* using spregress (official function from Stata 15)
use "Wqueen_fromStata_spmat.dta", clear
gen id = _n
order id, first
spset id
spmatrix fromdata WqueenS_fromStata15 = v*, normalize(row) replace
spmatrix summarize WqueenS_fromStata15

use "columbusDbase.dta", clear
spset id

spregress CRIME INC HOVAL, ml dvarlag(WqueenS_fromStata15) vce(robust)
estat ic
estat impact

* using the spregcs package (BE CAREFUL!! it requires a W created with spmat)
spregcs CRIME INC HOVAL, wmfile("Wqueen_fromStata_spmat.dta") model(sar) mfx(lin)

* using the spatreg package (BE CAREFUL!! it requires a W created with spatwmat)
spatreg CRIME INC HOVAL, weights(WqueenS_fromStata_spatwmat) eigenval(eWqueenS_fromStata_spatwmat) model(lag)



* (2) SEM: Spatial error model (using 3 alternative packages)

* using spregress (official function from Stata 15)
use "Wqueen_fromStata_spmat.dta", clear
gen id = _n
order id, first
spset id
spmatrix fromdata WqueenS_fromStata15 = v*, normalize(row) replace
spmatrix summarize WqueenS_fromStata15

use "columbusDbase.dta", clear
spset id

spregress CRIME INC HOVAL, ml errorlag(WqueenS_fromStata15) vce(robust)
estat ic
estat impact

* using the spregcs package (BE CAREFUL!! it requires a W created with spmat)
spregcs CRIME INC HOVAL, wmfile("Wqueen_fromStata_spmat.dta") model(sem) mfx(lin)

* using the spatreg package (BE CAREFUL!! it requires a W created with spatwmat)
spatreg CRIME INC HOVAL, weights(WqueenS_fromStata_spatwmat) eigenval(eWqueenS_fromStata_spatwmat) model(error)


* (3) Fit SLX model: spatial lag of the independent variables
use "Wqueen_fromStata_spmat.dta", clear
gen id = _n
order id, first
spset id
spmatrix fromdata WqueenS_fromStata15 = v*, normalize(row) replace
spmatrix summarize WqueenS_fromStata15

use "columbusDbase.dta", clear
spset id

spregress CRIME INC HOVAL, ml ivarlag(WqueenS_fromStata15: INC HOVAL) vce(robust)
estat ic
estat impact


* (4) Fit SAC model: spatial lag of the dependent and error term
spregress CRIME INC HOVAL, ml dvarlag(WqueenS_fromStata15) ivarlag(WqueenS_fromStata15: INC HOVAL) vce(robust)
estat ic
estat impact


* (5) Fit SDM model: spatial lag of the dependent and independent variables
spregress CRIME INC HOVAL, ml dvarlag(WqueenS_fromStata15) errorlag(WqueenS_fromStata15) vce(robust)
estat ic
estat impact


* (6) Fit SDEM model: spatial lag of the independent variables and error term
spregress CRIME INC HOVAL, ml ivarlag(WqueenS_fromStata15: INC HOVAL) errorlag(WqueenS_fromStata15) vce(robust)
estat ic
estat impact


* (7) Fit GNS model: spatial lag of the dependent, independent, and error terms
spregress CRIME INC HOVAL, ml dvarlag(WqueenS_fromStata15) ivarlag(WqueenS_fromStata15: INC HOVAL) errorlag(WqueenS_fromStata15) vce(robust)
estat ic
estat impact
