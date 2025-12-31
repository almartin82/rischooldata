# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw RIDE enrollment data into a
# clean, standardized format.
#
# Rhode Island ID System:
# - District IDs: 2-3 digit codes (e.g., 01 for Barrington)
# - School IDs: 5 digit codes (district + 2-3 digit school number)
# - State uses ~36 traditional districts + ~20 charter schools
#
# ==============================================================================

#' Process raw RIDE enrollment data
#'
#' Transforms raw RIDE data into a standardized schema.
#'
#' @param raw_data Data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Standardize column names (lowercase, remove spaces)
  names(raw_data) <- tolower(gsub("\\s+", "_", names(raw_data)))
  names(raw_data) <- gsub("[^a-z0-9_]", "", names(raw_data))

  # Detect data format and process accordingly
  df <- process_ride_enrollment(raw_data, end_year)

  # Create state aggregate
  state_row <- create_state_aggregate(df, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_row, df)

  result
}


#' Process RIDE enrollment data
#'
#' Handles the main processing for RIDE Data Center format.
#'
#' @param df Raw data frame with standardized column names
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_ride_enrollment <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by patterns (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      # Try exact match first
      if (pattern %in% cols) return(pattern)
      # Try pattern match
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Initialize result with core columns
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # Determine record type (State/District/Campus)
  # RIDE data typically has school-level, district-level, and state rows
  org_type_col <- find_col(c("orgtype", "org_type", "type", "level", "record_type"))
  org_level_col <- find_col(c("orglevel", "org_level"))
  school_col <- find_col(c("schoolcode", "school_code", "schoolid", "school_id", "schcode"))
  district_col <- find_col(c("districtcode", "district_code", "districtid", "district_id", "distcode", "lea_code", "leacode"))

  if (!is.null(org_type_col)) {
    # Use explicit type column
    result$type <- dplyr::case_when(
      grepl("state", df[[org_type_col]], ignore.case = TRUE) ~ "State",
      grepl("district|lea", df[[org_type_col]], ignore.case = TRUE) ~ "District",
      grepl("school|campus", df[[org_type_col]], ignore.case = TRUE) ~ "Campus",
      TRUE ~ "Campus"  # Default to campus for school-level data
    )
  } else if (!is.null(org_level_col)) {
    result$type <- dplyr::case_when(
      df[[org_level_col]] == "State" ~ "State",
      df[[org_level_col]] == "District" ~ "District",
      TRUE ~ "Campus"
    )
  } else {
    # Infer from ID columns
    if (!is.null(school_col) && !is.null(district_col)) {
      result$type <- dplyr::case_when(
        is.na(df[[school_col]]) | df[[school_col]] == "" ~ "District",
        TRUE ~ "Campus"
      )
    } else if (!is.null(school_col)) {
      result$type <- rep("Campus", n_rows)
    } else if (!is.null(district_col)) {
      result$type <- rep("District", n_rows)
    } else {
      result$type <- rep("Campus", n_rows)
    }
  }

  # District ID
  if (!is.null(district_col)) {
    result$district_id <- trimws(as.character(df[[district_col]]))
    # Pad to consistent width if needed
    result$district_id <- sprintf("%02s", result$district_id)
  }

  # School/Campus ID
  if (!is.null(school_col)) {
    result$campus_id <- trimws(as.character(df[[school_col]]))
  } else {
    result$campus_id <- rep(NA_character_, n_rows)
  }

  # District name
  dist_name_col <- find_col(c("districtname", "district_name", "distname", "dist_name", "leaname", "lea_name"))
  if (!is.null(dist_name_col)) {
    result$district_name <- trimws(df[[dist_name_col]])
  }

  # School/Campus name
  school_name_col <- find_col(c("schoolname", "school_name", "schname", "sch_name", "campus_name", "campusname"))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(df[[school_name_col]])
  } else {
    result$campus_name <- rep(NA_character_, n_rows)
  }

  # Charter flag
  charter_col <- find_col(c("charter", "charterflag", "charter_flag", "ischarter", "is_charter"))
  if (!is.null(charter_col)) {
    charter_vals <- trimws(tolower(df[[charter_col]]))
    result$charter_flag <- dplyr::case_when(
      charter_vals %in% c("y", "yes", "1", "true", "charter") ~ "Y",
      charter_vals %in% c("n", "no", "0", "false") ~ "N",
      TRUE ~ NA_character_
    )
  }

  # Total enrollment
  total_col <- find_col(c("total", "totalenrollment", "total_enrollment", "enrollment", "count", "headcount", "total_headcount"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Race/Ethnicity
  demo_map <- list(
    white = c("white", "white_count", "wh", "ethnicity_white"),
    black = c("black", "black_count", "bl", "africanamerican", "african_american", "ethnicity_black"),
    hispanic = c("hispanic", "hispanic_count", "hi", "latino", "ethnicity_hispanic"),
    asian = c("asian", "asian_count", "as", "ethnicity_asian"),
    native_american = c("nativeamerican", "native_american", "americanindian", "american_indian", "ai", "na", "ethnicity_native"),
    pacific_islander = c("pacificislander", "pacific_islander", "pi", "hawaiian", "native_hawaiian", "ethnicity_pacific"),
    multiracial = c("multiracial", "multi_racial", "twoormorerace", "two_or_more", "multirace", "ethnicity_multi")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  male_col <- find_col(c("male", "male_count", "m", "gender_male"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(c("female", "female_count", "f", "gender_female"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("frl", "frpl", "free_reduced", "freereducedlunch", "free_reduced_lunch",
                    "economicdisadvantaged", "economically_disadvantaged", "lowincome", "low_income"),
    lep = c("el", "ell", "lep", "englishlearner", "english_learner", "limitedengproficient",
            "limited_english", "multilingual"),
    special_ed = c("iep", "sped", "specialed", "special_ed", "special_education",
                   "disability", "students_with_disabilities", "swd")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_patterns <- list(
    grade_pk = c("pk", "pre_k", "prek", "prekindergarten", "grade_pk", "gradepk"),
    grade_k = c("^k$", "kindergarten", "grade_k", "gradek", "^kg$"),
    grade_01 = c("grade_01", "grade01", "gr01", "^1$", "^01$", "first"),
    grade_02 = c("grade_02", "grade02", "gr02", "^2$", "^02$", "second"),
    grade_03 = c("grade_03", "grade03", "gr03", "^3$", "^03$", "third"),
    grade_04 = c("grade_04", "grade04", "gr04", "^4$", "^04$", "fourth"),
    grade_05 = c("grade_05", "grade05", "gr05", "^5$", "^05$", "fifth"),
    grade_06 = c("grade_06", "grade06", "gr06", "^6$", "^06$", "sixth"),
    grade_07 = c("grade_07", "grade07", "gr07", "^7$", "^07$", "seventh"),
    grade_08 = c("grade_08", "grade08", "gr08", "^8$", "^08$", "eighth"),
    grade_09 = c("grade_09", "grade09", "gr09", "^9$", "^09$", "ninth"),
    grade_10 = c("grade_10", "grade10", "gr10", "^10$", "tenth"),
    grade_11 = c("grade_11", "grade11", "gr11", "^11$", "eleventh"),
    grade_12 = c("grade_12", "grade12", "gr12", "^12$", "twelfth")
  )

  for (name in names(grade_patterns)) {
    col <- find_col(grade_patterns[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Set campus_id to NA for district rows
  result$campus_id[result$type == "District"] <- NA_character_
  result$campus_name[result$type == "District"] <- NA_character_

  result
}


#' Create state-level aggregate from district data
#'
#' @param df Processed data frame (should contain district-level rows)
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(df, end_year) {

  # Filter to district-level rows only for aggregation
  district_df <- df[df$type == "District", ]

  if (nrow(district_df) == 0) {
    # If no district rows, sum all campus rows
    district_df <- df[df$type == "Campus", ]
  }

  if (nrow(district_df) == 0) {
    # Return empty state row if no data
    return(data.frame(
      end_year = end_year,
      type = "State",
      district_id = NA_character_,
      campus_id = NA_character_,
      district_name = NA_character_,
      campus_name = NA_character_,
      charter_flag = NA_character_,
      row_total = NA_integer_,
      stringsAsFactors = FALSE
    ))
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    charter_flag = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}
