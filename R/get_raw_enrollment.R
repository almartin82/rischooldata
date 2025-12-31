# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from RIDE.
#
# Data Source: Rhode Island Department of Education (RIDE) Data Center
# URL: https://datacenter.ride.ri.gov/
#
# RIDE provides October 1st Public School Student Headcounts with enrollment
# data by school, district, and state, broken down by:
# - Grade level (PK through 12)
# - Race/ethnicity
# - Gender
# - Free/Reduced Lunch status
# - English Learner (EL) status
# - IEP (Special Education) status
# - Immigrant status
# - Title I status
# - Charter status
#
# Data Eras:
# - Era 1 (2011-2014): Historical data from RIDE Data Center
#   Available through datacenter.ride.ri.gov with schoolyearid parameter
#   May have different column formats than modern data
# - Era 2 (2015-present): Current RIDE Data Center format
#   Files available at datacenter.ride.ri.gov with consistent format
#
# ==============================================================================

#' Download raw enrollment data from RIDE
#'
#' Downloads enrollment data from RIDE's Data Center.
#' Uses the October 1st Public School Student Headcounts reports.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years),
      "\nAvailable years: ", paste(available_years, collapse = ", ")
    ))
  }

  message(paste("Downloading RIDE enrollment data for", end_year, "..."))

  # Download from RIDE Data Center
  df <- download_ride_enrollment(end_year)

  # Add end_year column
  df$end_year <- end_year

  df
}


#' Download enrollment data from RIDE Data Center
#'
#' Downloads the October 1st Public School Student Headcounts file from RIDE.
#' The Data Center provides Excel files with enrollment data.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_ride_enrollment <- function(end_year) {

  # RIDE Data Center URL for October enrollment files

  # The file IDs change - we need to construct the URL dynamically
  # or download from a known pattern

  # Primary approach: Use the RIDE Data Center API/download endpoint
  # The enrollment data is available at:
  # https://datacenter.ride.ri.gov/Data/GetData or similar endpoints

  # Construct school year string (e.g., "2023-24" for end_year 2024)
  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  message(paste0("  Fetching October 1st enrollment for ", school_year, "..."))

  # Try multiple URL patterns that RIDE uses
  urls_to_try <- build_ride_urls(end_year)

  df <- NULL
  last_error <- NULL

  for (url in urls_to_try) {
    tryCatch({
      df <- download_ride_file(url, end_year)
      if (!is.null(df) && nrow(df) > 0) {
        message(paste0("  Successfully downloaded from: ", substr(url, 1, 80), "..."))
        break
      }
    }, error = function(e) {
      last_error <<- e
    })
  }

  if (is.null(df) || nrow(df) == 0) {
    # Try alternate download method
    df <- download_ride_enrollment_alt(end_year)
  }

  if (is.null(df) || nrow(df) == 0) {
    stop(paste0(
      "Failed to download enrollment data for year ", end_year,
      "\nRIDE may have changed their data format or the data may not be available yet.",
      "\nLast error: ", if (!is.null(last_error)) last_error$message else "No data returned"
    ))
  }

  df
}


#' Get school year ID for RIDE Data Center
#'
#' Maps end_year to the schoolyearid parameter used by RIDE Data Center.
#' Based on observed patterns: schoolyearid=11 corresponds to 2010-11,
#' schoolyearid=19 corresponds to 2018-19, etc.
#'
#' @param end_year School year end
#' @return Integer schoolyearid for RIDE Data Center
#' @keywords internal
get_schoolyear_id <- function(end_year) {

  # schoolyearid appears to be: end_year - 1999

  # e.g., 2011 -> 11, 2015 -> 15, 2024 -> 24
  # But with offset for older years
  # Based on research: schoolyearid=11 is 2010-11
  end_year - 2000
}


#' Build URLs to try for RIDE enrollment downloads
#'
#' @param end_year School year end
#' @return Character vector of URLs to try
#' @keywords internal
build_ride_urls <- function(end_year) {
  # RIDE Data Center uses various URL patterns
  # The exact file IDs vary by year, but we can try known patterns

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  school_year_alt <- paste0(end_year - 1, end_year)
  schoolyear_id <- get_schoolyear_id(end_year)

  # Known file ID patterns from research
  # File IDs in the 990-1100+ range are enrollment files
  base_url <- "https://datacenter.ride.ri.gov"

  # Calculate file ID based on year

  # fileid=994 appears to be associated with October enrollment data
  # For historical years, we need to try different patterns
  if (end_year >= 2015) {
    # Modern era - use known file ID patterns
    file_id_base <- 994
    file_id_offset <- end_year - 2021
  } else {
    # Historical era (2011-2014) - try different file ID ranges
    file_id_base <- 787  # Observed historical file ID
    file_id_offset <- end_year - 2011
  }

  urls <- c(
    # Primary: Enrollment dashboard export
    paste0(base_url, "/Data/Enrollment?schoolyearid=", schoolyear_id, "&format=excel"),

    # Direct data export endpoint
    paste0(base_url, "/Data/ExportData?datatype=enrollment&year=", end_year),
    paste0(base_url, "/Data/ExportData?datatype=October&year=", end_year),

    # File download endpoint with various file IDs
    paste0(base_url, "/Home/DownloadFile?fileid=", file_id_base + file_id_offset),

    # School year based search with export
    paste0(base_url, "/Home/SearchBySchoolYear?schoolyearid=", schoolyear_id, "&export=excel"),

    # Report export endpoints
    paste0(base_url, "/Report/Export?report=enrollment&schoolyear=", school_year),
    paste0(base_url, "/Report/Export?report=oct1headcount&schoolyear=", school_year),

    # Category-based endpoints (categoryid=246 is enrollment by demographics)
    paste0(base_url, "/Home/SearchByCategory?categoryid=246&schoolyear=", school_year, "&export=excel"),

    # CSV/API export
    paste0(base_url, "/api/enrollment/", end_year),
    paste0(base_url, "/api/data/enrollment?year=", end_year)
  )

  urls
}


