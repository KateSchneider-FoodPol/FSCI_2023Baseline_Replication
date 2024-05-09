/* 
Replication of data management for: The state of food systems worldwide in the countdown to 2030
Created: 29 June 2022
Last modified: 29 October 2023
Kate Schneider, kschne29@jhu.edu

Purpose: this script ingests raw datasets and extracts, reshapes, and calculates the selected FSCI indicators. 
Input data and metadata can be found here: 
https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/blob/552a860f9f3fda4e0116d42690f6b9c86773f458/FSCI%20Baseline_Supplementary%20Data%20-%20Appendix%20E%20-%20Metadata%20and%20Codebook.xlsx
Output datasets can be found here: https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/tree/552a860f9f3fda4e0116d42690f6b9c86773f458/FSCI%20analysis%20datasets
*/
* Date
display "$S_DATE"

// HOUSEKEEPING ////////////////////////////////////////////////////////////////

** Unique filepath to root folder: Enter your own filepath between the quotation marks
global filepath "Working directory" 
		// Note: working folder until finalized

* Relative filepaths:
global datain "$filepath\Raw data"
global saveto "$filepath\FSCI analysis datasets"
global tables "$filepath\Analysis results"
cd "$saveto"


// CLASSIFICATION, CONTEXT, AND WEIGHTING VARIABLES ////////////////////////////

* Harmonized variables to merge datasets: 
* country = country name
* ISO = country code / ISO3 code
* year = year

**# ISO3 country codes
		import delimited using "$datain\iso3", clear varnames(1)
		ren iso3 ISO
		lab var ISO "ISO-alpha3 code"
		ren name country
		lab var country "Country name"
		
		// Rename countries to align with official names per https://www.un.org/en/about-us/member-states
			replace country = "Bahamas" if country == "Bahamas (the)" 
			replace country = "British Indian Ocean Territory" if country == "British Indian Ocean Territory (the)" 
			replace country = "Cayman Islands" if country == "Cayman Islands (the)" 
			replace country = "Central African Republic" if country == "Central African Republic (the)" 
			replace country = "Cocos (Keeling) Islands" if country == "Cocos (Keeling) Islands (the)" 
			replace country = "Comoros" if country == "Comoros (the)" 
			replace country = "Democratic Republic of the Congo" if country == "Congo (the Democratic Republic of the)" 
			replace country = "Congo" if country == "Congo (the)" 
			replace country = "Cook Islands" if country == "Cook Islands (the)" 
			replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire" 
			replace country = "Dominican Republic" if country == "Dominican Republic (the)" 
			replace country = "Falkland Islands (Malvinas)" if country == "Falkland Islands (the) [Malvinas]" 
			replace country = "Faroe Islands" if country == "Faroe Islands (the)" 
			replace country = "French Southern and Antarctic Territories" if country == "French Southern Territories (the)" 
			replace country = "Gambia (Republic of The)" if country == "Gambia (the)" 
			replace country = "Holy See" if country == "Holy See (the)"
			replace country = "Dem People's Rep of Korea" if country == "Korea (the Democratic People's Republic of)" 
			replace country = "Republic of Korea" if country == "Korea (the Republic of)" 
			replace country = "Lao People's Democratic Republic" if country == "Lao People's Democratic Republic (the)" 
			replace country = "Macau" if country == "Macao" 
			replace country = "Marshall Islands" if country == "Marshall Islands (the)" 
			replace country = "Republic of Moldova" if country == "Moldova (the Republic of)" 
			replace country = "Netherlands" if country == "Netherlands (the)" 
			replace country = "Niger" if country == "Niger (the)" 
			replace country = "Northern Mariana Islands" if country == "Northern Mariana Islands (the)" 
			replace country = "Philippines" if country == "Philippines (the)" 
			replace country = "Russian Federation" if country == "Russian Federation (the)" 
			replace country = "Reunion" if country == "Réunion" 
			replace country = "Saint Helena" if country == "Saint Helena, Ascension and Tristan da Cunha" 
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon" 
			replace country = "Sudan" if country == "Sudan (the)" 
			replace country = "Svalbard and Jan Mayen Islands" if country == "Svalbard and Jan Mayen" 
			replace country = "Syrian Arab Republic" if country == "Syrian Arab Republic (the)" 
			replace country = "Taiwan" if country == "Taiwan (Province of China)" 
			replace country = "United Republic of Tanzania" if country == "Tanzania, the United Republic of" 
			replace country = "United Arab Emirates" if country == "United Arab Emirates (the)" 
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom of Great Britain and Northern Ireland (the)" 
			replace country = "United States Minor Outlying Islands" if country == "United States Minor Outlying Islands (the)" 
			replace country = "United States of America" if country == "United States of America (the)" 
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)" 
			replace country = "British Virgin Islands" if country == "Virgin Islands (British)" 
			replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
			replace country = "Western Sahara" if country == "Western Sahara*" 
		
		// Save
		save iso, replace
		export delimited using iso, replace
	
**#UN member state classification
		import delimited using "$datain\g2015_2005_1.csv", clear varnames(1)
			// Collapse to ADM0 level
				collapse (first) status disp_area adm0_code, by(adm0_name)
				foreach v in adm0_name status disp_area adm0_code {
					lab var `v' ""
				}
		
		ren adm0_name country
		replace status = "Occupied Palestinian Territory" if status == "Occupied Palestinan Territory"
		encode status, gen(UN_status_detail)
		lab var UN_status_detail "UN status and territorial details"
		tab UN_status_detail
		tab UN_status_detail, nolabel
		gen UNmemberstate = 1 if UN_status_detail == 8
		replace UNmemberstate = 0 if UNmemberstate == .
		gen UN_status = .
			replace UN_status = 1 if UNmemberstate == 1
			replace UN_status = 2 if inlist(UN_status_detail,16,17)
			replace UN_status = 3 if inlist(UN_status_detail,20,21)
			replace UN_status = 4 if UN_status_detail == 19
			replace UN_status = 5 if inlist(UN_status_detail,1,2,3,4,5,6,7,8,9)
			replace UN_status = 5 if inlist(UN_status_detail,11,12,13,14,15,18,22,23,24,25)
		lab def status 1 "Member state" 2 "Occupied territory" 3 "Sovereignty unsettled" 4 "Permanent observer to the UN" 5 "Territory, region, or administrated by a state"
			lab val UN_status status
			gen territoryof = status if UN_status == 5
			drop status adm0_code
			
			// Merge in ISO codes
			// Rename countries to align with official names per https://www.un.org/en/about-us/member-states
			tab country
			replace country = "Antigua and Barbuda" if country == "Antigua & Barbuda"
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Bosnia and Herzegovina" if country == "Bosnia & Herzegovina"
			replace country = "Cabo Verde" if country == "Cape Verde"
			replace country = "Côte D'Ivoire" if country == "CÃ´te d'Ivoire"
			replace country = "Czechia" if country == "Czech Republic"
			replace country = "Eswatini" if country == "Swaziland"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Libya" if country == "Libyan Arab Jamahiriya"
			replace country = "North Macedonia" if country == "The former Yugoslav Republic of Macedonia"
			replace country = "Republic of Moldova" if country == "Moldova, Republic of"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "U.K. of Great Britain and Northern Ireland"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
			replace country = "Viet Nam" if country == "Vietnam"					
			replace country = "Reunion" if country == "RÃ©union"
			replace country = "Turks and Caicos Islands" if country == "Turks and Caicos islands"
			replace country = "Iran (Islamic Republic of)" if country == "Iran  (Islamic Republic of)" 		
			merge 1:1 country using iso
				browse if _merge!=3
				drop if _merge == 2 & !inlist(country,"South Sudan", "Serbia", "Montenegro") // territories not classified by UN, except new member states since GAUL exercise
			// Correct Serbia, Montenegro, and South Sudan
				browse if inlist(country,"South Sudan", "Serbia", "Montenegro", "Sudan", "Serbia and Montenegro")
				replace UNmemberstate = 1 if inlist(country,"South Sudan", "Serbia", "Montenegro")
				replace UN_status_detail = 8 if inlist(country,"South Sudan", "Serbia", "Montenegro")
				replace UN_status = 1 if inlist(country,"South Sudan", "Serbia", "Montenegro")
				replace disp_area = "NO" if inlist(country,"South Sudan", "Serbia", "Montenegro")
				drop if country == "Serbia and Montenegro"
				drop _merge
			sort country

		// Save
		save UNStatus, replace
		export delimited using UNStatus, replace

**# World Bank classifications used for regional coding and country income level
		import excel using "$datain\CLASS.xlsx", sheet("List of economies") firstrow clear
		drop Lendingcategory OtherEMUorHIPC
		ren Code ISO
		ren Region wb_region
		ren Incomegroup incgrp
		lab var wb_region "Region (World Bank)"
		lab var incgrp "Income Group (World Bank)"
			
			// Fix codes that do not match ISO3 classification
			replace ISO="_CH" if ISO=="CHI" // Channel Islands
			tab Economy if wb_region==""
			drop if wb_region=="" // drops aggregate groups
			ren Economy country 
			ren wb_region wb_region_str
			encode wb_region_str, gen(wb_region)
			drop wb_region_str 
		
		// Save
		save wb_areaincomeclass, replace
		export delimited using wb_areaincomeclass, replace 
	
		// Merge World Bank and UN Member states datasets
		use wb_areaincomeclass, clear
			
			// Replace country names with UN member official name
				replace country = "Bahamas" if country == "Bahamas, The" 
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia" 
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep." 
				replace country = "Congo" if country == "Congo, Rep." 
				replace country = "Czechia" if country == "Czech Republic" 
				replace country = "Côte D'Ivoire" if ISO == "CIV"
				replace country = "Egypt" if country == "Egypt, Arab Rep." 
				replace country = "Gambia (Republic of The)" if country == "Gambia, The" 
				replace country = "Hong Kong" if country == "Hong Kong SAR, China" 
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep." 
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep." 
				replace country = "Republic of Korea" if country == "Korea, Rep." 
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic" 
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR" 
				replace country = "Macau" if country == "Macao SAR, China" 
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts." 
				replace country = "Republic of Moldova" if country == "Moldova" 
				replace country = "Slovakia" if country == "Slovak Republic" 
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis" 
				replace country = "Saint Lucia" if country == "St. Lucia" 
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines" 
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe" 
				replace country = "Taiwan" if country == "Taiwan, China" 
				replace country = "United Republic of Tanzania" if country == "Tanzania" 
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom" 
				replace country = "United States of America" if country == "United States" 
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB" 
				replace country = "Viet Nam" if country == "Vietnam" 
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
				replace country = "Yemen" if country == "Yemen, Rep." 
				replace country = "Palestine, State of" if country == "West Bank and Gaza"

				merge 1:1 country using UNStatus, update // replaces country names with UN country name 
				drop _merge
				
				// Keep aggregate and disaggregated Palestine for now, fill in classification information across datasets
					browse if inlist(country,"West Bank", "Gaza Strip", "Palestine, State of")
						replace ISO = "PSE" if inlist(country,"West Bank", "Gaza Strip")
						replace incgrp = "Lower middle income" if inlist(country,"West Bank", "Gaza Strip")
						replace wb_region = 4 if inlist(country,"West Bank", "Gaza Strip")	
						replace disp_area = "NO" if country == "Palestine, State of"
						replace UN_status_detail = 15 if country == "Palestine, State of"
						replace UNmemberstate = 0 if country == "Palestine, State of"				
					
			// Fill in governing and UN member state status for territories only in WB dataset
				browse if UN_status_detail == .
				gen ISO_governing = ""
				tab UN_status_detail, sum(UN_status_detail)
					replace ISO_governing = "AUS" if UN_status_detail == 1
					replace ISO_governing = "CHN" if UN_status_detail == 2
					replace ISO_governing = "CHN" if UN_status_detail == 3
					replace ISO_governing = "DNK" if UN_status_detail == 4
					replace ISO_governing = "DNK" if UN_status_detail == 5
					replace ISO_governing = "FRA" if UN_status_detail == 6
					replace ISO_governing = "FRA" if UN_status_detail == 7
					replace ISO_governing = "NLD" if UN_status_detail == 9
					replace ISO_governing = "NLD" if UN_status_detail == 10
					replace ISO_governing = "NOR" if UN_status_detail == 11
					replace ISO_governing = "NZL" if UN_status_detail == 12
					replace ISO_governing = "NZL" if UN_status_detail == 13
					replace ISO_governing = "XXX" if UN_status_detail == 14
					replace ISO_governing = "XXX" if UN_status_detail == 15
					replace ISO_governing = "PRT" if UN_status_detail == 16
					replace ISO_governing = "XXX" if UN_status_detail == 17
					replace ISO_governing = "VAT" if UN_status_detail == 18
					replace ISO_governing = "GBR" if UN_status_detail == 19
					replace ISO_governing = "GBR" if UN_status_detail == 20
					replace ISO_governing = "GBR" if UN_status_detail == 21
					replace ISO_governing = "USA" if UN_status_detail == 22
					replace ISO_governing = "USA" if UN_status_detail == 23
					replace ISO_governing = "VEN" if UN_status_detail == 24
			
			// Drop the Vatican
				drop if country == "Holy See"
		// Save
			save countryclassification, replace
				
** Merge in UN regional classification and M49 codes
		import excel using "$datain\13_M49_Annex_regional_groupings_21_Oct_22.xlsx", sheet("M49_FAO") firstrow clear cellrange(B2)
		drop Geographicalgroupingsa C
		ren D UN_contregion_code
		ren E UN_continental_region
		ren F UN_subregion_code
		ren G UN_subregion
		ren H UN_intermedregion_code
		ren I UN_intermediary_region
		ren J m49_code
		ren K ISO
		drop Othergroupingsb-Comments
		ren L country // to merge with country classification even though not all are countries
		drop in 1/2 // drop heading rows imported as observations
		replace country = "French Southern and Antarctic Territories" if country == "French Southern Territories"
		replace country = "Côte D'Ivoire" if ISO == "CIV"
		replace country = "Gambia (Republic of The)" if country == "Gambia"
		replace country = "Hong Kong" if country == "China, Hong Kong SAR"
		replace country = "Macau" if country == "China, Macao"
		replace country = "Taiwan" if country == "Taiwan, Province of China"
		replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
		replace country = "Palestine, State of" if country == "Palestine"
		replace country = "Reunion" if country == "Réunion"
		replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
		replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
		replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
		replace country = "St. Martin (French part)" if country == "Saint Martin (French Part)"
		replace country = "Kosovo" if country == "Kosovo (Serbia)"
		drop if country == ""
		save UN_m49_classifications, replace
		
		use countryclassification, clear
		merge 1:1 ISO country using UN_m49_classifications
		replace UNmemberstate = 0 if UNmemberstate == .
		drop _merge
		
* Generate modified M49 regional groupings
tab UN_continental_region
tab UN_subregion
tab UN_intermediary_region
gen fsci_regions = ""
	replace fsci_regions = "Northern Africa & Western Asia" if UN_subregion == "Northern Africa" | UN_subregion == "Western Asia"
	replace fsci_regions = "Sub-Saharan Africa" if UN_subregion == "Sub-Saharan Africa"
	replace fsci_regions = "Latin America & Caribbean" if UN_subregion == "Latin America and the Caribbean"
	replace fsci_regions = "Northern America and Europe" if UN_subregion == "Northern America" | UN_continental_region == "Europe"
	replace fsci_regions = "Central Asia" if UN_subregion == "Central Asia"
	replace fsci_regions = "Eastern Asia" if UN_subregion == "Eastern Asia"
	replace fsci_regions = "Southern Asia" if UN_subregion == "Southern Asia"
	replace fsci_regions = "South-eastern Asia" if UN_subregion == "South-eastern Asia"
	replace fsci_regions = "Oceania" if UN_continental_region == "Oceania"
	
tab2 country fsci_regions
					
		// Save
			save countryclassification, replace
			export delimited using countryclassification, replace
	
**# World Bank Population data
		import delimited using "$datain\API_SP.POP.TOTL_DS2_en_csv_v2_4554708", varnames(5)rowrange(5:271) clear
		ren v* totalpop#, addnumber(1960)
		ren countryname country
		ren countrycode ISO
		drop indicatorcode indicatorname
		drop totalpop2022
			* drop aggregations
			drop if inlist(ISO, "AFE", "AFW", "ARB", "CEB", "CSS", "EAP", "EAR", "EAS", "ECA")
			drop if inlist(ISO, "ECS", "EMU", "EUU", "FCS", "HIC", "HPC", "IBD", "IBT", "IDA")
			drop if inlist(ISO, "INX", "LAC", "INX", "LAC", "LCN", "LDC", "LIC", "LMC", "LMY")
			drop if inlist(ISO, "LTE", "MEA", "MIC", "MNA", "OED", "OSS", "PRE", "PSS", "PST")
			drop if inlist(ISO, "SSA", "SSF", "SST", "TEA", "TEC", "TLA", "TMN", "TSA", "TSS")
			drop if inlist(ISO, "UMC", "WLD", "IDB", "IDX", "NAC", "SAS")
		reshape long totalpop, i(country ISO) j(year)
		lab var totalpop "Total population (number)"

			// Merge in country classification
				replace ISO="_CH" if ISO=="CHI" // Channel Islands
				replace country = "Bahamas" if country == "Bahamas, The" 
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia" 
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep." 
				replace country = "Congo" if country == "Congo, Rep." 
				replace country = "Czechia" if country == "Czech Republic" 
				replace country = "Côte D'Ivoire" if ISO == "CIV"
				replace country = "Egypt" if country == "Egypt, Arab Rep." 
				replace country = "Gambia (Republic of The)" if country == "Gambia, The" 
				replace country = "Hong Kong" if country == "Hong Kong SAR, China" 
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep." 
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep." 
				replace country = "Republic of Korea" if country == "Korea, Rep." 
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic" 
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR" 
				replace country = "Macau" if country == "Macao SAR, China" 
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts." 
				replace country = "Republic of Moldova" if country == "Moldova" 
				replace country = "Slovakia" if country == "Slovak Republic" 
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis" 
				replace country = "Saint Lucia" if country == "St. Lucia" 
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines" 
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe" 
				replace country = "Taiwan" if country == "Taiwan, China" 
				replace country = "United Republic of Tanzania" if country == "Tanzania" 
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom" 
				replace country = "United States of America" if country == "United States" 
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB" 
				replace country = "Viet Nam" if country == "Vietnam" 
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
				replace country = "Yemen" if country == "Yemen, Rep." 
				replace country = "Türkiye" if country == "Turkiye"
				replace country = "Palestine, State of" if country == "West Bank and Gaza"
				replace country = "Curaçao" if country == "Curacao"
			merge m:1 ISO country using countryclassification
				browse if _merge!=3
					/* Drop territories recorded by World Bank but not UN
						Kosovo
						Channel Islands --- only includes aggregate not individual islands as captured by UN
					*/
				drop if _merge != 3
				drop _merge

		// Save
		save population, replace
		export delimited using population, replace
		
		
**# World Bank GDP data
	import delimited using "$datain\API_NY.GDP.MKTP.CD_DS2_en_csv_v2_4578252.csv", rowrange(5:271) varnames(5) clear 
	drop indicatorcode indicatorname
	ren v* y#, addnum(1960)
	reshape long y, i(countrycode countryname) j(year)
	ren y GDP
	ren countrycode ISO
		
		// Merge in GDP per capita
		preserve
			import delimited using "$datain\API_NY.GDP.PCAP.CD_DS2_en_csv_v2_4578209", rowrange(5:271) varnames(5) clear 
			drop indicatorcode indicatorname
			ren v* y#, addnum(1960)
			reshape long y, i(countrycode countryname) j(year)
			ren y GDP_percap
			ren countrycode ISO
			tempfile gdppercap
				save `gdppercap'
		restore
		merge 1:1 ISO year using `gdppercap'
		drop _merge
			// drop regional groupings
			drop if inlist(ISO, "AFE", "AFW", "ARB", "CEB", "CSS", "EAP", "EAR", "EAS")
			drop if inlist(ISO, "ECA", "ECS", "EMU", "EUU", "FCS", "HIC", "HPC", "IBD")
			drop if inlist(ISO, "IBT", "IDA", "IDX", "INX", "LAC", "LCN", "LDC", "LIC")
			drop if inlist(ISO, "LMC", "LMY", "LTE", "MEA", "MIC", "MNA", "NAC", "OED") 
			drop if inlist(ISO, "OSS", "PRE", "PSS", "PST", "SAS", "SSA", "SSF", "SST")
			drop if inlist(ISO, "TEA", "TEC", "TLA", "TMN", "TSA", "TSS", "UMC", "WLD")
			drop if ISO=="IDB"
			
			// Merge with region and income group - to address match issues
			ren countryname country
			// Merge in country classification
				replace ISO="_CH" if ISO=="CHI" // Channel Islands
				replace country = "Bahamas" if country == "Bahamas, The" 
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia" 
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep." 
				replace country = "Congo" if country == "Congo, Rep." 
				replace country = "Czechia" if country == "Czech Republic" 
				replace country = "Côte D'Ivoire" if ISO == "CIV"
				replace country = "Egypt" if country == "Egypt, Arab Rep." 
				replace country = "Gambia (Republic of The)" if country == "Gambia, The" 
				replace country = "Hong Kong" if country == "Hong Kong SAR, China" 
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep." 
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep." 
				replace country = "Republic of Korea" if country == "Korea, Rep." 
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic" 
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR" 
				replace country = "Macau" if country == "Macao SAR, China" 
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts." 
				replace country = "Republic of Moldova" if country == "Moldova" 
				replace country = "Slovakia" if country == "Slovak Republic" 
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis" 
				replace country = "Saint Lucia" if country == "St. Lucia" 
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines" 
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe" 
				replace country = "Taiwan" if country == "Taiwan, China" 
				replace country = "United Republic of Tanzania" if country == "Tanzania" 
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom" 
				replace country = "United States of America" if country == "United States" 
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB" 
				replace country = "Viet Nam" if country == "Vietnam" 
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
				replace country = "Yemen" if country == "Yemen, Rep." 
				replace country = "Türkiye" if country == "Turkiye"
				replace country = "Palestine, State of" if country == "West Bank and Gaza"
				replace country = "Curaçao" if country == "Curacao"

			merge m:1 ISO country using countryclassification
				browse if _merge!=3
					/* Drop territories recorded by World Bank but not UN
						Kosovo
						Channel Islands
					*/
				drop if _merge != 3
				drop _merge
			tab country
			lab var GDP "Gross domestic product (current US$)"
			lab var GDP_percap "Gross domestic product per capita (current US$ / capita)"
		
		// Save
		save GDP, replace
		export delimited using GDP, replace

		
**# Land area 
		import delimited using "$datain\FAOSTAT_landarea.csv", clear
		drop domaincode domain elementcode element itemcode yearcode flag flagdescription
		ren area country
		drop if country == "China" // drop aggregate China value to avoid double counting
			* Note units
			tab2 item unit // all in 1000 ha
		drop unit 
		tab item
		encode item, gen(item2)
		tab item, sum(item2)
		drop item
		reshape wide value, i(areacodeiso3 country year) j(item2)
		ren value1 agland_area
		ren value2 cropland
		ren value3 landarea 
			* Convert unit to square km
			foreach v in agland_area cropland landarea{
				replace `v' = `v' / 100		
			}
			lab var agland_area "Agricultural land (land used for cultivation of crops and animal husbandry, includes permanent pasture) (sq. km)"
			lab var cropland "Cropland (land used for cultivation of crops, includes permanent crops) (sq. km)"
			lab var landarea "Land area (sq. km)"
			
			// Merge in country classification
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "French Guiana" if country == "French Guyana"
			replace country = "Palestine, State of" if country == "Palestine"
			replace country = "Reunion" if country == "Réunion"
			replace country = "Saint Helena" if country == "Saint Helena, Ascension and Tristan da Cunha"
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
			replace country = "Saint Martin (French part)" if country == "Saint-Martin (French part)"
			replace country = "Turks and Caicos Islands (the)" if country == "Turks and Caicos Islands"
			replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
			merge m:1 country using iso
				browse if _merge!=3
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			drop if _merge!=3
			drop _merge
			merge m:1 country ISO using	countryclassification
			browse if _merge!=3
			drop if _merge!=3 // historical country names have no data
			drop _merge 
			sort ISO year
				tab country
			browse if ISO != areacodeiso3
			drop areacodeiso3
		
		// Save
		save landarea, replace
		export delimited using landarea, replace

		
// DIETS, NUTRITION, & HEALTH //////////////////////////////////////////////////

