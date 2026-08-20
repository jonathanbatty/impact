\name{impact}
\alias{impact}
\title{Run the Inclusive Multimorbidity Phenotyping Algorithm and Coding Tool}
\usage{
impact(data, id, codesystems, searchvars, level,
  multimorbidity = FALSE, summary = FALSE)
}
\arguments{
  \item{data}{A data frame containing one coded event per row.}
  \item{id}{Name of the identifier column retained in the result.}
  \item{codesystems}{One or more supported code-system names.}
  \item{searchvars}{One code-column group per code system.}
  \item{level}{Required output level: \code{"ltc"} or \code{"phenotype"}.}
  \item{multimorbidity}{Add phenotype-based multimorbidity measures.}
  \item{summary}{Print matched-code counts by code system.}
}
\value{A data frame containing the identifier and 321 granular LTC indicators or 116 grouped phenotype indicators.}
\description{
Maps coded healthcare events using IMPACT. With \code{multimorbidity = TRUE},
\code{__nphenotypes} and all related measures count grouped phenotypes at
either output level.
}
\examples{
events <- data.frame(patid = 1:2, code = c("410.01", "999.99"))
impact(events, "patid", "icd9cm", "code", level = "phenotype")
}
