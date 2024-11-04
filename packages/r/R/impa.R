#' @export
select_codesystem <- function(ontology){
  
  if (ontology == "icd9cm"){
    source("__icd9cm.R", local = TRUE)
    output <- generate_lookup_icd9cm()
    return(output)
  }
  
  if (ontology == "icd9pcs"){
    source("__icd9pcs.R", local = TRUE)
    output <- generate_lookup_icd9pcs()
    return(output)
  }
  
  if (ontology == "icd10cm"){
    source("__icd10cm.R", local = TRUE)
    output <- generate_lookup_icd10cm()
    return(output)
  }
  
  if (ontology == "icd10pcs"){
    source("__icd10pcs.R", local = TRUE)
    output <- generate_lookup_icd10pcs()
    return(output)
  }
  
  if (ontology == "icd10"){
    source("__icd10.R", local = TRUE)
    output <- generate_lookup_icd10()
    return(output)
  }
  
  if (ontology == "opcs4"){
    source("__opcs4.R", local = TRUE)
    output <- generate_lookup_opcs4()
    return(output)
  }
  
  if (ontology == "cprdaurum"){
    source("__medcodeid.R", local = TRUE)
    output <- generate_lookup_medcodeid()
    return(output)
  }
  
}