** Manage main DQQ dataset
		import excel using "$datain\DQQ Indicators 2021.xlsx", firstrow clear
		tab Indicator
		ren MeanPrevalence Mean_Prevalence
		ren Lowerconfidenceinterval LCI
		ren Upperconfidenceinterval UCI
		tab Subgroup
		keep if Subgroup == "All"
		drop Subgroup Region Incomeclassification
		ren Country country
		encode Indicator, gen(Variable)
		ren Indicator indicator_label
		tab Variable, sum(Variable)
		** Keep variables selected for the FSCI:
			* MDD-W
			* GDR score
			* NCD-Protect
			* NCD-Risk
			* Sugar-sweetened soft drink consumption (NOTE: do not select sugar-sweetened beverages, which also includes sugar added to coffee and tea and fruit juice and is not selected for the FSCI)
			* Zero fruits or vegetables
		keep if inlist(Variable, 1, 19, 21, 24, 25, 37, 48)
		tab Variable, sum(Variable)
		recode Variable (19=2) (21=3) (24=4) (25=5) (37=6) (48=7)
		tab indicator_label, sum(Variable)
		gen indicator = "All5" if Variable == 1
			replace indicator = "GDR_score" if Variable == 2
			replace indicator = "MDD_W" if Variable == 3
			replace indicator = "NCD_P" if Variable == 4
			replace indicator = "NCD_R" if Variable == 5
			replace indicator = "SSSD" if Variable == 6
			replace indicator = "NoFV" if Variable == 7
			drop Variable
		sort country indicator
			tempfile DQQlong
			save `DQQlong', replace
		drop LCI UCI indicator_label
		reshape wide Mean_Prevalence, i(ISO3 country) j(indicator) string
		ren Mean_Prevalence* *
			tempfile DQQmean
			save `DQQmean', replace
		use `DQQlong', clear 
		drop indicator_label Mean_Prevalence UCI 
		reshape wide LCI, i(ISO3) j(indicator) string
		ren LCI* *_LCI
			tempfile DQQLCI
			save `DQQLCI', replace
		use `DQQlong', clear 
		drop indicator_label Mean_Prevalence LCI 
		reshape wide UCI, i(ISO3) j(indicator) string
		ren UCI* *_UCI
			tempfile DQQUCI
			save `DQQUCI', replace
		use `DQQmean', clear
		merge 1:1 ISO3 using `DQQLCI'
		drop _merge
		merge 1:1 ISO3 using `DQQUCI'
			drop _merge
			destring, replace
			order ISO3 All5* NCD_P* NCD_R* GDR_score* NoFV* SSSD* MDD*
			lab var All5 "All-5 (%)" 
			lab var NCD_P "NCD-Protect Score (0-9)"
			lab var NCD_R "NCD-Risk Score (0-9)"
			lab var GDR_score "GDR Score (0-18)"
			lab var NoFV "Zero fruit or vegetables (%)"
			lab var SSSD "Sugar-sweetened soft drink consumption (%)"
			lab var MDD_W "Minimum Dietary Diversity-Women (%)"
			tab NoFV
			tab SSSD
			ren ISO3 ISO
			gen year=2021
			replace country = "Lao People's Democratic Republic" if country == "Laos"
			replace country = "Russian Federation" if country == "Russia"
			replace country = "United Republic of Tanzania" if country == "Tanzania"
			replace country = "United States of America" if country == "United States"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Viet Nam" if country == "Vietnam"
			merge 1:1 ISO country using countryclassification
			drop if _merge==2
			drop _merge
			ren No* zero* // rename NoFV to match IYCF ZeroFV indicator
			* convert all percentage variables to a 0-100 scale
			sum
		foreach v of varlist All* zero* SSSD* MDD* {
			replace `v'=`v'*100
			}
			sum
		save DQQ_2021, replace

	
** FOOD ENVIRONMENTS ***********************************************************

**# Cost of a healthy diet (FAO)
		import delimited using "$datain\FAOSTAT_CAHD.csv", clear
		ren area country
		drop if country == "China" // drop aggregate China value to avoid double counting
		drop domaincode domain areacode elementcode element itemcode yearcode flag flagdescription
		encode item, gen(item2)
		tab item2
		tab item2, nolabel
		drop item
		ren item2 item
		tab unit
		tab2 item unit
		drop unit
		reshape wide value, i(country year) j(item)
		ren value1 cohd
		ren value2 pctcantafford
		lab var cohd "Cost of a healthy diet (current PPP$/cap/day)"
		lab var pctcantafford "Percent of the population who cannot afford a healthy diet"
			
			// Merge in country classification
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "Turks and Caicos Islands (the)" if country == "Turks and Caicos Islands"
			merge m:1 country using iso
				browse if _merge != 3 // Palestine
				drop if _merge!=3
				drop _merge
				replace country = "Turks and Caicos Islands" if country == "Turks and Caicos Islands (the)"
			merge m:1 country ISO using countryclassification
			drop if _merge!=3
			drop _merge
			merge m:1 country ISO using	countryclassification
			browse if _merge!=3
			drop if _merge!=3 
			drop _merge 
			sort ISO year
				tab country
				
		// Save
		save costofdiet, replace
		export delimited using costofdiet, replace
		
**# Availability of fruits and vegetables (kg/capita) (FAO)
		import delimited using "$datain\FAOSTAT_FruitVegetableAvailability_2010-2019.csv", clear
		ren area country
		drop if country == "China" // drop aggregate China value to avoid double counting
		ren value availability 
		lab var availability "Availability (kg/capita/yr)"
		drop domaincode domain areacode elementcode element itemcode yearcode flag flagdescription
		encode item, gen(item2)
		tab item2
		tab item2, nolabel
		drop item
		reshape wide availability, i(country year) j(item2)
		ren availability1 avail_fruits
		ren availability2 avail_veg
		lab var avail_fruits "Fruits availability (kg/capita/yr)"
		lab var avail_veg "Vegetables availability (kg/capita/yr)"
			
			// Merge in country classification
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			drop if _merge!=3
			drop _merge
			merge m:1 country ISO using	countryclassification
			browse if _merge!=3
			drop if _merge!=3 // historical country names have no data
			drop _merge unit
			sort ISO year
				tab country
			
			// Convert from kg/capita/year to grams per person per day
			replace avail_fruits = avail_fruits * 1000 / 365
			replace avail_veg = avail_veg * 1000 / 365
			lab var avail_fruits "Fruits availability (grams/capita/day)"
			lab var avail_veg "Vegetables availability (grams/capita/day)"

		// Save
		save fruitveg_availability, replace
		export delimited using fruitveg_availability, replace

**# Retail value of ultra-processed foods (Euromonitor)
		import excel using "$datain\Euromonitor Datasets for GAIN_07-07-21 v3.xlsx", clear sheet("Ultraprocessedfood US$") firstrow
			* Note currency is in nominal US$
		ren G UPFretailval2017
		ren H UPFretailval2018
		ren I UPFretailval2019
		drop J-O
		ren Geography country
		drop if country == ""
		reshape long UPFretailval, i(country Category DataType Unit CurrencyConversion CurrentConstant) j(year)
		foreach v in Category DataType Unit CurrencyConversion CurrentConstant {
			tab `v'
		}
		lab var UPFretailval "Retail value of ultra-processed foods, US$ millions (current dollars)"
			* Note currency converted from local currency to US$ value using year on year exchange rates
		drop Category DataType Unit CurrencyConversion CurrentConstant
			
			// Merge in ISO and WB income and region classification
			replace country = "Democratic Republic of the Congo" if country == "Congo, Democratic Republic"
			replace country = "Iran (Islamic Republic of)" if country == "Iran"
			replace country = "Congo" if country == "Congo-Brazzaville"
			replace country = "Lao People's Democratic Republic" if country == "Laos"
			replace country = "Republic of Moldova" if country == "Moldova"
			replace country = "Dem People's Rep of Korea" if country == "North Korea"
			replace country = "Russian Federation" if country == "Russia"
			replace country = "Sao Tome and Principe" if country == "Sao Tomé e Príncipe"
			replace country = "Saint Kitts and Nevis" if country == "St Kitts and Nevis"
			replace country = "Saint Lucia" if country == "St Lucia"
			replace country = "Saint Vincent and the Grenadines" if country == "St Vincent and the Grenadines"
			replace country = "Republic of Korea" if country == "South Korea"
			replace country = "Syrian Arab Republic" if country == "Syria"
			replace country = "United Republic of Tanzania" if country == "Tanzania"
			replace country = "United States Virgin Islands" if country == "US Virgin Islands"
			replace country = "United States of America" if country == "USA"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
			replace country = "Hong Kong" if country == "Hong Kong, China"
			replace country = "Macau" if country == "Macau, China"
			replace country = "Reunion" if country == "Réunion"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
			replace country = "Czechia" if country == "Czech Republic"
			replace country = "Viet Nam" if country == "Vietnam"
			replace country = "Curaçao" if country == "Curacao"
			replace country = "Sint Maarten (Dutch part)" if country == "Sint Maarten"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
				browse if _merge != 3
					/* Drop territories not classified in GAUL 				
						Kosovo
					*/
				drop if _merge !=3
				drop _merge
				sort ISO year
				order ISO country year wb_region incgrp UPFretailval
*Note: China value reflects mainland China only		

		// Merge in population to calculate per capita metric
			merge 1:1 ISO country year using population
			drop if _merge!=3
			drop _merge
			
		// Generate per capita
			gen UPFretailval_percap = UPFretailval / totalpop
			
		// Change units from millions to dollars
			replace UPFretailval_percap = UPFretailval_percap * 1000000
			lab var UPFretailval_percap "Retail value of ultra-processed foods per capita per year, US$ (current dollars)"

		// Save
		save UPFretailval, replace
		export delimited using UPFretailval, replace

**# % population using safely managed drinking water services (SDG 6.1.1) (WHO/UNICEF Joint Monitoring Programme)
		import excel using "$datain\JMP_2021_WLD.xlsx", sheet("Water") cellrange(A3:AA4917) firstrow clear
			ren A country
			ren ISO3 ISO
			ren C year
			drop D-T
			ren (Safelymanaged Accessibleonpremises Availablewhenneeded Freefromcontamination Piped Nonpiped) (safeh20 onpremise whenneeded uncontaminated piped nonpiped)
			lab var safeh20 "Proportion of population using safely managed drinking water source (SDG 6.1.1)"
			replace country = "Faroe Islands" if country == "Faeroe Islands"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Reunion" if country == "Réunion"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
			replace country = "Czechia" if country == "Czech Republic"
			replace country = "Viet Nam" if country == "Vietnam"
			replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
			replace country = "Palestine, State of" if country == "State of Palestine"
			replace country = "Saint Martin (French Part)" if country == "Saint Martin (French part)"
			replace country = "Bonaire, Sint Eustatius and Saba" if country == "Caribbean Netherlands"
			replace country = "Saint Barthélemy" if country == "Saint Barthelemy"
			merge m:1 ISO country using countryclassification
				browse if _merge!=3
				drop if _merge != 3 
				/* Territories with data that are dropped:
						Channel Islands
				*/
			drop _merge
			sort ISO year
			foreach v in safeh20 onpremise whenneeded uncontaminated Annualrateofchangeinsafely piped nonpiped {
				replace `v'="" if `v'=="-"
				replace `v'="0.1" if `v'=="<1"
				replace `v'="99.9" if `v'==">99"
			}
			destring safeh20 onpremise whenneeded uncontaminated Annualrateofchangeinsafely piped nonpiped, replace
			drop onpremise whenneeded uncontaminated Annualrateofchangeinsafely piped nonpiped
*Note: China value reflects mainland China only			

		// Save
		save safewater, replace
		export delimited using safewater, replace

		
** FOOD SECURITY ***************************************************************

**# % population experiencing moderate or severe food insecurity (FAO)
		import delimited using "$datain\FAOSTAT_FoodInsecurity.csv", clear
			destring, replace
			drop if value==. // most observations are rows with no data - see original excel, these are not meaningful missing values
			ren area country
			tab year
			ren year fies_yearrange
			lab var fies_yearrange "FIES 3-year period"
			encode fies_yearrange, gen(year)
			tab year
			tab year, nolabel
			recode year (1=2015) (2=2016) (3=2017) (4=2018) (5=2019) (6=2020) // when merging with other datasets, observation identified by the middle year of the 3-year average (e.g., 2015 takes the value of the 2014-2016 average, 2016 takes the value of the 2015-2017 average)
			sort country year 
			encode item, gen(disagg)
			tab disagg
			tab disagg, nolabel
			keep if disagg == 3 // total population
			drop domaincode domain areacodem49 elementcode element itemcode item yearcode flag flagdescription note disagg
			ren value fies_modsev
			lab var fies_modsev "Prevalence of experiencing moderate or severe food insecurity (FIES-based; % population)"
				
			// Merge in ISO codes
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "Palestine, State of" if country == "Palestine"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
			drop if _merge != 3 
			drop _merge
			order ISO country year fies_yearrange fies_modsev wb_region incgrp
*Note: no China data		
		// Save 
			save FIES_modsev, replace 
			export delimited using FIES_modsev, replace

**# % population who cannot afford a healthy diet (FAO)
		use costofdiet, clear

**# PoU: Prevalence of Undernourishment (FAO)
		import delimited using "$datain\FAOSTAT_POUndernourishment.csv", clear
			ren area country
			tab year
			drop if value == "" // eliminates the single year observations - have no data for the indicator
			tab year
			ren year pou_yearrange
			lab var pou_yearrange "POU 3-year period"
			encode pou_yearrange, gen(year)
			tab year
			tab year, nolabel
			forval i=1/20 { 
					local n=2000+(`i')
					recode year (`i'=`n')
				}
			tab year
			tab year, nolabel
				* when merging with other datasets, observation identified by the middle year of the 3-year average (e.g., 2015 takes the value of the 2014-2016 average, 2016 takes the value of the 2015-2017 average)
			drop domaincode domain areacodem49 elementcode element itemcode item yearcode flag flagdescription note
			ren value pou
			lab var pou "Prevalence of undernourishment (% population)"
			drop if country == "China" // Drop aggregated China to avoid double counting
				
				// Merge in ISO codes
					replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
					replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
					replace country = "Gambia (Republic of The)" if country == "Gambia"
					replace country = "China" if country == "China, mainland"
					replace country = "Hong Kong" if country == "China, Hong Kong SAR"
					replace country = "Taiwan" if country == "China, Taiwan Province of"
					replace country = "Macau" if country == "China, Macao SAR"
					replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
					drop if _merge != 3 
					drop _merge
					// Convert POU to numeric 
					tab pou
					tab country if pou=="<2.5"
					ren pou pou_string
					gen pou=pou_string
					replace pou="2.5" if pou=="<2.5" // NOTE: Observations of less than 2.5 have been recoded as 2.5 to allow for quantitative analysis, however the value name should be corrected in all visualizations
					destring pou, replace
					lab var pou "Prevalence of undernourishment (% population)"
					drop unit 
					sort ISO year
					tab country

		// Save 
			save POU, replace 
			export delimited using POU, replace

		
** DIET QUALITY ****************************************************************

**# MDD-W: % women age 15-49 years meeting minimum dietary diversity (Gallup World Poll)
		use DQQ_2021, clear
		keep ISO MDD_W* country year incgrp wb_region ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
		sort ISO
		order ISO country year MDD* wb_region incgrp
			
		// Save
			save MDD_W_2021, replace
			export delimited using MDD_W_2021, replace

