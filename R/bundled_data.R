# ==============================================================================
# Bundled Data Functions
# ==============================================================================
#
# This file contains functions for loading bundled enrollment data.
# The RIDE Data Center requires JavaScript for file downloads, so we bundle
# static data files that can be updated periodically.
#
# Data Sources:
# - oct1st-headcount-2010-2026.xlsx: District and school totals by year
# - oct1st-headcount-2010-2025-State-Demo.xlsx: State-level demographics
#
# ==============================================================================

#' Load bundled enrollment data
#'
#' Loads the bundled October 1st enrollment data from the package.
#' This is the primary data source since the RIDE Data Center
#' requires browser-based downloads.
#'
#' @param end_year School year end (2011-2026)
#' @return Data frame with enrollment data in wide format
#' @keywords internal
load_bundled_enr <- function(end_year) {

  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years),
      "\nAvailable years: ", paste(range(available_years), collapse = "-")
    ))
  }

  # Load district/school data
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  if (lea_file == "") {
    stop("Bundled data file not found. Package may need reinstallation.")
  }

  # Read LEA sheet
  lea_data <- readxl::read_excel(lea_file, sheet = "LEAs")

  # Read Schools sheet
  school_data <- readxl::read_excel(lea_file, sheet = "Schools")

  # Convert year column name to string
  year_col <- as.character(end_year - 2000 + 2000)  # e.g., 2024 -> "2024"

  # Check if year column exists
  if (!year_col %in% names(lea_data)) {
    # Try alternate format (some files use 2-digit years)
    year_col_alt <- as.character(end_year - 2000)
    if (!year_col_alt %in% names(lea_data)) {
      stop(paste0("Year ", end_year, " not found in bundled data"))
    }
    year_col <- year_col_alt
  }

  # Process LEA data
  lea_processed <- lea_data |>
    dplyr::select(`LEA NAME`, dplyr::all_of(year_col)) |>
    dplyr::rename(
      district_name = `LEA NAME`,
      row_total = !!year_col
    ) |>
    dplyr::mutate(
      end_year = end_year,
      type = "District",
      district_id = NA_character_,
      campus_id = NA_character_,
      campus_name = NA_character_,
      row_total = as.numeric(row_total)
    ) |>
    # Filter out total rows and NA values
    dplyr::filter(!is.na(row_total),
                  !grepl("^(Grand )?Total$", district_name, ignore.case = TRUE))

  # Process school data
  school_processed <- school_data |>
    dplyr::select(`Row Labels`, dplyr::all_of(year_col)) |>
    dplyr::rename(
      campus_name = `Row Labels`,
      row_total = !!year_col
    ) |>
    dplyr::mutate(
      end_year = end_year,
      type = "Campus",
      district_id = NA_character_,
      campus_id = NA_character_,
      district_name = NA_character_,
      row_total = as.numeric(row_total)
    ) |>
    dplyr::filter(!is.na(row_total))

  # Combine
  combined <- dplyr::bind_rows(lea_processed, school_processed)

  # Load state demographics
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  if (demo_file != "" && end_year <= 2025) {
    demo_data <- readxl::read_excel(demo_file, sheet = 1)

    # Get year column
    demo_year_col <- as.character(end_year - 2000 + 2000)
    if (!demo_year_col %in% names(demo_data)) {
      demo_year_col <- as.character(end_year - 2000)
    }

    if (demo_year_col %in% names(demo_data)) {
      # Process demographic data into state row
      demo_values <- demo_data[[demo_year_col]]
      demo_labels <- demo_data[[1]]

      state_row <- data.frame(
        end_year = end_year,
        type = "State",
        district_id = NA_character_,
        campus_id = NA_character_,
        district_name = NA_character_,
        campus_name = NA_character_,
        stringsAsFactors = FALSE
      )

      # Extract values by label
      get_val <- function(pattern) {
        idx <- grep(pattern, demo_labels, ignore.case = TRUE)
        if (length(idx) > 0) as.numeric(demo_values[idx[1]]) else NA_real_
      }

      state_row$row_total <- get_val("^TOTAL$")

      # Grade levels
      state_row$grade_pk <- get_val("GRADE-PK")
      state_row$grade_k <- get_val("GRADE-KF") + get_val("GRADE-KG")
      state_row$grade_01 <- get_val("GRADE-01")
      state_row$grade_02 <- get_val("GRADE-02")
      state_row$grade_03 <- get_val("GRADE-03")
      state_row$grade_04 <- get_val("GRADE-04")
      state_row$grade_05 <- get_val("GRADE-05")
      state_row$grade_06 <- get_val("GRADE-06")
      state_row$grade_07 <- get_val("GRADE-07")
      state_row$grade_08 <- get_val("GRADE-08")
      state_row$grade_09 <- get_val("GRADE-09")
      state_row$grade_10 <- get_val("GRADE-10")
      state_row$grade_11 <- get_val("GRADE-11")
      state_row$grade_12 <- get_val("GRADE-12")

      # Race/ethnicity
      state_row$white <- get_val("RACE7-WH7")
      state_row$black <- get_val("RACE7-BL7")
      state_row$hispanic <- get_val("RACE7-HI7")
      state_row$asian <- get_val("RACE7-AS7")
      state_row$native_american <- get_val("RACE7-AM7")
      state_row$pacific_islander <- get_val("RACE7-PI7")
      state_row$multiracial <- get_val("RACE7-MU7")

      # Gender
      state_row$male <- get_val("^GENDER-M$")
      state_row$female <- get_val("^GENDER-F$")

      # Special populations
      state_row$econ_disadv <- get_val("^FRL$")
      state_row$lep <- get_val("^ELL$")
      state_row$special_ed <- get_val("^IEP$")
      state_row$immigrant <- get_val("^IMMIGRANT$")
      state_row$homeless <- get_val("^HOMELESS$")
      state_row$title1 <- get_val("^TITLE1$")

      # Non-binary/other gender
      state_row$gender_other <- get_val("^GENDER-O$")

      # Add charter flag
      state_row$charter_flag <- NA_character_

      combined <- dplyr::bind_rows(state_row, combined)
    }
  }

  # Ensure all expected columns exist
  expected_cols <- c("end_year", "type", "district_id", "campus_id",
                     "district_name", "campus_name", "charter_flag", "row_total",
                     "white", "black", "hispanic", "asian",
                     "native_american", "pacific_islander", "multiracial",
                     "male", "female", "gender_other",
                     "econ_disadv", "lep", "special_ed",
                     "immigrant", "homeless", "title1",
                     "grade_pk", "grade_k", "grade_01", "grade_02", "grade_03",
                     "grade_04", "grade_05", "grade_06", "grade_07", "grade_08",
                     "grade_09", "grade_10", "grade_11", "grade_12")

  for (col in expected_cols) {
    if (!col %in% names(combined)) {
      combined[[col]] <- NA
    }
  }

  combined
}


#' Check if bundled data is available for a year
#'
#' @param end_year School year end
#' @return TRUE if bundled data exists for the year
#' @keywords internal
bundled_data_available <- function(end_year) {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  if (lea_file == "") return(FALSE)

  # Check if year column exists
  tryCatch({
    lea_data <- readxl::read_excel(lea_file, sheet = "LEAs", n_max = 1)
    year_col <- as.character(end_year - 2000 + 2000)
    year_col %in% names(lea_data)
  }, error = function(e) FALSE)
}