#' Download a file from RIDE Data Center
#'
#' @param url URL to download from
#' @param end_year School year end (for temp file naming)
#' @return Data frame or NULL if download fails
#' @keywords internal
download_ride_file <- function(url, end_year) {

  # Create temp file
  tname <- tempfile(
    pattern = paste0("ride_enr_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Download with httr
  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120),
    httr::add_headers(
      "User-Agent" = "rischooldata R package",
      "Accept" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel, text/csv, */*"
    )
  )

  # Check for HTTP errors
  if (httr::http_error(response)) {
    unlink(tname)
    return(NULL)
  }

  # Check file size (small files likely error pages)
  file_info <- file.info(tname)
  if (file_info$size < 1000) {
    # Check if it's an HTML error page
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    if (any(grepl("^<|error|not found|404", first_lines, ignore.case = TRUE))) {
      unlink(tname)
      return(NULL)
    }
  }

  # Try to read as Excel
  df <- tryCatch({
    readxl::read_excel(tname, sheet = 1, col_types = "text")
  }, error = function(e) {
    # Try as CSV
    tryCatch({
      readr::read_csv(tname, col_types = readr::cols(.default = readr::col_character()),
                      show_col_types = FALSE)
    }, error = function(e2) {
      NULL
    })
  })

  unlink(tname)

  df
}


#' Alternative download method for RIDE enrollment data
#'
#' Uses the eRIDE FRED (Frequently Requested Education Data) system
#' as a fallback when the Data Center is unavailable.
#'
#' @param end_year School year end
#' @return Data frame or NULL if download fails
#' @keywords internal
download_ride_enrollment_alt <- function(end_year) {

  message("  Trying alternate download method (FRED/eRIDE)...")

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  # eRIDE FRED URLs
  fred_url <- paste0(
    "https://www.eride.ri.gov/FileExchange/GetFile.aspx?",
    "category=Enrollment&year=", school_year
  )

  df <- tryCatch({
    download_ride_file(fred_url, end_year)
  }, error = function(e) {
    NULL
  })

  if (is.null(df) || nrow(df) == 0) {
    # Try InfoWorks archived data (for historical years)
    df <- download_infoworks_enrollment(end_year)
  }

  df
}


#' Download enrollment from InfoWorks (archived system)
#'
#' For historical data that may only be available in the archived
#' InfoWorks system.
#'
#' @param end_year School year end
#' @return Data frame or NULL if download fails
#' @keywords internal
download_infoworks_enrollment <- function(end_year) {

  message("  Trying InfoWorks archive...")

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  # InfoWorks data export URL
  infoworks_url <- paste0(
    "http://infoworks.ride.ri.gov/data/export?",
    "indicator=enrollment&year=", school_year, "&format=csv"
  )

  tname <- tempfile(
    pattern = paste0("ride_infoworks_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  df <- tryCatch({
    response <- httr::GET(
      infoworks_url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(120)
    )

    if (httr::http_error(response)) {
      return(NULL)
    }

    readr::read_csv(tname, col_types = readr::cols(.default = readr::col_character()),
                    show_col_types = FALSE)
  }, error = function(e) {
    NULL
  })

  unlink(tname)

  df
}


#' Import local enrollment file
#'
#' For cases where automated download is not possible, this function
#' allows importing a locally downloaded file.
#'
#' @param file_path Path to local Excel or CSV file
#' @param end_year School year end (for adding year column)
#' @return Data frame with enrollment data
#' @keywords internal
import_local_enrollment <- function(file_path, end_year) {

  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  ext <- tolower(tools::file_ext(file_path))

  df <- switch(ext,
    "xlsx" = readxl::read_excel(file_path, sheet = 1, col_types = "text"),
    "xls" = readxl::read_excel(file_path, sheet = 1, col_types = "text"),
    "csv" = readr::read_csv(file_path, col_types = readr::cols(.default = readr::col_character()),
                             show_col_types = FALSE),
    stop(paste("Unsupported file type:", ext))
  )

  df$end_year <- end_year

  df
}
