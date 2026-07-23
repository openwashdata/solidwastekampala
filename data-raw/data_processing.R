# Description ------------------------------------------------------------------
# R script to process uploaded raw data into a tidy, analysis-ready data frame
# Load packages ----------------------------------------------------------------
## Run the following code in console if you don't have the packages
## install.packages(c("usethis", "fs", "here", "readr", "readxl", "openxlsx",
##                    "dplyr", "stringr", "purrr"))
library(usethis)
library(fs)
library(here)
library(readr)
library(readxl)
library(openxlsx)
library(dplyr)
library(stringr)
library(purrr)

# Read data --------------------------------------------------------------------
## Only the three raw area sheets are processed. "All_data" consolidates the
## same 103 rows (used as a cross-check during planning), "Codes" is the
## codebook, and the remaining sheets hold derived results.
## All columns are read as text: guessed column types differ across sheets (a
## text-stored number makes Ggaba's metals column character) and readxl renders
## numeric cells to text at full double precision, so the round-trip is
## lossless. Column names are hand-written because the merged two-level headers
## differ in spelling between sheets.

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

## Sheet order matches the row numbering in the All_data sheet
data_in <- c("Bwaise I", "Bukoto I", "Ggaba") |>
  map(\(sheet) read_excel(
    here::here("data-raw", "data_sheets_with_analysis.xlsx"),
    sheet = sheet,
    skip = 4,
    col_names = raw_names,
    col_types = "text"
  )) |>
  bind_rows()

# Tidy data --------------------------------------------------------------------

