*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/wb_es_cri201028.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m 
tab corr_crit, m
tab corr_submp, m
tab corr_doc, m
tab nocft, m
tab taxhav2, m

foreach var of varlist singleb corr_crit corr_submp corr_doc nocft taxhav2 {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  //tax haven undefined
}
tab ind_singleb_val  singleb, m
tab ind_corr_doc_val  corr_doc, m
tab ind_corr_crit_val  corr_crit, m
tab ind_corr_submp_val  corr_submp, m
tab ind_nocft_val  nocft, m
tab ind_taxhav2_val  taxhav2, m
************************************

tab corr_ben2, m 
tab corr_proc, m 
tab corr_decp, m
foreach var of varlist corr_ben2 corr_proc corr_decp {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_ben2_val  corr_ben2, m
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_decp_val  corr_decp, m
************************************

*Contract Share
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
************************************

*Transparency
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
foreach var of varlist buyer_name tender_title bidder_name tender_supplytype bid_price impl proc aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2

gen ind_tr_bids_val = 0 if tender_recordedbidscount==.
replace ind_tr_bids_val= 100 if tender_recordedbidscount!=.

*rename tr_aw_date2 ind_tr_aw_date2_val
************************************

********************************************************************************
save $country_folder/wb_es_cri201028.dta, replace
********************************************************************************
*Fixing variables for reverse tool

gen tender_country = "ES"
************************************

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)

br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************

*rename buyer_NUTS3 buyer_geocodes
rename buyer_nuts2 buyer_nuts2_orig
tab buyer_nuts, m
gen buyer_nuts_len = length(buyer_nuts)
tab buyer_nuts_len, m
gen buyer_nuts2 = ""
bys buyer_nuts_len: replace buyer_nuts2 = buyer_nuts + "0000" if buyer_nuts_len== 1
bys buyer_nuts_len: replace buyer_nuts2 = buyer_nuts + "000" if buyer_nuts_len== 2
bys buyer_nuts_len: replace buyer_nuts2 = buyer_nuts + "00" if buyer_nuts_len== 3
bys buyer_nuts_len: replace buyer_nuts2 = buyer_nuts + "0" if buyer_nuts_len== 4
bys buyer_nuts_len: replace buyer_nuts2 = buyer_nuts  if buyer_nuts_len== 5
br buyer_nuts2 buyer_nuts buyer_nuts_len if buyer_nuts_len!=0
tab buyer_nuts2
drop buyer_nuts
rename buyer_nuts2 buyer_nuts
************************************

gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]"
drop buyer_nuts_len
replace buyer_geocodes="" if buyer_nuts==""
*if buyer nuts is missing it shoud be empty
*for bidder and impl also
*before that check nuts all nuts code and assigned city in a new sheet
************************************

*Fixing IMPL nuts
tab tender_addressofimplementation_n, m
gen imp_nuts_len = length(tender_addressofimplementation_n)
tab imp_nuts_len, m
gen imp_nuts2 = ""
bys imp_nuts_len: replace imp_nuts2 = tender_addressofimplementation_n + "0000" if imp_nuts_len== 1
bys imp_nuts_len: replace imp_nuts2 = tender_addressofimplementation_n + "000" if imp_nuts_len== 2
bys imp_nuts_len: replace imp_nuts2 = tender_addressofimplementation_n + "00" if imp_nuts_len== 3
bys imp_nuts_len: replace imp_nuts2 = tender_addressofimplementation_n + "0" if imp_nuts_len== 4
bys imp_nuts_len: replace imp_nuts2 = tender_addressofimplementation_n  if imp_nuts_len== 5
br imp_nuts2 tender_addressofimplementation_n imp_nuts_len if imp_nuts_len!=0
tab imp_nuts2
drop buyer_nuts
rename imp_nuts2 imp_nuts
************************************

gen tender_addressofimplementation_c = substr(imp_nuts,1,2) 
gen  tender_addressofimplementation_c = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]"
replace tender_addressofimplementation2="" if imp_nuts==""
drop tender_addressofimplementation_n
rename tender_addressofimplementation2 tender_addressofimplementation_n
tab tender_addressofimplementation_n, m
tab tender_addressofimplementation_c, m
drop imp_nuts
************************************

*Fixing Bidder nuts
tab bidder_nuts, m
replace bidder_nuts="" if bidder_nuts=="00"

