version 17
set matastrict on
mata:

void impact_load(
    string scalar coding_sys,
    string scalar ltc_ids_local,
    string scalar level,
    string scalar ltc_phenotypes_local,
    transmorphic scalar lookup)
{
    string rowvector ltcs, phenotypes, codes, old_value, mapped
    string scalar target
    real scalar i, j

    ltcs = tokens(st_local(ltc_ids_local))
    phenotypes = tokens(st_local(ltc_phenotypes_local))
    mapped = J(1, 0, "")

    for (i = 1; i <= cols(ltcs); i++) {
        codes = tokens(st_local(coding_sys + "_" + ltcs[i]))
        target = level == "ltc" ? ltcs[i] : phenotypes[i]
        if (cols(codes) > 0 & anyof(mapped, target) == 0) mapped = (mapped, target)

        for (j = 1; j <= cols(codes); j++) {
            old_value = asarray(lookup, codes[j])
            if (all(old_value :== "")) {
                asarray(lookup, codes[j], target)
            }
            else if (anyof(old_value, target) == 0) {
                asarray(lookup, codes[j], (old_value, target))
            }
        }
    }

    printf("Number of %ss indexed:          %9.0fc\n", level, cols(mapped))
    printf("Number of codes mapped:         %9.0fc\n", rows(asarray_keys(lookup)))
}

void impact_find(
    string scalar varname,
    string scalar resultvars,
    transmorphic scalar lookup)
{
    string colvector codes
    string rowvector vars, targets
    real matrix results
    transmorphic scalar result_index
    real scalar i, j

    vars = tokens(resultvars)
    st_view(results = J(0, 0, .), ., vars)
    st_sview(codes = J(0, 0, ""), ., varname)

    result_index = asarray_create()
    for (i = 1; i <= cols(vars); i++) asarray(result_index, vars[i], i)

    for (i = 1; i <= rows(codes); i++) {
        targets = asarray(lookup, strtrim(codes[i]))
        for (j = 1; j <= cols(targets); j++) {
            if (targets[j] != "") {
                results[i, asarray(result_index, "__" + targets[j])] = 1
            }
        }
    }
}

void impact_multimorbidity(
    string scalar resultvars,
    string scalar target_ids_string,
    string scalar target_phenotypes_string,
    string scalar phenotype_ids_string,
    string scalar phenotype_systems_string,
    string scalar phenotype_categories_string)
{
    string rowvector result_names, target_ids, target_phenotypes
    string rowvector phenotype_ids, systems, categories, unique_systems
    real matrix result_data, phenotype_data
    real colvector system_count, nbody
    real scalar i, j, col
    real rowvector match_index
    string scalar varname

    result_names = tokens(resultvars)
    target_ids = tokens(target_ids_string)
    target_phenotypes = tokens(target_phenotypes_string)
    phenotype_ids = tokens(phenotype_ids_string)
    systems = tokens(phenotype_systems_string)
    categories = tokens(phenotype_categories_string)

    result_data = st_data(., result_names)
    phenotype_data = J(rows(result_data), cols(phenotype_ids), 0)

    for (i = 1; i <= cols(target_ids); i++) {
        match_index = selectindex(phenotype_ids :== target_phenotypes[i])
        if (cols(match_index) == 1) {
            phenotype_data[, match_index[1]] = phenotype_data[, match_index[1]] :|
                (result_data[, i] :== 1)
        }
    }

    col = st_addvar("int", "__nphenotypes")
    st_store(., col, rowsum(phenotype_data))

    system_count = J(rows(result_data), 1, 0)
    for (i = 1; i <= cols(phenotype_ids); i++) {
        if (categories[i] == "mental") system_count = system_count + phenotype_data[, i]
    }
    col = st_addvar("int", "__nmental")
    st_store(., col, system_count)
    col = st_addvar("int", "__nphysical")
    st_store(., col, rowsum(phenotype_data) - system_count)

    unique_systems = J(1, 0, "")
    for (i = 1; i <= cols(systems); i++) {
        if (anyof(unique_systems, systems[i]) == 0) unique_systems = (unique_systems, systems[i])
    }

    nbody = J(rows(result_data), 1, 0)
    for (j = 1; j <= cols(unique_systems); j++) {
        system_count = J(rows(result_data), 1, 0)
        for (i = 1; i <= cols(phenotype_ids); i++) {
            if (systems[i] == unique_systems[j]) system_count = system_count + phenotype_data[, i]
        }
        varname = substr("__bs_" + unique_systems[j], 1, 32)
        col = st_addvar("int", varname)
        st_store(., col, system_count)
        nbody = nbody + (system_count :> 0)
    }

    col = st_addvar("int", "__nbody")
    st_store(., col, nbody)
}

real scalar impact_count(string scalar varname, transmorphic scalar lookup)
{
    string colvector codes
    real scalar i, count

    st_sview(codes = J(0, 0, ""), ., varname)
    count = 0
    for (i = 1; i <= rows(codes); i++) {
        if (any(asarray(lookup, strtrim(codes[i])) :!= "")) count++
    }
    return(count)
}

end
