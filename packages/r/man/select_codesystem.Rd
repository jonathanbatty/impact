\name{select_codesystem}
\alias{select_codesystem}
\title{Load an IMPACT code-system lookup}
\usage{select_codesystem(ontology)}
\arguments{\item{ontology}{A supported code-system name.}}
\value{An independent environment mapping code strings to one or more granular LTC identifiers.}
\description{Returns a defensive copy of the IMPACT lookup for one coding system. Modifying the returned environment does not alter IMPACT's internal lookup.}