**# MDD (IYCF): % children 6-23 months meeting minimum dietary diversity (UNICEF)
		import excel using "$datain\UNICEF_Expanded_Global_Databases_Diets_6_23months_2021.xlsx", sheet("MDD trends") cellrange(A7) clear
			keep B C G H I J M R W AB AG // Total values (point estimate) and disaggregations by sex and urban-rural retained (age groups, wealth quintile, and maternal education are not preserved in our dataset at this point)
			ren B ISO
			ren C country
			ren G datasource_year
			ren H year
			ren I source1	
			ren J source2
			ren M MDD_iycf
				lab var MDD_iycf "MDD, children 6-23 months (%)"
			ren R MDD_iycf_m
				lab var MDD_iycf_m "MDD, children 6-23 months (male, % male population)"
			ren W MDD_iycf_f
				lab var MDD_iycf_f "MDD, children 6-23 months (female, % female population)"
			ren AB MDD_iycf_u
				lab var MDD_iycf_u "MDD, children 6-23 months (urban, % urban population)"
			ren AG MDD_iycf_r
				lab var MDD_iycf_r "MDD, children 6-23 months (rural, % rural population)"
			drop in 1/3 // excel multiline headers
			sort ISO year
			tab2 datasource_year year
			destring, replace
			duplicates tag ISO year, gen(dup)
			tab dup
			browse if dup == 1 // Chad has 2 values for 2019, one from MICS that is complete and one from SMART that does not have urban-rural disaggregation - decision to keep MICS source only
			drop if dup == 1 & year == 2019 & source1 == "SMART"
			drop dup
				
			// Merge in classifications
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Palestine, State of" if country == "State of Palestine"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
				merge m:1 ISO country using countryclassification
					browse if _merge !=3
					drop if _merge!=3 
					drop _merge
			
			// Save
			save MDD_youngchild, replace
			
			// Keep only latest data point per country
				unique country
				// Save labels
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}
					collapse (last) year source1 source2 MDD_iycf MDD_iycf_m MDD_iycf_f MDD_iycf_u MDD_iycf_r, by(ISO country)
					// Relabel
						foreach v of var * {
						label var `v' "`l`v''"
							}
					unique country
				export delimited using MDD_youngchild_latestyear, replace
				
			// Merge MDD-W and MDD-IYCF for joint visualization - data on children are from different years, so joint viz with v=caveats
				use MDD_youngchild, clear
				drop source*
				merge m:1 ISO country using MDD_W_2021, force
				tab country if _merge==2 // GQQ countries with no UNICEF data on children
				browse if _merge!=3
				keep if _merge==3
				drop _merge
				tab country
				keep ISO country year MDD_iycf MDD_W wb_region incgrp ISO_governing UN_status_detail UNmemberstate UN_status territoryof
				by ISO, sort: egen mostrecent=max(cond(MDD_iycf!=., year, .))
				keep if year==mostrecent
				drop mostrecent 
				tab year
				lab var MDD_W "Minimum Dietary Diversity-Women, 2021 (%)" 
				tab country, sum(year)
				ren year IYCF_year
				lab var IYCF_year "Year of MDD-IYCF data collection"
		
		// Save
		export delimited using MDD_combined, replace
	
**# All-5: % adult population consuming all 5 food groups (Gallup World Poll)
		use DQQ_2021, clear
		keep ISO All* year wb_region incgrp country ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
		sort ISO
		order ISO country year All* wb_region incgrp
		
		// Save
		save All5_2021, replace
		export delimited using All5_2021, replace

**# % adult population consuming zero fruits or vegetables  (Gallup World Poll)
		use DQQ_2021, clear
		keep ISO zero* year wb_region incgrp country ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
		sort ISO
		order ISO country year zero* wb_region incgrp
		
		// Save
		save ZeroFV_adult_2021, replace
		export delimited using ZeroFV_adult_2021, replace

**# % children 6-23 month consuming zero fruits or vegetables (UNICEF)
		import excel using "$datain\UNICEF_Expanded_Global_Databases_Unhealthy_practices_2021.xlsx", sheet("Zero Fruits and Vegetables") cellrange(A7) clear
			keep B C G H I J M R W AB AG // Total values (point estimate) and disaggregations by sex and urban-rural retained (age groups, wealth quintile, and maternal education are not preserved in our dataset at this point)
			ren B ISO
			ren C country
			ren G datasource_year
			ren H year
			ren I source1	
			ren J source2
			ren M zeroFV_iycf
				lab var zeroFV_iycf "Zero fruits and vegetables, children 6-23 months (%)"
			ren R zeroFV_iycf_m
				lab var zeroFV_iycf_m "Zero fruits and vegetables, children 6-23 months (male, % male population)"
			ren W zeroFV_iycf_f
				lab var zeroFV_iycf_f "Zero fruits and vegetables, children 6-23 months (female, % female population)"
			ren AB zeroFV_icyf_u
				lab var zeroFV_icyf_u "Zero fruits and vegetables, children 6-23 months (urban, % urban population)"
			ren AG zeroFV_icyf_r
				lab var zeroFV_icyf_r "Zero fruits and vegetables, children 6-23 months (rural, % rural population)"
			drop in 1/3 // excel multiline headers
			sort ISO year
			destring, replace
			drop if ISO=="" & zeroFV_iycf==. & year==.
			duplicates tag ISO year, gen(dup)
			tab dup
			browse if dup == 1 // Chad has 2 values for 2019, one from MICS that is complete and one from SMART that does not have urban-rural disaggregation - decision to keep MICS source only
			drop if dup == 1 & year == 2019 & source1 == "SMART"
			drop dup
			
			// Merge in classifications
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Palestine, State of" if country == "State of Palestine"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
				merge m:1 ISO country using countryclassification
					browse if _merge != 3
					drop if _merge!=3 
					drop _merge
		
		// Save
		save ZeroFV_youngchild, replace
	
		// Keep latest data point per country
		unique country
		// Save labels
			foreach v of var * {
			local l`v' : variable label `v'
				if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
			collapse (last) datasource_year year source1 source2 zeroFV_iycf zeroFV_iycf_m zeroFV_iycf_f zeroFV_icyf_u zeroFV_icyf_r, by(ISO country)
			// Relabel
				foreach v of var * {
				label var `v' "`l`v''"
					}
		unique country
		export delimited using ZeroFV_youngchild_latestyear, replace
	
		// Merge zero FV for adults and young children for joint visualization - data on children are from different years, so joint viz with caveats
		use ZeroFV_youngchild, clear
			drop source*
			merge m:1 ISO using ZeroFV_adult_2021, force
			tab country if _merge==2 // GQQ countries with no UNICEF data on children
			browse if _merge!=3
			keep if _merge==3
			drop _merge
			tab country
			keep ISO country year zeroFV_iycf zeroFV wb_region incgrp ISO_governing UN_status_detail UNmemberstate UN_status territoryof
			by ISO, sort: egen mostrecent=max(cond(zeroFV_iycf!=., year, .))
			keep if year==mostrecent
			drop mostrecent 
			tab year
			lab var zeroFV "Zero fruit or vegetables (adults), 2021 (%)" 
			tab country, sum(year)
			ren year IYCF_year
			lab var IYCF_year "Year of MDD-IYCF data collection"
			
		// Save
		export delimited using ZeroFV_combined, replace

**# NCD-Protect and NCD-Risk (Gallup World Poll)
		use DQQ_2021, clear
			keep ISO NCD* GDR* year wb_region incgrp country ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
			sort ISO
			order ISO country year NCD* GDR* wb_region incgrp
			drop GDR_score*
		
		// Save
		save NCDP-NCDR_adult_2021, replace
		export delimited using NCDP-NCDR_adult_2021, replace
		
**# Sugar-sweetened soft drink consumption (Gallup World Poll)
		use DQQ_2021, clear
			keep ISO SSSD* year wb_region incgrp country ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
			sort ISO
			order ISO country year SSSD* wb_region incgrp
		
		// Save
		save SSSD_adult_2021, replace
		export delimited using SSSD_adult_2021, replace
	
	
// ENVIRONMENT, NATURAL RESOURCES, & PRODUCTION ////////////////////////////////

** GHG EMISSIONS ***************************************************************

**# Greenhous gas emissions (total)
		import delimited using "$datain\FAOSTAT_EmissionsFS.csv", clear 
		ren value fs_emissions
		lab var fs_emissions "Agri-food systems greenhouse gas emissions (kT CO2eq) (AR5)"
		drop domaincode domain areacodem49 elementcode element itemcode item yearcode unit flag flagdescription sourcecode source note
		ren area country

		// Replace ISO codes for historic states to harmonize with WB dataset
			drop if country == "China" // drop aggregate China value to avoid double counting
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "Palestine, State of" if country == "Palestine"
			replace country = "Reunion" if country == "Réunion"
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
			replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
			replace country = "French Guiana" if country == "French Guyana"

		
		// Merge in region and income group
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
					/* Territories with non-zero data dropped: Channel Islands,
					Saint Helena et al	*/
				drop if _merge != 3 // Historic states and territories named above
				drop _merge

	// Save
		save fsemissions, replace
		export delimited using fsemissions, replace

**# Greenhouse gas emissions intensity
		import delimited using "$datain\FAOSTAT_EmissionsIntensities.csv", clear
			ren item product
			drop domaincode domain areacodem49 elementcode itemcode yearcode unit flag flagdescription
			ren area country
			encode product, gen(product2)
			drop product
			tab product2
			encode element, gen(variable)
			drop element
			reshape wide value, i(country year product2) j(variable)	
			ren value1 emiss_ 
			ren value2 emint_
			ren value3 prod_	
			reshape wide emiss_ emint_  prod_, i(country year) j(product2)
			foreach v of varlist emint_* {
				lab var `v' "Emissions intensity, kg Co2eq/kg product"
			}
			foreach v of varlist prod_* {
				lab var `v' "Total production (tonnes)"
			}
			foreach v of varlist emiss_* {
				lab var `v' "Total emissions (CO2 eq) (AR5)"
			}
		
		// Merge in region and income group
		drop if country == "China" // drop aggregate China value to avoid double counting
			replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "Palestine, State of" if country == "Palestine"
			replace country = "Reunion" if country == "Réunion"
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
			replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
			replace country = "French Guiana" if country == "French Guyana"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
				drop if _merge !=3 // historic states
				drop _merge
		
		// Further clean
			*(names can be confirmed based on tabulation of product variable before first reshaping)
			ren (emiss_#) (emiss_cerealsnorice emiss_eggs emiss_beef emiss_chickenmeat emiss_pork emiss_cowmilk emiss_rice)
			ren (emint_#) (emint_cerealsnorice emint_eggs emint_beef emint_chickenmeat emint_pork emint_cowmilk emint_rice)
			ren (prod_#) (prod_cerealsnorice prod_eggs  prod_beef prod_chickenmeat prod_pork prod_cowmilk prod_rice)
			foreach v of varlist emint_* {
				lab var `v' "Emissions intensity, kg Co2eq/kg product"
			}
			foreach v of varlist prod_* {
				lab var `v' "Total production (tonnes)"
			} 
		* Drop production variables that will be duplicated in yield dataset
		drop prod_eggs prod_beef prod_chickenmeat prod_pork prod_cowmilk
			
		// Save
		save emissions_intensity, replace
		export delimited using emissions_intensity, replace

		
** PRODUCTION ******************************************************************

**# Food product yield per food group (FAO)
		* Import total product to add products not included in emissions intensity series
		import delimited using "$datain\FAOSTAT_Production_1961-2020.csv", clear
			tempfile prod
			save `prod'
		import delimited using "$datain\FAOSTAT_Yields_1961-2020.csv", clear
			append using `prod'
			preserve
				* Merge in area harvested and number of animals for weighted average
				import delimited using "$datain\FAOSTAT_AreaAnimalsProducing.csv", clear
				tempfile area
				save `area'
			restore
			append using `area'
		drop domaincode domain elementcode yearcode flag flagdescription itemcodecpc areacodem49
		ren area country
		ren item product
		encode product, gen(product2)
		drop product
		tab product2
		encode element, gen(var)
		tab var
		tab var, nolabel
				replace var = 4 if inlist(var, 2,3) // for eggs and milk, recode to match meats producing animals
				replace var = 6 if var == 7 // for meat, recode element to match crops yield
				tab var
		drop element
		drop if value == .
		tab var, sum(var) // note frequencies here for check after recoding
		describe var
		lab drop var
		recode var (1=3) (2=4) (5=1) (6=2)
			lab def var 1 "Production" 2 "Yield" 3 "Area harvested" 4 "Producing/slaughted animals"
			lab val var var
			tab var // Confirm correct relabeling by comparing frequencies with table above
		tab2 unit product2 if var == 1 // Production
		tab2 unit product2 if var == 2 // Yield
		tab2 unit product2 if var == 3 // Area
		tab2 unit product2 if var == 4 // Number
				* drop duplicate units
				duplicates tag country year product2 var, gen(dups)
				tab dups
				tab2 unit product2 if dups == 1 & var == 1
				drop if unit == "1000 No" & product2 == 4 & var == 1 & dups == 1
				tab2 unit product2 if dups == 1 & var == 2
				drop if unit == "No/An" & product2 == 4 & var == 2 & dups == 1
				drop dups
				* Convert head to to thousands
				replace value = value/1000 if var == 4 & unit == "Head" 
				replace unit = "1000 Head" if var == 4 & unit == "Head"
		reshape wide value unit, i(country year product2) j(var) 
		ren value1 production
		ren unit1 prod_unit
		ren value2 yield
		ren unit2 yield_unit
		ren value3 areaharvested
		ren unit3 areaharvest_unit
		ren value4 producinganimals
		ren unit4 prodanimals_unit
		tab product2
		tab product2, nolabel
		tab2 product2 yield_unit
		tab2 product2 prod_unit
		tab2 product2 areaharvest_unit
		tab2 product2 prodanimals_unit
			
			// Convert products in hectograms/ha to tonnes
			replace yield = yield / 10000 if yield_unit == "hg/ha" // note 4 values are 0 and are not replaced
			replace yield_unit = "tonnes/ha" if yield_unit == "hg/ha"
			
			// Convert products in hg/An to kg/animal
			replace yield = yield / 10 if yield_unit == "hg/An"
			replace yield_unit = "kg/animal" if yield_unit == "hg/An"
			
			// Convert yield from 100mg / animal to kg / animal (** Note egg yield unit in FAOSTAT changed from grams to mg in 2022)
			replace yield = yield / 1000000 if yield_unit == "100mg/An"
			replace yield_unit = "kg/animal" if yield_unit == "100mg/An"
			
			// Convert yield from .1g / animal to kg / animal (0.1g = 100 mg)
			replace yield = yield / 1000000 if yield_unit == "0.1g/An"
			replace yield_unit = "kg/animal" if yield_unit == "0.1g/An"
			
			tab2 product2 yield_unit
			tab2 product2 prod_unit
			drop if prod_unit == "1000 No" // Faroe Islands, production value = 0
				
			// Merge in country classification
				drop if country == "China" // drop aggregate China value to avoid double counting
				replace country = "China" if country == "China, mainland"
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "French Guiana" if country == "French Guyana"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Côte D'Ivoire" if country=="Côte d'Ivoire"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Reunion" if country == "Réunion"
				replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Türkiye" if country == "T?rkiye"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge != 3
					drop if _merge != 3
					drop _merge
				ren product2 product
				tab product, sum(product)
				rename production prod
				reshape wide prod prod_unit yield yield_unit areaharvest_unit areaharvested prodanimals_unit producinganimals, i(country year) j(product)
				ren (*10 *11 *12) (*_roottuber *_treenuts *_vegetables)				
				ren (*1 *2 *3 *4 *5 *6 *7 *8 *9) (*_cereals *_citrus *_fruit *_eggs *_beef *_chickenmeat *_pork  *_pulses *_cowmilk)
				lab var yield_cereals "Cereal yield, total (tonnes/ha)"
				lab var yield_citrus "Citrus fruit yield, total (tonnes/ha)"
				lab var yield_eggs "Eggs yield, primary (kg/animal)"
				lab var yield_fruit "Fruit yield, primary (tonnes/ha)"
				lab var yield_cowmilk "Milk yield, total (kg/animal)"
				lab var yield_pulses "Pulses yield, total (kg/ha)"
				lab var yield_roottuber "Roots & tubers yield, total (kg/ha)"
				lab var yield_treenuts "Treenuts yield, total (kg/ha)"
				lab var yield_vegetables "Vegetables yield, primary (tonnes/ha)"
				lab var yield_beef "Beef (meat) yield, primary (kg/animal)"
				lab var yield_chickenmeat "Chicken (meat) yield, primary (kg/animal)"
				lab var yield_pork "Pork (meat) yield, primary (kg/animal)"
				foreach v of varlist prod_* {
					lab var `v' "Total production (tonnes)"
				} 
				foreach v of varlist areaharvested* {
					lab var `v' "Area harvested (ha)"
				} 
				foreach v of varlist producinganimals* {
					lab var `v' "Producing/slaughtered animals (thousands)"
				} 

				drop *_unit*
				drop areaharvested_beef areaharvested_chickenmeat areaharvested_cowmilk areaharvested_eggs areaharvested_pork producinganimals_cereals producinganimals_citrus producinganimals_fruit producinganimals_pulses producinganimals_roottuber producinganimals_treenuts producinganimals_vegetables
		
		// Save
		save yield, replace
		export delimited using yield, replace
	
	
** LAND ************************************************************************

**# Cropland expansion
	import delimited using "$datain\FAOSTAT_cropland.csv", clear
	drop domaincode domain elementcode yearcode flag flagdescription itemcode areacodem49
	ren area country
	ren value cropland
	lab var cropland "Cropland area (1000 ha)"
				// Merge in country classification
				drop if country == "China" // drop aggregate China value to avoid double counting
				replace country = "China" if country == "China, mainland"
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "French Guiana" if country == "French Guyana"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Côte D'Ivoire" if country=="Côte d'Ivoire"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Reunion" if country == "Réunion"
				replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Türkiye" if country == "T?rkiye"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 
				replace country = "Netherlands" if country == "Netherlands (Kingdom of the)"
			merge m:1 country using iso
				drop if _merge!=3 // drops historic states and territories
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge != 3
					drop if _merge != 3
					drop _merge
		drop element item unit
	** Calculate expansion as 5 year average
		sort country year
		forval i = 1/5 {
		gen croplandchange`i' = .
			
		}
		
		forval year = 1966/2020 {
			replace croplandchange1 = cropland[_n] - cropland[_n-1] if year == `year' & croplandchange1 == . & country[_n] == country[_n-1]
			replace croplandchange2 = cropland[_n-1] - cropland[_n-2] if year == `year' & croplandchange2 == . & country[_n-1] == country[_n-2]
			replace croplandchange3 = cropland[_n-2] - cropland[_n-3] if year == `year' & croplandchange3 == . & country[_n-2] == country[_n-3]
			replace croplandchange4 = cropland[_n-3] - cropland[_n-4] if year == `year' & croplandchange4 == . & country[_n-3] == country[_n-4]
			replace croplandchange5 = cropland[_n-4] - cropland[_n-5] if year == `year' & croplandchange5 == . & country[_n-4] == country[_n-5]
		}
		
		gen croplandchange = (croplandchange1 + croplandchange2 + croplandchange3 + croplandchange4 + croplandchange5) / 5
		drop croplandchange1-croplandchange5
		* Convert to percentage change
		lab var croplandchange "Average in cropland, previous 5 years (1000 ha)"
		gen croplandchange_pct = (((cropland + croplandchange) / cropland)-1)*100
		lab var croplandchange_pct "Cropland change, 5-year average (%)"
		order country year cropland croplandchange croplandchange_pct
			// Save 
			save croplandexpansion, replace
			export delimited croplandexpansion, replace
	

** WATER ***********************************************************************

**# Agricultural water withdrawal as % of total renewable resources (AQUASTAT)
		import delimited "$datain\AQUASTAT_WaterPressure_1982-2018.csv", clear
			gen ISO=substr(area,1,3)
			tab ISO
			browse
			drop in 1263/1272 // footnote and empbty rows impored from csv
			gen country=substr(area,5,.)
			tab country
			drop area areaid variableid symbol md v9
			ren value agwaterdraw
			lab var agwaterdraw "Agricultural water withdrawal as % of total renewable resources"
				
				// Merge in country classification
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
				replace country = "Grenada" if country == "Grenade"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 
				merge m:1 ISO country using countryclassification
					browse if _merge!=3 
				drop if _merge != 3 
				drop _merge
				sort ISO year
				drop variablename
				order ISO country year agwaterdraw wb_region incgrp
				tab country

** Treatment of China???

			// Save
			save agwaterdraw, replace
			export delimited agwaterdraw, replace

			
** BIOSPHERE INTEGRITY *********************************************************

**# Functional integrity: % agricultural land with minimum level (10%) of natural habitat (DeClerck et al 2021)
		import delimited using "$datain\Apex2021_FullTable_GAUL.csv", clear
		ren adm0_name country
		lab var country "Country"
		foreach v in csiro68 ghm1 hfp4 lia ensb_thr3 natural integ1km10 {
			replace `v'="" if `v'=="NA"
		}
		destring, replace
		ren integ1km10 functionalintegrity
		lab var functionalintegrity "Share of agricultural land with at least 10% natural habitat (%)"
		drop csiro68 ghm1 hfp4 lia ensb_thr3 natural
		distinct country
		duplicates list country
		* note there are two records for West Bank that are not equal and a China/India record in addition to separate observations for each country
			drop if country=="West Bank" // exclude West Bank from analysis

					// Merge in country classification
					replace country = "Lao People's Democratic Republic" if country=="Lao PDR"
					replace country = "Pitcairn" if country == "Pitcairn Island"
					replace country = "Reunion" if country == "Réunion"
					replace country = "Turks and Caicos Islands" if country == "Turks and Caicos islands"
					replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
					replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
					replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
					replace country = "Gambia (Republic of The)" if country == "Gambia"
					replace country = "Türkiye" if country == "Turkey"
					replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "U.K. of Great Britain and Northern Ireland"
					replace country = "Cabo Verde" if country == "Cape Verde"
					replace country = "Czechia" if country == "Czech Republic"
					replace country = "Republic of Moldova" if country == "Moldova, Republic of"
					replace country = "Eswatini" if country == "Swaziland"
					replace country = "North Macedonia" if country == "The former Yugoslav Republic of Macedonia"
					replace country = "Iran (Islamic Republic of)" if country == "Iran  (Islamic Republic of)"
					drop if functionalintegrity == .
					merge 1:1 country using iso
					drop if _merge!=3
					drop _merge 
					merge 1:1 country ISO using countryclassification
						browse if _merge!=3
							* Drop Abyei
						drop if _merge!=3
						drop _merge
					gen year=2015
					sort ISO year
					replace ISO_governing = "JPN" if country == "Senkaku Islands"
					
			sum functionalintegrity
			* Convert to 0 to 100 scale
			replace functionalintegrity = functionalintegrity*100

			// Save
			save functionalintegrity, replace
			export delimited functionalintegrity, replace

**# Fishery health index progress score (Minderoo Foundation)
		import excel using "$datain\Global Fishing Index 2021 Data for Download V1.1.xlsx", sheet("Progress and Governance results") cellrange(A2:T144) firstrow clear
			ren Country country
			ren ISOCode ISO
			drop Region
			ren Progressscore fishhealth
				lab var fishhealth "Fisheries health progress score"
			encode Progressscoreadjusted, gen(fishhealth_adj)
				recode fishhealth_adj (1=0) (2=1)
				lab def yesno 0 "No" 1  "Yes", replace
				lab val fishhealth_adj yesno
				lab var fishhealth_adj "Indicates country with <10% of stocks assessed where fisheries health progress score has been capped at global median."
					** Note adjustment method: The country's Progress score was capped at the global median score (20.4 out of 100) ig less than 10% of its national catch was assessed
				drop Progressscoreadjusted
			gen year=2021
				lab var year "Year"
				
				// Merge in country classification
					replace country = "Micronesia (Federated States of)" if country == "Federated States of Micronesia"
					replace country = "Iran (Islamic Republic of)" if country == "Islamic Republic of Iran"
					replace country = "Pitcairn" if country == "Pitcairn Islands"
					replace country = "Turks and Caicos Islands" if country == "Turks and Caicos Island"
					replace country = "Taiwan" if country == "Taiwan (Province of China)"
					replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
					replace country = "Côte D'Ivoire" if ISO == "CIV"
					replace country = "Gambia (Republic of The)" if country == "Gambia"
					replace country = "Türkiye" if country == "Turkey"
					merge 1:1 ISO country using countryclassification
					browse if _merge!=3
						drop if _merge!=3 
						drop _merge
						sort ISO year
* Note: China value includes Macau. Taiwan is assessed separately. There are no data for Hong Kong.				
			
			// Save
				drop Overallgrade Dataavailability Stocksustainability Numberofstocksassessed Numberofsustainablestocks Numberofnationalstocks NumberofRFMOstocks Numberofstockswithofficiala Numberofstockswithnovelasse Totalreconstructedcatch19902 Totalcatchsustainable Totalcatchoverfished Totalcatchunassessed Nationalcatchassessed RFMOcatchassessed
				save fishhealth, replace
				export delimited fishhealth, replace

				
** POLLUTION *******************************************************************
**# Total pesticides per unit of land (kg/ha) (FAO)
	import delimited using "$datain\FAOSTAT_Pesticides_1990-2020", clear
		ren value pesticides 
		tab unit
		lab var pesticides "Total pesticides per unit of land (kg active ingredient/ha)"
		drop domaincode domain areacode elementcode element itemcode yearcode flag flagdescription
		ren area country
		
			// Merge in country classification
				drop if country == "China" // drop aggregate China value to avoid double counting
				replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "China" if country == "China, mainland"
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Reunion" if country == "Réunion"
				replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
				replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
				replace country = "French Guiana" if country == "French Guyana"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
					drop if _merge != 3 
				drop _merge item unit
				sort ISO year
				tab country

		// Save
			save pesticides, replace
			export delimited using pesticides, replace
	
**# Sustainable nitrogen management index (Zhang et al.)
		import excel using "$datain\SNMIcal", firstrow clear
			ren Area country
			ren Year year
			ren SNMI sustNO2mgmt
			lab var sustNO2mgmt "Sustainable nitrogen management index"
			
			// Merge in country classification
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 
				replace country = "French Guiana" if country == "French Guyana" 
				replace country = "Gambia (Republic of The)" if country == "Gambia" 
				replace country = "Palestine, State of" if country == "Palestine" 
				replace country = "Türkiye" if country == "Turkey" 
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)" 
	
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			* Note: value for China includes Hong Kong, Macau, and Taiwan
					browse if _merge!=3
					drop if _merge != 3 & !inlist(country, "Hong Kong", "Taiwan", "Macau")
					drop _merge
			// Apply China value to territories
				preserve
					keep if inlist(country, "China", "Hong Kong", "Taiwan", "Macau")
					expand 57 if inlist(country, "Hong Kong", "Taiwan", "Macau")
					egen v1 = seq(), by(country)
					replace v1 = v1+1960
					replace year = v1 if inlist(country, "Hong Kong", "Taiwan", "Macau")
					sort year country
					egen val = mean(sustNO2mgmt), by(year)
					replace sustNO2mgmt = val if inlist(country, "Hong Kong", "Taiwan", "Macau")
					drop if country == "China"
					drop v1 val
					tempfile ters
						save `ters', replace
				restore
				drop if inlist(country, "Hong Kong", "Taiwan", "Macau")
				append using `ters'
			
		// Save
			save sustNO2mgmt, replace
			export delimited sustNO2mgmt, replace

			
// LIVELIHOODS, POVERTY, & EQUITY //////////////////////////////////////////////

** POVERTY & INCOME ************************************************************

**# Share of agriculture in GDP (FAO)
		import delimited using "$datain\FAOSTAT_ShareAgricultureGDP.csv", clear
			ren area country
			ren value aginGDP
			tab item
			tab unit
			lab var aginGDP "Agriculture value added share of GDP (%) (SDG 2.a.1)"
			drop domaincode domain areacodem49 elementcode element itemcodesdg item yearcode unit flag flagdescription note
			
			// Merge in country classification
				drop if country == "China" // drop aggregate China value to avoid double counting
				replace country="Côte D'Ivoire" if country=="Côte d'Ivoire"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "China" if country == "China, mainland"
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Reunion" if country == "Réunion"
				replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
				replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"
				replace country = "French Guiana" if country == "French Guyana"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea" 

				drop if aginGDP == .
			
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
			drop if _merge != 3  
			drop _merge
				sort ISO year
				tab country
				sort ISO year
				order ISO country year aginGDP wb_region incgrp
				drop if aginGDP == .
			
			// Save
			save agshareGDP, replace
			export delimited using agshareGDP, replace

			
** EMPLOYMENT ******************************************************************

**# Unemployment rate, urban and rural (ILO)
* Note: ILO modelled estimates, November 2021 version
* Note: data are long form with totals and age and sex disaggregations, be careful of double counting
		import delimited using "$datain\UNE_2EAP_SEX_AGE_GEO_RT_A-full-2022-06-30.csv", clear
			ren ref_area ISO
			ren ref_arealabel country
			ren sex sex2
			encode sex2, gen(sex)
			drop sex2
			encode classif1label, gen(agegroup)
			drop classif1label
			encode classif2, gen(geog)
			drop classif2*
			ren time year
			ren obs_value unemp
			lab var unemp "Unemployment rate (ILO modelled estimates) (%)"
			drop source sourcelabel indicator indicatorlabel sexlabel classif1 obs_status obs_statuslabel
			lab var country "Country"
			lab var agegroup "Age group"
			tab sex
			tab sex, nolabel
			recode sex (3=0)
			lab def sex 1 "Female" 2 "Male" 0 "Total", replace
			lab val sex sex
			tab agegroup
			tab agegroup, nolabel
			recode agegroup (1=0) (2=1) (3=2)
			lab def ag 0 "Total population age 15+" 1 "Youth, age 15-24" 2 "Adults, age 25+", replace
			lab val agegroup ag
			tab geog 
			tab geog, nolabel
			recode geog (1=0) (2=1) (3=2)
			lab def geo 0 "Total" 1 "Rural" 2 "Urban", replace
			lab val geog geo
			lab var geog "Geography (urban/rural)"
			tab geog
			lab var sex "Sex"
			sort ISO year
		
		// Merge in country classification
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
			replace country = "Democratic Republic of the Congo" if country == "Congo, Democratic Republic of the"
			replace country = "Cabo Verde" if country == "Cape Verde"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Republic of"
			replace country = "Republic of Korea" if country == "Korea, Republic of"
			replace country = "Republic of Moldova" if country == "Moldova, Republic of"
			replace country = "Dem People's Rep of Korea" if country == "Korea, Democratic People's Republic of"
			replace country = "Palestine, State of" if country == "Occupied Palestinian Territory"
			replace country = "Taiwan" if country == "Taiwan, China"
			replace country = "United Republic of Tanzania" if country == "Tanzania, United Republic of"
			replace country = "United States of America" if country == "United States"
			merge m:1 ISO country using countryclassification 
				tab country if _merge == 1
				drop if _merge !=3 // aggregates
				drop _merge
					
			// Save
			save unemployment_disaggregated, replace

			// generate aggregate dataset by of all sex all age groups by urban and rural
			keep if sex==0 & agegroup==0 
			drop sex agegroup
			ren unemp unemp_
			reshape wide unemp_, i(ISO country year) j(geog)
			ren unemp_0 unemp_tot
			ren unemp_1 unemp_r
			ren unemp_2 unemp_u
			lab var unemp_tot "Unemployment rate, age 15+, total"
			lab var unemp_r "Unemployment rate, age 15+, rural"
			lab var unemp_u "Unemployment rate, age 15+, urban"
			
			// Save
				save unemployment_urbrur, replace

**# Underemployment rate, urban and rural (ILO)
		import delimited using "$datain\TRU_DEMP_SEX_AGE_GEO_RT_A-full-2022-06-30.csv", clear
			ren ref_area ISO
			ren ref_arealabel country
			ren sex sex2
			encode sex2, gen(sex)
			drop sex2
			encode classif1label, gen(agegroup)
			drop classif1label
			encode classif2, gen(geog)
			drop classif2*
			ren time year
			ren obs_value underemp
			lab var underemp "Time-related underemployment rate (ILO modelled estimates) (%)"
			drop source sourcelabel indicator indicatorlabel sexlabel classif1 obs_status obs_statuslabel
			lab var country "Country"
			lab var agegroup "Age group"
			tab sex
			tab sex, nolabel
			recode sex (3=0)
			lab def sex 1 "Female" 2 "Male" 0 "Total", replace
			lab val sex sex
			tab agegroup
			tab agegroup, nolabel
			drop if inlist(agegroup,1,2,3,4) // drop "aggregate bands" disaggregation, keep only those that align with the unemployment categories
			tab agegroup
			tab agegroup, nolabel
			recode agegroup (5=0) (7=1) (9=2)
			drop if !inlist(agegroup,0,1,2)
			lab def ag 0 "Total population age 15+" 1 "Youth, age 15-24" 2 "Adults, age 25+", replace
			lab val agegroup ag
			tab geog 
			tab geog, nolabel
			recode geog (1=0) (2=1) (3=2) (4=3)
			lab def geo 0 "Total" 1 "Rural" 2 "Urban" 3 "Undefined", replace
			lab val geog geo
			lab var geog "Geography (urban/rural)"
			lab var sex "Sex"
			sort ISO year
			drop note*
		
		// Merge in country classification
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
			replace country = "Democratic Republic of the Congo" if country == "Congo, Democratic Republic of the"
			replace country = "Cabo Verde" if country == "Cape Verde"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Republic of"
			replace country = "Republic of Korea" if country == "Korea, Republic of"
			replace country = "Republic of Moldova" if country == "Moldova, Republic of"
			replace country = "Dem People's Rep of Korea" if country == "Korea, Democratic People's Republic of"
			replace country = "Palestine, State of" if country == "Occupied Palestinian Territory"
			replace country = "Taiwan" if country == "Taiwan, China"
			replace country = "United Republic of Tanzania" if country == "Tanzania, United Republic of"
			replace country = "United States of America" if country == "United States"		
			merge m:1 ISO country using countryclassification 
					tab country if _merge == 1
					drop if _merge !=3 
					drop _merge
			
			// Save
			save underemployment_disaggregated, replace
			
			// generate aggregate dataset by of all sex all age groups by urban and rural
				keep if sex==0 & agegroup==0 
				drop sex agegroup
				ren underemp underemp_
				reshape wide underemp_, i(ISO country year) j(geog)
				ren underemp_0 underemp_tot
				ren underemp_1 underemp_r
				ren underemp_2 underemp_u
				lab var underemp_tot "Time-related underemployment rate, age 15+, total"
				lab var underemp_r "Time-related underemployment rate, age 15+, rural"
				lab var underemp_u "Time-related underemployment rate, age 15+, urban"
			
		// Save
			save underemployment_urbrur, replace
		
		// Generate combined dataset of unemployment and underemployment for visualization
		use unemployment_disaggregated, clear
			merge 1:1 ISO country year sex agegroup geog using underemployment_disaggregated
			browse if _merge!=3
			drop _merge
			order ISO country year unemp underemp, first 
			sort ISO year
			misstable sum
			drop if unemp==. & underemp==. // drop if no data for either variable
			unique ISO
				lab def geo 0 "Total" 1 "Rural" 2 "Urban" 3 "Undefined", replace
				lab val geog geo
				table agegroup sex geog
				browse if geog==3 // few observations that cannot be classified as urban or rural (none have unemployment data)
				
				// Save
					save employment_disaggregated, replace
					export delimited employment_disaggregated, replace
			
			// Generate latest year variable
				egen latestyear=max(year) if unemp!=. & underemp!=., by(ISO)
				tab latestyear // 2020 
				keep if year==latestyear
				tab year
				unique ISO
				drop latestyear

			// Save
				save employment_disaggregated_latestyear, replace
				export delimited employment_disaggregated_latestyear, replace

				
** SOCIAL PROTECTION ***********************************************************

**# Social protection coverage (World Bank)
		import delimited using "$datain\API_PER_ALLSP.COV_POP_TOT_DS2_en_csv_v2_4157459.csv", varnames(5) rowrange(5:271) clear
			drop v5-v44 // years prior to 2000
			ren v* spcoverage#, addnumber(2000)
			reshape long spcoverage, i(countryname countrycode indicatorname indicatorcode) j(year)
			tab year
			lab var year "Year"
			tab indicatorname
			ren countryname country
			ren countrycode ISO
			lab var spcoverage "Coverage of social protection and labor programs (% population)"
			drop indicatorname
			tab indicatorcode
			** Note indicator code: per_allsp.cov_pop_tot 
			drop indicatorcode
			
		// Merge in country classifications
				replace country = "Bahamas" if country == "Bahamas, The" 
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia" 
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep." 
				replace country = "Congo" if country == "Congo, Rep." 
				replace country = "Czechia" if country == "Czech Republic" 
				replace country = "Côte D'Ivoire" if ISO == "CIV"
				replace country = "Egypt" if country == "Egypt, Arab Rep." 
				replace country = "Gambia (Republic of The)" if country == "Gambia, The" 
				replace country = "Hong Kong" if country == "Hong Kong SAR, China" 
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep." 
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep." 
				replace country = "Republic of Korea" if country == "Korea, Rep." 
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic" 
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR" 
				replace country = "Macau" if country == "Macao SAR, China" 
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts." 
				replace country = "Republic of Moldova" if country == "Moldova" 
				replace country = "Slovakia" if country == "Slovak Republic" 
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis" 
				replace country = "Saint Lucia" if country == "St. Lucia" 
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines" 
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe" 
				replace country = "Taiwan" if country == "Taiwan, China" 
				replace country = "United Republic of Tanzania" if country == "Tanzania" 
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom" 
				replace country = "United States of America" if country == "United States" 
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB" 
				replace country = "Viet Nam" if country == "Vietnam" 
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
				replace country = "Yemen" if country == "Yemen, Rep." 
				replace country = "Türkiye" if country == "Turkey"	
				replace country = "Palestine, State of" if country == "West Bank and Gaza"
				replace country = "Curaçao" if country == "Curacao"
			merge m:1 ISO country using countryclassification
				tab country if _merge == 1 // aggregate areas and Channel Islands, Kosovo
				drop if _merge!=3
				drop _merge
				sort ISO year
				drop if spcoverage==.

* Note: value for China based on China Household Income Project and appears to include the territories. To be conservative, we apply the value to mainland China only.
		// Save
			save SP_coverage, replace
			export delimited using SP_coverage, replace

**# Social protection adequacy (World Bank)
		import delimited using "$datain\API_PER_ALLSP.ADQ_POP_TOT_DS2_en_csv_v2_4157457.csv", varnames(5) rowrange(5:271) clear
		drop v5-v44 // years prior to 2000
		drop v67 // empty column
		ren v* spadequacy#, addnumber(2000)
		reshape long spadequacy, i(countryname countrycode indicatorname indicatorcode) j(year)
		tab year
		lab var year "Year"
		ren countrycode ISO
		tab indicatorname
			// Note outliers > 100 changed to missing
			browse if spadequacy > 100 & spadequacy !=. // Lao PDR 2018 (133), Syria 2003 (811)
			replace spadequacy = . if spadequacy > 100 & spadequacy != .
			// label variable with indicator name
			lab var spadequacy "Adequacy of social protection and labor programs (% of total welfare of beneficiary households)"
			drop indicatorname
			tab indicatorcode
			** Note indicator code: per_allsp.adq_pop_tot 
			drop indicatorcode 
			ren countryname country
		
		// Merge in country classifications
			replace country = "Bahamas" if country == "Bahamas, The" 
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia" 
			replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep." 
			replace country = "Congo" if country == "Congo, Rep." 
			replace country = "Czechia" if country == "Czech Republic" 
			replace country = "Côte D'Ivoire" if ISO == "CIV"
			replace country = "Egypt" if country == "Egypt, Arab Rep." 
			replace country = "Gambia (Republic of The)" if country == "Gambia, The" 
			replace country = "Hong Kong" if country == "Hong Kong SAR, China" 
			replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep." 
			replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep." 
			replace country = "Republic of Korea" if country == "Korea, Rep." 
			replace country = "Kyrgyzstan" if country == "Kyrgyz Republic" 
			replace country = "Lao People's Democratic Republic" if country == "Lao PDR" 
			replace country = "Macau" if country == "Macao SAR, China" 
			replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts." 
			replace country = "Republic of Moldova" if country == "Moldova" 
			replace country = "Slovakia" if country == "Slovak Republic" 
			replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis" 
			replace country = "Saint Lucia" if country == "St. Lucia" 
			replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines" 
			replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe" 
			replace country = "Taiwan" if country == "Taiwan, China" 
			replace country = "United Republic of Tanzania" if country == "Tanzania" 
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom" 
			replace country = "United States of America" if country == "United States" 
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB" 
			replace country = "Viet Nam" if country == "Vietnam" 
			replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)" 
			replace country = "Yemen" if country == "Yemen, Rep." 
			replace country = "Türkiye" if country == "Turkey"	
			replace country = "Palestine, State of" if country == "West Bank and Gaza"
				replace country = "Curaçao" if country == "Curacao"
		merge m:1 ISO country using countryclassification
			tab country if _merge == 1 // aggregate areas and Channel Islands, Curacao, Kosovo, Sint Maarten, Saint Martin			merge m:1 ISO country using countryclassification
			drop if _merge!=3 
			drop _merge
			drop if spadequacy==.
			sort ISO year
			
* Note: value for China based on China Household Income Project and appears to include the territories. To be conservative, we apply the value to mainland China only.

			// Save
			save SP_adequacy, replace
			export delimited using SP_adequacy, replace

		// Combined dataset of latest year per country combining coverage and adequacy for joint visualization
			use SP_coverage, clear
			merge 1:1 ISO year using SP_adequacy, keepusing(spadequacy)
			drop _merge
				
				// Keep latest year 
				misstable sum
				tab year
				egen latestyear=max(year), by(ISO) // identifies the latest year that is non-missing (now that missing was dropped)
				tab latestyear
				misstable sum
				sum if spadequacy==. // no missing data in latest year
				keep if year==latestyear
				tab year
				misstable sum
				list country if spadequacy==.
				ren latestyear datayear
				lab var datayear "Data year (latest available)"
				order ISO country year spcoverage spadequacy datayear
				
				// Save
					save social_protection_latest, replace
					export delimited using social_protection_latest, replace


** RIGHTS **********************************************************************

**# % children 5-17 engaged in child labor (UNICEF)
* NOTE: this dataset is in long form and includes disaggregation by sex and a total value, take care not to double count
		import delimited using "$datain\GLOBAL_DATAFLOW_UNICEF_CHLD_5-17_LBR_ECON", clear
			ren ref_areageographicarea country
			gen ISO=substr(country,1,3)
			tab ISO
			replace country=substr(country,5,.)
			tab country
			lab var country "Country"
			ren sexsex sex
			ren time_periodtimeperiod year
			lab var sex "Sex"
			lab var year "Year"
			ren obs_valueobservationvalue childlabor
			list indicatorindicator in 1/1
			lab var childlabor "% children (aged 5-17 years) engaged in child labour (economic activities)"
			drop dataflow indicatorindicator unit_multiplierunitmultiplier unit_measureunitofmeasure obs_statusobservationstatus obs_confobservationconfidentaili lower_boundlowerbound upper_boundupperbound wgtd_sampl_sizeweightedsamplesiz obs_footnoteobservationfootnote series_footnoteseriesfootnote data_sourcedatasource source_linkcitationoforlinktothe custodiancustodian time_period_methodtimeperiodacti ref_periodreferenceperiod coverage_timetheperiodoftimeforw agecurrentage
			order ISO country year sex childlabor
			encode sex, gen(sex2)
			drop sex
			ren sex2 sex
			tab sex
			tab sex, nolabel
			recode sex (3=0)
			lab def sex 1 "Female" 2 "Male" 0 "Total", replace
			lab val sex sex
			sort ISO year sex
			
		// Merge in country classification
			replace country = trim(country)
			replace country = "Côte D'Ivoire" if country == "CÃ´te d'Ivoire"
			replace country = "Türkiye" if country == "Republic of TÃ¼rkiye"
			replace country = "Palestine, State of" if country == "State of Palestine"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 ISO country using countryclassification
				browse if _merge != 3
				drop if _merge==2
				drop _merge
				
		// Further clean and shape
			tab country, sum(year) // Note data year for each country
			unique country
			drop ISO_governing UN_status territoryof 
			reshape wide childlabor, i(ISO year wb_region incgrp country UNmemberstate) j(sex)
			ren childlabor0 childlabor // this is the total
				lab var childlabor "% children (aged 5-17 years) engaged in child labour (economic activities)"
			ren childlabor1 childlabor_f
				lab var childlabor_f "% children (aged 5-17 years) engaged in child labour (economic activities), female"
			ren childlabor2 childlabor_m
				lab var childlabor_m "% children (aged 5-17 years) engaged in child labour (economic activities), male"
			
		// Save
			save childlabor, replace
			export delimited using childlabor, replace
	
**# % total landholdings held by women (FAO)
		import delimited using "$datain\FAOSTAT_LandholdingBySex_1990-2010.csv", clear
			ren area country
			ren value landholding
			tab item
			encode item, gen(sex)
			lab def sex 1 "Female" 2 "Male", replace
			lab val sex sex
			lab var sex "Sex"
			tab unit
			lab var landholding "Holdings operated by sex (% holdings)"
			drop domaincode domain areacodefao elementcode itemcode unit flag flagdescription note
			
			// Merge in country classification
				replace country = "Côte D'Ivoire" if country == "C?te d'Ivoire"
				replace country = "Reunion" if country == "R?union"
				replace country = "French Guiana" if country == "French Guyana"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
					drop if _merge!=3 
				drop _merge
				tab censusyear
				gen year=substr(censusyear,-4,4) // take year as last year of census range
				tab year
				destring year, replace
				tab country, sum(year)
				egen latestyear=max(year), by(ISO)

				// Keep only latest data point for countries with more than one survey round
					tab country if year != latestyear
					tab wcaround
					tab2 wcaround latestyear
					keep if year == latestyear
					tab wcaround
					tab country if wcaround == 2000
					tab country if wcaround == 1990
					drop wcaround // note WCA round determines definitions used in computation
					drop element item censusyear
					ren latestyear datayear
					lab var datayear "Data year (latest available)"
					order ISO country year landholding sex wb_region incgrp datayear
						** Note: Issue with Uruguay - male + female do not add up to 100%
						drop if country == "Uruguay"	
			// Save
				save landholdings_bysex, replace
				export delimited using landholdings_bysex, replace
			
				// Save female share variable to merge with other data
					drop datayear ISO_governing UN_status_detail UN_status territoryof 
					tab sex
					reshape wide landholding, i(ISO country year wb_region incgrp UNmemberstate) j(sex)
					ren landholding1 landholding_fem
					ren landholding2 landholding_male
					lab var landholding_fem "Share of landholdings operated by women (% holdings)"
					lab var landholding_male "Share of landholdings operated by men (% holdings)"
					
				// Save
					save landholdings_female, replace
					export delimited using landholdings_female, replace


					
// GOVERNANCE //////////////////////////////////////////////////////////////////

** SHARED VISION & STRATEGIC PLANNING ******************************************

**# Civil Society Index (Varieties of democracy)
		import delimited using "$datain\V-Dem-CY-Core-v12.csv", clear
			ren country_name country
			ren country_text_id ISO
			drop country_id
			sum year
			drop if year<1960
			sort ISO year
			destring, replace
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Ivory Coast"
			replace country = "Congo" if country == "Republic of the Congo"
			replace country = "Cabo Verde" if country == "Cape Verde"
			replace country = "Czechia" if country == "Czech Republic"
			replace country = "Gambia (Republic of The)" if country == "The Gambia"
			replace country = "Iran (Islamic Republic of)" if country == "Iran"
			replace country = "Republic of Korea" if country == "South Korea"
			replace country = "Lao People's Democratic Republic" if country == "Laos"
			replace country = "Republic of Moldova" if country == "Moldova"
			replace country = "Myanmar" if country == "Burma/Myanmar"
			replace country = "Dem People's Rep of Korea" if country == "North Korea"
			replace country = "West Bank" if country == "Palestine/West Bank"
			replace country = "Gaza Strip" if country == "Palestine/Gaza"
			replace ISO = "PSE" if country == "West Bank"
			replace ISO = "PSE" if country == "Gaza Strip"
			replace country = "Russian Federation" if country == "Russia"
			replace country = "Syrian Arab Republic" if country == "Syria"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "United Republic of Tanzania" if country == "Tanzania"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
			replace country = "Viet Nam" if country == "Vietnam"
			replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
			merge m:1 ISO country using countryclassification
				tab country if _merge == 1 
				tab country if _merge ==2
				drop if _merge != 3
				drop _merge
							
				// Save full dataset
				save V-Dem_all, replace
				
				// Keep only the Civil Society Participation Index indicator
				keep ISO country wb_region incgrp year ISO_governing UN_status_detail UNmemberstate UN_status territoryof m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code v2x_cspart v2x_cspart_codelow v2x_cspart_codehigh v2x_cspart_sd 
				ren (v2x_*) (*)
				ren cspart_codelow cspart_lower 
				ren cspart_codehigh cspart_upper
				lab var cspart "Civil society participation index"
				lab var cspart_lower "Civil society participation index, lower bound of 68% probability distribution (~1 standard deviation below mean point estimate)"
				lab var cspart_upper "Civil society participation index, upper bound of 68% probability distribution (~1 standard deviation above mean point estimate)"
							
			// Save
				save VDem_CSPI, replace
				export delimited using VDem_CSPI, replace

**# % urban population living in cities signed onto the Milan Urban Food Policy Pact (MUFPP, Landscan population data, GADM administrative boundaries, FSCI) 
		// National populations
			import delimited using "$datain\all_cntry_pops", clear
			drop v1
			ren country_urban_pop pop_u
			replace pop_u = pop_u / 1000 // Change unit from individuals to thousands of people
			ren country_total_pop landscan_population
			replace landscan_population = landscan_population / 1000 // Change unit from individuals to thousands of people
			sum landscan_population
			lab var pop_u "Total urban population, thousands"
			lab var landscan_population "Total population, thousands"
			gen year = 2020
			
			// Save
				save populations_2020, replace
	
		// City populations
			import delimited using "$datain\city_pops", clear
			ren citiescity city
			ren citiescountry country
			replace city_pop = city_pop / 1000 // Change unit from individuals to thousands of people
			lab var city "City"
			lab var city_pop "City population, thousands"
			egen nmufppcities = count(v1), by(country)
			tab nmufppcities
			lab var nmufppcities "Number of MUFPP cities in the country"
			drop v1
				
				// Collapse to country level totals
				// Save labels
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}
					collapse (first) nmufppcities (sum) city_pop, by(country)
					// Relabel
						foreach v of var * {
						label var `v' "`l`v''"
							}
				ren city_pop mufpp_urbpop 
				lab var mufpp_urbpop "Total population (national) living in MUFPP municipalities, thousands"
				* Merge in country populations
				replace country = "Cabo Verde" if country == "Cape Verde"
				merge 1:1 country using populations_2020
				drop _merge
				replace mufpp_urbpop = 0 if mufpp_urbpop ==.
	
		// Calculate indicator
			gen mufppurbshare = (mufpp_urbpop / pop_u) * 100
			sum mufppurbshare
			lab var mufppurbshare "Share of urban population living in MUFPP signatory municipalities (%)"
				
			// Merge in country classifications
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Republic of Moldova" if country == "Moldova"
				replace country = "Russian Federation" if country == "Russia"
				replace country = "Republic of Korea" if country == "South Korea"
				replace country = "United Republic of Tanzania" if country == "Tanzania"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "United States of America" if country == "United States"
				replace country = "Czechia" if country == "Czech Republic"
				replace country = "Timor-Leste" if country == "East Timor"
				replace country = "Falkland Islands (Malvinas)" if country == "Falkland Islands"
				replace country = "Iran (Islamic Republic of)" if country == "Iran"
				replace country = "Lao People's Democratic Republic" if country == "Laos"
				replace country = "North Macedonia" if country == "Macedonia"
				replace country = "Micronesia (Federated States of)" if country == "Micronesia"
				replace country = "Dem People's Rep of Korea" if country == "North Korea"
				replace country = "Svalbard and Jan Mayen Islands" if country == "Svalbard and Jan Mayen"
				replace country = "Syrian Arab Republic" if country == "Syria"
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe"
				replace country = "Viet Nam" if country == "Vietnam"
				replace country = "United States Virgin Islands" if country == "Virgin Islands, U.S."
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Reunion" if country == "Réunion"
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
				replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"	
				replace country = "Macau" if country == "Macao" 
				replace country = "Saint Martin (French Part)" if country == "Saint-Martin" 
				replace country = "Sint Maarten (Dutch part)" if country == "Sint Maarten" 
				replace country = "Bonaire, Sint Eustatius and Saba" if country == "Bonaire, Saint Eustatius and Saba" 
				merge 1:1 country using iso
				drop if _merge!=3
				drop _merge
				merge 1:1 country ISO using countryclassification
				browse if _merge != 3 
				tab country if _merge == 1
					/* Drop territories not in GAUL: Akrotiri and Dhekelia
						Bonaire, Saint Eustatius and Saba
						Brunei
						Caspian Sea
						Curaçao
						Kosovo
						Northern Cyprus
						Saint-Martin
						Sint Maarten
						Åland */
				drop if _merge != 3 
				drop _merge
				sort ISO 
				order ISO country wb_region incgrp year mufppurbshare	
			
			// Save
				save mufpp_pop, replace
				export delimited using mufpp_pop, replace

**# Degree of legal recognition of the Right to Food (FAO / FSCI)
		import excel using "$datain\Rigth-to-Food_Dataset", firstrow clear sheet("Sheet1")
		tab constitutional_recognition
		ren constitutional_recognition legal_recognition
		encode legal_recognition, gen(legrectype)
			// Merge in country classification
			replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
			replace country = "Côte D'Ivoire" if country == "Cote d'Ivoire"
			replace country = "Democratic Republic of the Congo" if country == "Democratic Republic of Congo"
			replace country = "Iran (Islamic Republic of)" if country == "Iran"
			replace country = "Syrian Arab Republic" if country == "Syrian Arab Repubic"
			replace country = "Türkiye" if country == "Turkey"
			replace country = "Uzbekistan" if country == "Uzbekistan "
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge != 3
			
			** Note:  Record as "none" for UN member states that were not in the constitutional recognition database
				tab legrectype
				tab legrectype, nolabel
				describe legrectype
				lab def legrectype 0 "None", modify
				replace legrectype = 0 if _merge==2 & UNmemberstate == 1
				drop if _merge == 2 & UNmemberstate == 0
				drop _merge
				order ISO country legrectype wb_region incgrp
				drop legal_recognition
				lab var legrectype "Type of recognition of the right to food"

		// Aggregate into explicit and directive, other, none
			gen righttofood = 1 if inlist(legrectype, 1, 2)
			replace righttofood = 2 if inlist(legrectype, 3, 4, 5)
			replace righttofood = 3 if legrectype == 0
			lab def rtf 1 "Explicit protection or directive principle of state policy" 2 "Other implicit or national codification of international obligations or relevant provisions" 3 "None"
			lab val righttofood rtf
			lab var righttofood "Degree of legal recognition of the Right to Food"
			order righttofood, after(country)

		// Collapse to country level, keeping max level of recognition (e.g., explicit > implicit > none) 
			drop legrectype
			duplicates tag ISO righttofood, gen(dup)
			tab dup
			
			// Create a variable to identify countries with multiple policies
				preserve
					collapse (max) dup, by(ISO)
						gen multiple_policies=0
						replace multiple_policies = 1 if dup!=0
						keep ISO multiple_policies
						tempfile mp
						save `mp', replace
				restore
				merge m:1 ISO using `mp'
				drop _merge

				// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
				}
				collapse (min) righttofood (first) country wb_region incgrp multiple_policies UNmemberstate ISO_governing m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code, by(ISO)
				// Relabel
					foreach v of var * {
					label var `v' "`l`v''"
						}
		gen year = 2021 // last update of the website was April 2021
		
				// Territories
					sort country ISO year
					browse if UNmemberstate == 0
					tab ISO_governing if UNmemberstate == 0
					tab country if UNmemberstate == 0
					* 59 areas and territories
		// Save
			save righttofood, replace
			export delimited using righttofood, replace

**# Presence of a national food systems transformation pathway (FAO)
		import delimited using "$datain\FSPathways_presence", varnames(1) bindquote(strict) clear
		gen fspathway = 1
		drop countofthemes v3
		// Merge in country classification
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge != 3
			drop if _merge == 2 & UNmemberstate == 0 
			drop _merge 
			replace fspathway = 0 if fspathway == .
			lab var fspathway "Presence of a national food systems transformation pathway"
		gen year = 2022
		// Save
			save fspathways, replace
			export delimited using fspathways, replace

		import delimited using "$datain\FSPathways_data", varnames(1) bindquote(strict) clear
		ren theme fstrans_theme
		ren meanofimplementation fstrans_means
		ren priorityinpathway fstrans_priority
		ren measureinpathway fstrans_measure
		// Merge in country classification
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge != 3
			drop if _merge == 2 & UNmemberstate == 0 
			drop _merge 

			gen year = 2022

		// Encode the detailed classifications
			encode fstrans_theme, gen(fstrans_theme2)
			encode fstrans_means, gen(fstrans_means2)
			drop fstrans_theme fstrans_means
			ren *2 *
		
		// Record categories for theme and means of implementation
			tab fstrans_theme
			tab fstrans_means
		
		// Save detailed dataset
			save fspathways_detail, replace
			export delimited using fspathways_detail, replace
		
		// Collapse to one data point per country for binary indicator to merge into master datasets
			// Save labels
			foreach v of var * {
			local l`v' : variable label `v'
				if `"`l`v''"' == "" {
				local l`v' "`v'"
				}
			}
			collapse (first) fspathway country wb_region incgrp year ISO_governing UNmemberstate m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code, by(ISO)
			// Relabel
				foreach v of var * {
				label var `v' "`l`v''"
					}
		// Save
			save fspathways, replace
			export delimited using fspathways, replace

** EFFECTIVE IMPLEMENTATION ****************************************************

**# Government effectiveness index (World Governance Indicators)
	* NOTE: Estimate of governance (ranges from approximately -2.5 (weak) to 2.5 (strong) governance performance)
		import excel using "$datain\wgidataset.xlsx", sheet("GovernmentEffectiveness") cellrange(A14) firstrow clear 
		ren A country
		ren B ISO
		ren C ge1996
		ren D ge_se1996
		ren E ge_score1996
		ren F ge_rank1996
		ren G ge_lower1996
		ren H ge_upper1996
		ren I ge1998
		ren J ge_se1998
		ren K ge_score1998
		ren L ge_rank1998
		ren M ge_lower1998
		ren N ge_upper1998
		ren O ge2000
		ren P ge_se2000
		ren Q ge_score2000
		ren R ge_rank2000
		ren S ge_lower2000
		ren T ge_upper2000
		ren U ge2002
		ren V ge_se2002
		ren W ge_score2002
		ren X ge_rank2002
		ren Y ge_lower2002
		ren Z ge_upper2002
		ren AA ge2003
		ren AB ge_se2003
		ren AC ge_score2003
		ren AD ge_rank2003
		ren AE ge_lower2003
		ren AF ge_upper2003
		ren AG ge2004
		ren AH ge_se2004
		ren AI ge_score2004
		ren AJ ge_rank2004
		ren AK ge_lower2004
		ren AL ge_upper2004
		ren AM ge2005
		ren AN ge_se2005
		ren AO ge_score2005
		ren AP ge_rank2005
		ren AQ ge_lower2005
		ren AR ge_upper2005
		ren AS ge2006
		ren AT ge_se2006
		ren AU ge_score2006
		ren AV ge_rank2006
		ren AW ge_lower2006
		ren AX ge_upper2006
		ren AY ge2007
		ren AZ ge_se2007
		ren BA ge_score2007
		ren BB ge_rank2007
		ren BC ge_lower2007
		ren BD ge_upper2007
		ren BE ge2008
		ren BF ge_se2008
		ren BG ge_score2008
		ren BH ge_rank2008
		ren BI ge_lower2008
		ren BJ ge_upper2008
		ren BK ge2009
		ren BL ge_se2009
		ren BM ge_score2009
		ren BN ge_rank2009
		ren BO ge_lower2009
		ren BP ge_upper2009
		ren BQ ge2010
		ren BR ge_se2010
		ren BS ge_score2010
		ren BT ge_rank2010
		ren BU ge_lower2010
		ren BV ge_upper2010
		ren BW ge2011
		ren BX ge_se2011
		ren BY ge_score2011
		ren BZ ge_rank2011
		ren CA ge_lower2011
		ren CB ge_upper2011
		ren CC ge2012
		ren CD ge_se2012
		ren CE ge_score2012
		ren CF ge_rank2012
		ren CG ge_lower2012
		ren CH ge_upper2012
		ren CI ge2013
		ren CJ ge_se2013
		ren CK ge_score2013
		ren CL ge_rank2013
		ren CM ge_lower2013
		ren CN ge_upper2013
		ren CO ge2014
		ren CP ge_se2014
		ren CQ ge_score2014
		ren CR ge_rank2014
		ren CS ge_lower2014
		ren CT ge_upper2014
		ren CU ge2015
		ren CV ge_se2015
		ren CW ge_score2015
		ren CX ge_rank2015
		ren CY ge_lower2015
		ren CZ ge_upper2015
		ren DA ge2016
		ren DB ge_se2016
		ren DC ge_score2016
		ren DD ge_rank2016
		ren DE ge_lower2016
		ren DF ge_upper2016
		ren DG ge2017
		ren DH ge_se2017
		ren DI ge_score2017
		ren DJ ge_rank2017
		ren DK ge_lower2017
		ren DL ge_upper2017
		ren DM ge2018
		ren DN ge_se2018
		ren DO ge_score2018
		ren DP ge_rank2018
		ren DQ ge_lower2018
		ren DR ge_upper2018
		ren DS ge2019
		ren DT ge_se2019
		ren DU ge_score2019
		ren DV ge_rank2019
		ren DW ge_lower2019
		ren DX ge_upper2019
		ren DY ge2020
		ren DZ ge_se2020
		ren EA ge_score2020
		ren EB ge_rank2020
		ren EC ge_lower2020
		ren ED ge_upper2020
		drop in 1/1 // drop sub-heading row
		
		// Reshape
			reshape long ge ge_se ge_score ge_rank ge_lower ge_upper, i(ISO country) j(year)
			order ISO country ge*
			drop if ISO==""
			lab var ge "Government Effectiveness Index, World Governance Indicators"
			foreach v of varlist ge* {
			replace `v'="" if `v'=="#N/A"
			destring `v', replace
			}
			ren ge govteffect
			
			// Merge in country classifiers
				replace ISO="AND" if country=="Andorra"
				replace ISO="COD" if ISO=="ZAR"
				replace ISO="TLS" if ISO=="TMP"
				replace ISO="ROU" if ISO=="ROM"
				replace country = "Bahamas" if country == "Bahamas, The"
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep."
				replace country = "Congo" if country == "Congo, Rep."
				replace country = "Cabo Verde" if country == "Cape Verde"
				replace country = "Czechia" if country == "Czech Republic"
				replace country = "Egypt" if country == "Egypt, Arab Rep."
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts."
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
				replace country = "Gambia (Republic of The)" if country == "Gambia, The"
				replace country = "Hong Kong" if country == "Hong Kong SAR, China"
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep."
				replace country = "Jersey" if country == "Jersey, Channel Islands"
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis"
				replace country = "Republic of Korea" if country == "Korea, Rep."
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR"
				replace country = "Saint Lucia" if country == "St. Lucia"
				replace country = "Macao" if country == "Macao SAR, China"
				replace country = "Republic of Moldova" if country == "Moldova"
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. Rep."
				replace country = "Reunion" if country == "Réunion"
				replace country = "Sao Tome and Principe" if country == "São Tomé and Principe"
				replace country = "Slovakia" if country == "Slovak Republic"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Taiwan" if country == "Taiwan, China"
				replace country = "United Republic of Tanzania" if country == "Tanzania"
				replace country = "United States of America" if country == "United States"
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB"
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)"
				replace country = "Viet Nam" if country == "Vietnam"
				replace country = "Yemen" if country == "Yemen, Rep."
				replace country = "Palestine, State of" if country == "West Bank and Gaza"
				replace ISO = "PSE" if country == "Palestine, State of"
				replace country = "Macau" if country == "Macao" 
				merge m:1 ISO country using countryclassification
				browse if _merge!=3 
				drop if _merge!=3
				drop _merge
			
			// Further clean 
				drop ge_score ge_rank
				lab var ge_se "Government Effectiveness Index, std. error"
				ren ge_lower ge_LCI
				ren ge_upper ge_UCI
				lab var ge_LCI "Government Effectiveness Index, 90% confidence interval lower bound"
				lab var ge_UCI "Government Effectiveness Index, 90% confidence interval upper bound"
				
		// Save
			save goveffectiveness, replace
			export delimited using goveffectiveness, replace

**# International Health Regulations State Party Assessment report (IHR SPAR), Food safety capacity (WHO Global Health Observatory)
		import delimited using "$datain\WHO-GHO_FoodSafety_2018-2020.csv", clear
		keep indicatorcode indicator valuetype parentlocationcode parentlocation locationtype spatialdimvaluecode location datasource value period
		ren value foodsafety
		lab var foodsafety "Food Safety Capacity Score"
		ren period year
		ren spatialdimvaluecode ISO
		ren location country
		drop indicatorcode indicator valuetype parentlocationcode parentlocation locationtype datasource
			
		// Merge in country classification
			replace country = "Côte D'Ivoire" if ISO == "CIV"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "North Macedonia" if country == "The former Yugoslav Republic of Macedonia"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 ISO country using countryclassification
			browse if _merge!=3 
			drop if _merge!=3
			drop _merge
			
		// Save all years
			save foodsafety, replace
			export delimited using foodsafety, replace
			
			// Save 2020
			unique country
			distinct country if year==2020
			reshape wide foodsafety, i(ISO country wb_region incgrp) j(year)
			gen foodsafety_latestyear = foodsafety2020 if foodsafety2020 != .
				replace foodsafety_latestyear = foodsafety2019 if foodsafety2020 == .
				replace foodsafety_latestyear = foodsafety2018 if foodsafety_latestyear == .
				* NOTE: latest year is 2020 for most countries, for 21 countries data come from 2019 (N=15) or 2018 (N=6)
		
		// Save		
			save foodsafety_latestyear, replace
			export delimited using foodsafety_latestyear, replace
		
**# Presence of health-related food taxes (World Cancer Research Fund International NOURISHING)
		import delimited using "$datain\policy-export06-Jul-2022.csv", varnames(1) colrange(1:6) bindquote(strict) maxquotedrows(50) stringcols(_all) clear // Note the data are not machine readable and users may encounter challenges importing this raw file. Any country in this dataset has at least one health-related food tax within its borders, though some are only at subnational level (USA, Norway). Information on the policy design is contained under subpolicyarea and policyaction, but contains extensive text
		gen healthtax_any = 1
		lab var healthtax_any "Presence of any health-related food taxes at national or sub-national level"
		drop type policyarea subpolicyarea // type and policyarea have no variation, subpolicy area identifies this indicator of interest ("health-related food taxes") 
		// policy action variable contains extensive text, if interested in specific policy attributes, it is advised to read this content online as the download overwrite much of the text with other characters. 
		sort country
		egen order = seq()
		gen national = 1
		replace national = 0 if order == 36 // Catalonia has additional law beyond national laws in Spain
		replace national = 0 if country == "USA"
		drop order
		lab var national "Policy is applied at national level (1=yes)"
		lab def yesno 0 "No" 1 "Yes"
		lab val national yesno
			
			// Save full information dataset
				save healthtax_details, replace
				export delimited using healthtax_details, replace

		// Distinguish between national and subnational taxes
		gen healthtax = 1 if national == 1
			replace healthtax = 0 if national == 0
		gen healthtax_subnational = 1 if national == 0
			replace healthtax_subnational = 1 if national == 0
		drop national healthtax_any
			
			// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
				}
			
			// Collapse to country level
				collapse (first) healthtax healthtax_subnational, by(country)
			
			// Relabel
				foreach v of var * {
				label var `v' "`l`v''"
					}

			// Merge in ISO, regions, and income groups
				replace country = "Brunei Darussalam" if country == "Brunei"
				replace country = "Saint Vincent and the Grenadines" if country == "St Vincent and the Grenadines"
				replace country = "United Arab Emirates" if country == "UAE"
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "UK"
				replace country = "United States of America" if country == "USA"
				replace country = "Saint Helena" if country == "St Helena"
				merge 1:1 country using iso
				drop if _merge!=3
				drop _merge
				merge 1:1 country ISO using countryclassification
				browse if _merge != 3
				replace healthtax = 0 if _merge == 2 & UNmemberstate == 1
				replace healthtax_subnational = 0 if _merge == 2 & UNmemberstate == 1
				drop if _merge != 3 & UNmemberstate == 0
				drop _merge
				
			// Further clean
				gen year = 2021 // last documented update of the NOURISHING database, which is continually updated and was accessed in July 2022
				order ISO country wb_region incgrp year healthtax
				replace healthtax_subnational = 0 if healthtax == 1 // National level indicator is hierarchical to subnational - subnational only recorded where national does not exist
				lab var healthtax "Presence of any health-related food taxes at the national level"
				lab var healthtax_subnational "Presence of any health-related food taxes but only at sub-national level"
		
			// Save 
				save healthtax, replace
				export delimited using healthtax, replace

	
