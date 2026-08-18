version 17
set matastrict on
mata:

// Function that loads selected coding system into associative array
void impact_load(string scalar coding_sys, 
		       transmorphic scalar lookup_asarray)
{
	
	// Declare variables
	string rowvector ltcs, codes, old_value, new_value, ltcs_mapped
	real scalar n_ltcs, n_codes, i, j
	
	// 'cprdaurum' is an alias for the CPRD Aurum medcodeid codelists
	if (coding_sys == "cprdaurum") coding_sys = "medcodeid"
	
	// Create colvector containing each of the 120 LTCs
	ltcs = tokens(st_local("ltcs"))
	n_ltcs = cols(ltcs)

	// Populate codelist lookup with string values
	ltcs_mapped = ("")
	for (i = 1; i <= n_ltcs; i++) {
		
		codes = tokens(st_local(coding_sys + "_" + ltcs[i]))
		n_codes = cols(codes)
		
		if (n_codes != 0) {
			for (j = 1; j <= n_codes; j++) {
			
				// Check if key already exists in the asarray
				if (asarray(lookup_asarray, codes[j]) == "") {
					
					// If key does not exist, add a new key-value pair to the asarray
					asarray(lookup_asarray, codes[j], ltcs[i])
				}
				else {
					// If key exists, append new variable name to the value rowvector
					old_value = asarray(lookup_asarray, codes[j])
					new_value = (old_value, ltcs[i])
					asarray(lookup_asarray, codes[j], new_value)
				}
			}
			
			// Append to list of LTCs mapped
			ltcs_mapped = (ltcs_mapped, ltcs[i])
		}
	}
	
	// Remove empty strings from list of mapped ltcs
	ltcs_mapped = select(ltcs_mapped, strlen(ltcs_mapped))
	
	// Display summary statistics about lookup
	displayas("text")
	printf("Number of LTCs indexed:            %9.0fc", cols(ltcs_mapped))
	printf("\nNumber of codes mapped to LTCs:    %9.0fc\n", rows(asarray_keys(lookup_asarray)))
}

// Function to search view of dataset for codes in text files and replace 
// placeholder variables accordingly.
void impact_find(string scalar varname,
               string scalar touse, 
		       string scalar resultvars, 
		       transmorphic scalar code_lookup)
{
	// Declare variables
	string colvector tosearch
	real colvector searchresults
	string rowvector vars, result
	string scalar result_var
	real scalar i, j, n
	transmorphic scalar resindex
	
	// Tokenize result variables (to hold outputs of search)
	vars = tokens(resultvars)
	
	// Create a view of each of the result columns (bytes)
	st_view(searchresults = J(0, 0, .), ., vars, touse)
	
	// Map each variable name to the view column id
	resindex = asarray_create()
	n = cols(vars)
	for (i = 1; i <= n; i++) {
		asarray(resindex, vars[i], i)
	}
		
	// Create a view of the vector to be searched (strings)
	st_sview(tosearch = J(0, 0, .), ., varname, touse)
	
	// Search over the search vector using the associative array; replace value
	// in relevant result column if a match is found.
	// Use of a for loop enables assignment of multiple conditions for a single 
	// code.
	n = rows(tosearch)
	for (i = 1; i <= n; i++) { 
		
		result = asarray(code_lookup, tosearch[i])	
				
		if (any(result :!= "")) {
			for (j = 1; j <= cols(result); j++) {
				result_var = "__" + result[j]
				searchresults[i, asarray(resindex, result_var)] = 1
			}
		}
	}
}


// Parse a double-quoted list into the values at even indices (mirrors the
// Python split('"')[2::2] logic for the leading-doubled-quote format used by
// the __ltcs.ado metadata macros).
string rowvector impact_parse_quoted(string scalar s)
{
	// Declare variables
	string rowvector toks, vals
	real scalar i, n, prev

	toks = J(1, 0, "")
	prev = 1
	n = strlen(s)
	for (i = 1; i <= n; i++) {
		if (substr(s, i, 1) == `"""') {
			toks = (toks, substr(s, prev, i - prev))
			prev = i + 1
		}
	}
	toks = (toks, substr(s, prev, n - prev + 1))

	// Values are the tokens at odd 1-based indices 3, 5, 7, ... (mirroring the
	// Python split('"')[2::2] zero-based selection); drop any trailing empty
	// token left by the closing quote.
	vals = J(1, 0, "")
	for (i = 3; i <= cols(toks); i = i + 2) {
		if (toks[i] != "") vals = (vals, toks[i])
	}
	return(vals)
}

// Convert a body-system name into a valid Stata variable name
string scalar sysname(string scalar s)
{
	s = ustrregexra(s, "&", "and")
	s = ustrregexra(s, " ", "_")
	return(s)
}

// Create multimorbidity body-system variables (__nbody and one __bs_<system>
// count per body system) from the result (__<LTC>) columns.
void impact_mm(string scalar resultvars)
{
	// Declare variables
	string rowvector ltcs, mapsys, uniqsys, sysvars
	real scalar n, i, j
	real matrix X
	real colvector syssum, nbodyvec
	string scalar vname

	ltcs = tokens(st_local("ltcs"))
	n = cols(ltcs)
	mapsys = impact_parse_quoted(st_local("ltc_mapping"))

	// Distinct body systems, in first-appearance order
	uniqsys = J(1, 0, "")
	for (i = 1; i <= n; i++) {
		if (anyof(uniqsys, mapsys[i]) == 0) uniqsys = (uniqsys, mapsys[i])
	}

	// Per-row number of distinct body systems affected
	nbodyvec = J(st_nobs(), 1, 0)

	// For each body system, count the number of present LTCs and add a variable
	for (j = 1; j <= cols(uniqsys); j++) {
		sysvars = J(1, 0, "")
		for (i = 1; i <= n; i++) {
			if (mapsys[i] == uniqsys[j]) sysvars = (sysvars, "__" + ltcs[i])
		}
		X = st_data(., sysvars)
		syssum = rowsum(X)
		vname = "__bs_" + sysname(uniqsys[j])
		st_addvar("long", vname)
		st_store(., st_varindex(vname), syssum)
		nbodyvec = nbodyvec + (syssum :> 0)
	}

	// __nbody: number of distinct body systems affected
	st_addvar("long", "__nbody")
	st_store(., st_varindex("__nbody"), nbodyvec)
}

// Return the number of rows in variable whose code maps to at least one LTC
real scalar impact_count(string scalar varname, transmorphic scalar lookup)
{
	// Declare variables
	string colvector codes
	real scalar n, i, cnt

	st_sview(codes = J(0, 0, .), ., varname, ".")
	n = rows(codes)
	cnt = 0
	for (i = 1; i <= n; i++) {
		if (any(asarray(lookup, codes[i]) :!= "")) cnt++
	}
	return(cnt)
}


end