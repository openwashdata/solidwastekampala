# solidwastekampala: clean raw data and write the dictionary

Plan written 2026-07-22. Status as of 2026-07-23: Step 0 is complete; steps 1-4 are
tracked as GitHub issues (one issue per step) and not yet executed.

## Context

New openwashdata data package `solidwastekampala` at
`/Users/lschoebitz/Documents/gitrepos/gh-org-openwashdata/data/solidwastekampala`.
The raw dataset (`data-raw/data_sheets_with_analysis.xlsx`) accompanies the manuscript
"Quantity and Composition of Domestic Solid Waste in Kampala City as Influenced by
Socio-Economic Factors" (Katukiza et al., Makerere University): a 7-day household waste
characterisation in three Kampala parishes (Bwaise I = low income, Bukoto I = middle,
Ggaba = high), 103 analyzed households (39/32/32).

Scope of this plan (per user request): clean the data and write the dictionary, following
washr conventions. README, roxygen docs, website, and metadata come later.

Decisions confirmed with the user:

- Wire up git first (repo openwashdata/solidwastekampala exists on GitHub, private; local
  dir has no .git yet).
- Keep all 5 per-household metric columns (total, per-day, per-capita, volume, density)
  as recorded.

Empirical facts the implementation relies on (established by inspection):

- Process ONLY the three raw area sheets "Bwaise I", "Bukoto I", "Ggaba". "All_data" is a
  consolidation (103 rows, numerically identical positionally; used as cross-check only).
  "Codes" is a codebook (source for canonical factor levels). All other sheets are derived
  results and are not processed.
- Sheet layout: rows 1-2 title/notes, rows 3-4 two-level headers, data from row 5;
  37 columns. Rows with non-empty "No.": 39/32/32 = 103. Trailing rows are sheet-level
  summary stats (safe to drop by filtering on integer "No.").
- The 10 waste-category columns are kilograms per 7-day collection (verified: they sum to
  the Total column, 99/103 rows within 0.01 kg). Density column is kg/L (manuscript
  reports kg/m3, factor 1000).