** ACCOUNTABILITY **************************************************************

**# V-Dem Accountability index (Varieties of Democracy)
	use V-Dem_all, clear
		
		// Keep accountability index indicators only
		keep ISO country year wb_region incgrp v2x_accountability v2x_accountability_codelow v2x_accountability_codehigh ISO_governing UNmemberstate m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code
		ren (v2x_*) (*)
		ren accountability_codelow accountability_lower 
		ren accountability_codehigh accountability_upper
		lab var accountability "Accountability index"
		lab var accountability_lower "Accountability index, lower bound of 68% probability distribution (~1 standard deviation below mean point estimate)"
		lab var accountability_upper "Accountability index, upper bound of 68% probability distribution (~1 standard deviation above mean point estimate)"
		
		// Save
			save VDem_Accountability, replace
			export delimited using VDem_Accountability, replace

**# Budget transparency score (Open Budget Initiative)
		import delimited using "$datain\ibp_data_summary_2006-2012.csv", clear
			tempfile series
			save `series', replace
		import delimited using "$datain\ibp_data_summary_2015.csv", clear
			tempfile y2015
			save `y2015', replace
		import delimited using "$datain\ibp_data_summary_2017.csv", clear
			tempfile y2017
			save `y2017', replace
		import delimited using "$datain\ibp_data_summary_2019.csv", clear
			tempfile y2019
			save `y2019', replace
		import delimited using "$datain\ibp_data_summary_2021.csv", clear
			tempfile y2021
			save `y2021', replace
		use `series', clear
		append using `y2015'
		append using `y2017'
		append using `y2019'
		append using `y2021'
		drop rank
		lab var open_budget_index "Open Budget Index Score"

			** NOTE: 2-digit country codes need to me matched to 3-digit ISO codes
			preserve
				import delimited using "$datain\countries-codes", clear
				ren iso2code ISO2
				ren iso3code ISO3
				keep ISO2 ISO3
				save iso-2_crosswalk, replace
			restore
				ren country ISO2
				merge m:1 ISO2 using iso-2_crosswalk, keepusing(ISO3)
				drop if _merge != 3
				drop _merge
				ren ISO3 ISO
				drop ISO2
			
			// Merge in country classifications
				browse if ISO == ""
				tab ISO
				preserve 
					use countryclassification, clear
					drop if ISO == ""
					drop if inlist(country,"West Bank", "Gaza Strip")
					drop if ISO == "IOT" // British Indian Ocean Territory and Chagos Archipelago
					tempfile class
						save `class', replace
				restore
					merge m:1 ISO using `class'
					drop if _merge != 3
					drop _merge
					lab var year ""
