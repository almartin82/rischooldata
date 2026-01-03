# ==============================================================================
# LIVE Pipeline Tests for Rhode Island Enrollment Data
# ==============================================================================
#
# These tests verify each step of the data pipeline using LIVE network calls
# and actual file operations. NO MOCKS.
#
# Note: RIDE Data Center requires JavaScript for file downloads, so the package
# uses bundled data files. These tests verify:
# 1. RIDE Data Center website is accessible (even if downloads need JS)
# 2. Bundled data files exist and are readable
# 3. Excel files parse correctly with expected structure
# 4. Data values match known published values
# 5. Processing pipeline maintains fidelity
#
# Test Categories:
# 1. URL Availability Tests - Verify RIDE websites return HTTP 200
# 2. Bundled File Tests - Verify bundled Excel files are valid
# 3. Excel Parsing Tests - Verify files parse with expected structure
# 4. Column Structure Tests - Verify expected columns exist
# 5. Year Filtering Tests - Verify data extraction by year
# 6. Aggregation Tests - Verify totals sum correctly
# 7. Data Quality Tests - Verify no Inf/NaN/impossible values
# 8. Output Fidelity Tests - Verify tidy output matches raw data
#
# ==============================================================================

# Helper: Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}

# ==============================================================================
# 1. URL AVAILABILITY TESTS
# ==============================================================================

test_that("RIDE Data Center base domain is accessible", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::GET("https://datacenter.ride.ri.gov", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("RIDE Data Center Enrollment Dashboard page is accessible", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::GET("https://datacenter.ride.ri.gov/Data/EnrollmentDashboard",
                        httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("RIDE main website is accessible", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::GET("https://www.ride.ri.gov", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("RIDE Data Center file detail pages are accessible", {
  skip_on_cran()
  skip_if_offline()

  # Known file IDs for enrollment data (as of late 2025)
  file_ids <- c(1115, 1114)

  for (fid in file_ids) {
    url <- paste0("https://datacenter.ride.ri.gov/Home/FileDetail?fileid=", fid)
    response <- httr::GET(url, httr::timeout(30))
    expect_equal(
      httr::status_code(response),
      200,
      info = paste("FileDetail page for fileid", fid, "should be accessible")
    )
  }
})

test_that("RIDE Data Center download endpoint returns expected response", {
  skip_on_cran()
  skip_if_offline()

  # The DownloadFile endpoint requires JavaScript, so we expect a 500 error
  # or redirect when accessed programmatically
  url <- "https://datacenter.ride.ri.gov/Home/DownloadFile?fileid=1115"
  response <- httr::GET(url, httr::timeout(30))


  # Document the expected behavior: 500 error because JS is required
  # This is not a failure - it's documenting the known limitation
  status <- httr::status_code(response)
  expect_true(
    status %in% c(200, 302, 403, 500),
    info = paste("DownloadFile endpoint returned HTTP", status,
                 "- downloads require JavaScript")
  )
})

# ==============================================================================
# 2. BUNDLED FILE TESTS
# ==============================================================================

test_that("Bundled LEA/School enrollment file exists", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  expect_true(lea_file != "", info = "LEA file should exist in package")
  expect_true(file.exists(lea_file), info = "LEA file should be readable")
})

test_that("Bundled State Demographics file exists", {
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  expect_true(demo_file != "", info = "Demographics file should exist in package")
  expect_true(file.exists(demo_file), info = "Demographics file should be readable")
})

test_that("Bundled files have reasonable size", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  lea_size <- file.info(lea_file)$size
  demo_size <- file.info(demo_file)$size

  # Files should be >10KB (not empty or corrupt)
  expect_true(lea_size > 10000,
              info = paste("LEA file should be >10KB, got", lea_size, "bytes"))
  expect_true(demo_size > 5000,
              info = paste("Demo file should be >5KB, got", demo_size, "bytes"))
})

# ==============================================================================
# 3. EXCEL PARSING TESTS
# ==============================================================================

test_that("LEA file has expected Excel sheets", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  sheets <- readxl::excel_sheets(lea_file)

  expect_true("LEAs" %in% sheets, info = "Should have LEAs sheet")
  expect_true("Schools" %in% sheets, info = "Should have Schools sheet")
})

test_that("LEA sheet parses to valid data frame", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  df <- readxl::read_excel(lea_file, sheet = "LEAs")

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0, info = "LEAs sheet should have data rows")
  expect_true(ncol(df) > 0, info = "LEAs sheet should have columns")
})

test_that("Schools sheet parses to valid data frame", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  df <- readxl::read_excel(lea_file, sheet = "Schools")

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0, info = "Schools sheet should have data rows")
})

