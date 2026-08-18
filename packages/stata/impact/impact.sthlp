{smcl}
{* 2024-11-01}{...}
{hi:help impact}
{hline}
{cmd:impact} ascertains the Inclusive Multimorbidity Phenotyping Algorithm's long-term conditions
from routinely collected, coded healthcare data (e.g. ICD-9-CM, ICD-10-CM, ICD-10,
ICD-10-PCS, ICD-9-PCS, OPCS-4, or CPRD Aurum medcodeid values).
{hline}
{p 8 12 2}
{synoptline}
{synopt:{cmd:impact} {opt:{cmd:dataset(string)}} {opt:{cmd:id(string)}} {opt:{cmd:codesystems(string)}} {opt:{cmd:searchvars(string)}}} {p_end}
{p 4 4 4}
{synopt:{opt:n_cores(integer)}} specifies the number of CPU cores to use. Default is 1.
Set to 0 to use all available cores. This release executes the mapping serially;
{cmd:n_cores()} is accepted for interface compatibility with the R and Python
implementations. {p_end}
{synopt:{opt:multimorbidity}} creates a set of multimorbidity-related variables:
{cmd:__nltc} (total number of long-term conditions), {cmd:__nmental} and
{cmd:__nphysical} (mental/physical counts), {cmd:__nbody} (number of distinct
body systems affected), and one {cmd:__bs_}<system> count per body system. {p_end}
{synopt:{opt:summary}} prints, for each codelist searched, the number of codes
matched in the searched variable(s). {p_end}
{hline}
{marker:description}
{hi:Description}
{p}
{cmd:impact} takes a dataset containing coded diagnoses/procedures, maps each code to one
or more long-term conditions (LTCs) using the iMPA codelists, and returns the input dataset
with one new indicator variable per LTC (named {cmd:__}<ltc>, taking values 0/1).
{p}
The command is designed to be run on a dataset in which each row is a single coded event,
with a unique identifier ({cmd:id}) and one or more variables holding the codes
({cmd:searchvars}). Each element of {cmd:codesystems} must correspond, in order, to an
element of {cmd:searchvars}.
{p}
{marker:options}
{hi:Options}
{dl 4 6}
{opt:dataset(string)} specifies the path to the dataset (e.g. a .dta file) to be searched.
This dataset should be loaded from disk; Stata should be {cmd:{stata clear all:clear all}}
before the command is run. {p_end}
{opt:id(string)} specifies the name of the unique identifier variable in the dataset.
This variable is retained in the output along with the generated LTC indicators. {p_end}
{opt:codesystems(string)} specifies the coding system(s) to be used in the mapping,
separated by spaces: {cmd:icd9cm}, {cmd:icd9pcs}, {cmd:icd10cm}, {cmd:icd10pcs},
{cmd:icd10}, {cmd:opcs4}, or {cmd:medcodeid}. {p_end}
{opt:searchvars(string)} specifies the variables to search for iMPA codes, in the same
order as {cmd:codesystems}. Multiple variables per code system may be given (space or
comma separated). The number of code systems and the number of search variables must
be equal. {p_end}
{opt:n_cores(integer)} specifies the number of CPU cores to use when running the mapping
algorithm. The default is 1. Specify 0 to use all available cores. This release runs
the mapping serially; {cmd:n_cores()} is accepted for interface compatibility. {p_end}
{opt:multimorbidity} creates multimorbidity-related variables: {cmd:__nltc} (total number
of long-term conditions), {cmd:__nmental} and {cmd:__nphysical} (mental/physical counts),
{cmd:__nbody} (number of distinct body systems affected), and one {cmd:__bs_}<system>
count per body system. {p_end}
{opt:summary} prints, for each codelist searched, the number of codes matched in the
searched variable(s). {p_end}
{dl_end}
{marker:examples}
{hi:Examples}
{p}
{p 4 8 2}{cmd:. impact, dataset(events.dta) id(patid) codesystems(icd10cm) searchvars(icdcode)}{p_end}
{p 4 8 2}{cmd:. impact, dataset(events.dta) id(patid) codesystems(icd10cm icd10pcs) searchvars(icdcode proccode) multimorbidity summary}{p_end}
{marker:seealso}
{hi:See also}
{p}
{cmd:help impact} for the full documentation; the iMPA codelists and the R and Python
implementations are available from the IMPACT GitHub repository.
{p}