* Value for China is mainland only
				
		// Save
			save OBI, replace
			export delimited using OBI, replace

**# Guarantees for public access to information
		import excel using "$datain\SG_INF_ACCSS.xlsx", firstrow clear
			ren GeoAreaName country
			ren J yearofadoption
			lab var yearofadoption "Year of adoption"
			drop SeriesCode GeoAreaCode ReportingType Units K-AZ
			ren SeriesDescription accessinfo
			lab var accessinfo "Guarantees for public access to information (SDG 16.10.2)"
			replace accessinfo = "1"
			destring accessinfo, replace
			
			// Merge in country classification
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			replace accessinfo = 0 if accessinfo ==. & _merge == 2 & UNmemberstate == 1
				drop if _merge == 2 & UNmemberstate == 0
				drop _merge Goal Target Indicator
				order ISO country accessinfo yearofadoption 
				gen year = 2021 // policy picture as of 2021 (last year of adoption recorded)
			
		// Save
			save AccessInfo, replace
			export delimited using AccessInfo, replace

// RESILIENCE & SUSTAINABILITY /////////////////////////////////////////////////

** EXPOSURE TO SHOCKS **********************************************************

**# Total damages by GDP of all disasters (2021 $US) (EM-DAT)
		
		// Numerator: Total damages (2021 $US)
		import excel using "$datain\emdat_public_2022_10_09.xlsx", cellrange(A7:AX24426) firstrow clear // Take care to import the correct cell range to include all data, may vary by download of raw data 
			destring, replace
			describe OFDAResponse Appeal Declaration AIDContribution000US DisMagValue DisMagScale 
			foreach v in OFDAResponse Appeal Declaration DisMagScale  {
				tab `v'
			}
			sum DisMagValue AIDContribution000US

			// Collapse to country-year level, summing impact variables
				// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
				}
				*** Note we are not clear if there is possibility of double counting in this summation of all disasters
				collapse (sum) TotalDeaths NoInjured NoAffected NoHomeless TotalAffected  AIDContribution000US ReconstructionCosts000US ReconstructionCostsAdjusted InsuredDamages000US InsuredDamagesAdjusted000 TotalDamages000US TotalDamagesAdjusted000US (first) ISO, by(Country Year)
				
				// Relabel
					foreach v of var * {
					label var `v' "`l`v''"
						}
			
			// Merge in country classification
				ren Country country 
				ren Year year
				replace ISO = "" if country == "Netherlands Antilles"
				replace country = "United Arab Emirates" if country == "United Arab Emirates (the)"
				replace ISO = "" if country == "Azores Islands"
				replace country = "Bahamas" if country == "Bahamas (the)"
				replace country = "Côte D'Ivoire" if ISO == "CIV"
				replace country = "Democratic Republic of the Congo" if country == "Congo (the Democratic Republic of the)"
				replace country = "Congo" if country == "Congo (the)"
				replace country = "Cook Islands" if country == "Cook Islands (the)"
				replace country = "Comoros" if country == "Comoros (the)"
				replace country = "Cayman Islands" if country == "Cayman Islands (the)"
				replace country = "Czechia" if country == "Czech Republic (the)"
				replace country = "Dominican Republic" if country == "Dominican Republic (the)"
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom of Great Britain and Northern Ireland (the)"
				replace country = "Gambia (Republic of The)" if country == "Gambia (the)"
				replace country = "Republic of Korea" if country == "Korea (the Republic of)"
				replace country = "Lao People's Democratic Republic" if country == "Lao People's Democratic Republic (the)"
				replace country = "Republic of Moldova" if country == "Moldova (the Republic of)"
				replace country = "Marshall Islands" if country == "Marshall Islands (the)"
				replace country = "North Macedonia" if country == "Macedonia (the former Yugoslav Republic of)"
				replace country = "Northern Mariana Islands" if country == "Northern Mariana Islands (the)"
				replace country = "Niger" if country == "Niger (the)"
				replace country = "Netherlands" if country == "Netherlands (the)"
				replace country = "Philippines" if country == "Philippines (the)"
				replace country = "Dem People's Rep of Korea" if country == "Korea (the Democratic People's Republic of)"
				replace country = "Reunion" if country == "Réunion"
				replace country = "Russian Federation" if country == "Russian Federation (the)"
				replace country = "Sudan" if country == "Sudan (the)"
				replace country = "Turks and Caicos Islands" if country == "Turks and Caicos Islands (the)"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Taiwan" if country == "Taiwan (Province of China)"
				replace country = "United Republic of Tanzania" if country == "Tanzania, United Republic of"
				replace country = "United States of America" if country == "United States of America (the)"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "British Virgin Islands" if country == "Virgin Island (British)"
				replace country = "United States Virgin Islands" if country == "Virgin Island (U.S.)"				
				replace country = "Macau" if country == "Macao"

				merge m:1 ISO country using countryclassification
				browse if _merge!=3 
				drop if _merge!=3 // Drops historic states and Canary Islands that do not appear in any other dataset
				drop _merge
			
			// Save full dataset
				save EM-DAT_all, replace
				export delimited EM-DAT_all, replace
			
		// Bring in variables for denominator - GDP is selected, but also merge in alternative of land area
			use landarea, clear
			
			// merge in GDP
			merge 1:1 ISO year using GDP
			drop _merge
			replace GDP = GDP/1000
			lab var GDP "Gross domestic product, current US$, thousands"
			
			drop if year == 2022
			
			// Save denominator dataset
			save GDP_sqkm, replace
			
		// Generate indicator 
			use EM-DAT_all, clear
			
			// Keep total damages (nominal/current US$ impact variable) and real dollars and merge in denominator
			keep year TotalDamages000US TotalDamagesAdjusted000US ISO wb_region incgrp country
			tab year
			unique ISO year
			unique ISO
			merge 1:1 ISO country year using GDP_sqkm
			tab country if _merge==1 // non-zero damages records for territories that have no GDP and land area data: American Samoa, Anguilla, Azores Islands, Bermuda, British Virgin Islands, Cayman Islands, Cook Islands, French Guiana, French Polynesia, Guadeloupe, Guam, Hong Kong, Macao, Martinique, Montserrat, Netherlands Antilles, New Caledonia, Niue, Northern Mariana Islands, Palestine, Puerto Rico, Reunion, Saint Helena, Ascension and Tristan,  Taiwan, Tokelau, Turks and Caicos Islands, United States Virgin Islands, Wallis and Futuna.
			drop _merge 

			// Generate indicator: Total damages of all disasters (current US$, thousands) (EM-DAT), by GDP (current US$, thousands) 

				// Convert current dollar damages from thousands to units to match GDP digits
					gen damages = TotalDamages000US
					lab var damages "Total Damages (current $US, thousands)"
					gen damages_gdp = damages / GDP
					lab var damages_gdp "Ratio of total damages to GDP"
					replace damages_gdp = damages_gdp * 100 // change scale for readability
					gen damages_sqkm = TotalDamagesAdjusted000US / landarea
					lab var damages_sqkm "Total damages (2015 US$, thousands) per square km"
					drop if year == 2022 // drop because the year is still incomplete					
			
		// Save
			save damages, replace
			export delimited using damages, replace
			
			
** RESILIENCE CAPACITIES *******************************************************

**# Dietary sourcing flexibility index (FAO) - provided directly by FAO 
		import excel using "$datain\DSFI_EnergyFruitVeg_2016-2018.xlsx", clear
			drop in 1/1 // drop info line
			ren A country
			ren B kcal_production
			ren C kcal_import
			ren D kcal_stocks
			ren E kcal_total
			ren F fv_production
			ren G fv_imports
			ren H fv_stocks
			ren I fv_total
			lab var kcal_production "Kcal diversity, domestic production"
			lab var kcal_import "Kcal diversity, imports"
			lab var kcal_stocks "Kcal diversity, stocks"
			lab var kcal_total "Dietary sourcing flexibility index, calories (all sources)"
			lab var fv_production "Fruit & vegetable diversity, domestic production"
			lab var fv_imports "Fruit & vegetable diversity, imports"
			lab var fv_stocks "Fruit & vegetable diversity, stocks"
			lab var fv_total "Dietary sourcing flexibility index, fruits & vegetables (all sources)"
			drop in 1/3 // drop remaining headers
			
			// Drop aggregated areas
			drop if inlist(country, "WORLD", "AFRICA", "AMERICA", "ASIA", "EUROPE", "OCEANIA ", "Northern Africa")
			drop if inlist(country, "Sub-Saharan Africa", "Middle Africa", "Western Africa", "Latin America and the Caribbean", "Northern America")
			drop if inlist(country, "Central Asia", "South-eastern Asia", "Southern Asoa", "Western Asia", "Eastern Europe", "Northern Europe", "Southern Europe", "Caribbean", "South America")
			drop if inlist(country, "Australia and New Zealand", "Central America", "Eastern Africa", "Eastern Asia", "Melanesia", "Polynesia")
			drop if inlist(country, "Southern Africa", "Southern Asia", "Western Europe")
			tempfile kcal_fv
				save `kcal_fv', replace

		import excel using "$datain\DSFI_ProteinFat_2016-2018.xlsx", clear
			drop in 1/1 // drop info line
			ren A country
			ren B protein_production
			ren C protein_import
			ren D protein_stocks
			ren E protein_total
			ren F fat_production
			ren G fat_imports
			ren H fat_stocks
			ren I fat_total
			lab var protein_production "Protein diversity, domestic production"
			lab var protein_import "Protein diversity, imports"
			lab var protein_stocks "Protein diversity, stocks"
			lab var protein_total "Dietary sourcing flexibility index, protein (all sources)"
			lab var fat_production "Fats diversity, domestic production"
			lab var fat_imports "Fats diversity, imports"
			lab var fat_stocks "Fats diversity, stocks"
			lab var fat_total "Dietary sourcing flexibility index, fats (all sources)"
			drop in 1/3 // drop remaining headers
				
				// Drop aggregated areas
				drop if inlist(country, "WORLD", "AFRICA", "AMERICA", "ASIA", "EUROPE", "OCEANIA ", "Northern Africa")
				drop if inlist(country, "Sub-Saharan Africa", "Middle Africa", "Western Africa", "Latin America and the Caribbean", "Northern America")
				drop if inlist(country, "Central Asia", "South-eastern Asia", "Southern Asoa", "Western Asia", "Eastern Europe", "Northern Europe", "Southern Europe", "Caribbean", "South America")
				drop if inlist(country, "Australia and New Zealand", "Central America", "Eastern Africa", "Eastern Asia", "Melanesia", "Polynesia")
				drop if inlist(country, "Southern Africa", "Southern Asia", "Western Europe")
				tempfile pro_fat
					save `pro_fat', replace
		
		use `kcal_fv', clear
			merge 1:1 country using `pro_fat'
			drop _merge
			
			// Merge in country classification
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Micronesia (Federated States of)" if country == "Micronesia"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				drop if country == "China" // aggregate - drop to avoid double counting
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "China" if country == "China, mainland"
				merge 1:1 country using iso
				drop if _merge!=3
				drop _merge
				merge 1:1 country ISO using countryclassification
				browse if _merge!=3
				drop if _merge != 3 
				drop _merge
				gen dsfiyearrange = "2016-2018"
				gen year = 2018
				destring kcal_production kcal_import kcal_stocks kcal_total fv_production fv_imports fv_stocks fv_total protein_production protein_import protein_stocks protein_total fat_production fat_imports fat_stocks fat_total, replace
			// Save
				save dsfi, replace
				export delimited using dsfi, replace

**# Mobile cellular subscriptions (per 100 people) (International Telecommunications Union / World Bank)
		import delimited using "$datain\API_IT.CEL.SETS.P2_DS2_en_csv_v2_4151010.csv", clear rowrange(4:271)
			ren v1 country
			ren v2 ISO
			drop v4 // WDI code
			drop v66 v67 // 2021 with no data and an extra column of all missing data
			ren v5-v65 mobile#, addnumber(1960)
			drop mobile1960-mobile1990 // years before consumer mobile technology
			drop v3 // variable label "Mobile cellular subscriptions (per 100 people)"
			reshape long mobile, i(country ISO) j(year)
			lab var mobile "Mobile cellular subscriptions (number, per 100 people)"
			
			// Add in country classification
				replace country = "Bahamas" if country == "Bahamas, The"
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Côte D'Ivoire" if country == "Cote d'Ivoire"
				replace country = "Democratic Republic of the Congo" if country == "Congo, Dem. Rep."
				replace country = "Congo" if country == "Congo, Rep."
				replace country = "Curaçao" if country == "Curacao"
				replace country = "Czechia" if country == "Czech Republic"
				replace country = "Egypt" if country == "Egypt, Arab Rep."
				replace country = "Micronesia (Federated States of)" if country == "Micronesia, Fed. Sts."
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
				replace country = "Gambia (Republic of The)" if country == "Gambia, The"
				replace country = "Iran (Islamic Republic of)" if country == "Iran, Islamic Rep."
				replace country = "Kyrgyzstan" if country == "Kyrgyz Republic"
				replace country = "Saint Kitts and Nevis" if country == "St. Kitts and Nevis"
				replace country = "Republic of Korea" if country == "Korea, Rep."
				replace country = "Lao People's Democratic Republic" if country == "Lao PDR"
				replace country = "Saint Lucia" if country == "St. Lucia"
				replace country = "Republic of Moldova" if country == "Moldova"
				replace country = "Dem People's Rep of Korea" if country == "Korea, Dem. People's Rep."
				replace country = "Slovakia" if country == "Slovak Republic"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "United Republic of Tanzania" if country == "Tanzania"
				replace country = "Saint Vincent and the Grenadines" if country == "St. Vincent and the Grenadines"
				replace country = "United States of America" if country == "United States"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela, RB"
				replace country = "United States Virgin Islands" if country == "Virgin Islands (U.S.)"
				replace country = "Viet Nam" if country == "Vietnam"
				replace country = "Yemen" if country == "Yemen, Rep."
				replace country = "Macau" if country == "Macao SAR, China"
				replace country = "Hong Kong" if country == "Hong Kong SAR, China"
				replace country = "Sint Maarten (Dutch part)" if country == "Sint Maarten (Dutch Part)"
				replace country = "Saint Martin (French Part)" if country == "Saint Martin (French part)"
				replace country = "Palestine, State of" if country == "West Bank and Gaza"
				merge m:1 ISO country using countryclassification
				browse if _merge!=3
				drop if _merge!=3 // aggregate groups, Curacao, Kosovo, Saint Martin, Sint Maarten
				drop _merge
				sort ISO country wb_region incgrp mobile
			
		// Save
			save mobile, replace
			export delimited using mobile, replace

