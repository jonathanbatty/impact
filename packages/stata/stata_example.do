* Functional example for the IMPACT Stata package.
* Run from packages/stata with: stata -b do stata_example.do

clear all
set more off
adopath ++ "impact"

tempfile events
input long patid str8 icdcode
1 "410.01"
1 "427.31"
2 "250.00"
2 "493.00"
3 "999.99"
end
save `events'

* Granular LTC output: 410.01 maps to STMI and CORO.
clear
impact, dataset(`events') id(patid) codesystems(icd9cm) ///
    searchvars(icdcode) level(ltc) multimorbidity summary
assert __STMI == 1 in 1
assert __CORO == 1 in 1
assert __AFIB == 1 in 2
assert __T2DM == 1 in 3
assert __ASTH == 1 in 4
assert __STMI == 0 in 5
assert __nphenotypes == 2 in 1
assert __nmental == 0 in 1
assert __nphysical == 2 in 1
assert __nbody == 1 in 1
assert _N == 5

* Grouped phenotype output: the same first event maps to ACSN and CORO.
clear
impact, dataset(`events') id(patid) codesystems(icd9cm) ///
    searchvars(icdcode) level(phenotype) multimorbidity
assert __ACSN == 1 in 1
assert __CORO == 1 in 1
assert __AFIB == 1 in 2
assert __DIAB == 1 in 3
assert __ASTH == 1 in 4
assert __ACSN == 0 in 5
assert __nphenotypes == 2 in 1

* IMPORTANT: IMPACT output and multimorbidity counts are event-level. To
* obtain patient-level phenotypes, take the maximum of each phenotype flag
* across all events for the identifier, then recalculate the phenotype count.
display as text "Aggregating event-level output to patient-level phenotypes..."
ds __????
local phenotype_vars `r(varlist)'
keep patid `phenotype_vars'
collapse (max) `phenotype_vars', by(patid)
egen int __nphenotypes = rowtotal(`phenotype_vars')
assert __nphenotypes == 3 if patid == 1
assert __nphenotypes == 2 if patid == 2
assert __nphenotypes == 0 if patid == 3
assert _N == 3

display as result "OK: IMPACT Stata example passed"
