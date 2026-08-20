capture program drop impact
*! version 0.1.0 2026-08-18
program define impact
	version 17

	syntax ,                                      ///
		DATAset(string)                            ///
		ID(name)                                   ///
		CODESystems(string)                        ///
		SEARCHVars(string)                         ///
		LEVel(string)                              ///
		[                                          ///
			MULTImorbidity                           ///
			SUMMary                                  ///
		]

	quietly set niceness 10
	mata: mata set matafavor speed
	mata: mata set matamofirst on

	capture assert _N == 0
	if _rc != 0 {
		noisily display as error "Please {stata clear all:clear all} data from Stata before running IMPACT."
		error 498
	}

	local level = lower(strtrim("`level'"))
	if !inlist("`level'", "ltc", "phenotype") {
		display as error "level() must be either level(ltc) or level(phenotype)."
		error 198
	}
	quietly findfile "impact.mata"
	capture mata: mata drop impact_load()
	capture mata: mata drop impact_find()
	capture mata: mata drop impact_multimorbidity()
	capture mata: mata drop impact_count()
	run "`r(fn)'"

	// Capture LTC metadata before __phenotypes.ado reuses phenotype_id.
	quietly findfile "__ltcs.ado"
	quietly include "`r(fn)'"
	local ltc_ids "`ltc_id'"
	local ltc_labels `"`ltc_label'"'
	local ltc_phenotypes "`phenotype_id'"

	quietly findfile "__phenotypes.ado"
	quietly include "`r(fn)'"
	local phenotype_ids "`phenotype_id'"
	local phenotype_labels `"`phenotype_label'"'
	local phenotype_systems `"`phenotype_body_system'"'
	local phenotype_categories `"`phenotype_category'"'
	local n_phenotypes : word count `phenotype_ids'
	local phenotype_system_tokens ""
	local phenotype_category_tokens ""
	forvalues i = 1/`n_phenotypes' {
		local sys : word `i' of `phenotype_systems'
		local sys : subinstr local sys `"""' "", all
		local sys : subinstr local sys "&" "and", all
		local sys = ustrregexra(lower(strtoname("`sys'")), "_+", "_")
		local cat : word `i' of `phenotype_categories'
		local cat : subinstr local cat `"""' "", all
		local cat = lower("`cat'")
		local phenotype_system_tokens "`phenotype_system_tokens' `sys'"
		local phenotype_category_tokens "`phenotype_category_tokens' `cat'"
	}

	if "`level'" == "ltc" {
		local target_ids "`ltc_ids'"
		local target_labels `"`ltc_labels'"'
		local target_phenotypes "`ltc_phenotypes'"
	}
	else {
		local target_ids "`phenotype_ids'"
		local target_labels `"`phenotype_labels'"'
		local target_phenotypes "`phenotype_ids'"
	}

	local codesystems = strtrim(ustrregexra("`codesystems'", "[,]", " "))
	local searchvars = strtrim(ustrregexra("`searchvars'", "[,]", " "))
	local num_codesystems : word count `codesystems'
	local num_searchvars : word count `searchvars'
	if `num_codesystems' == 0 | `num_searchvars' == 0 {
		display as error "codesystems() and searchvars() must not be empty."
		error 198
	}
	if `num_codesystems' != `num_searchvars' {
		display as error "The number of code systems and search-variable expressions must be equal."
		error 198
	}

	tokenize "`codesystems'"
	forvalues i = 1/`num_codesystems' {
		local requested_cs_`i' = lower("``i''")
		local canonical_cs_`i' "`requested_cs_`i''"
		if inlist("`requested_cs_`i''", "cprdaurum", "medcodeid") {
			local canonical_cs_`i' "cprd_aurum_medcodeid"
		}
		else if "`requested_cs_`i''" == "cprdgold" {
			local canonical_cs_`i' "cprd_gold_medcode"
		}
	}

	tokenize "`searchvars'"
	local allvars ""
	forvalues i = 1/`num_searchvars' {
		local searchvars_`i' "``i''"
		local allvars "`allvars' ``i''"
	}
	local allvars : list uniq allvars

	local supported "cprd_aurum_medcodeid cprd_gold_medcode emis_local icd10 icd10cm icd10pcs icd9cm icd9pcs opcs4 read_cleansed read_original snomed_concept snomed_description"

	// Keep lookups separate so identical values in different coding systems
	// cannot be cross-matched.
	forvalues i = 1/`num_codesystems' {
		local cs "`canonical_cs_`i''"
		local is_supported : list cs in supported
		if !`is_supported' {
			display as error "Unknown code system: `requested_cs_`i''"
			display as text "See {stata help impact:help impact} for supported values."
			error 198
		}

		display as text _newline "Loading IMPACT code definitions for {bf:`cs'}..."
		quietly findfile "__`cs'.ado"
		quietly include "`r(fn)'"
		mata: code_lookup_`i' = asarray_create()
		mata: asarray_notfound(code_lookup_`i', "")
		mata: impact_load("`cs'", "ltc_ids", "`level'", "ltc_phenotypes", code_lookup_`i')
	}

	use `id' `allvars' using "`dataset'"

	// String storage preserves leading zeroes and long clinical identifiers.
	forvalues i = 1/`num_searchvars' {
		unab vars_to_search : `searchvars_`i''
		foreach var of varlist `vars_to_search' {
			capture confirm string variable `var'
			if _rc {
				display as error "Search variable `var' must be stored as a string."
				error 109
			}
		}
	}

	local n_targets : word count `target_ids'
	local resultvars ""
	tokenize "`target_ids'"
	forvalues i = 1/`n_targets' {
		quietly generate byte __``i'' = 0
		local lbl : word `i' of `target_labels'
		local lbl : subinstr local lbl `"""' "", all
		local shortlbl = substr(`"`lbl'"', 1, 80)
		label variable __``i'' `"`shortlbl'"'
		local resultvars "`resultvars' __``i''"
	}

	noisily display _newline "Ascertaining IMPACT `level' indicators (serial mapping)..."
	forvalues i = 1/`num_codesystems' {
		unab vars_to_search : `searchvars_`i''
		foreach var of varlist `vars_to_search' {
			mata: impact_find("`var'", "`resultvars'", code_lookup_`i')
		}
	}

	if "`summary'" != "" {
		display _newline "IMPACT summary:"
		forvalues i = 1/`num_codesystems' {
			unab vars_to_search : `searchvars_`i''
			local total 0
			foreach var of varlist `vars_to_search' {
				mata: st_local("cnt", strofreal(impact_count("`var'", code_lookup_`i')))
				local total = `total' + real("`cnt'")
			}
			display as text "  `requested_cs_`i'': `total' code(s) matched"
		}
	}

	keep `id' `resultvars'

	if "`multimorbidity'" != "" {
		mata: impact_multimorbidity("`resultvars'", "`target_ids'", "`target_phenotypes'", "`phenotype_ids'", "`phenotype_system_tokens'", "`phenotype_category_tokens'")
		label variable __nphenotypes "Number of IMPACT phenotypes"
		label variable __nmental "Number of mental health phenotypes"
		label variable __nphysical "Number of physical health phenotypes"
		label variable __nbody "Number of body systems affected"
	}

	noisily display as text "IMPACT code mapping complete." _newline
end
