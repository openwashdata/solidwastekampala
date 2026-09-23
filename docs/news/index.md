# Changelog

## solidwastekampala 1.0.2 (2026-09-23)

- The paper behind the data is now published: Katukiza et al. (2026),
  “Quantity and composition of domestic solid waste in Kampala City as
  influenced by socioeconomic factors”, Frontiers in Environmental
  Science 14, <doi:10.3389/fenvs.2026.1889921>. The README cites it at
  the top with its BibTeX entry, and DESCRIPTION, the data
  documentation, the dictionary, CITATION.cff, and inst/CITATION now
  refer to the paper instead of the manuscript. CITATION.cff lists the
  paper under `references`.
- Added a dot plot of waste per person by income level to the top of the
  README, replacing the boxplot in the example.
- Added the article “Waste per person by income” with an interactive
  version of the chart (Observable Plot in a Quarto article).

## solidwastekampala 1.0.1 (2026-09-17)

- Added Alex Y. Katukiza’s ORCID iD, verified against the public
  registry, so all eight authors now carry one in DESCRIPTION,
  CITATION.cff, and inst/CITATION
  ([\#26](https://github.com/openwashdata/solidwastekampala/issues/26)).
- Added the author ORCID iDs to the dataspice metadata. The creator `id`
  in `dataspice.json` and `inst/extdata/metadata.json` is now the ORCID
  URL, filled from DESCRIPTION by the new `data-raw/dataspice.R` script
  ([\#27](https://github.com/openwashdata/solidwastekampala/issues/27)).

## solidwastekampala 1.0.0 (2026-07-24)

- Initial release.
- Added the `solidwastekampala` dataset: quantity and composition of
  domestic solid waste for 103 households in Kampala City, with a full
  variable dictionary and CSV/XLSX exports
  ([\#17](https://github.com/openwashdata/solidwastekampala/issues/17),
  [\#18](https://github.com/openwashdata/solidwastekampala/issues/18)).
- Added package metadata, citation files, ORCID iDs for the authors, and
  Global Health Engineering, ETH Zurich as funder
  ([\#14](https://github.com/openwashdata/solidwastekampala/issues/14),
  [\#16](https://github.com/openwashdata/solidwastekampala/issues/16)).
- Confirmed all ORCID iDs with the main author and aligned the author
  order with the manuscript
  ([\#15](https://github.com/openwashdata/solidwastekampala/issues/15),
  [\#24](https://github.com/openwashdata/solidwastekampala/issues/24)).
- Added data documentation, an expanded README with a worked example,
  and the pkgdown website
  ([\#19](https://github.com/openwashdata/solidwastekampala/issues/19),
  [\#20](https://github.com/openwashdata/solidwastekampala/issues/20)).
- Added tests and the R-CMD-check GitHub Actions workflow
  ([\#21](https://github.com/openwashdata/solidwastekampala/issues/21),
  [\#22](https://github.com/openwashdata/solidwastekampala/issues/22)).
