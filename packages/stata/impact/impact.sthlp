{smcl}
{* 2026-08-20}{...}
{hi:help impact}
{hline}
{title:IMPACT — Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool}

{p 4 4 2}
{cmd:impact} maps coded healthcare events to either 321 granular long-term
condition (LTC) indicators or 116 grouped phenotype indicators.

{title:Syntax}

{p 8 12 2}
{cmd:impact}, {opt dataset(string)} {opt id(varname)}
{opt codesystems(string)} {opt searchvars(string)}
{opt level(ltc|phenotype)}
[{opt multimorbidity} {opt summary}]

{title:Required options}

{phang}
{opt dataset(string)} is the path to a Stata dataset containing one coded
event per row. Stata must contain no loaded observations before the command.

{phang}
{opt id(varname)} is the identifier retained in the result. Values may repeat
because output remains at coded-event row level. Names beginning {cmd:__} are
reserved for IMPACT outputs and cannot be used as the identifier.

{phang}
{opt codesystems(string)} lists code systems in the same order as
{cmd:searchvars()}. Supported canonical values are
{cmd:cprd_aurum_medcodeid}, {cmd:cprd_gold_medcode}, {cmd:emis_local},
{cmd:icd10}, {cmd:icd10cm}, {cmd:icd10pcs}, {cmd:icd9cm}, {cmd:icd9pcs},
{cmd:opcs4}, {cmd:read_cleansed}, {cmd:read_original},
{cmd:snomed_concept}, and {cmd:snomed_description}.

{phang}
{opt searchvars(string)} lists string variables or wildcard expressions to
search. There must be one expression per code system. Codes should remain
strings to preserve punctuation, leading zeroes and long identifiers.
Surrounding whitespace is ignored.

{phang}
{opt level(ltc|phenotype)} selects 321 granular {cmd:__}<LTC> indicators or
116 grouped {cmd:__}<phenotype> indicators. It must be specified on every run.

{title:Optional options}

{phang}
{opt multimorbidity} adds phenotype-based {cmd:__nphenotypes},
{cmd:__nmental}, {cmd:__nphysical}, one {cmd:__bs_}<system> count per body
system, and {cmd:__nbody}. These count grouped phenotypes at either output
level; multiple granular LTCs in one phenotype are counted once. Counts remain
at coded-event row level and are not aggregated across repeated identifiers.

{phang}
{opt summary} prints matched-code counts for each selected code system.

{title:Examples}

{p 4 8 2}{cmd:. clear all}{p_end}
{p 4 8 2}{cmd:. impact, dataset("events.dta") id(patid) codesystems(icd10) searchvars(icdcode) level(phenotype)}{p_end}
{p 4 8 2}{cmd:. clear all}{p_end}
{p 4 8 2}{cmd:. impact, dataset("events.dta") id(patid) codesystems(icd10 opcs4) searchvars(diagnosis procedure) level(ltc) multimorbidity summary}{p_end}

{title:Installation}

{p 4 4 2}
IMPACT is installed directly from its GitHub repository, not SSC. See the
package README for the {cmd:net install} command.
