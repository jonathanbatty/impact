clear all
cls

local code_system = "medcodeid" // To be passed to function as parameter

// Import list of LTCs
quietly include "ltcs.ado"

// Import only the code definition files that are required for code mapping
if ("`code_system'" == "icd9cm") quietly include "icd_9_cm.ado"
else if ("`code_system'" == "icd9pcs") quietly include "icd_9_pcs.ado"
else if ("`code_system'" == "icd10cm") quietly include "icd_10_cm.ado"
else if ("`code_system'" == "icd10pcs") quietly include "icd_10_pcs.ado"
else if ("`code_system'" == "icd10") quietly include "icd_10.ado"
else if ("`code_system'" == "opcs4") quietly include "opcs4.ado"
else if ("`code_system'" == "medcodeid") quietly include "medcodeid.ado"
else {
	display as error "Error! Select one of the available code systems documented in the help file."
	display as text "See: {stata help impa_helpfile: help impa}"
}

mata:
// Load coding system from stata local
coding_system = st_local("code_system")

// Initiate lookup array to store values
code_lookup = asarray_create()
asarray_notfound(code_lookup, "")

void load_lookups(string scalar coding_sys, 
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
	printf("Clinical codes successfully loaded and  mapped to long term conditions (LTCs).\n")
	printf("\nNumber of LTCs indexed:            %9.0fc", cols(ltcs_mapped))
	printf("\nNumber of codes mapped to LTCs:    %9.0fc\n", rows(asarray_keys(lookup_asarray)))
}

load_lookups(coding_system, code_lookup)

end



mata: asarray(code_lookup, "251601017")


// Create variables and label these appropriately
local n : word count `ltcs'

tokenize "`ltcs'"

forvalues i = 1 / `n' {
	generate __``i'' = .
	label variable __``i'' "`: word `i' of `ltc_labels''"
	display "``i'' `: word `i' of `ltc_labels''"
}