* Smoke test for the impact Stata package.
*
* Run from the package root (packages/stata) with:  do smoke_test.do
* (or from any directory, adjusting the ado-path / file paths as needed).
* Requires the impact.ado, impact.mata, __ltcs.ado and __icd*.ado files to be
* on the ado-path (e.g. installed via net install, or the current directory).

clear all

* Build a small dataset of coded events (one row per code)
* and save it to disk (impact reads the dataset from disk).
input long patid str30 icdcode
1 "41001"
1 "42731"
2 "25000"
2 "49300"
3 "99999"
end
save "smoke_events.dta", replace

* Ascertain long-term conditions
impact, dataset("smoke_events.dta") id(patid) codesystems(icd9cm) searchvars(icdcode) multimorbidity summary

* Checks
assert __MINF[_n==1] == 1
assert __CORO[_n==1] == 1
assert __AFIB[_n==2] == 1
assert __DIAB[_n==3] == 1
assert __ASTH[_n==4] == 1
assert __MINF[_n==5] == 0
assert __nltc[_n==1] == 2
assert __nbody[_n==1] == 1
assert __nmental[_n==1] == 0

display "OK: impact Stata smoke test passed"

erase "smoke_events.dta"