solidwastekampala <- data_in |>
  ## Keep household rows; trailing rows hold sheet-level summary statistics
  filter(str_detect(no, "^[0-9]+$")) |>
  ## Ggaba cell AE10 (Household_7) stores 2.674 as the text "2..674". The
  ## recorded total (60.082) excludes this value because Excel's SUM skips
  ## text. The total is kept as recorded, not recomputed, since the per-day,
  ## per-capita, and density columns chain off it.
  mutate(
    waste_metals_kg = if_else(
      waste_metals_kg == "2..674", "2.674", waste_metals_kg
    )
  ) |>
  mutate(
    across(waste_food_kg:density_kg_l, as.numeric),
    occupants = as.integer(occupants)
  ) |>
  ## Package-level unique key following the All_data numbering 1-103;
  ## household_id values repeat across parishes
  select(-no) |>
  mutate(id = row_number(), .before = 1) |>
  ## Two malformed IDs in Bukoto I
  mutate(
    household_id = recode_values(
      household_id,
      "Household__9" ~ "Household_9",
      "Househols_16" ~ "Household_16",
      default = household_id
    )
  ) |>
  ## Harmonize categorical labels. Where a recode_values() has no default, the
  ## listed values cover the whole column, so an unexpected value would surface
  ## as NA and fail the validation below.
  mutate(
    division = recode_values(
      division,
      "Kawenpe Division" ~ "Kawempe",
      "Makindye Division" ~ "Makindye",
      default = division
    ),
    parish = recode_values(
      parish,
      "Bukoto 1" ~ "Bukoto I",
      default = parish
    ),
    income_level = recode_values(
      income_level,
      "low-income" ~ "low",
      "Middle-Income" ~ "middle",
      "High-Income" ~ "high"
    ),
    age_head = recode_values(
      age_head,
      "18-35 years" ~ "18-35",
      "36-60 years" ~ "36-60",
      c("> 60 years", ">60 years") ~ ">60"
    ),
    education_head = recode_values(
      education_head,
      "IIIiterate" ~ "Illiterate",
      "Secondray" ~ "Secondary",
      "Tertairy" ~ "Tertiary",
      default = education_head
    ),
    profession_head = recode_values(
      profession_head,
      "Busness" ~ "Business",
      "Government Employee" ~ "Government employee",
      "Private Employee" ~ "Private employee",
      default = profession_head
    ),
    monthly_income_ugx = recode_values(
      monthly_income_ugx,
      "less than 500,000" ~ "<500,000",
      c(
        "500,000 - 1,000,000", "500,000 - 1,000,001", "500,000-1,00,000",
        "500,000-1,000-000", "500,000-1,0000,000", "500,0000-1,000,000"
      ) ~ "500,000-1,000,000",
      "1,000,000 - 3,000,000" ~ "1,000,000-3,000,000",
      default = monthly_income_ugx
    ),
    ## Niece/nephew follows the Codes-sheet taxonomy
    respondent = recode_values(
      respondent,
      c("Household Head", "Head") ~ "Household head",
      c("Son", "Daughter", "Son/Daughter") ~ "Son/daughter",
      "Niece" ~ "Niece/nephew",
      default = respondent
    ),
    period_of_stay = recode_values(
      period_of_stay,
      c("< 1 year", "less than  ayear") ~ "<1 year",
      "> 5 years" ~ ">5 years",
      default = period_of_stay
    ),
    ## Codes sheet: owner = 0; confirmed against All_data
    occupancy = recode_values(
      occupancy,
      c("0", "Occupied by Owner") ~ "Occupied by owner",
      default = occupancy
    ),
    housing_quality = recode_values(
      housing_quality,
      "Story Building" ~ "Story building",
      default = housing_quality
    ),
    ## The three-way split is kept; Bwaise I recorded only the combined
    ## "Iron sheets/tiles" category
    roof_material = recode_values(
      roof_material,
      "Iron Sheets" ~ "Iron sheets",
      "Iron Sheets/titles" ~ "Iron sheets/tiles",
      default = roof_material
    ),
    wall_material = recode_values(
      wall_material,
      "bricks" ~ "Bricks",
      c("Blocks", "Concrete Blocks") ~ "Concrete blocks",
      default = wall_material
    ),
    water_access = recode_values(
      water_access,
      c("House Connection", "Household Connetion") ~ "House connection",
      "Yard Tap" ~ "Yard tap",
      "Public Standpipe" ~ "Stand pipe",
      default = water_access
    ),
    sanitation_facility = recode_values(
      sanitation_facility,
      c("Shared", "shared Facilities", "Shared Facilities") ~
        "Shared facilities",
      c("Not Shared", "Not Shared Facilities", "Not Shared Faciltiies") ~
        "Not shared facilities"
    ),
    road_condition = recode_values(
      road_condition,
      c("unpaved", "Unpaced") ~ "Unpaved",
      default = road_condition
    )
  ) |>
  ## Ordered factors; nominal columns stay character
  mutate(
    income_level = factor(
      income_level,
      levels = c("low", "middle", "high"), ordered = TRUE
    ),
    age_head = factor(
      age_head,
      levels = c("18-35", "36-60", ">60"), ordered = TRUE
    ),
    education_head = factor(
      education_head,
      levels = c("Illiterate", "Primary", "Secondary", "Tertiary"),
      ordered = TRUE
    ),
    monthly_income_ugx = factor(
      monthly_income_ugx,
      levels = c(
        "<500,000", "500,000-1,000,000", "1,000,000-3,000,000", ">3,000,000"
      ),
      ordered = TRUE
    ),
    period_of_stay = factor(
      period_of_stay,
      levels = c("<1 year", "1-3 years", "3-5 years", ">5 years"),
      ordered = TRUE
    )
  )

## Validate ---------------------------------------------------------------
## Numeric values are preserved as recorded, including known internal
## inconsistencies in the source workbook (asserted below, not altered):
## - composition sum vs recorded total: Bwaise I Household_19, Bukoto I
##   Household_26 and Household_35, Ggaba Household_7
## - per-capita vs per-day / occupants: Ggaba Household_25 and Household_33
## - density vs total / volume: Bwaise I Household_1