- Exactly one text-stored number: Ggaba Household_7 metals cell "2..674" (intended 2.674;
  excluded from that row's SUM-formula total).
- Area means reproduce manuscript figures (per-capita 0.43/0.53/0.98 kg/ca.day, density
  368/571/325 kg/m3), confirming these are the right source sheets.

## Step 0: Git setup (complete, 2026-07-23)

All four points below are done: the repo is initialized with `origin` set to
`openwashdata/solidwastekampala`, `main` and `dev` both exist locally and on the remote
at the same commit with tracking set up, and the raw xlsx plus `data_processing.R` are
committed.

In the package directory:

1. `git init`, `git remote add origin git@github.com:openwashdata/solidwastekampala.git`,
   `git fetch origin`.
2. Reconcile: if `origin/main` has commits, create local `main` tracking it and lay the
   existing local files on top; if empty, create `main` fresh.
3. Create `dev` off `main`; all work in this plan is committed to `dev`.
4. Keep existing `.gitignore` (ignores `.Rproj.user`, `context/*`; manuscripts stay out of
   git). Commit the raw xlsx (3.4 MB) and `data_processing.R` in `data-raw/` per
   openwashdata convention.

## Step 1: Implement the Tidy section of data-raw/data_processing.R (issue #1)

Edit `data-raw/data_processing.R`: fill the "Read data" and "Tidy data" sections; leave
the Export section (lines 22-28, washr template) untouched. Add
`library(dplyr)`, `library(stringr)`, `library(purrr)` to the packages section.
Tidyverse style, snake_case throughout.

### Reading

Read each area sheet with
`read_excel(path, sheet, skip = 4, col_names = raw_names, col_types = "text")` and
`bind_rows()` in order Bwaise I, Bukoto I, Ggaba (matches All_data numbering). Reading as
text is deliberate: guessed types differ across sheets (the "2..674" cell makes Ggaba
metals character) and readxl renders numeric cells to text at full double precision, so
the round-trip is lossless. A hand-written 37-name vector beats programmatic header
flattening because the merged two-level headers differ in spelling per sheet.

The column vector:

```r
raw_names <- c(
  "no", "household_id", "division", "parish", "zone",
  "income_level", "occupants", "age_head", "gender_head", "education_head",
  "profession_head", "monthly_income_ugx", "respondent", "period_of_stay",
  "occupancy", "housing_quality", "roof_material", "wall_material",
  "floor_material", "water_access", "sanitation_facility", "road_condition",
  "waste_food_kg", "waste_garden_kg", "waste_wood_kg", "waste_textiles_kg",
  "waste_paper_kg", "waste_polythene_kg", "waste_plastics_kg",
  "waste_glass_kg", "waste_metals_kg", "waste_other_kg",
  "waste_total_kg", "waste_per_day_kg", "waste_per_capita_kg",
  "volume_l", "density_kg_l"
)
```

### Cleaning steps, in order

1. Drop trailing summary rows: `filter(str_detect(no, "^[0-9]+$"))`; expect 103 rows.
2. Fix the one text-stored number: `waste_metals_kg` `"2..674"` to `"2.674"` (comment
   citing Ggaba cell AE10, Household_7). Keep `waste_total_kg` as recorded (60.082,
   excludes the 2.674 because Excel SUM skips text); do not recompute, since per-day,
   per-capita, and density chain off the recorded total.
3. Convert types: waste columns through density to numeric, `occupants` to integer.
4. Drop `no`; add `id = row_number()` as first column (reproduces All_data numbering
   1-103; package-level unique key, since `household_id` values repeat across parishes).
5. Fix two malformed IDs in Bukoto: `Household__9` to `Household_9`, `Househols_16` to
   `Household_16`.
6. Harmonize categorical labels with `case_match()` per column, exact map:
   - division: "Kawenpe Division" -> "Kawempe"; "Makindye Division" -> "Makindye";
     "Nakawa" stays "Nakawa"
   - parish: "Bukoto 1" -> "Bukoto I"
   - income_level: "low-income" -> "low"; "Middle-Income" -> "middle";
     "High-Income" -> "high"
   - age_head: strip " years"; "> 60 years" and ">60 years" -> ">60"
   - education_head: "IIIiterate" -> "Illiterate"; "Secondray" -> "Secondary";
     "Tertairy" -> "Tertiary"
   - profession_head: "Busness" -> "Business"; "Government Employee" -> "Government
     employee"; "Private Employee" -> "Private employee"
   - monthly_income_ugx: "less than 500,000" -> "<500,000"; the 7 middle-band variants
     (e.g. "500,0000-1,000,000", "500,000-1,00,000", "500,000 - 1,000,001") ->
     "500,000-1,000,000"; "1,000,000 - 3,000,000" -> "1,000,000-3,000,000"
   - respondent: "Household Head"/"Head" -> "Household head"; "Son", "Daughter",
     "Son/Daughter" -> "Son/daughter"; "Niece" -> "Niece/nephew" (Codes-sheet taxonomy)
   - period_of_stay: "< 1 year", "less than  ayear" -> "<1 year";
     "> 5 years" -> ">5 years"
   - occupancy: "0" -> "Occupied by owner" (Codes sheet: owner = 0; confirmed by
     All_data); "Occupied by Owner" -> "Occupied by owner"
   - housing_quality: "Story Building" -> "Story building"
   - roof_material: "Iron Sheets" -> "Iron sheets"; "Iron Sheets/titles" -> "Iron
     sheets/tiles" (keep three-way split; Bwaise recorded only the combined category)
   - wall_material: "bricks" -> "Bricks"; "Blocks", "Concrete Blocks" -> "Concrete blocks"
   - water_access: "House Connection", "Household Connetion" -> "House connection";
     "Yard Tap" -> "Yard tap"; "Public Standpipe" -> "Stand pipe"
   - sanitation_facility: "Shared", "shared Facilities", "Shared Facilities" -> "Shared
     facilities"; "Not Shared", "Not Shared Facilities", "Not Shared Faciltiies" ->
     "Not shared facilities"
   - road_condition: "unpaved", "Unpaced" -> "Unpaved"
7. Ordered factors: income_level (low < middle < high), age_head, education_head
   (Illiterate < Primary < Secondary < Tertiary), monthly_income_ugx, period_of_stay.
   Nominal columns stay character.
8. Preserve all numeric values as recorded, including known internal inconsistencies
   (noted in script comments, not altered): composition-sum mismatches for Bwaise
   Household_19, Bukoto Household_26 and _35, Ggaba Household_7; per-capita
   inconsistencies Ggaba Household_25 and _33; density outlier Bwaise Household_1.
9. Assign the result to `solidwastekampala`.

### Validation block (end of Tidy section, stopifnot + comments)

- `nrow == 103`; parish counts 39/32/32.
- No NA in the final frame.
- Each categorical column's values are a subset of its expected level set.
- Composition sums vs `waste_total_kg` (tol 0.01): exactly 99/103 pass; the 4 exceptions
  are the known ids.
- `waste_per_day_kg == waste_total_kg / 7` for all rows;
  per-capita check passes 101/103 (2 known exceptions);
  density check within 0.005 passes 102/103 (1 known exception).

## Step 2: Run the script (issue #2)

`Rscript data-raw/data_processing.R` from the package root. Outputs:
`data/solidwastekampala.rda`, `inst/extdata/solidwastekampala.csv`,
`inst/extdata/solidwastekampala.xlsx`.

## Step 3: Dictionary (issue #3)

1. Run `washr::setup_dictionary()` (washr repo at
   `/Users/lschoebitz/Documents/gitrepos/gh-org-openwashdata/washr`, CRAN 1.0.1;
   `setup_dictionary()` reads `data/`, writes `data-raw/dictionary.csv` with columns
   directory, file_name, variable_name, variable_type, description).
2. Fill the 37 descriptions: one sentence per variable, unit and factor levels included.
   Draft texts are agreed (e.g. waste_food_kg: "Mass of food waste generated by the
   household over the 7-day collection period, in kilograms (ASTM waste category)";
   density_kg_l: "Bulk density of the generated waste, in kilograms per litre; multiply
   by 1000 for kg/m3 as reported in the manuscript"). Sources: manuscript definitions
   and the Codes sheet.

## Step 4: Commit (issue #4)

Commit to `dev` via the commit skill: the implemented `data_processing.R`, raw xlsx,
`data/solidwastekampala.rda`, `inst/extdata/*`, `data-raw/dictionary.csv`.

## Verification

- Script runs clean end to end; all stopifnot assertions pass.
- Load `data/solidwastekampala.rda`; spot-check: 103 x 37 (37 raw columns minus `no`
  plus `id`), factor levels as specified, no NA.
- Reproduce manuscript headline numbers from the tidy data: mean per-capita generation
  by income level about 0.43 / 0.53 / 0.98 kg/ca.day; mean density by area about
  0.368 / 0.571 / 0.325 kg/L.
- `dictionary.csv` has 37 rows (one per variable), every description non-empty.
- One-time cross-check already done during planning: tidy numeric values match All_data
  positionally with 0 mismatches.

## Out of scope (next steps later)

DESCRIPTION metadata (`washr::update_description()`), roxygen docs
(`washr::setup_roxygen()`), README, pkgdown website, dataspice metadata, CITATION.
