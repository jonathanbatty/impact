capture program drop impact
*! version 0.1.0 2024
program define impact
	version 17
	
	syntax ,   							  /// 
		   dataset(string)                /// Specifies the path to the dataset to be searched
	       id(string)                     /// Specifies the unique identifier in the dataset
		   codesystems(string)            /// Specifies the coding system(s) to be used in the mapping
		   searchvars(string)			  /// Variables to search for IMPACT codes (same order as codesystems)
	       [                              ///
			  multimorbidity              /// Creates a number of multimorbidity-related variables
			  summary                     /// Provides a summary of the totals of each codelist searched for
		   ] 

	// Set system parameters
	// Set niceness = 10 to free up memory immediately
	quietly set niceness 10
	
	// Set mata properties to favour speed
	mata: mata set matafavor speed
	mata: mata set matamofirst on
	
	// Check if data is currently loaded into Stata
	capture assert _N == 0
	if _rc != 0 {
		noisily display as error "Please {stata clear all:clear all} data from Stata before running IMPACT."
		error 498
	}
		   
	// Import mata functions
	quietly findfile "impact.mata"
	run "`r(fn)'"
		   
	// Import list of LTCs
	quietly findfile "__ltcs.ado"
	quietly include "`r(fn)'"
		   
	// Parse codesystems to identify which definition files to load
	local codesystems = strtrim(ustrregexra("`codesystems'","[,]", ""))
	local num_codesystems : word count `codesystems'
	tokenize "`codesystems'"
	
	forvalues i = 1 / `num_codesystems' { 
		local codesystem_`i' = "``i''"
	}
	
	// Parse searchvars to identify variables to search
	local searchvars = strtrim(ustrregexra("`searchvars'","[,]", " "))
	local num_searchvars : word count `searchvars'
	tokenize "`searchvars'"
	
	// Combine all vars listed in searchvars
	local allvars = ""
	forvalues i = 1 / `num_searchvars' {
		local searchvars_`i' = "``i''"
		local allvars = "`allvars' ``i''"
	}
	local allvars : list uniq allvars
	
	// Throw error if number of codesystems != searchvars
	if (`num_codesystems' != `num_searchvars') {
		display as error "Error. The number of code systems and the number of search variables must be equal."
		error(3001)
	}

	// Create local macros to store which codesystems are to be searched
	local icd9cm = 0
	local icd9pcs = 0
	local icd10cm = 0
	local icd10pcs = 0
	local icd10 = 0
	local opcs4 = 0
	local medcodeid = 0
	
	// Load the definition files for only the selected code systems, for code mapping 
	forvalues i = 1 / `num_codesystems' {
		display as text _newline "Loading IMPACT code definitions for: {bf:" %9s "`codesystem_`i''" "}"
		
		local codesys = "`codesystem_`i''"
		
		if ("`codesys'" == "icd9cm") {
			local icd9cm = 1
			quietly findfile "__icd9cm.ado"
			quietly include "`r(fn)'"
		} 
		else if ("`codesys'" == "icd9pcs") {
			local icd9pcs = 1
			quietly findfile "__icd9pcs.ado"
			quietly include "`r(fn)'"
		}
		else if ("`codesys'" == "icd10cm") {
			local icd10cm = 1
			quietly findfile "__icd10cm.ado"
			quietly include "`r(fn)'"
		}
		else if ("`codesys'" == "icd10pcs") {
			local icd10pcs = 1
			quietly findfile "__icd10pcs.ado"
			quietly include "`r(fn)'"
		} 
		else if ("`codesys'" == "icd10") {
			local icd10 = 1
			quietly findfile "__icd10.ado"
			quietly include "`r(fn)'"
		}
		else if ("`codesys'" == "opcs4") {
			local opcs4 = 1
			quietly findfile "__opcs4.ado"
			quietly include "`r(fn)'"
		}
		else if ("`codesys'" == "medcodeid" | "`codesys'" == "cprdaurum") {
			local medcodeid = 1
			quietly findfile "__medcodeid.ado"
			quietly include "`r(fn)'"
		}
		else {
			display as error "Error. Select one of the available code systems documented in the help file."
			display as text "See: {stata help impact: help impact}"
			error(3300)	
		}
		
		// Initiate lookup array to store code-LTC mapping(s) for a given codesystem
		mata: code_lookup_`codesys' = asarray_create()
		mata: asarray_notfound(code_lookup_`codesys', "")	   
				
		// Load selected coding system into associative array
		mata: impact_load("`codesys'", code_lookup_`codesys')
	}
	
	// Load required data
	use `id' `allvars' using `dataset'
	
	// Create result variables and label these appropriately
	local n : word count `ltcs'
	tokenize "`ltcs'"

	// Create a local to store names of created variables
	local resultvars = ""
	
	forvalues i = 1 / `n' {
		quietly generate byte __``i'' = 0
		local lbl : word `i' of `ltc_labels'
		local lbl : subinstr local lbl `"""' "" , all
		label variable __``i'' "`lbl'"
		local resultvars = "`resultvars' __``i''"
	}
	
	// Run the mapping algorithm on the requested number of cores
	noisily display _newline "Ascertaining iMPA long-term conditions using `n_cores' CPU core(s)..."
	
	// Loop over each codesystem - searchvar pair and run search routine for each;
	// Therefore if four pairs submitted, run four separate searches
	forvalues i = 1 / `num_codesystems' {
		
		// Get unabbreviated list of all variables to search
		unab vars_to_search : `searchvars_`i''
		
		// Loop over each variable that contains code data to be searched
		foreach var of varlist `vars_to_search' {
			findcodes `var' "`resultvars'" code_lookup_`codesystem_`i''
		}
	}
	
	// If both ICD-9-CM and ICD-9-PCS, ICD-10-CM and ICD-PCS or ICD-10 and OPCS4 are selected,
	// also evaluate adjunct codes and use these to make a more precise ascertainment of
	// CKD status.
	if (`icd9cm' == 1 & `icd9pcs' == 1) {
		display "Using ICD-9-CM and ICD-9-PCS codes in combination to more accurately ascertain LTCs..."
	}
	if (`icd10cm' == 1 & `icd10pcs' == 1) {
		display "Using ICD-10-CM and ICD-10-PCS codes in combination to more accurately ascertain LTCs..."
	}
	if (`icd10' == 1 & `opcs4' == 1) {
		display "Using ICD-10 and OPCS-4 codes in combination to more accurately ascertain LTCs..."
	}
	if (`medcodeid' == 1) {
		display "Applying hierarchical medcodeid-based rules to more accurately ascertain LTCs..."
	}
	
	// Provide a summary of the totals of each codelist searched for
	if "`summary'" != "" {
		display _newline "Summary of codelists searched:"
		forvalues i = 1 / `num_codesystems' {
			local cs = "`codesystem_`i''"
			unab vars_to_search : `searchvars_`i''
			local total 0
			foreach var of varlist `vars_to_search' {
				mata: st_local("cnt", strofreal(impact_count("`var'", code_lookup_`cs')))
				local total = `total' + `cnt'
			}
			display as text "  `cs': `total' code(s) matched in the searched variable(s)"
		}
	}
	
	// Keep only ID and result variables
	keep `id' `resultvars'
	
	// Create multimorbidity-related variables if requested
	if "`multimorbidity'" != "" {
		
		// Total number of long-term conditions
		quietly egen __nltc = rowtotal(`resultvars')
		label variable __nltc "Total number of long-term conditions"
		
		// Mental and physical counts, derived from the per-LTC category
		local mentalvars ""
		local n_ltcs : word count `ltcs'
		tokenize "`ltcs'"
		forvalues i = 1 / `n_ltcs' {
			local cat : word `i' of `ltc_category'
			local cat : subinstr local cat `"""' "" , all
			if "`cat'" == "Mental" {
				local mentalvars "`mentalvars' __``i''"
			}
		}
		quietly egen __nmental = rowtotal(`mentalvars')
		label variable __nmental "Number of mental long-term conditions"
		quietly generate byte __nphysical = __nltc - __nmental
		label variable __nphysical "Number of physical long-term conditions"
		
		// Body-system variables: number of distinct body systems affected and
		// the number of conditions within each body system
		quietly mata: impact_mm("`resultvars'")
	}
	
	// Print confirmation of completion.
	noisily display as text "Code mapping complete." _newline
	
end

// Program to execute search function on nonmissing rows of data for each variable
capture program drop findcodes
program define findcodes
	args variable resultvars code_lookup
			
	// Mark observations that are nonmissing
	marksample touse, strok
	markout `touse' `variable', strok
			
	// Find conditions
	mata: impact_find("`variable'", "`touse'", "`resultvars'", `code_lookup')
	
end

// Use codesystem-searchvar pairs to create multiple lookups (prevent clashes, etc)
