*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
import delimited using  $utility_data/country/AT/starting_data/UK_data.csv, encoding(UTF-8) clear
********************************************************************************

*Create tender final price
bys tender_id: replace tender_finalprice=sum(bid_price) if bid_iswinning=="t"
sort tender_id tender_finalprice
bys tender_id: replace tender_finalprice=tender_finalprice[1] if tender_finalprice==.
sum tender_finalprice
sum tender_finalprice if tender_finalprice==0 //275,522
tab bid_iswinning if tender_finalprice==0 //t
tab tender_proceduretype if tender_finalprice==0 //mostly open and restricted

************************************
*Create contract value from bid_price
gen ca_contract_value=bid_price
gen lca_contract_value=log(ca_contract_value)
*hist lca_contract_value // normal

xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)
************************************
save $country_folder/UK_wip.dta, replace
************************************

use $utility_data/wb_ppp_data.dta, clear
keep if countrycode == "GBR"
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_gbr.dta, replace

use $utility_data/wb_ppp_data.dta, clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_eu.dta, replace

********************************************************************************
use $country_folder/UK_wip.dta ,clear

gen year = tender_year
merge m:1 year using $country_folder/ppp_data_gbr.dta
drop if _m==2
tab year if _m==1, m //2020 no ppp data
tabstat ppp, by(year)
replace ppp=0.680356 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year
rename ppp ppp_gbp


gen year = tender_year
merge m:1 year using $country_folder/ppp_data_eu.dta
drop if _m==2
tab year if _m==1, m //2020 no ppp data
tabstat ppp, by(year)
replace ppp=.684051 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year
rename ppp ppp_eur


gen tender_finalprice_ppp = tender_finalprice/ppp_gbp if currency=="GBP" | missing(currency)
gen bid_price_ppp =  bid_price/ppp_gbp if currency=="GBP" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp_gbp if currency=="GBP" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp_gbp if currency=="GBP" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp_gbp if currency=="GBP" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp_gbp if currency=="GBP" | missing(currency)

replace tender_finalprice_ppp = tender_finalprice/ppp_eur if currency=="EUR" 
replace bid_price_ppp =  bid_price/ppp_eur if currency=="EUR"
replace ca_contract_value_ppp =  ca_contract_value/ppp_eur if currency=="EUR" 
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if currency=="EUR" 
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if currency=="EUR"
replace lot_updatedprice_ppp = lot_updatedprice/ppp_eur if currency=="EUR"

********************************************************************************

*Market id
replace tender_cpvs = "99100000" if missing(tender_cpvs) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) & missing(tender_supplytype)

gen marketid = substr(tender_cpvs,1,2)
tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid
*destring marketid, replace

************************************

*Create filter ok
gen filter_ok = 0 
replace filter_ok = 1 if !missing(tender_publications_lastcontract) & !missing(bidder_name)
*Filtering out contracts with very high values
count if tender_finalprice>10000000 & filter_ok
tab filter_ok, m  //533,519
count if filter_ok
di `r(N)'/_N  // 64.42% of observations
************************************

*Supply type
encode tender_supplytype, gen(ca_type)
replace ca_type=. if tender_supplytype==""
tab ca_type, m
************************************

*Buyer type
tab buyer_buyertype, m
encode buyer_buyertype, gen(anb_type)
replace anb_type=. if buyer_buyertype==""
tab anb_type, m
************************************

*Buyer Location
tab buyer_nuts, m
gen anb_nuts2 = substr(buyer_nuts,1,2)
replace buyer_nuts="" if anb_nuts2!="UK"
gen buyer_nuts3=substr(buyer_nuts,1,3)
encode buyer_nuts3,gen(anb_loc)
************************************

*Dates
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen last_cft_pub = date(tender_publications_lastcallfor, "YMD")
format bid_deadline first_cft_pub %d
gen aw_date = date(tender_publications_firstdcontra, "YMD")
gen ca_date = date(tender_publications_firstdcontra, "YMD")
format aw_date ca_date first_cft_pub %d
label var aw_date "award date - from publication first contract date"
label var ca_date "award decision date"
********************************************************************************

save $country_folder/UK_wip.dta , replace
********************************************************************************
*END
