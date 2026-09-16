# Description ------------------------------------------------------------------
# Regenerate the dataspice metadata, data-raw/metadata/dataspice.json and its
# copy inst/extdata/metadata.json, from the four CSV tables in
# data-raw/metadata/. Run it after a change to those tables or to the authors
# in DESCRIPTION.
#
# DESCRIPTION is the single source of truth for author identifiers. The id
# column of creators.csv is filled from the ORCID iDs in Authors@R by matching
# on name, and the rows follow the Authors@R order. The schema.org context maps
# "id" to "@id", so each creator in the JSON-LD is identified by the ORCID URL.
# Name, affiliation, and email stay as written in creators.csv, since
# DESCRIPTION carries no affiliations.
# Load packages ----------------------------------------------------------------
## Run the following code in console if you don't have the packages
## install.packages(c("desc", "dataspice", "readr", "dplyr", "here", "fs"))
library(desc)
library(dataspice)
library(readr)
library(dplyr)
library(here)
library(fs)

# Author identifiers from DESCRIPTION ------------------------------------------
authors <- desc::desc_get_authors(here::here("DESCRIPTION"))
authors <- authors[vapply(authors, \(p) "aut" %in% p$role, logical(1))]

orcid_url <- function(p) {
  orcid <- unname(p$comment["ORCID"])
  if (is.null(orcid) || is.na(orcid)) {
    NA_character_
  } else {
    paste0("https://orcid.org/", orcid)
  }
}

identifiers <- tibble(
  name = vapply(authors, \(p) paste(p$given, p$family), character(1)),
  id = vapply(authors, orcid_url, character(1))
)

# Creators table ---------------------------------------------------------------
creators_path <- here::here("data-raw", "metadata", "creators.csv")

creators <- read_csv(creators_path, col_types = cols(.default = "c")) |>
  select(-id) |>
  inner_join(identifiers, y = _, by = "name") |>
  select(id, name, affiliation, email)

## Every author in DESCRIPTION has a row in creators.csv and an ORCID iD
stopifnot(
  nrow(creators) == length(authors),
  !anyNA(creators$id)
)

write_csv(creators, creators_path)

# Write the JSON-LD ------------------------------------------------------------
dataspice::write_spice(here::here("data-raw", "metadata"))
fs::file_copy(
  here::here("data-raw", "metadata", "dataspice.json"),
  here::here("inst", "extdata", "metadata.json"),
  overwrite = TRUE
)