**# Social Capital Index - Legatum Prosperity Index
		import excel using "$datain\2021_Full_Data_Set_-_Legatum_Prosperity_Index.xlsx", sheet("Indicators x 300") firstrow clear
			destring, replace
			describe
			ren area_name country
			ren area_code ISO
			foreach v in country area_group pillar_name element_name indicator_name {
				encode `v', gen(`v'_)
			}
			drop area_group pillar_name element_name indicator_name
			ren country country_string
			rename *_ *
			
			// Keep social capital score indicators only
				drop rank* raw_value* area_group
				order country ISO pillar_name element_name indicator_name, first
				tab pillar_name 
				tab pillar_name, nolabel
				keep if pillar_name==12
				tab element_name 
				// indicators of interest:
					* help from family and friends 
					* generalized interpersonal trust
					* confidence in financial institutions and banks
					* public trust in politicians or confidence in national government
				tab indicator_name
				tab indicator_name, nolabel
					* help from family and friends 139
					* generalized interpersonal trust 122
					* confidence in financial institutions   50
					* public trust in politicians or confidence in national government 226
				keep if inlist(indicator_name,139,122,50,226)
				drop pillar_name element_name			
			
			// Reshape
				reshape long score_, i(country country_string ISO indicator_name) j(year)
				ren *_ *
				misstable sum score
				reshape wide score, i(country country_string ISO year) j(indicator_name)
				ren *139 help_*
					lab var help_score "Help from family & friends"
				ren *122 trust_*
					lab var trust_score "Generalized interpersonal trust"
				ren *50 finconf_*
					lab var finconf_score "Confidence in financial institutions"
				ren *226 poltrust_*
					lab var poltrust_score "Public trust in politicians or confidence in national government"			
			
			// Confirm no strong correlations among 4 indicators:
				pwcorr finconf_score trust_score help_score poltrust_score, star(.05) 
				spearman finconf_score trust_score help_score poltrust_score, pw star(.05)
			
			// Create composite index
				sum finconf_score trust_score help_score poltrust_score, d
				ameans finconf_score trust_score help_score poltrust_score
				tempfile wide
					save `wide', replace
				ren (finconf_score trust_score help_score poltrust_score) (soccap(#)), addnumber
				reshape long soccap, i(country country_string year) j(origvar)
				lab drop indicator_name_
				egen soccapindex=gmean(soccap), by(country year)
				lab var soccapindex "Social capital (index)"
					// Save labels
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}
				collapse (first) ISO soccapindex, by(country country_string year)
					// Relabel
						foreach v of var * {
						label var `v' "`l`v''"
							}
				
				// Merge individual variables back in
					merge 1:1 country year using `wide', keepusing(finconf_score trust_score help_score poltrust_score)
					drop _merge
			
			// Merge in country classification
				drop country
				ren country_string country
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Democratic Republic of the Congo" if country == "Democratic Republic of Congo"
				replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "United Kingdom"
				replace country = "Gambia (Republic of The)" if country == "The Gambia"
				replace country = "Iran (Islamic Republic of)" if country == "Iran"
				replace country = "Republic of Korea" if country == "South Korea"
				replace country = "Lao People's Democratic Republic" if country == "Laos"
				replace country = "Republic of Moldova" if country == "Moldova"
				replace country = "Russian Federation" if country == "Russia"
				replace country = "Sao Tome and Principe" if country == "São Tomé and Príncipe"
				replace country = "Syrian Arab Republic" if country == "Syria"
				replace country = "Türkiye" if country == "Turkey"
				replace country = "Taiwan" if country == "Taiwan, China"
				replace country = "United Republic of Tanzania" if country == "Tanzania"
				replace country = "United States of America" if country == "United States"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
				replace country = "Viet Nam" if country == "Vietnam"
				merge m:1 ISO country using countryclassification
					browse if _merge!=3 
					drop if _merge!=3 
					drop _merge
				sort ISO year
				order ISO country year, first
	
		// save dataset
			save socialcapital, replace
			export delimited socialcapital, replace

** AGRO- AND FOOD DIVERISTY
**# Proportion of agricultural land with minimum level of species diversity (crop and pasture) (FAO, SPAM / FSCI)
	/* Method to produce the input dataset: We adopted total crop species (1-32) and total livestock species (0-8) distributions for the year 2010 as global georeferenced data in a 10x10km resolution from Jones et al. 2021. Using QGIS 3.26.1, we generated a dataset on total global species richness (0-38) by adding up both individual layers, and produced country-level zonal histograms based on world administrative boundaries by the World Food Programme (2019). 
	Reference: Jones, SK et al. (2021) Agrobiodiversity Index scores show agrobiodiversity is underutilized in national food systems. https://doi.org/10.1038/s43016-021-00344-3
	Layer sources: 
		https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2PEPLH
			File name crops: sr_2010_spam_v2r0_42c
			File name livestock: Livestock_8_richness	
		https://public.opendatasoft.com/explore/dataset/world-administrative-boundaries/information/
*/
	
		import delimited using "$datain\global.hist.tsr.csv", clear
		drop status color_code region continent iso_3166_1_ french_shor
		ren name country
		ren iso3 ISO
		ren histo_# aglandpixels_#
		foreach v of varlist aglandpixels* {
			lab var `v' ""
		}
		ren histo_nodata nonagpixels
			* HISTO_ variables denote distribution of no of pixels (1 pixel = 10x10km or 10,000 ha) for species count 1-38) within each country
			* sum total number of pixels per country
			egen totalagpixels_country = rowtotal(aglandpixels_1-aglandpixels_38)
					// Drop countries where all land area is missing species data
					tempvar missingcheck
						gen `missingcheck' = 1 if totalagpixels_country == 0
						tab country if `missingcheck' == 1
						drop if `missingcheck' == 1
			
			// Collapse the dataset to the global level to find the threshold number of species at which (and above) covers 25% of global ag land (the 25% of land with the most diversity)
				preserve 
					// Save labels
						foreach v of var * {
						local l`v' : variable label `v'
							if `"`l`v''"' == "" {
							local l`v' "`v'"
							}
						}
					collapse (sum) aglandpixels_* totalagpixels_country
						// Relabel
							foreach v of var * {
							label var `v' "`l`v''"
								}
					ren totalagpixels_country totalagpixels_world
					lab var totalagpixels_world ""
					gen topquartile_allagpix = totalagpixels_world / 4
					
					// Reshape long
					gen i = 1
					reshape long aglandpixels_, i(i) j(N_species)
					ren aglandpixels_ aglandpixels
					
					// Identify cumulative percent of agricultural land by number of species
					gsort- N_species
						// Generate cumulative share of total agricultural land
						gen cumagpix = aglandpixels if N_species == 38
						forval N = 37(-1)1 {
						replace cumagpix = aglandpixels + cumagpix[_n-1] if N_species == `N'
							}
							
							* Identify the number of species where the cumulative number of pixels most closely approximates the top 25% of all ag land ranked by species diversity
							tab N_species, sum(cumagpix)
				restore
		
				// Merge in country classification
					replace country = "Antigua and Barbuda" if country == "Antigua & Barbuda"
					replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
					replace country = "Bosnia and Herzegovina" if country == "Bosnia & Herzegovina"
					replace country = "Cabo Verde" if country == "Cape Verde"
					replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
					replace country = "Czechia" if country == "Czech Republic"
					replace country = "Eswatini" if country == "Swaziland"
					replace country = "Gambia (Republic of The)" if country == "Gambia"
					replace country = "Libya" if country == "Libyan Arab Jamahiriya"
					replace country = "North Macedonia" if country == "The former Yugoslav Republic of Macedonia"
					replace country = "Republic of Moldova" if country == "Moldova, Republic of"
					replace country = "Türkiye" if country == "Turkey"
					replace country = "United Kingdom of Great Britain and Northern Ireland" if country == "U.K. of Great Britain and Northern Ireland"
					replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela"
					replace country = "Viet Nam" if country == "Vietnam"		
					replace ISO = "PSE" if inlist(country,"West Bank", "Gaza Strip")
					replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
					replace country = "Ilemi triangle" if country == "Ilemi Triangle" 
					replace country = "Jammu and Kashmir" if country == "Jammu-Kashmir" 
					merge 1:1 ISO country using countryclassification
						browse if _merge!=3
					
					drop if _merge != 3 // Drop Abyei
					drop _merge

				// Calculate percent of total ag land that has the minimum species diversity per country
					egen pixelsminspecies = rowtotal(aglandpixels_24-aglandpixels_38)
					gen pctagland_minspecies = (pixelsminspecies / totalagpixels_country)*100
					lab var pctagland_minspecies "Percent of agricultural land with minimum species diversity (24 or more species)"
					drop aglandpixels* nonagpixels
				
				gen year = 2010

				// Save
					save minspeciesrichness, replace
					export delimited using minspeciesrichness, replace

**# Number of animal genetic resources and wild useful plants for food and agriculture secured in conservation facilities (SDGs)
			import delimited using "$datain\FAOSTAT_geneticresources.csv", clear
			ren area country
			tab item
			encode item, gen(indicator)
 			tab unit
			drop domaincode domain areacodem49 elementcode element itemcodesdg item yearcode unit flag flagdescription note
			drop if value == .
			reshape wide value, i(country year) j(indicator)
			ren value1 genres_plant
			ren value2 genres_animal
			lab var genres_plant "Plant genetic resources accessions stored ex situ (number)"
			replace genres_plant = genres_plant / 1000 // convert to thousands
			lab var genres_plant "Plant genetic resources accessions stored ex situ (thousands)"
			lab var genres_animal "Number of local breeds for which sufficient genetic resources are stored for reconstitution"
			
			// Merge in country classification
				replace country = "Hong Kong" if country == "China, Hong Kong Special Administrative Region"
				replace country = "Macau" if country == "China, Macao Special Administrative Region"
				replace country = "Palestine, State of" if country == "State of Palestine"
				replace country = "Heard Island and McDonald Islands" if country == "Heard and McDonald Islands"
				replace country = "French Southern and Antarctic Territories" if country == "French Southern Territories"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Pitcairn" if country == "Pitcairn Islands"
				replace country = "Reunion" if country == "Réunion"
				replace country = "South Georgia & the South Sandwich Islands" if country == "South Georgia and the South Sandwich Islands"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				replace country = "Wallis and Futuna" if country == "Wallis and Futuna Islands"	
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			replace country = "Saint Pierre et Miquelon" if country == "Saint Pierre and Miquelon"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
				drop if _merge != 3  
				drop _merge
				sort ISO year
			
			// Save
				save geneticresources, replace
				
				
** RESILIENCE RESPONSES/STRATEGIES *********************************************

**# Coping strategies index (WFP) 
		import delimited using "$datain\food_security_timeseries_2020", clear
			* convert dates to Stata date format
			tab date
			ren date date_str
			gen day = substr(date_str,1,2)
			gen month = substr(date_str,4,2)
			gen year = substr(date_str,7,2)
			destring day month year, replace
			replace year=2020 if year==20
			gen date = mdy(month, day, year)
				format date %tdDD/NN/YY
			tab date
			drop day month year date_str
			gen year = year(date)
			gen month = month(date)
			gen day = day(date)
			// save
			tempfile wfp2020
			save `wfp2020', replace
		
		import delimited using "$datain\food_security_timeseries_2021", clear
			* convert dates to Stata date format
			tab date
			ren date date_str
			gen day = substr(date_str,1,2)
			gen month = substr(date_str,4,2)
			gen year = substr(date_str,7,2)
			destring day month year, replace
			replace year=2021 if year==21
			gen date = mdy(month, day, year)
				format date %tdDD/NN/YY
			tab date
			drop day month year date_str
			gen year = year(date)
			gen month = month(date)
			gen day = day(date)
			// save
			tempfile wfp2021
			save `wfp2021', replace
		
		import delimited using "$datain\food_security_metrics_data_2021-06_to_2022-07.csv", clear
			* convert dates to Stata date format
			tab date
			ren date date_str
			gen day = substr(date_str,1,2)
			gen month = substr(date_str,4,2)
			gen year = substr(date_str,7,2)
			destring day month year, replace
			replace year=2021 if year==21
			replace year=2022 if year==22
			gen date = mdy(month, day, year)
				format date %tdDD/NN/YY
			tab date
			drop day month year date_str
			gen year = year(date)
			gen month = month(date)
			gen day = day(date)
			// drop 2021 dates
			drop if year == 2021
			// save
			tempfile wfprecent
			save `wfprecent', replace
		
		// Combine years of data
			use `wfp2020', clear
			append using `wfp2021'
			append using `wfprecent'
			sort date
			tab date
			describe
			ren country ISO
			tab datatype
			encode datatype, gen(method)
			tab method
			recode method (1=3) (3=1)
			lab def method 1 "Survey" 2 "Predicted" 3 "Mixed", replace
			lab val method method
			lab var method "Data collection method"
			tab method
			tab country_name if method==1
			tab country_name if method==3 // CAR, Congo, Nigeria
			
		// Drop FCS variables
			drop fcs_people fcs_prevalence
			
		// Label variables
			lab var rcsi_prevalence "Prevalence of reduced coping strategies (%), daily"
			* Convert prevalence to 0-100 scale
				replace rcsi_prevalence=rcsi_prevalence*100
				
			// Merge in country classification
				ren country_name country
				replace country = "Bolivia (Plurinational State of)" if country == "Bolivia"
				replace country = "Côte D'Ivoire" if country == "Côte d'Ivoire"
				replace country = "Côte D'Ivoire" if country == "CÃ´te d'Ivoire"
				replace country = "Cabo Verde" if country == "Cape Verde"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Iran (Islamic Republic of)" if country == "Iran  (Islamic Republic of)"
				replace country = "Republic of Moldova" if country == "Moldova, Republic of"
				replace country = "Palestine, State of" if country == "State of Palestine"
				merge m:1 ISO country using countryclassification
				browse if _merge!=3
				drop if _merge!=3
				drop _merge  
			
			// Keep only complete years
				drop if year == 2020
				drop if year == 2022
			
			// Calculate annual metric as maximum prevalence observed in the year 
					// Save labels
						foreach v of var * {
						local l`v' : variable label `v'
							if `"`l`v''"' == "" {
							local l`v' "`v'"
							}
						}
					collapse (max) rcsi_prevalence (first) incgrp wb_region disp_area UN_status_detail UNmemberstate UN_status territoryof ISO_governing, by(ISO country year)
						// Relabel
							foreach v of var * {
							label var `v' "`l`v''"
								}
			lab var rcsi_prevalence "Annual maximum prevalence of use of severe coping strategies (%)"
			
			// Save
				save rCSI_2021, replace
				export delimited using rCSI_2021, datafmt replace
	
	
** LONG-TERM OUTCOMES **********************************************************

**# Food price volatility (FAO / FSCI) 
	import delimited using "$datain\FAOSTAT_Monthly Food CPI_2000-2020", clear 
		ren value CPI_food
		lab var CPI_food "Consumer Prices, Food Indices (2015 = 100)"
		drop domaincode domain areacodefao yearcode itemcode item monthscode unit
		
		// Merge in country classification
			ren area country
			replace country="Côte D'Ivoire" if country=="C?te d'Ivoire"
			replace country="Reunion" if country=="R?union"
			replace country="Türkiye" if country=="T?rkiye"
			replace country = "Gambia (Republic of The)" if country == "Gambia"
			replace country = "Palestine, State of" if country == "Palestine"
			replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
			drop if country == "China" // drop aggregate China to avoid double counting
			replace country = "China" if country == "China, mainland"
			replace country = "Hong Kong" if country == "China, Hong Kong SAR"
			replace country = "Taiwan" if country == "China, Taiwan Province of"
			replace country = "Macau" if country == "China, Macao SAR"
			replace country = "Åland Islands" if country == "?land Islands"
			replace country = "Curaçao" if country == "Cura?ao"

			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			browse if _merge!=3
				drop if _merge!=3 // Aland islands and Curacao
				drop _merge
			* Convert dates to date format
				gen monthnum = month(date(months, "M"))
				tostring year, replace
				gen yearnum = year(date(year, "Y"))
				gen date = ym(yearnum, monthnum)
					format date %tm
					drop year months
					ren monthnum month
					ren yearnum year
				order ISO country, first
				order wb_region incgrp flag flagdescription note, last
		
			// Diagnostics - test for stationarity
				encode ISO, gen(i)
				xtset i date // unbalanced
					tab ISO
					egen countnm = count(CPI_food != .), by(ISO)
					tab ISO, sum(countnm)
					tab country if countnm<264
					* Unbalanced panel because Sudan has missing data
				
				// Log the index
					gen log_fpi = log(CPI_food)
						lab var log_fpi "Logged Food Price Index, monthly"
				
				/* Visual inspection
					forval r=1/7 {
						local v : label (wb_region) `r'
						xtline log_fpi if wb_region == `r', overlay legend(size(tiny) rowgap(zero) rows(4)) name(fpi_`r', replace) ytitle("Log Food Price Index") xtitle("") title("`v'", size(small))
					}
					forval r=1/7 {
						graph display fpi_`r'
						graph export fpi_`r'.png, replace
					} */

				// Unit root tests
					* Key features of the data that define most appropriate test:
						* Unbalanced panel
						* assumption that all panels share the same autoregressive parameter so that ρi = ρ for all i does not hold
						** --> only fisher-type and Im–Pesaran–Shin tests can be used
					xtunitroot ips CPI_food, demean 
					xtunitroot ips CPI_food, trend 
					xtunitroot ips CPI_food, demean trend
					xtunitroot fisher CPI_food, lags(11) dfuller // 11 lags to account for seasonality
					xtunitroot fisher CPI_food, lags(11) dfuller drift // --> Evidence of drift
					xtunitroot fisher CPI_food, lags(11) dfuller trend // --> No evidence of trend
					xtunitroot fisher CPI_food, lags(11) pperron
					* --> As expected, evidence of non-stationarity
				
				// First difference the logged FPI by convention (Gilbert & Morgan 2010)
					sort ISO date
					by ISO: gen fpi_diff1 = log_fpi[_n] - log_fpi[_n-1]
						* Take the absolute value of the logged first difference
						sum fpi_diff1
						sum fpi_diff1 if fpi_diff1 < 0
						replace fpi_diff1 = abs(fpi_diff1)
						lab var fpi_diff1 "Absolute value of first difference of logged monthly Food Price Index"
					
					* IPS test
					xtunitroot ips fpi_diff1 // reject H0 that all are non-stationary in favor of Ha that at least one panel is stationary
						xtunitroot ips fpi_diff1, demean // no evidence of drift (test stats unaltered relative to first specification)
						xtunitroot ips fpi_diff1, trend  // no evidence of trend (test stats unaltered relative to first specification)
						xtunitroot ips fpi_diff1, demean trend
					* ADF test
						xtunitroot fisher fpi_diff1, lags(11) dfuller // 11 lags to account for seasonality
							* identify fewest lags that are still significant
							xtunitroot fisher fpi_diff1, lags(1) dfuller
							* test for drift and trend
								xtunitroot fisher fpi_diff1, lags(1) dfuller drift // --> No evidence of drift 
								xtunitroot fisher fpi_diff1, lags(1) dfuller trend // --> No evidence of trend
					* PPerron test
						xtunitroot fisher fpi_diff1, lags(1) pperron
						* --> confirm first differencing logged FPI results in trend stationarity
					
				/* visualize first difference of logged FPI
					forval r=1/7 {
					local v : label (wb_region) `r'
					xtline fpi_diff1 if wb_region == `r', overlay legend(size(tiny) rowgap(zero) rows(4)) name(fdiff_fpi_`r', replace) ytitle("Log Food Price Index") xtitle("") title("`v'", size(small))
				}
					// visualize per country
					sum i
					forval i=1/198 {
					local v : label (i) `i'
					xtline fpi_diff1 if i == `i', overlay legend(off) name(fpvol_`i', replace) ytitle("Log Food Price Index") xtitle("") title("`v'", size(small))
				}*/

			// Generate volatility measures
				sort ISO year
				egen fpi_sd = sd(fpi_diff1), by(ISO year)
					lab var fpi_sd "Standard Deviation of (first differenced logged) Food Price Index, annual"
					sum fpi_sd
				egen fpi_mean = mean(fpi_diff1), by(ISO year)
					lab var fpi_mean "Mean of (first differenced logged) Food Price Index, annual"
					sum fpi_mean
				bys ISO year: gen fpi_cv = (fpi_sd / fpi_mean)
					lab var fpi_cv "Food price volatility (CV of first difference logged food price index), annual"
					sum fpi_cv
					* Check
					tabstat fpi_diff1, stats(sd mean cv) by(ISO)
					sum fpi_sd fpi_mean fpi_cv
				
			// Save
				drop flag flagdescription note i countnm 
				order ISO country year wb_region incgrp fpi_sd fpi_cv, first
				save foodpricevolatility, replace
				export delimited using foodpricevolatility, replace
				
			// Collapse to yearly dataset to merge with other data
				use foodpricevolatility, clear
					// Save labels
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}
					collapse (first) fpi_sd fpi_cv fpi_mean (mean) CPI_food, by(ISO country year wb_region incgrp m49_code UN_continental_region UN_subregion UN_intermediary_region UN_contregion_code UN_subregion_code UN_intermedregion_code)
					// Relabel
						foreach v of var * {
						label var `v' "`l`v''"
							}
						lab var CPI_food "Mean annual CPI-Food"
			
			// Save
				save foodpricevolatility_annual, replace
				export delimited using foodpricevolatility_annual, replace
			
**# Food supply variability (FAO)
		import delimited using "$datain\FAOSTAT_FoodSupplyVariability.csv", clear
			ren area country
			drop item // variable label "Per capita food supply variability (kcal/cap/day)"
			drop domaincode domain areacodem49 elementcode element itemcode item unit flag flagdescription note
			ren value foodsupplyvar
			lab var foodsupplyvar "Per capita food supply variability (kcal/cap/day)"
			drop yearcode
			
			// Merge in country classification
				replace country = "Côte D'Ivoire" if country == "C?te d'Ivoire"
				replace country = "Gambia (Republic of The)" if country == "Gambia"
				replace country = "Venezuela, Bolivarian Republic of" if country == "Venezuela (Bolivarian Republic of)"
				drop if country == "China" // aggregate - drop to avoid double counting
				replace country = "Hong Kong" if country == "China, Hong Kong SAR"
				replace country = "Macau" if country == "China, Macao SAR"
				replace country = "Taiwan" if country == "China, Taiwan Province of"
				replace country = "China" if country == "China, mainland"
				replace country = "Palestine, State of" if country == "Palestine"
				replace country = "Türkiye" if country == "T?rkiye"
				replace country = "Dem People's Rep of Korea" if country == "Democratic People's Republic of Korea"
			merge m:1 country using iso
				drop if _merge!=3
				drop _merge
			merge m:1 country ISO using countryclassification
			drop if _merge == 2
				drop _merge
				
			// Further clean
				sort country year
				sum foodsupplyvar if year==2021
				drop if year == 2021 // all missing
				order ISO country year, first
			
		// Save
			save foodsupplyvariability, replace
			export delimited using foodsupplyvariability, replace

			
**# COMBINED MASTER DATASET - ALL YEARS ****************************************

* context and merging variables
	use countryclassification, clear
	expand 63
	egen year = seq(), from(1960) by(ISO country)
		tab year
	merge 1:m ISO country year using population
		drop _merge
	merge 1:1 ISO country year using GDP
		drop _merge
	merge 1:1 ISO country year using landarea
		drop _merge

* Diets, nutrition  & health
	merge 1:1 ISO country year using fruitveg_availability, nogen
	merge 1:1 ISO country year using UPFretailval, nogen // TO BE REMOVED IF PERMISSION NOT SECURED
		drop UPFretailval
	merge 1:1 ISO country year using safewater, nogen 
	merge 1:1 ISO country year using FIES_modsev, nogen
		drop unit
	merge 1:1 ISO country year using costofdiet, nogen
	merge 1:1 ISO country year using POU, nogen
		drop pou_string
	merge 1:1 ISO country year using DQQ_2021, nogen force
		drop *_LCI *_UCI GDR_score*
	merge 1:1 ISO country year using MDD_youngchild, nogen 
		drop datasource_year source1 source2
	merge 1:1 ISO country year using ZeroFV_youngchild, nogen
		drop datasource_year source1 source2

* Environment, production, & natural resources
	merge 1:1 ISO country year using fsemissions, nogen keepusing(fs_emissions) 
	merge 1:1 ISO country year using emissions_intensity, nogen 
		* Drop total emissions 
		drop emiss*
	merge 1:m ISO country year using yield, nogen 
	merge 1:1 ISO country year using croplandexpansion, keepusing(croplandchange_pct) nogen
	merge 1:1 ISO country year using agwaterdraw, nogen
	merge 1:1 ISO country year using functionalintegrity, nogen
		drop areaha
	merge 1:1 ISO country year using fishhealth, nogen keepusing(fishhealth)
	merge 1:1 ISO country year using pesticides, nogen
	merge 1:1 ISO country year using sustNO2mgmt, nogen

* Livelihoods, poverty, and equity
	merge 1:1 ISO country year using agshareGDP, nogen
	merge 1:1 ISO country year using unemployment_urbrur, nogen
	merge 1:1 ISO country year using underemployment_urbrur, nogen
		drop underemp_3
	merge 1:1 ISO country year using SP_coverage, nogen
	merge 1:1 ISO country year using SP_adequacy, nogen
	merge 1:1 ISO country year using childlabor, nogen
	merge 1:1 ISO country year using landholdings_female, keepusing(landholding_fem) nogen

* Governance
	merge 1:1 ISO country year using VDem_CSPI, nogen
		drop cspart_*
	merge 1:1 ISO country year using mufpp_pop, nogen
		drop nmufppcities mufpp_urbpop landscan_population
	merge 1:1 ISO country year using righttofood, nogen
		drop multiple_policies
	merge 1:1 ISO country year using fspathways, nogen 
	merge 1:1 ISO country year using goveffectiveness, nogen
		drop ge_LCI ge_UCI ge_se
	merge 1:1 ISO country year using foodsafety, nogen
	merge 1:1 ISO country year using healthtax, nogen keepusing(healthtax)
	merge 1:1 ISO country year using VDem_Accountability, nogen
		drop *lower *upper
	merge 1:1 ISO country year using OBI, nogen
	merge 1:1 ISO country year using AccessInfo, nogen
		drop yearofadoption

* Resilience
	merge 1:1 ISO country year using damages, keepusing(damages_gdp) nogen
	merge 1:1 ISO country year using dsfi, nogen
		drop kcal_production kcal_import kcal_stocks fv_production fv_imports fv_stocks protein_production protein_import protein_stocks fat_production fat_imports fat_stocks fv_total	protein_total fat_total
	merge 1:1 ISO country year using mobile, nogen
	merge 1:1 ISO country year using socialcapital, nogen
		drop finconf_score trust_score help_score poltrust_score 
	merge 1:1 ISO country country year using minspeciesrichness, keepusing(pctagland_minspecies) nogen
	merge 1:1 ISO country year using geneticresources, nogen keepusing(genres*)
	merge 1:1 ISO country year using rCSI_2021, nogen keepusing(rcsi_prevalence)
	merge 1:1 ISO country year using foodpricevolatility_annual, nogen keepusing(fpi_cv)
	merge 1:1 ISO country year using foodsupplyvariability, nogen
		
		// Organize dataset
			* Move total production to end
			order prod_* areaharvested* producing* pop_u, last
			* Move sex and geographic disaggregations of variables with totals to end
			order MDD_iycf_m MDD_iycf_f MDD_iycf_u MDD_iycf_r zeroFV_iycf_m zeroFV_iycf_f zeroFV_icyf_u zeroFV_icyf_r childlabor_f childlabor_m, last
			* move indicator yearrange variables to end
			order fies_yearrange pou_yearrange dsfiyearrange, last
			* order land area variables
			order landarea agland_area cropland, after(GDP_percap)
			
		// Additional territory information/
			// Replace ISO_governing for territories without
				browse if ISO == ""
				tab country if ISO == ""
				unique country if ISO == ""
				browse if ISO_governing == "" & UNmemberstate == 0 
					// Drop Antarctica - no data for any variable
					drop if ISO == "ATA"

				tab ISO_governing if UNmemberstate == 0, m
				unique country if UNmemberstate == 0
				
		// Drop territories without data for >80% of indicators in the latest year per area-indicator (determined using the latest year dataset, see code below)		
			* Result: drop all areas that are non-UN members, none have data in the latest year for >50th percentile of coverage of member states (40 indicators)
			drop if UNmemberstate == 0

	order incgrp wb_region UNmemberstate year, after(country)
	order ISO, first
		
		// Relabel 
			lab val wb_region wb_region
			lab val UNmemberstate yesno
			
		// Drop unnecessary classifiers
		drop disp_area UN_status UN_status_detail territoryof ISO_governing
	
	// Save
		save FSCI_2022_timeseries, replace
		export delimited FSCI_2022_timeseries, replace
		
// Document data coverage per indicator ////////////////////////////////////////
		use FSCI_2022_timeseries, clear
		sort ISO year

			* Set excel - write to coverage spreadsheet for manual copy into metadata and codebook Excel workbook
			putexcel set "$tables\FSCI2022_coverage", replace sheet("Years")
			putexcel A1 = "Indicator"
			putexcel B1 = "Year (lower bound)"
			putexcel C1 = "Year (upper bound)"

				/* Sample code executed in loop
				preserve
				keep ISO country year All5
				drop if All5 == .
				sum year
				matrix A = r(min)'
				matrix B = r(max)'
				putexcel A2 = "All5"
				putexcel B2 = matrix(A)
				putexcel C2 = matrix(B)
				restore */
			local row = 2
			foreach v of varlist totalpop-foodsupplyvar {
			preserve
				keep ISO country year `v'
				drop if `v' == .
				sum year
				matrix A = r(min)'
				matrix B = r(max)'
				putexcel A`row' = "`v'"
				putexcel B`row' = matrix(A)
				putexcel C`row' = matrix(B)
			restore	
			local ++row
			}
			// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
					}
				collapse (firstnm) incgrp-foodsupplyvar, by(ISO country)
				// Relabel
					foreach v of var * {
					label var `v' "`l`v''"
						} 
			foreach v of varlist totalpop-foodsupplyvar {
				replace `v' = 1 if `v' != .
				replace `v' = 0 if `v' == .
			}
			sort country
			browse if country == ""
			browse if ISO == ""
				
				// Relabel WB regions
					lab val wb_region wb_region
					lab val UNmemberstate yesno
		
		// Export to coverage spreadsheet for manual copy into metadata and codebook Excel workbook
			export excel using "$tables\FSCI2022_coverage.xlsx", sheet("Countries", modify) firstrow(variables)
				