test_that("State Demographics file parses to valid data frame", {
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  df <- readxl::read_excel(demo_file, sheet = 1)

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 0, info = "Demographics file should have data rows")
  expect_true(ncol(df) > 0, info = "Demographics file should have columns")
})

# ==============================================================================
# 4. COLUMN STRUCTURE TESTS
# ==============================================================================

test_that("LEA sheet has expected columns for all years", {
  lea_file <- system.file("extdata", "oct1st-headcount-2010-2026.xlsx",
                          package = "rischooldata")

  df <- readxl::read_excel(lea_file, sheet = "LEAs")
  col_names <- names(df)

  # Should have LEA NAME column
  expect_true("LEA NAME" %in% col_names, info = "Should have 'LEA NAME' column")

  # Should have year columns for 2010-2026
  for (yr in 2010:2026) {
    expect_true(
      as.character(yr) %in% col_names,
      info = paste("Should have year column:", yr)
    )
  }
})

test_that("Demographics file has expected row labels", {
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  df <- readxl::read_excel(demo_file, sheet = 1)
  labels <- df[[1]]

  expected_labels <- c("TOTAL", "GENDER-M", "GENDER-F", "GRADE-01",
                       "RACE7-WH7", "RACE7-HI7", "FRL", "ELL", "IEP")

  for (lbl in expected_labels) {
    expect_true(
      lbl %in% labels,
      info = paste("Demographics file should have row label:", lbl)
    )
  }
})

test_that("Demographics file has year columns", {
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")

  df <- readxl::read_excel(demo_file, sheet = 1)
  col_names <- names(df)

  # Should have year columns for 2012-2025 (demographics start at 2012)
  for (yr in 2012:2025) {
    expect_true(
      as.character(yr) %in% col_names,
      info = paste("Demographics file should have year column:", yr)
    )
  }
})

# ==============================================================================
# 5. YEAR FILTERING TESTS
# ==============================================================================

test_that("bundled_data_available returns TRUE for all supported years", {
  for (yr in get_available_years()) {
    expect_true(
      bundled_data_available(yr),
      info = paste("Bundled data should be available for year", yr)
    )
  }
})

test_that("load_bundled_enr returns data for each year", {
  skip_on_cran()

  for (yr in get_available_years()) {
    df <- load_bundled_enr(yr)

    expect_true(is.data.frame(df), info = paste("Year", yr, "should return data frame"))
    expect_true(nrow(df) > 0, info = paste("Year", yr, "should have data"))
    expect_true("type" %in% names(df), info = paste("Year", yr, "should have type column"))
    expect_true("row_total" %in% names(df), info = paste("Year", yr, "should have row_total"))
  }
})

test_that("get_raw_enr errors for unsupported year", {
  expect_error(rischooldata:::get_raw_enr(2005), "end_year must be")
  expect_error(rischooldata:::get_raw_enr(2030), "end_year must be")
})

# ==============================================================================
# 6. AGGREGATION TESTS
# ==============================================================================

test_that("State total equals sum of district totals for 2025", {
  skip_on_cran()

  df <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)

  state_total <- df$row_total[df$type == "State"][1]
  district_sum <- sum(df$row_total[df$type == "District"], na.rm = TRUE)

  expect_equal(state_total, district_sum,
               info = "State total should equal sum of district totals")
})

test_that("Gender totals equal state total for 2025", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  total <- state[state$subgroup == "total_enrollment", "n_students"]
  male <- state[state$subgroup == "male", "n_students"]
  female <- state[state$subgroup == "female", "n_students"]
  other <- state[state$subgroup == "gender_other", "n_students"]

  gender_sum <- male + female + ifelse(is.na(other), 0, other)

  expect_equal(total, gender_sum,
               info = "Gender sum should equal total enrollment")
})

test_that("Race categories sum to total enrollment for 2025", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  total <- state[state$subgroup == "total_enrollment", "n_students"]

  race_subgroups <- c("white", "black", "hispanic", "asian",
                      "native_american", "pacific_islander", "multiracial")
  race_sum <- sum(state[state$subgroup %in% race_subgroups, "n_students"], na.rm = TRUE)

  expect_equal(race_sum, total,
               info = "Race categories should sum to total enrollment")
})