gen bidder_nuts_len = length(bidder_nuts)
tab bidder_nuts_len, m
gen bidder_nuts2 = ""
bys bidder_nuts_len: replace bidder_nuts2 = bidder_nuts + "0000" if bidder_nuts_len== 1
bys bidder_nuts_len: replace bidder_nuts2 = bidder_nuts + "000" if bidder_nuts_len== 2
bys bidder_nuts_len: replace bidder_nuts2 = bidder_nuts + "00" if bidder_nuts_len== 3
bys bidder_nuts_len: replace bidder_nuts2 = bidder_nuts + "0" if bidder_nuts_len== 4
bys bidder_nuts_len: replace bidder_nuts2 = bidder_nuts  if bidder_nuts_len== 5
count if missing(bidder_nuts)
count if missing(bidder_nuts2)
br bidder_nuts2 bidder_nuts bidder_nuts_len if bidder_nuts_len!=0
tab bidder_nuts2
drop bidder_nuts bidder_nuts_len
gen bidder_nuts_len = length(bidder_nuts)
tab bidder_nuts_len, m
drop bidder_nuts_len
rename bidder_nuts2 bidder_nuts
tab bidder_nuts
************************************

gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]"
replace bidder_geocodes="" if bidder_nuts==""
************************************

*year-month-day as a string 

foreach var of varlist bid_deadline first_cft_pub last_cft_pub aw_date ca_date {
	gen `var'_n=date(`var', "YMD")
	format `var'_n %d
}

foreach var of varlist bid_deadline_n first_cft_pub_n last_cft_pub_n aw_date_n ca_date_n {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx="0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen `var'_str = yearx + "-" + monthx + "-" + dayx
	replace `var'_str ="" if `var'_str ==".-0.-0."
	drop dayx monthx yearx len_mon len_day
	drop `var'
	rename `var'_str `var'
}
************************************

gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
drop buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
gen lot_est_pricecurrency = currency
************************************

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
replace lot_localProductCode = substr(lot_localProductCode,1,8)
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

br tender_title lot_title
gen title = lot_title
replace title = tender_title if missing(title)
************************************

br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
*replace bids_count = tender_recordedbidscount if missing(bids_count)
************************************

*Exporting for the rev flatten tool\

*Indicators
rename ind_corr_proc_val c_INTEGRITY_PROCEDURE_TYPE
rename ind_corr_submp_val  c_INTEGRITY_ADVERTISEMENT_PERIOD
rename ind_corr_decp_val  c_INTEGRITY_DECISION_PERIOD
rename ind_nocft_val  c_INTEGRITY_CALL_FOR_TENDER_PUB
rename ind_singleb_val  c_INTEGRITY_SINGLE_BID
rename ind_csh_val  c_INTERGIRTY_WINNER_SHARE
rename ind_corr_ben2_val c_INTEGRITY_BENFORD

rename tr_tender_title c_TRANSPARENCY_TITLE_MISSING
rename tr_bid_price c_TRANSPARENCY_VALUE_MISSING
rename tr_impl c_TRANSPARENCY_IMP_LOC_MISSING
rename tr_tender_recordedbidscount c_TRANSPARENCY_BID_NR_MISSING
rename tr_buyer_name c_TRANSPARENCY_BUYER_NAME_MIS
rename tr_bidder_name c_TRANSPARENCY_BIDDER_NAME_MIS
rename tr_tender_supplytype c_TRANSPARENCY_SUPPLY_TYPE_MIS
rename tr_proc c_TRANSPARENCY_PROC_METHOD_MIS
rename ind_tr_aw_date2_val c_TRANSPARENCY_AWARD_DATE_MIS


rename buyer_district_api buyer_district
rename buyer_city_api buyer_city
rename buyer_county_api buyer_county
rename buyer_NUTS3 buyer_nuts3

rename bid_price_ppp bid_price_netAmountUsd

*reshape long c_ , i(tender_id proa_ycsh proa_ycsh4 taxhav2 ) j(indicator, string)

*rename c_ tender_indicator_value
*rename indicator tender_indicator_type
*br tender_indicator_type tender_indicator_value
************************************

*Fixing Transparency indicators first
replace tender_indicator_type="TRANSPARENCY_BUYER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BUYER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_BIDDER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BIDDER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_SUPPLY_TYPE_MISSING" if tender_indicator_type=="TRANSPARENCY_SUPPLY_TYPE_MIS"
replace tender_indicator_type="TRANSPARENCY_PROC_METHOD_MISSING" if tender_indicator_type=="TRANSPARENCY_PROC_METHOD_MIS"
replace tender_indicator_type="TRANSPARENCY_AWARD_DATE_MISSING" if tender_indicator_type=="TRANSPARENCY_AWARD_DATE_MIS"
************************************

*Calculating  status


*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
 
*undefined if tax haven ==9 
gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"
************************************

gen tender_indicator_status = "INSUFFICIENT DATA" if inlist(tender_indicator_value,99,999,.)
replace tender_indicator_status = "CALCULATED" if missing(tender_indicator_status)
replace tender_indicator_value=. if inlist(tender_indicator_value,99,999,.)
************************************