**# COMBINED MASTER DATASET - LATEST YEAR **************************************
	/* example code for mostrecent - run it over a loop for every variable with preserve and restore to keep one variable at a time:
		by ISO, sort: egen mostrecent=max(cond(MDD_iycf!=., year, .))
		keep if year==mostrecent
		drop mostrecent 
	*/
		use FSCI_2022_timeseries, clear
		tab year
		* Drop extra classification details, disaggregated variables, and yearrange indicator variables
		drop prod_cerealsnorice-dsfiyearrange 
		drop UN_contregion_code UN_subregion_code UN_intermedregion_code
		sort ISO year
			/* demonstration code to keep latest year per country per variable using indicator zeroFV_iycf
				keep ISO year zeroFV_iycf
				sort ISO year
				tab year
				tab2 ISO year if zeroFV_iycf != .
				drop if zeroFV_iycf == .
				// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
				}
			collapse (max) year (lastnm) zeroFV_iycf, by(ISO)
				// Relabel
					foreach v of var * {
					label var `v' "`l`v''"
						}
				tab ISO, sum(year)
				drop if year < 2000
			*/

		foreach i of varlist totalpop-foodsupplyvar {
			preserve	
				keep ISO country year `i'
				sort ISO country year
				*tab year
				*tab2 ISO year if `i' != .
				drop if `i' == .
				// Save labels
				foreach v of var * {
				local l`v' : variable label `v'
					if `"`l`v''"' == "" {
					local l`v' "`v'"
					}
				}
			collapse (max) year (lastnm) `i', by(ISO country) 
				// Relabel
					foreach v of var * {
					label var `v' "`l`v''"
						}
				*tab ISO, sum(year)
					if year < 2000 {
						tab country
					}
						else {
							di ""
						}
				drop if year <2000
				// Save
					tempfile lts_`i'
					save `lts_`i'', replace	
				// record what is the latest year
					replace `i' = year if `i' != .
					drop year
					tempfile ltyr_`i'
					save `ltyr_`i''
		restore		
		}
		
		use countryclassification, clear
		// Drop extra classification details and territories
			drop if UNmemberstate == 0
			order incgrp fsci_regions  UNmemberstate UN_* wb_region, after(country)
			order ISO m49_code, first
		
		// Merge in latest year value computed above
			foreach i in totalpop GDP GDP_percap landarea agland_area cropland avail_fruits avail_veg UPFretailval_percap safeh20 fies_modsev pctcantafford cohd pou All5 NCD_P NCD_R SSSD zeroFV  MDD_W MDD_iycf zeroFV_iycf fs_emissions emint_cerealsnorice emint_eggs emint_beef emint_chickenmeat emint_pork emint_cowmilk emint_rice yield_cereals yield_citrus yield_fruit yield_eggs yield_beef yield_chickenmeat yield_pork yield_pulses yield_cowmilk yield_roottuber yield_treenuts yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP unemp_tot unemp_r unemp_u underemp_tot underemp_r underemp_u spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex pctagland_minspecies genres_animal genres_plant rcsi_prevalence fpi_cv foodsupplyvar {
				merge 1:1 ISO country using `lts_`i'', nogen update replace
			}		
			
			drop year
	
		// Save
			save FSCI_2022_latestyear, replace
			export delimited using FSCI_2022_latestyear, replace
			
// Save dataset recording what year is the latest year per country-indicator  //
	use countryclassification, clear
	drop if UNmemberstate == 0
		drop ISO_governing UN_status_detail UN_status territoryof 
			order incgrp fsci_regions  UNmemberstate UN_* wb_region, after(country)
			order ISO m49_code, first
		
		// Merge in latest year computed above
			foreach i in totalpop GDP GDP_percap landarea agland_area cropland avail_fruits avail_veg UPFretailval_percap safeh20 fies_modsev pctcantafford cohd pou All5 NCD_P NCD_R SSSD zeroFV  MDD_W MDD_iycf zeroFV_iycf fs_emissions emint_cerealsnorice emint_eggs emint_beef emint_chickenmeat emint_pork emint_cowmilk emint_rice yield_cereals yield_citrus yield_fruit yield_eggs yield_beef yield_chickenmeat yield_pork yield_pulses yield_cowmilk yield_roottuber yield_treenuts yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP unemp_tot unemp_r unemp_u underemp_tot underemp_r underemp_u spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex pctagland_minspecies genres_animal genres_plant rcsi_prevalence fpi_cv foodsupplyvar {
				merge 1:1 ISO country using `ltyr_`i'', nogen
			}

		// Save
			save FSCI_2022_ltsyr_metadata, replace
			export delimited using FSCI_2022_ltsyr_metadata, replace

	
**# Summary statistics *********************************************************
		
	use FSCI_2022_latestyear, clear
			sort ISO
			drop disp_area UN_status_detail UN_status territoryof ISO_governing 
			drop *_u *_tot // urban and total employment variables
			* Order variables as presented in tables
			global variableorder cohd avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP unemp_r underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal  rcsi_prevalence fpi_cv foodsupplyvar
			order $variableorder, first
			order emint_eggs emint_chickenmeat emint_pork yield_citrus yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts, last
		
	* Global distribution (quartiles)
			putexcel set "$tables\ResultsTable", modify sheet("Global summary") // Modify to preserve formatting, or change to replace if desired
			tabstat $variableorder, stats(min p25 p50 p75 max) save
			putexcel A2 = matrix(r(StatTotal)'), names nformat(number_d1) 
			putexcel B1 = "Summary statistics, Latest year per country-indicator"
			putexcel A2 = "Indicator" 
			putexcel B2 = "Minimum"
			putexcel C2 = "25th percentile"
			putexcel D2 = "Median"
			putexcel E2 = "75th percentile"
			putexcel F2 = "Maximum"
	
	* Weighted Means - by population
			putexcel H2 = "Population-weighted Mean"
			putexcel I2 = "Population-weighted SD"
			tabstat cohd UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fishhealth unemp_r underemp_r spcoverage spadequacy childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex rcsi_prevalence [aweight = totalpop], stats(mean SD) save
			putexcel G2 = matrix(r(StatTotal)'), nformat(number_d1) names
			putexcel H2 = "Population-weighted Mean"
			putexcel I2 = "Population-weighted SD"
	* Weighted Means - by GDP
			tabstat aginGDP damages_gdp [aweight = GDP], stats(mean SD) save
			putexcel J2 = matrix(r(StatTotal)'), nformat(number_d1) names
			putexcel K2 = "GDP-weighted Mean"
			putexcel L2 = "GDP-weighted SD"
			
	* Weighted Means - by production (emissions intensity only)
			* Merge in 2020 production variables
			preserve
				use yield, clear
				keep if UNmemberstate == 1
				keep prod_* country year ISO
				keep if year == 2020
				drop year
				tempfile production 
					save `production'
				use emissions_intensity, clear
				keep prod_cerealsnorice prod_rice country year ISO
				keep if year == 2020
				drop year
				tempfile prod2
					save `prod2'
			restore
			preserve		
			merge 1:1 country ISO using `production'
				drop if _merge != 3
				drop _merge
			merge 1:1 country ISO using `prod2'
				drop if _merge != 3
				drop _merge
			keep country ISO emint* prod*
				tempfile production
				save `production'
			local n = 3
			foreach i in eggs beef chickenmeat pork cowmilk  {
				tabstat emint_`i'  [aweight = prod_`i'], stats(mean SD) save	
				putexcel M`n' = matrix(r(StatTotal)'), nformat(number_d1) rownames
				local ++n
				}
			local n=8
			foreach i in cerealsnorice rice  {
				tabstat emint_`i' [aweight = prod_`i'], stats(mean SD) save		
				putexcel M`n' = matrix(r(StatTotal)'), nformat(number_d1) rownames
				local ++n
				}
			putexcel N2 = "Production-weighted Mean"
			putexcel O2 = "Production-weighted SD"
	restore
	* Weighted Means - by area harvested / number of animals (Yield only)
			preserve
				use yield, clear
				keep if UNmemberstate == 1
				keep area* producing* country year ISO
				keep if year == 2020
				drop year
				tempfile areaproducing 
					save `areaproducing'
			restore
			preserve		
			merge 1:1 country ISO using `areaproducing'
				drop if _merge != 3
				drop _merge
			keep country ISO yield* area* producing*
				tempfile producing
				save `producing'
			local n = 3
			foreach i in eggs beef chickenmeat pork cowmilk  {
				tabstat yield_`i'  [aweight = producinganimals_`i'], stats(mean SD) save	
				putexcel P`n' = matrix(r(StatTotal)'), nformat(number_d1) rownames
				local ++n
				}
			local n=8
			foreach i in cereals citrus fruit pulses roottuber treenuts vegetables {
				tabstat yield_`i' [aweight = areaharvested_`i'], stats(mean SD) save		
				putexcel P`n' = matrix(r(StatTotal)'), nformat(number_d1) rownames
				local ++n
				}
			putexcel Q2 = "Area harvested/ Producing animals-weighted Mean"
			putexcel R2 = "Area harvested/ Producing animals-weighted SD"
	restore
	
	* Weighted Means - by agricultural land area
		* Functional integrity - by 2015 ag land area
		* Min species richness - by 2010 ag land area
	preserve	
		use landarea, clear
		keep if UNmemberstate == 1
		keep if inlist(year, 2010, 2015)
		keep ISO country agland_area year
		reshape wide agland_area, i(ISO country) j(year)
		tempfile landweights
			save `landweights'
	restore
	preserve
		keep ISO country functionalintegrity pctagland_minspecies 
		merge 1:1 country ISO  using `landweights'
			drop if _merge == 2
			drop _merge
		tabstat functionalintegrity [aweight = agland_area2015], stats(mean SD) save
			putexcel S3 = matrix(r(StatTotal)'), nformat(number_d1) rownames
		tabstat  pctagland_minspecies [aweight = agland_area2010], stats(mean SD) save
			putexcel S4 = matrix(r(StatTotal)'), nformat(number_d1) rownames
			putexcel T2 = "Agland-weighted Mean"
			putexcel U2 = "Agland-weighted SD"
	restore
	
	* Weighted Means - by cropland area
		tabstat croplandchange_pct agwaterdraw pesticides sustNO2mgmt [aweight = cropland], stats(mean SD) save
			putexcel S7 = matrix(r(StatTotal)'), nformat(number_d1) rownames
			putexcel T6 = "Cropland-weighted Mean"
			putexcel U6 = "Cropland-weighted SD"
	
	* Weighted Means - by total land area-indicator
		tabstat landholding_fem genres_plant genres_animal  [aweight = landarea], stats(mean SD) save
			putexcel V3 = matrix(r(StatTotal)'), nformat(number_d1) rownames
			putexcel W2 = "Total land area-weighted Mean"
			putexcel X2 = "Total land area-weighted SD"
			
	* Unweighted Means
		tabstat avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar, stats(mean SD) save
			putexcel Y3 = matrix(r(StatTotal)'), nformat(number_d1) rownames
			putexcel Z2 = "Unweighted Mean"
			putexcel AA2 = "Unweighted SD"
			
	* Weighted mean by urban population
	preserve
		use mufpp_pop, clear
		drop if UNmemberstate == 0
		keep ISO country pop_u
		
		tempfile urbpop
		save `urbpop'
	restore
	merge 1:1 ISO country using `urbpop'
		drop if _merge != 3
		drop _merge
	tabstat mufppurbshare [aweight = pop_u], stats(mean SD) save
		putexcel AB3 = matrix(r(StatTotal)'), nformat(number_d1) rownames
		putexcel AC2 = "Urban population-weighted Mean"
		putexcel AD2 = "Urban population-weighted SD"
		
// Save dataset with all weighting variables for visualizations -- latest year
	merge 1:1 country ISO using `production', keepusing(prod*) 
		drop _merge
	merge 1:1 country ISO using `producing', keepusing(area* producing*)
		drop _merge
	merge 1:1 country ISO using `landweights'
		drop _merge
	merge 1:1 country ISO using `urbpop', keepusing(pop_u)
	drop _merge
	save FSCI_2022_latestyear_withweightvars, replace
	export delimited using FSCI_2022_latestyear_withweightvars, replace
	
	* Reorder variables
	order country country ISO incgrp fsci_regions, first
	save "Supplementary Data - Appendix F - Baseline dataset.dta", replace
	export excel using "Supplementary Data - Appendix F - Baseline dataset", firstrow(varlabels) replace
	
// Create dataset with weighting variables for all years
use FSCI_2022_timeseries, clear
	preserve
		use yield, clear
		keep if UNmemberstate == 1
		keep prod_* areaharvested* producinganimals* country year ISO
		tempfile production 
			save `production'
		use emissions_intensity, clear
		keep if UNmemberstate == 1
		keep prod_cerealsnorice prod_rice country year ISO
		tempfile prod2
			save `prod2'
	restore
	preserve	
		use landarea, clear
		keep if UNmemberstate == 1
		keep if inlist(year, 2010, 2015)
		keep ISO country agland_area year
		reshape wide agland_area, i(ISO country) j(year)
		tempfile landweights
			save `landweights'
	restore
	preserve
		use mufpp_pop, clear
		keep if UNmemberstate == 1
		keep ISO country pop_u year
		tempfile urbpop
		save `urbpop'
	restore
	merge 1:1 country ISO year using `production' 
		drop _merge
	merge 1:1 country ISO year using `prod2'
		drop _merge
	merge m:1 country ISO using `landweights'
		drop _merge
	merge 1:1 country ISO year using `urbpop'
		drop _merge
save FSCI_2022_timeseries_withweightvars, replace
export delimited using FSCI_2022_timeseries_withweightvars, replace


// Regional and global median
		use FSCI_2022_latestyear, clear
			sort ISO
			drop disp_area territoryof ISO_governing wb_region incgrp UN_*
			drop *_u *_tot // urban and total employment variables
			drop emint_eggs emint_chickenmeat emint_pork yield_citrus yield_eggs yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			* Order variables as presented in tables
			order $variableorder, first
		
			putexcel set "$tables\ResultsTable", modify sheet("Regional Medians")
			encode fsci_regions, gen(fsciregion)
			tab fsciregion
			tabstat $variableorder if fsciregion == 1, stats(p50) save
			putexcel A3 = matrix(r(StatTotal)'), names nformat(number_d1) 		
			putexcel B1 = "Summary statistics, Latest year per country-indicator"
			putexcel A2 = "Indicator" 
			putexcel B2 = "Central Asia"
			putexcel C2 = "Eastern Asia"
			putexcel D2 = "Latin America & Caribbean"
			putexcel E2 =  "Northern Africa & Western Asia"
			putexcel F2 ="Northern America & Europe"
			putexcel G2 = "Oceania"
			putexcel H2 = "South-eastern Asia"
			putexcel I2 = "Southern Asia"
			putexcel J2 = "Sub-Saharan Africa"
			putexcel K2 = "Global"
			forv i = 1/26 {
				local col : word `i' of `c(ALPHA)'
			forval r = 2/9 {
			tabstat $variableorder if fsciregion == `r', stats(p50) save
			if `r'+1 == `i' {
				putexcel `col'4 = matrix(r(StatTotal)'), nonames nformat(number_d1) 
			}
			else {
				continue
			}
			}
			}
			tabstat $variableorder, stats(p50) save
			putexcel K4 = matrix(r(StatTotal)'), nonames nformat(number_d1) 		

// Income group and global median
		use FSCI_2022_latestyear, clear
			sort ISO
			drop wb_region fsci_regions UN_*
			drop *_u *_tot // urban and total employment variables
			drop emint_eggs emint_chickenmeat emint_pork yield_citrus yield_eggs yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			* Order variables as presented in tables
			order $variableorder, first
		
			putexcel set "$tables\ResultsTable", modify sheet("Income group Medians")
			encode incgrp, gen(income)
			tab income, sum(income)
			recode income (1=5) (2=1) (3=2) (4=3) 
			recode income (5=4)
			lab def income 1 "Low income" 2 "Lower middle income" 3 "Upper middle income" 4 "High income", replace
			lab val income income
			tabstat $variableorder if income == 1, stats(p50) save
			putexcel A3 = matrix(r(StatTotal)'), names nformat(number_d1) 		
			putexcel B1 = "Summary statistics, Latest year per country-indicator"
			putexcel A2 = "Indicator" 
			putexcel B2 = "Low income"
			putexcel C2 = "Lower middle income"
			putexcel D2 = "Upper middle income"
			putexcel E2 = "High income"
			putexcel F2 = "Global"
			forv i = 1/26 {
				local col : word `i' of `c(ALPHA)'
			forval r = 2/4 {
			tabstat $variableorder if income == `r', stats(p50) save
			if `r'+1 == `i' {
				putexcel `col'4 = matrix(r(StatTotal)'), nonames nformat(number_d1) 
			}
			else {
				continue
			}
			}
			}
			tabstat $variableorder, stats(p50) save
			putexcel F4 = matrix(r(StatTotal)'), nonames nformat(number_d1) 		

		// Weighted means by region 
		use FSCI_2022_latestyear_withweightvars, clear
			sort ISO
			drop wb_region incgrp UN_*
			drop emint_eggs emint_chickenmeat emint_pork yield_citrus yield_eggs yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			* Order variables as presented in tables
			order $variableorder, first
			
			* Collapse to weighted mean by regional
				local pop cohd UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fishhealth unemp_r underemp_r spcoverage spadequacy childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex rcsi_prevalence
				local GDP aginGDP damages_gdp
				local prod beef cowmilk cerealsnorice rice // Emissions intensity
				local areaharvested cereals fruit vegetables // Yield
				local producing beef cowmilk // Yield
				local cropland croplandchange_pct agwaterdraw  pesticides sustNO2mgmt 
				local agland1 functionalintegrity 
				local agland2 pctagland_minspecies
				local landarea landholding_fem genres_plant genres_animal
				local popU mufppurbshare
				local unweighted avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar
				
				preserve
					foreach i in `prod' {
						egen emint_`i'_mean = wtmean(emint_`i'), by(fsci_regions) weight(prod_`i')
					}
					keep fsci_regions emint_*_mean
					ren emint_*_mean emint_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) emint*, by(fsci_regions)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile prodm
					save `prodm'
				restore
				preserve
					foreach i in `areaharvested' {
						egen yield_`i'_mean = wtmean(yield_`i'), by(fsci_regions) weight(areaharvested_`i')
					}
					keep fsci_regions yield_*_mean
					ren yield_*_mean yield_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) yield_*, by(fsci_regions)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile yieldaream
					save `yieldaream'
				restore
				preserve
					foreach i in `producing' {
						egen yield_`i'_mean = wtmean(yield_`i'), by(fsci_regions) weight(producinganimals_`i')
					}
					keep fsci_regions yield_*_mean
					ren yield_*_mean yield_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) yield_*, by(fsci_regions)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile yieldprodm
					save `yieldprodm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `pop' [aweight = totalpop], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile populationm
					save `populationm'
				restore
				preserve
				foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `GDP' [aweight = GDP], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile GDPm
					save `GDPm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `cropland' [aweight = cropland], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile croplandm
					save `croplandm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `agland1' [aweight = agland_area2015], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile agland1m
					save `agland1m'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `agland2' [aweight = agland_area2010], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile agland2m
					save `agland2m'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `landarea' [aweight = landarea], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile landaream
					save `landaream'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `popU' [aweight = pop_u], by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile popum
					save `popum'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `unweighted', by(fsci_regions)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile unweightedm
					save `unweightedm'
				restore
			use `populationm', clear
			merge 1:1 fsci_regions using `GDPm', nogen
			merge 1:1 fsci_regions using `croplandm', nogen
			merge 1:1 fsci_regions using `agland1m', nogen
			merge 1:1 fsci_regions using `agland2m', nogen
			merge 1:1 fsci_regions using `landaream', nogen
			merge 1:1 fsci_regions using `popum', nogen
			merge 1:1 fsci_regions using `unweightedm', nogen
			merge 1:1 fsci_regions using `prodm', nogen
			merge 1:1 fsci_regions using `yieldaream', nogen
			merge 1:1 fsci_regions using `yieldprodm', nogen
			order fsci_regions $variableorder
			drop if fsci_regions == ""
			encode fsci_regions, gen(fsci_regions1)
			drop fsci_regions
			ren fsci_regions1 fsci_regions
			tab fsci_regions
			tab fsci_regions, sum(fsci_regions)
			describe fsci_regions
			xpose, clear varname
			drop if _varname == "fsci_regions"
			ren _varname indicator
			ren (v#) (regionmean#)
			order indicator, first
			save FSCI_latestyear_weightedmeans_region, replace
		
			putexcel set "$tables\ResultsTable", modify sheet("Regional Weighted means")
			mkmat regionmean1-regionmean9, matrix(M) rownames(indicator)
			putexcel A3 = matrix(M), rownames nformat(1)
			putexcel B1 = "Summary statistics, Regional weighted means, Latest year per country-indicator"
			putexcel A2 = "Indicator" 
			putexcel B2 = "Central Asia"
			putexcel C2 = "Eastern Asia"
			putexcel D2 = "Latin America & Caribbean"
			putexcel E2 = "Northern Africa & Western Asia"
			putexcel F2 = "Northern America & Europe"
			putexcel G2 = "Oceania"
			putexcel H2 = "South-eastern Asia"
			putexcel I2 = "Southern Asia"
			putexcel J2 = "Sub-Saharan Africa"
	
	// Weighted means by income group 
		use FSCI_2022_latestyear_withweightvars, clear
			sort ISO
			drop wb_region fsci_regions UN_*
			drop emint_eggs emint_chickenmeat emint_pork yield_citrus yield_eggs yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			* Order variables as presented in tables
			order ISO country incgrp $variableorder, first
			
			* Collapse to weighted mean by income group
				local pop cohd UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fishhealth unemp_r underemp_r spcoverage spadequacy childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex rcsi_prevalence
				local GDP aginGDP damages_gdp
				local prod beef cowmilk cerealsnorice rice // Emissions intensity
				local areaharvested cereals fruit vegetables // Yield
				local producing beef cowmilk // Yield
				local cropland croplandchange_pct agwaterdraw  pesticides sustNO2mgmt landholding_fem 
				local agland1 functionalintegrity 
				local agland2 pctagland_minspecies
				local landarea landholding_fem genres_plant genres_animal
				local popU mufppurbshare
				local unweighted avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar
				
				preserve
					foreach i in `prod' {
						egen emint_`i'_mean = wtmean(emint_`i'), by(incgrp) weight(prod_`i')
					}
					keep incgrp emint_*_mean
					ren emint_*_mean emint_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) emint*, by(incgrp)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile prodm
					save `prodm'
				restore
				preserve
					foreach i in `areaharvested' {
						egen yield_`i'_mean = wtmean(yield_`i'), by(incgrp) weight(areaharvested_`i')
					}
					keep incgrp yield_*_mean
					ren yield_*_mean yield_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) yield_*, by(incgrp)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile yieldaream
					save `yieldaream'
				restore
				preserve
					foreach i in `producing' {
						egen yield_`i'_mean = wtmean(yield_`i'), by(incgrp) weight(producinganimals_`i')
					}
					keep incgrp yield_*_mean
					ren yield_*_mean yield_*
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (first) yield_*, by(incgrp)
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile yieldprodm
					save `yieldprodm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `pop' [aweight = totalpop], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile populationm
					save `populationm'
				restore
				preserve
				foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `GDP' [aweight = GDP], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile GDPm
					save `GDPm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `cropland' [aweight = cropland], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile croplandm
					save `croplandm'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `agland1' [aweight = agland_area2015], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile agland1m
					save `agland1m'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `agland2' [aweight = agland_area2010], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
					}
					tempfile agland2m
					save `agland2m'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `landarea' [aweight = landarea], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile landaream
					save `landaream'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `popU' [aweight = pop_u], by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile popum
					save `popum'
				restore
				preserve
					foreach v of var * {
					local l`v' : variable label `v'
						if `"`l`v''"' == "" {
						local l`v' "`v'"
						}
					}				
					collapse (mean) `unweighted', by(incgrp)			
					foreach v of var * {
					label var `v' "`l`v''"
						}
					tempfile unweightedm
					save `unweightedm'
				restore
			use `populationm', clear
			merge 1:1 incgrp using `GDPm', nogen
			merge 1:1 incgrp using `croplandm', nogen
			merge 1:1 incgrp using `agland1m', nogen
			merge 1:1 incgrp using `agland2m', nogen
			merge 1:1 incgrp using `landaream', nogen
			merge 1:1 incgrp using `popum', nogen
			merge 1:1 incgrp using `unweightedm', nogen
			merge 1:1 incgrp using `prodm', nogen
			merge 1:1 incgrp using `yieldaream', nogen
			merge 1:1 incgrp using `yieldprodm', nogen
			order incgrp $variableorder
			drop if incgrp == ""
			encode incgrp, gen(incgrp1)
			drop incgrp
			ren incgrp1 incgrp
			tab incgrp
			tab incgrp, sum(incgrp)
			recode incgrp (1=5) (2=1) (3=2) (4=3) 
			recode incgrp (5=4)
			lab def income 1 "Low income" 2 "Lower middle income" 3 "Upper middle income" 4 "High income", replace
			lab val incgrp income
			tab incgrp, sum(incgrp)
			describe incgrp
			xpose, clear varname
			ren v1 v5 
			drop if _varname == "incgrp"
			ren _varname indicator
			order indicator v2 v3 v4 v5
			ren (v#) (a b c d)
			ren (a b c d) (incgroupmean#), addnumber
			order indicator, first
			save FSCI_latestyear_weightedmeans_income, replace
		
			putexcel set "$tables\ResultsTable", modify sheet("Income Group Weighted means")
			mkmat incgroupmean1-incgroupmean4, matrix(I) rownames(indicator)
			putexcel A3 = matrix(I), rownames nformat(1)
			putexcel B1 = "Summary statistics, Income Group weighted means, Latest year per country-indicator"
			putexcel A2 = "Indicator" 
			putexcel B2 = "Low income"
			putexcel C2 = "Lower middle income"
			putexcel D2 = "Upper middle income"
			putexcel E2 = "High income"

			
**# Test for statistically significant differences across regions and income groups
	use FSCI_2022_latestyear, clear
			sort ISO
			drop disp_area UN_status_detail UN_status territoryof ISO_governing m49_code UNmemberstate UN_contregion_code UN_continental_region UN_subregion_code UN_subregion UN_intermedregion_code UN_intermediary_region wb_region totalpop GDP GDP_percap landarea agland_area cropland emint_eggs emint_chickenmeat emint_pork yield_citrus yield_eggs yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			drop *_u *_tot // urban and total employment variables
			* Order variables as presented in tables
			order ISO country incgrp fsci_regions $variableorder, first
			lab var fies_modsev "FIES"
			lab var spadequacy "Social protection adequacy"
			lab var fsci_regions "Region"
			lab var emint_cerealsnorice "Cereals (excl rice) emissions intensity, kgCO2eq/kg product"
			lab var emint_beef "Beef emissions intensity, kgCO2eq/kg product"
			lab var emint_cowmilk "Milk emissions intensity, kgCO2eq/kg product"
			lab var emint_rice "Rice emissions intensity, kgCO2eq/kg product"


		* Test ANOVA assumption of equivalence of variance - Regions
			putexcel set "$tables\ResultsTable", modify sheet("Variance test")
			putexcel A1 = "Test of equivalence of variance assumption for ANOVA (Levene's test) - By REGION"
			putexcel A2 = "Indicator"
			putexcel B1 = "Highlighted cells reject H0 of equivalence of variances"
			putexcel B2 = "Test at mean"
			putexcel C2 = "Test at median"
			putexcel D2 = "Test at trimmed meat (top and bottom 5% removed)"
			describe cohd
			local varlabel : var label cohd
			putexcel A3 = ("`varlabel'")
			robvar cohd, by(fsci_regions) 
				/* robvar implements Levine's test of statistically significant difference in the standard deviation of a variable between groups
				Interpretation: W0 = test centered at the mean. W50 = test statistic for Levene's Test centered at the median. W10 = test statistic for Levene's Test centered using the 10% trimmed mean – i.e. the top 5% and bottom 5% of values are trimmed out so they don't overly influence the test.
				*/
			putexcel B3 = matrix(r(p_w0)')
			putexcel C3 = matrix(r(p_w50)')
			putexcel D3 = matrix(r(p_w10)')
			local row = 4
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			robvar `v', by(fsci_regions) 
			putexcel B`row' = matrix(r(p_w0)')
			putexcel C`row' = matrix(r(p_w50)')
			putexcel D`row' = matrix(r(p_w10)')
			local ++row
		}
			
		* Unequal variances for most indicators
	
			* Test ANOVA assumption of equivalence of variance - Income group
			putexcel set "$tables\ResultsTable", modify sheet("Variance test")
			putexcel A64 = "Test of equivalence of variance assumption for ANOVA (Levene's test) - By INCOME GROUP"
			putexcel A65 = "Indicator"
			putexcel B65 = "Test at mean"
			putexcel C65 = "Test at median"
			putexcel D65 = "Test at trimmed meat (top and bottom 5% removed)"
			describe cohd
			local varlabel : var label cohd
			putexcel A66 = ("`varlabel'")
			robvar cohd, by(incgrp) 
				/* robvar implements Levine's test of statistically significant difference in the standard deviation of a variable between groups
				Interpretation: W0 = test centered at the mean. W50 = test statistic for Levene's Test centered at the median. W10 = test statistic for Levene's Test centered using the 10% trimmed mean – i.e. the top 5% and bottom 5% of values are trimmed out so they don't overly influence the test.
				*/
			putexcel B66 = matrix(r(p_w0)')
			putexcel C66 = matrix(r(p_w50)')
			putexcel D66 = matrix(r(p_w10)')
			local row = 67
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar  {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			robvar `v', by(incgrp) 
			putexcel B`row' = matrix(r(p_w0)')
			putexcel C`row' = matrix(r(p_w50)')
			putexcel D`row' = matrix(r(p_w10)')
			local ++row
		}
			* Unequal variances for most indicators

	* ANOVA
			putexcel set "$tables\ResultsTable", modify sheet("ANOVA")
			putexcel A1 = "One-way ANOVA - by REGION"
			putexcel A2 = "Indicator"
			putexcel B2 = "F-stat"
			putexcel C2 = "p-val F-test"
			putexcel D2 = "Bartlett's equal variances p-val" // Bartlett's test of equal variances
				* Interpretation: null hypothesis that the variances are the same across groups (against HA that at least two are different)
			local varlabel : var label cohd
			putexcel A3 = ("`varlabel'")
			oneway cohd fsci_regions
			putexcel B3 = `r(F)'
			local p = Ftail(r(df_m), r(df_r), r(F)) // Calculate p-value to store (not stored in results)
			putexcel C3 = `p'
				* Interpretation:  It tests the null hypothesis that the mean ranks of the groups are the same. 
			local bart_p = chi2tail(r(df_bart), r(chi2bart))
			putexcel D3 = `bart_p'
			local row = 4
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			oneway `v' fsci_regions
			putexcel B`row' = `r(F)'
			local p = Ftail(r(df_m), r(df_r), r(F)) // Calculate p-value to store (not stored in results)
			putexcel C`row' = `p'
				* Interpretation:  It tests the null hypothesis that the variation within groups is greater than the variation between groups. 
			local bart_p = chi2tail(r(df_bart), r(chi2bart))
			putexcel D`row' = `bart_p'
			local ++row
		}

		
			putexcel A64 = "One-way ANOVA - by INCOME GROUP"
			putexcel A65 = "Indicator"
			putexcel B65 = "F-stat"
			putexcel C65 = "p-val F-test"
			putexcel D65 = "Bartlett's equal variances p-val" // Bartlett's test of equal variances
				* Interpretation: null hypothesis that the variances are the same across groups (against HA that at least two are different)
			local varlabel : var label cohd
			putexcel A66 = ("`varlabel'")
			oneway cohd fsci_regions
			putexcel B66 = `r(F)'
			local p = Ftail(r(df_m), r(df_r), r(F)) // Calculate p-value to store (not stored in results)
			putexcel C66 = `p'
				* Interpretation:  It tests the null hypothesis that the mean ranks of the groups are the same. 
			local bart_p = chi2tail(r(df_bart), r(chi2bart))
			putexcel D66 = `bart_p'
			local row = 67
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			oneway `v' fsci_regions
			putexcel B`row' = `r(F)'
			local p = Ftail(r(df_m), r(df_r), r(F)) // Calculate p-value to store (not stored in results)
			putexcel C`row' = `p'
				* Interpretation:  It tests the null hypothesis that the variation within groups is greater than the variation between groups
			local bart_p = chi2tail(r(df_bart), r(chi2bart))
			putexcel D`row' = `bart_p'
			local ++row
		}
		
	* Non-parametric test of the difference in medians
			
		* Medians test - By region
			putexcel set "$tables\ResultsTable", modify sheet("Medians tests")
			putexcel A1 = "Nonparametric K-sample test on the equality of medians - by REGION"
			putexcel A2 = "Indicator"
			putexcel B2 = "p-value"
			local varlabel : var label cohd
			putexcel A3 = ("`varlabel'")
			median cohd, by(fsci_regions) 
			putexcel B3 = matrix(r(p)')
				/* Interpretation:  It tests the null hypothesis that the K samples were drawn from populations with the same median. 
					p-val = two-sided p-value from normal approximation
					p-val exact = Fisher's exact p-value
				*/
			local row = 4
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			median `v', by(fsci_regions) 
			putexcel B`row' = matrix(r(p)')
			local ++row
		}
			

		* Medians test - By income group
			putexcel set "$tables\ResultsTable", modify sheet("Medians tests")
			putexcel A64 = "Nonparametric K-sample test on the equality of medians - By INCOME GROUP"
			putexcel A65 = "Indicator"
			putexcel B65 = "p-value"
			local varlabel : var label cohd
			putexcel A66 = ("`varlabel'")
			median cohd, by(incgrp) 
			putexcel B66 = matrix(r(p)')

				/* Interpretation:  It tests the null hypothesis that the K samples were drawn from populations with the same median. 
					p-val = two-sided p-value from normal approximation
					p-val exact = Fisher's exact p-value
				*/
			local row = 67
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef  emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			median `v', by(incgrp) 
			putexcel B`row' = matrix(r(p)')
			local ++row
		}
			
		* Nonparametric Means test - by region 
			putexcel set "$tables\ResultsTable", modify sheet("Means test")
			putexcel A1 = "Nonparametric Kruskal-Wallis H test on the equality of means - By REGION"
			putexcel A2 = "Indicator"
			putexcel B2 = "p-value"
			local varlabel : var label cohd
			putexcel A3 = ("`varlabel'")
			kwallis cohd, by(fsci_regions) 
			local p = chi2tail(r(df), r(chi2)) // Calculate p-value to store (not stored in kwallis results)
			putexcel B3 = `p'
				* Interpretation:  It tests the null hypothesis that the mean ranks of the groups are the same. 
				
			local row = 4
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice  yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			kwallis `v', by(fsci_regions) 
			local p = chi2tail(r(df), r(chi2))
			putexcel B`row' = `p'
			local ++row
		}

		* Nonparametric Means test - by region 
			putexcel set "$tables\ResultsTable", modify sheet("Means test")
			putexcel A64 = "Nonparametric Kruskal-Wallis H test on the equality of means - By INCOME GROUP"
			putexcel A65 = "Indicator"
			putexcel B65 = "p-value"
			local varlabel : var label cohd
			putexcel A66 = ("`varlabel'")
			kwallis cohd, by(incgrp) 
			local p = chi2tail(r(df), r(chi2)) // Calculate p-value to store (not stored in kwallis results)
			putexcel B66 = `p'
				* Interpretation:  It tests the null hypothesis that the mean ranks of the groups are the same. 
				
			local row = 67
			foreach v in avail_fruits avail_veg UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fs_emissions emint_cerealsnorice emint_beef emint_cowmilk emint_rice yield_cereals yield_fruit yield_beef yield_cowmilk yield_vegetables croplandchange_pct agwaterdraw functionalintegrity fishhealth pesticides sustNO2mgmt aginGDP  unemp_r  underemp_r spcoverage spadequacy childlabor landholding_fem cspart mufppurbshare righttofood fspathway govteffect foodsafety healthtax accountability open_budget_index accessinfo damages_gdp kcal_total mobile soccapindex  pctagland_minspecies genres_plant genres_animal rcsi_prevalence fpi_cv foodsupplyvar {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			kwallis `v', by(incgrp) 
			local p = chi2tail(r(df), r(chi2))
			putexcel B`row' = `p'
			local ++row
		}
		
	* Weighted Least Squares
			// Import desirable direction of change
			import excel using "$filepath\FSCI_2022 Metadata and Codebook", sheet("Coverage + Years_searchable") firstrow clear
			keep Indicator Desirable_direction
			drop in 70/75 // context/weighting variables
			drop if inlist(Indicator, "emint_chickenmeat", "emint_eggs", "emint_pork", "yield_chickenmeat", "yield_citrus", "yield_eggs")
			drop if inlist(Indicator, "yield_pork", "yield_pulses", "yield_roottuber", "yield_treenuts")
			forval i = 1/59 {
				local newvars `newvars' `=Indicator[`i']' 
			}
			ds Indicator, not
			rename (`r(varlist)') (value_=)
			reshape long value_, i(Indicator) j(direction) string
			reshape wide value_, i(direction) j(Indicator) string
			ren value_* *_dir
			drop direction
			expand 194
			egen v1 = seq() // workaround to merge into dataset with no matching var 
			tempfile direction	
				save `direction', replace
				
			use FSCI_2022_latestyear_withweightvars, clear
			drop if UNmemberstate == 0
			drop m49_code UNmemberstate UN_contregion_code UN_continental_region UN_subregion_code UN_subregion UN_intermedregion_code UN_intermediary_region wb_region GDP_percap prod_citrus prod_eggs prod_chickenmeat prod_pork prod_pulses prod_roottuber prod_treenuts areaharvested_citrus producinganimals_eggs producinganimals_chickenmeat producinganimals_pork areaharvested_pulses areaharvested_roottuber areaharvested_treenuts 
			drop yield_eggs emint_eggs emint_chickenmeat emint_pork yield_citrus yield_chickenmeat yield_pork yield_pulses yield_roottuber yield_treenuts
			egen v1 = seq() // workaround to merge into dataset with no matching var 
			merge 1:1 v1 using `direction'
			drop v1 _merge
			describe *_dir
			destring *_dir, replace
			encode fsci_regions, gen(region)
			tab region, sum(region) 
			
			* Generate global mean variable
			local pop cohd UPFretailval_percap safeh20 pou fies_modsev pctcantafford  MDD_W MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fishhealth unemp_r underemp_r spcoverage spadequacy childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex rcsi_prevalence
			local GDP aginGDP damages_gdp
			local prod beef cowmilk cerealsnorice rice // Emissions intensity
			local areaharvested cereals fruit vegetables // Yield
			local producing beef cowmilk // Yield
			local cropland croplandchange_pct agwaterdraw  pesticides sustNO2mgmt  
			local agland1 functionalintegrity 
			local agland2 pctagland_minspecies
			local landarea genres_plant genres_animal landholding_fem
			local popU mufppurbshare
			local unweighted avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar

			// Generate demeaned observations and reverse sign for desirable direction of change
			foreach v in `pop' {
				egen `v'_globmean = wtmean(`v'), weight(totalpop)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}
			foreach v in `GDP' {
				egen `v'_globmean = wtmean(`v'), weight(GDP)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `prod' {
				egen emint_`v'_globmean = wtmean(emint_`v'), weight(prod_`v')
				gen emint_`v'_demeaned = (emint_`v' -  emint_`v'_globmean)*emint_`v'_dir
			}			
			foreach v in `areaharvested' {
				egen yield_`v'_globmean = wtmean(yield_`v'), weight(areaharvested_`v')
				gen yield_`v'_demeaned = (yield_`v' -  yield_`v'_globmean)*yield_`v'_dir
			}			
			foreach v in `producing' {
				egen yield_`v'_globmean = wtmean(yield_`v'), weight(producinganimals_`v')
				gen yield_`v'_demeaned = (yield_`v' -  yield_`v'_globmean)*yield_`v'_dir
			}			
			foreach v in `cropland' {
				egen `v'_globmean = wtmean(`v'), weight(cropland)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `agland1' {
				egen `v'_globmean = wtmean(`v'), weight(agland_area2015)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `agland2' {
				egen `v'_globmean = wtmean(`v'), weight(agland_area2010)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `landarea' {
				egen `v'_globmean = wtmean(`v'), weight(landarea)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `popU' {
				egen `v'_globmean = wtmean(`v'), weight(pop_u)
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir
			}			
			foreach v in `unweighted' {
				egen `v'_globmean = mean(`v')
				gen `v'_demeaned = (`v' -  `v'_globmean)*`v'_dir 
			}			
		
			lab var fies_modsev "FIES"
			lab var spadequacy "Social protection adequacy"
			lab var fsci_regions "Region"
			lab var emint_cerealsnorice "Cereals (excl rice) emissions intensity, kgCO2eq/kg product"
			lab var emint_beef "Beef emissions intensity, kgCO2eq/kg product"
			lab var emint_cowmilk "Milk emissions intensity, kgCO2eq/kg product"
			lab var emint_rice "Rice emissions intensity, kgCO2eq/kg product"

		* WLS - by REGION		
			putexcel set "$tables\ResultsTable", modify sheet("WLS")
			putexcel A1 = "Weighted Least Squares - by REGION"
			putexcel A2 = "Indicator"
			putexcel B1 = "Deviation from global mean (aligned to desirable direction of change)"
			putexcel B2 = "Central Asia"
			putexcel C2 = "Eastern Asia"
			putexcel D2 = "Latin America & Caribbean"
			putexcel E2 = "Northern Africa & Western Asia"
			putexcel F2 = "Northern America and Europe"
			putexcel G2 = "Oceania"
			putexcel H2 = "South-eastern Asia"
			putexcel I2 = "Southern Asia"
			putexcel J2 = "Sub-Saharan Africa"
			putexcel K1 = "P-val"
			putexcel K2 = "Central Asia"
			putexcel L2 = "Eastern Asia"
			putexcel M2 = "Latin America & Caribbean"
			putexcel N2 = "Northern Africa & Western Asia"
			putexcel O2 = "Northern America and Europe"
			putexcel P2 = "Oceania"
			putexcel Q2 = "South-eastern Asia"
			putexcel R2 = "Southern Asia"
			putexcel S2 = "Sub-Saharan Africa"
			putexcel V2 = "p-val F-test"


			local varlabel : var label cohd			
			putexcel A3 = ("`varlabel'")
			regress cohd_demeaned ibn.region [aw = totalpop], noconstant robust	
			* If rerunning with cluster robust, here's the code: regress cohd_demeaned ibn.region [aw = totalpop], noconstant vce(cluster region)
			matrix beta = e(b)
			putexcel B3 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K3 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V3 = matrix(F)
			
			* Locals for variable loop groups based on weighting variable
			local pop UPFretailval_percap safeh20 pou pctcantafford  MDD_iycf   zeroFV_iycf unemp_r  spcoverage  childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex 
			local GDP aginGDP damages_gdp
			local prod beef cowmilk cerealsnorice rice // Emissions intensity
			local areaharvested cereals fruit vegetables // Yield
			local producing beef cowmilk // Yield
			local cropland croplandchange_pct agwaterdraw  pesticides sustNO2mgmt  
			local agland1 functionalintegrity 
			local agland2 pctagland_minspecies
			local landarea genres_plant genres_animal landholding_fem
			local popU mufppurbshare
			local unweighted avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar
						
			local row = 4		
			foreach v in `pop' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
		
			foreach v in `GDP' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = GDP], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
				
			foreach v in `prod' {
			local varlabel : var label emint_`v'
			putexcel A`row' = ("`varlabel'")
			regress emint_`v'_demeaned ibn.region [aw = prod_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `areaharvested' {
			local varlabel : var label yield_`v'
			putexcel A`row' = ("`varlabel'")
			regress yield_`v'_demeaned ibn.region [aw = areaharvested_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `producing' {
			local varlabel : var label yield_`v'
			putexcel A`row' = ("`varlabel'")
			regress yield_`v'_demeaned ibn.region [aw = producinganimals_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `cropland' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = cropland], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `agland1' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = agland_area2015], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `agland2' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = agland_area2010], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `landarea' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = landarea], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `popU' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region [aw = pop_u], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `unweighted' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.region, noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}

			// Variables that require manual individual programming: fies_modsev MDD_W All5 zeroFV  NCD_P NCD_R SSSD fishhealth underemp_r spadequacy rcsi_prevalence
			local varlabel : var label fies_modsev
			putexcel A51 = ("`varlabel'")
			regress fies_modsev_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel B51 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K51 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V51 = matrix(F)
			
			local row = 52
			foreach v in MDD_W All5 zeroFV  NCD_P NCD_R SSSD {			
				local varlabel : var label `v'
				putexcel A`row' = ("`varlabel'")
				regress `v'_demeaned ibn.region [aw = totalpop], noconstant robust	
				matrix beta = e(b)
				matrix b1 = beta[1,1..5]
				matrix b2 = beta[1,6..8]
				putexcel B`row' = matrix(b1)
				putexcel H`row' = matrix(b2)
				matrix A = r(table)
				matrix list A
				matrix pval1 = A[4,1] 
				matrix pval2 = A[4,3]
				matrix pval3 = A[4,4]
				matrix pval4 = A[4,5]
				matrix pval5 = A[4,6]
				matrix pval6 = A[4,7]
				matrix pval7 = A[4,8]
				putexcel K`row' = matrix(pval1)
				putexcel M`row' = matrix(pval2)
				putexcel N`row' = matrix(pval3)
				putexcel O`row' = matrix(pval4)
				putexcel Q`row' = matrix(pval5)
				putexcel R`row' = matrix(pval6)
				putexcel S`row' = matrix(pval7)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
			}

			local varlabel : var label fishhealth
			putexcel A58 = ("`varlabel'")
			regress fishhealth_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel C58 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..8]
			putexcel L58 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V58 = matrix(F)
			
			local varlabel : var label underemp_r
			putexcel A59 = ("`varlabel'")
			regress underemp_r_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel C59 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..8]
			putexcel L59 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V59 = matrix(F)
			
			local varlabel : var label spadequacy
			putexcel A60 = ("`varlabel'")
			regress spadequacy_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel B60 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..9]
			putexcel K60 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V60 = matrix(F)
			
			local varlabel : var label rcsi_prevalence
			putexcel A61 = ("`varlabel'")
			regress rcsi_prevalence_demeaned ibn.region [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			matrix b1 = beta[1,1..2]
			matrix b2 = beta[1,3..4]
			putexcel D61 = matrix(b1)
			putexcel I61 = matrix(b2)
			matrix A = r(table)
			matrix pval1 = A[4,1..2]
			matrix pval2 = A[4,3..4]
			putexcel M61 = matrix(pval1)
			putexcel R61 = matrix(pval1)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V61 = matrix(F)

			
		* WLS - by INCOME GROUP	
			encode incgrp, gen(income)
			recode income (1=5)
			tab income, sum(income)
			recode income (2=1) (3=2) (4=3) (5=4)
			lab def inc 1 "Low income" 2 "Lower middle income" 3 "Upper middle income" 4 "High income"
			lab val income inc
			tab income, sum(income)

			putexcel set "$tables\ResultsTable", modify sheet("WLS")
			putexcel A64 = "Weighted Least Squares - by REGION"
			putexcel A65 = "Indicator"
			putexcel B65 = "Deviation from global mean (aligned to desirable direction of change)"
			putexcel B65 = "Low income"
			putexcel C65 = "Lower middle income"
			putexcel D65 = "Upper middle income"
			putexcel E65 = "High income"
			putexcel K64 = "P-val"
			putexcel K65 = "Low income"
			putexcel L65 = "Lower middle income"
			putexcel M65 = "Upper middle income"
			putexcel N65 = "High income"
			putexcel V65 = "p-val F-test"
			 
			local varlabel : var label cohd			
			putexcel A66 = ("`varlabel'")
			regress cohd_demeaned ibn.income [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel B66 = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K66 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V66 = matrix(F)
			
			* Locals for variable loop groups based on weighting variable
			local pop UPFretailval_percap safeh20 pou fies_modsev pctcantafford MDD_iycf All5 zeroFV zeroFV_iycf NCD_P NCD_R SSSD fishhealth unemp_r underemp_r spcoverage spadequacy childlabor cspart govteffect foodsafety healthtax accountability open_budget_index kcal_total soccapindex 
			local GDP aginGDP damages_gdp
			local prod beef cowmilk cerealsnorice rice // Emissions intensity
			local areaharvested cereals fruit vegetables // Yield
			local producing beef cowmilk // Yield
			local cropland croplandchange_pct agwaterdraw  pesticides sustNO2mgmt  
			local agland1 functionalintegrity 
			local agland2 pctagland_minspecies
			local landarea genres_plant genres_animal landholding_fem
			local popU mufppurbshare
			local unweighted avail_fruits avail_veg fs_emissions accessinfo righttofood fspathway mobile fpi_cv foodsupplyvar						
			
			local row = 67		
			foreach v in `pop' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
		
			foreach v in `GDP' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = GDP], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
				
			foreach v in `prod' {
			local varlabel : var label emint_`v'
			putexcel A`row' = ("`varlabel'")
			regress emint_`v'_demeaned ibn.income [aw = prod_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `areaharvested' {
			local varlabel : var label yield_`v'
			putexcel A`row' = ("`varlabel'")
			regress yield_`v'_demeaned ibn.income [aw = areaharvested_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `producing' {
			local varlabel : var label yield_`v'
			putexcel A`row' = ("`varlabel'")
			regress yield_`v'_demeaned ibn.income [aw = producinganimals_`v'], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `cropland' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = cropland], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `agland1' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = agland_area2015], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `agland2' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = agland_area2010], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `landarea' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = landarea], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `popU' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income [aw = pop_u], noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}
			foreach v in `unweighted' {
			local varlabel : var label `v'
			putexcel A`row' = ("`varlabel'")
			regress `v'_demeaned ibn.income, noconstant robust	
			matrix beta = e(b)
			putexcel B`row' = matrix(beta)
			matrix A = r(table)
			matrix pval = A[4,1..4]
			putexcel K`row' = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V`row' = matrix(F)
			local ++row
				}

			// Variable that requires manual individual programming: MDD-W, rcsi_prevalence	
			local varlabel : var label MDD_W
			putexcel A124 = ("`varlabel'")
			regress MDD_W_demeaned ibn.income [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			matrix b = beta[1,1..3]
			putexcel B124 = matrix(b)
			matrix A = r(table)
			matrix pval = A[4,1..3]
			putexcel K124 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V124 = matrix(F)
			
			local varlabel : var label rcsi_prevalence
			putexcel A125 = ("`varlabel'")
			regress rcsi_prevalence_demeaned ibn.income [aw = totalpop], noconstant robust	
			matrix beta = e(b)
			matrix b = beta[1,1..3]
			putexcel B125 = matrix(b)
			matrix A = r(table)
			matrix pval = A[4,1..3]
			putexcel K125 = matrix(pval)
			matrix F = Ftail(e(df_m), e(df_r), e(F))
			putexcel V125 = matrix(F)

			
** Baseline data year summary
			use FSCI_2022_ltsyr_metadata, clear
			ren avail_fruits-foodsupplyvar indicator#, addnumber
			keep country indicator*
			reshape long indicator, i(country) j(n)
			drop n
			ren indicator year
			tab year
			** 92.5% of data points are from 2017-2022
			** 6.5% are from 2010-2016			
			** 1 % are from 2000-2009