test_that("fetch_enr state total matches bundled data directly", {
  skip_on_cran()

  # Get state total from package
  processed <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)
  package_total <- processed$row_total[processed$type == "State"][1]

  # Get state total directly from bundled file
  demo_file <- system.file("extdata", "oct1st-headcount-2010-2025-State-Demo.xlsx",
                           package = "rischooldata")
  demo_data <- readxl::read_excel(demo_file, sheet = 1)
  idx_total <- grep("^TOTAL$", demo_data[[1]])
  raw_total <- as.numeric(demo_data[["2025"]][idx_total[1]])

  expect_equal(package_total, raw_total,
               info = "Package state total should match raw bundled data")
})

# ==============================================================================
# 7. DATA QUALITY TESTS
# ==============================================================================

test_that("No Inf values in processed data", {
  skip_on_cran()

  data <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)

  numeric_cols <- names(data)[sapply(data, is.numeric)]
  for (col in numeric_cols) {
    expect_false(
      any(is.infinite(data[[col]]), na.rm = TRUE),
      info = paste("Column", col, "should not have Inf values")
    )
  }
})

test_that("No NaN values in processed data", {
  skip_on_cran()

  data <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)

  numeric_cols <- names(data)[sapply(data, is.numeric)]
  for (col in numeric_cols) {
    expect_false(
      any(is.nan(data[[col]]), na.rm = TRUE),
      info = paste("Column", col, "should not have NaN values")
    )
  }
})

test_that("All enrollment counts are non-negative", {
  skip_on_cran()

  data <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)

  expect_true(
    all(data$row_total >= 0, na.rm = TRUE),
    info = "row_total should be non-negative"
  )
})

test_that("State total is in reasonable range for all years", {
  skip_on_cran()

  for (yr in get_available_years()) {
    data <- fetch_enr(yr, tidy = FALSE, use_cache = FALSE)
    state_total <- data$row_total[data$type == "State"][1]

    # Rhode Island has ~130K-160K students
    expect_true(state_total > 130000,
                info = paste("Year", yr, "state total should be > 130k, got", state_total))
    expect_true(state_total < 160000,
                info = paste("Year", yr, "state total should be < 160k, got", state_total))
  }
})

test_that("Percentages in tidy output are in valid range", {
  skip_on_cran()

  data <- fetch_enr(2025, tidy = TRUE, use_cache = FALSE)

  if ("pct" %in% names(data)) {
    pct_values <- data$pct[!is.na(data$pct)]

    expect_true(
      all(pct_values >= 0, na.rm = TRUE),
      info = "Percentages should be >= 0"
    )

    expect_true(
      all(pct_values <= 1, na.rm = TRUE),
      info = "Percentages should be <= 1 (as decimal)"
    )
  }
})

test_that("District count is reasonable", {
  skip_on_cran()

  data <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)
  n_districts <- sum(data$type == "District", na.rm = TRUE)

  # Rhode Island has ~36 traditional districts + charters = 50-70 LEAs
  expect_true(n_districts >= 45, info = paste("Should have >= 45 districts, got", n_districts))
  expect_true(n_districts <= 80, info = paste("Should have <= 80 districts, got", n_districts))
})

# ==============================================================================
# 8. OUTPUT FIDELITY TESTS
# ==============================================================================

test_that("tidy=TRUE state total matches tidy=FALSE state total", {
  skip_on_cran()

  wide <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)
  tidy <- fetch_enr(2025, tidy = TRUE, use_cache = FALSE)

  wide_state <- wide$row_total[wide$type == "State"][1]
  tidy_state <- tidy$n_students[tidy$is_state &
                                 tidy$subgroup == "total_enrollment" &
                                 tidy$grade_level == "TOTAL"][1]

  expect_equal(wide_state, tidy_state,
               info = "State total should match between wide and tidy formats")
})

test_that("tidy output has required columns", {
  skip_on_cran()

  tidy <- fetch_enr(2025, tidy = TRUE, use_cache = FALSE)

  required_cols <- c("end_year", "type", "subgroup", "n_students",
                     "is_state", "is_district", "is_campus")

  for (col in required_cols) {
    expect_true(col %in% names(tidy),
                info = paste("Tidy output should have column:", col))
  }
})

