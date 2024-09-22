version 17
set matastrict on
mata:

// Function that loads selected coding system into associative array
void impa_load(string scalar coding_sys, 
		       transmorphic scalar lookup_asarray)
{
	
	// Declare variables
	string rowvector ltcs, codes, old_value, new_value, ltcs_mapped
	real scalar n_ltcs, n_codes, i, j
	
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
void impa_find(string scalar varname,
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
				
		if (result != "") {
			for (j = 1; j <= cols(result); j++) {
				result_var = "__" + result[j]
				searchresults[i, asarray(resindex, result_var)] = 1
			}
		}
	}
}


end