stopifnot(
  nrow(solidwastekampala) == 103,
  identical(
    as.integer(table(solidwastekampala$parish)[c("Bwaise I", "Bukoto I", "Ggaba")]),
    c(39L, 32L, 32L)
  ),
  !anyNA(solidwastekampala)
)

expected_levels <- list(
  division = c("Kawempe", "Makindye", "Nakawa"),
  parish = c("Bwaise I", "Bukoto I", "Ggaba"),
  zone = c(
    "Bishop Mukwaya", "Bubajjwe", "Kiyaga", "Kulumba", "Lubagge", "Lule",
    "Mukalazi", "Nsubuga Godioz", "Ssemwogerere"
  ),
  income_level = c("low", "middle", "high"),
  age_head = c("18-35", "36-60", ">60"),
  gender_head = c("Female", "Male"),
  education_head = c("Illiterate", "Primary", "Secondary", "Tertiary"),
  profession_head = c(
    "Business", "Government employee", "Housewife", "Private employee",
    "Retired"
  ),
  monthly_income_ugx = c(
    "<500,000", "500,000-1,000,000", "1,000,000-3,000,000", ">3,000,000"
  ),
  respondent = c("Household head", "Spouse", "Son/daughter", "Niece/nephew"),
  period_of_stay = c("<1 year", "1-3 years", "3-5 years", ">5 years"),
  occupancy = c("Occupied by owner", "Rented"),
  housing_quality = c("Bungalow", "Story building", "Temporary"),
  roof_material = c("Cemented", "Iron sheets", "Iron sheets/tiles", "Tiles"),
  wall_material = c("Bricks", "Concrete blocks", "Mud/poles"),
  floor_material = c("Cemented", "Mud", "Tiles"),
  water_access = c("House connection", "Stand pipe", "Yard tap"),
  sanitation_facility = c("Not shared facilities", "Shared facilities"),
  road_condition = c("Paved", "Unpaved")
)

stopifnot(
  imap_lgl(expected_levels, \(levels, column) {
    all(as.character(solidwastekampala[[column]]) %in% levels)
  })
)

## Composition columns are kilograms per 7-day collection and sum to the
## recorded total within 0.01 kg for 99 of 103 households
composition_sum <- solidwastekampala |>
  select(waste_food_kg:waste_other_kg) |>
  rowSums()
composition_ok <-
  abs(composition_sum - solidwastekampala$waste_total_kg) <= 0.01
household_label <-
  paste(solidwastekampala$parish, solidwastekampala$household_id)
stopifnot(
  sum(composition_ok) == 99,
  identical(
    household_label[!composition_ok],
    c(
      "Bwaise I Household_19", "Bukoto I Household_26",
      "Bukoto I Household_35", "Ggaba Household_7"
    )
  )
)

per_day_ok <- abs(
  solidwastekampala$waste_per_day_kg - solidwastekampala$waste_total_kg / 7
) < 1e-9
per_capita_ok <- abs(
  solidwastekampala$waste_per_capita_kg -
    solidwastekampala$waste_per_day_kg / solidwastekampala$occupants
) < 1e-9
density_ok <- abs(
  solidwastekampala$density_kg_l -
    solidwastekampala$waste_total_kg / solidwastekampala$volume_l
) <= 0.005
stopifnot(
  all(per_day_ok),
  identical(
    household_label[!per_capita_ok],
    c("Ggaba Household_25", "Ggaba Household_33")
  ),
  identical(household_label[!density_ok], "Bwaise I Household_1")
)

# Export Data ------------------------------------------------------------------
usethis::use_data(solidwastekampala, overwrite = TRUE)
fs::dir_create(here::here("inst", "extdata"))
readr::write_csv(solidwastekampala,
                 here::here("inst", "extdata", paste0("solidwastekampala", ".csv")))
openxlsx::write.xlsx(solidwastekampala,
                     here::here("inst", "extdata", paste0("solidwastekampala", ".xlsx")))