test_that("tidy output contains expected subgroups", {
  skip_on_cran()

  tidy <- fetch_enr(2025, tidy = TRUE, use_cache = FALSE)
  subgroups <- unique(tidy$subgroup)

  expected_subgroups <- c("total_enrollment", "white", "black", "hispanic",
                          "male", "female", "lep", "special_ed")

  for (sg in expected_subgroups) {
    expect_true(sg %in% subgroups,
                info = paste("Should have subgroup:", sg))
  }
})

test_that("2025 demographic values match published RIDE data", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  get_val <- function(sg) state[state$subgroup == sg, "n_students"]

  # Values from RIDE October 1st headcount 2024-25
  expect_equal(get_val("total_enrollment"), 135978, info = "Total should be 135,978")
  expect_equal(get_val("white"), 68431, info = "White should be 68,431")
  expect_equal(get_val("hispanic"), 41785, info = "Hispanic should be 41,785")
  expect_equal(get_val("black"), 12818, info = "Black should be 12,818")
  expect_equal(get_val("asian"), 4391, info = "Asian should be 4,391")
  expect_equal(get_val("male"), 69805, info = "Male should be 69,805")
  expect_equal(get_val("female"), 65292, info = "Female should be 65,292")
  expect_equal(get_val("econ_disadv"), 73804, info = "FRL should be 73,804")
  expect_equal(get_val("lep"), 20352, info = "ELL should be 20,352")
  expect_equal(get_val("special_ed"), 25140, info = "IEP should be 25,140")
})

# ==============================================================================
# CROSS-YEAR CONSISTENCY TESTS
# ==============================================================================

test_that("State totals are consistent across recent years", {
  skip_on_cran()

  years <- 2022:2025
  totals <- sapply(years, function(yr) {
    data <- fetch_enr(yr, tidy = FALSE, use_cache = FALSE)
    data$row_total[data$type == "State"][1]
  })

  # Year-over-year change should be < 10%
  for (i in 2:length(totals)) {
    yoy_change <- abs(totals[i] / totals[i-1] - 1)
    expect_true(
      yoy_change < 0.10,
      info = paste("YoY change from", years[i-1], "to", years[i], "should be < 10%")
    )
  }
})

test_that("Number of districts is consistent across recent years", {
  skip_on_cran()

  years <- 2022:2025
  district_counts <- sapply(years, function(yr) {
    data <- fetch_enr(yr, tidy = FALSE, use_cache = FALSE)
    sum(data$type == "District", na.rm = TRUE)
  })

  # District count should be similar across years (within 15%)
  for (i in 2:length(district_counts)) {
    change <- abs(district_counts[i] / district_counts[i-1] - 1)
    expect_true(
      change < 0.15,
      info = paste("District count change from", years[i-1], "to", years[i], "should be < 15%")
    )
  }
})

# ==============================================================================
# SPECIFIC KNOWN VALUE TESTS
# ==============================================================================

test_that("Providence is largest district in 2025", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  districts <- enr[enr$type == "District" &
                   enr$subgroup == "total_enrollment" &
                   enr$grade_level == "TOTAL", c("district_name", "n_students")]

  largest <- districts$district_name[which.max(districts$n_students)]

  expect_true(grepl("Providence", largest, ignore.case = TRUE),
              info = paste("Providence should be largest, found:", largest))

  # Providence should have 20,000+ students
  pvd <- districts[districts$district_name == "Providence", "n_students"]
  expect_true(pvd > 19000,
              info = paste("Providence should have >19k students, got", pvd))
})

test_that("Known district enrollments match 2025 raw data", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  districts <- enr[enr$type == "District" &
                   enr$subgroup == "total_enrollment" &
                   enr$grade_level == "TOTAL", c("district_name", "n_students")]

  get_district <- function(name) {
    districts[districts$district_name == name, "n_students"]
  }

  # Values from oct1st-headcount-2010-2026.xlsx LEAs sheet, 2025 column
  expect_equal(get_district("Providence"), 20250, info = "Providence should match raw")
  expect_equal(get_district("Warwick"), 7853, info = "Warwick should match raw")
  expect_equal(get_district("Cranston"), 10037, info = "Cranston should match raw")
  expect_equal(get_district("Barrington"), 3294, info = "Barrington should match raw")
})