gen buyer_indicator_type = "INTEGRITY_BENFORD"
rename corr_ben2 buyer_indicator_value
gen buyer_indicator_status = "INSUFFICIENT DATA" if inlist(buyer_indicator_value,99,.)
replace buyer_indicator_status = "CALCULATED" if missing(buyer_indicator_status)
replace buyer_indicator_value=. if inlist(buyer_indicator_value,99,999,.)
************************************

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
br  buyer_id bidder_id
********************************************************************************
save $country_folder/wb_es_cri201028.dta, replace
********************************************************************************

*Fixing variables for the rev flatten tool\

sort tender_id lot_row_nr

tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)
tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
************************************
bys tender_id: gen x=_N
format tender_title  bidder_name  tender_publications_lastcontract  %15s
br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
count if missing(tender_lotscount)
gen lot_number = 1 if tender_isframework=="t" & missing(lot_row_nr)
replace lot_number = lot_row_nr if tender_isframework=="t" & !missing(lot_row_nr)
bys tender_id: replace lot_number=_n if tender_isframework!="t"
count if missing(lot_number)

sort  tender_id   lot_number
br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
************************************

*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n
br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK
************************************
save $country_folder/XX_wip.dta, replace
************************************

*Sanctions - added later 
/*

recast str818 bidder_name, force
merge m:1 bidder_name using $utility_data/country/ES/ES_sanctions.dta
drop bidder_name 
drop if _m==2
drop _m
format w_name %15s
br w_name n_row1-sanct_country4 if !missing(n_row1)
drop n_row*
*Manage dates
format sanct_startDate1 sanct_startDate2 sanct_startDate3 %d

gen ca_dateD = date(ca_date,"YMD")
format ca_dateD %d

forval x =1/3 {
gen sanct_startDate`x'_f = date(sanct_startDate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_endDate`x',"YMD")
drop sanct_startDate`x' sanct_endDate`x'
rename sanct_startDate`x'_f sanct_startDate`x'
rename sanct_endDate`x'_f sanct_endDate`x'
}
format sanct_startDate* sanct_endDate* %d
br  aw_dec_date sanct_startDate* sanct_endDate* if !missing(sanct_startDate1)
gen bidder_hasSanction="false"
replace bidder_hasSanction="true" if !missing(sanct_startDate1)
gen bidder_previousSanction="false"
replace bidder_previousSanction="true" if aw_dec_date>=sanct_endDate1 & !missing(sanct_endDate1)
replace bidder_previousSanction="" if missing(aw_dec_date)
*Dates we only keep the latest start and end date
gen sanct_startdate = .
replace sanct_startdate = sanct_startDate1 if !missing(sanct_startDate1)
replace sanct_startdate = sanct_startDate2 if !missing(sanct_startDate2)
replace sanct_startdate = sanct_startDate3 if !missing(sanct_startDate3)
*replace sanct_startdate = sanct_startDate4 if !missing(sanct_startDate4)
format sanct_startdate %d
br sanct_startdate sanct_startDate* if !missing(sanct_startDate3)
gen sanct_enddate = .
replace sanct_enddate = sanct_endDate1 if !missing(sanct_endDate1)
replace sanct_enddate = sanct_endDate2 if !missing(sanct_endDate2)
*replace sanct_enddate = sanct_endDate3 if !missing(sanct_endDate3)
*replace sanct_enddate = sanct_endDate4 if !missing(sanct_endDate4)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate3)
format sanct_enddate %d 
foreach var of varlist sanct_startdate sanct_enddate {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = dayx + "-" + monthx + "-" + yearx
drop dayx monthx yearx
}

foreach var of varlist sanct_startdate sanct_enddate {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx="0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen `var'_str = yearx + "-" + monthx + "-" + dayx
	replace `var'_str ="" if `var'_str ==".-0.-0."
	drop dayx monthx yearx len_mon len_day
	drop `var'
	rename `var'_str `var'
}

br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startDate1)
*drop sanct_legalGround1-sanct_endDate3
*Sanctioning Authority name
br sanct_name1 sanct_name2 sanct_name3 if !missing(sanct_startdate)
gen sanct_name = sanct_name1 if !missing(sanct_name1)
replace sanct_name= sanct_name + " & " + sanct_name2 if !missing(sanct_name2)
replace sanct_name= sanct_name + " & " + sanct_name3 if !missing(sanct_name3)
*replace sanct_name= sanct_name + " & " + sanct_name4 if !missing(sanct_name4)
*Sanctioned corruption indicator
tab bidder_hasSanction, m
tab bidder_previousSanction, m
br aw_dec_date bidder_hasSanction bidder_previousSanction  sanct_startdate sanct_enddate sanct_name if !missing(sanct_startdate)
*/
*************************  

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben2_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
*************************

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben2_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

*Implementing some fixes

drop if missing(tender_id)

replace tender_supplytype= "" if tender_supplytype=="OTHER"

replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype)


export delimited $country_folder/ES_mod.csv, replace
********************************************************************************
*END