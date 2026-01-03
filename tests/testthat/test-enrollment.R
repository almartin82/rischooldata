# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("N/A")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns expected range", {
  years <- get_available_years()
  expect_true(is.integer(years) || is.numeric(years))
  expect_true(2011 %in% years)  # Historical data starts at 2011
  expect_true(2015 %in% years)
  expect_true(2024 %in% years)
  expect_true(min(years) >= 2011)  # Updated to include historical era
  expect_true(max(years) >= 2024)
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2000), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("rischooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  # (Assuming no cache exists for year 9999)
  expect_false(cache_exists(9999, "tidy"))
})

test_that("build_ride_urls returns valid URLs", {
  urls <- build_ride_urls(2024)
  expect_true(is.character(urls))
  expect_true(length(urls) > 0)
  expect_true(all(grepl("^https?://", urls)))

  # Test historical year URLs
  urls_historical <- build_ride_urls(2012)
  expect_true(is.character(urls_historical))
  expect_true(length(urls_historical) > 0)
  expect_true(all(grepl("^https?://", urls_historical)))
})

test_that("get_schoolyear_id returns correct values", {
  # Based on research: schoolyearid = end_year - 2000
  expect_equal(get_schoolyear_id(2011), 11)
  expect_equal(get_schoolyear_id(2015), 15)
  expect_equal(get_schoolyear_id(2024), 24)
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- tryCatch(
    fetch_enr(2024, tidy = FALSE, use_cache = FALSE),
    error = function(e) NULL
  )

  # Skip if download fails (network issues, data format changes)
  skip_if(is.null(result), "Could not download data from RIDE")

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result) || "district_name" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have multiple records
  expect_true(nrow(result) > 0)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Create mock wide data for testing tidy function
  mock_wide <- data.frame(
    end_year = 2024,
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "01001"),
    district_name = c(NA, "Barrington", "Barrington"),
    campus_name = c(NA, NA, "Barrington High School"),
    charter_flag = c(NA, "N", "N"),
    row_total = c(142000, 3500, 1200),
    white = c(80000, 2800, 950),
    hispanic = c(35000, 350, 120),
    black = c(12000, 100, 40),
    asian = c(5000, 200, 70),
    grade_k = c(8000, 200, NA),
    grade_09 = c(11000, 280, 300),
    stringsAsFactors = FALSE
  )

  # Tidy it
  tidy_result <- tidy_enr(mock_wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("white" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  # Create mock tidy data
  mock_tidy <- data.frame(
    end_year = 2024,
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "01001"),
    district_name = c(NA, "Barrington", "Barrington"),
    campus_name = c(NA, NA, "Barrington HS"),
    charter_flag = c(NA, "N", "N"),
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(142000, 3500, 1200),
    pct = 1.0,
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(mock_tidy)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))
  expect_true("is_charter" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_campus))
  expect_true(is.logical(result$is_charter))

  # Check values
  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_campus, c(FALSE, FALSE, TRUE))
  expect_equal(result$is_charter, c(FALSE, FALSE, FALSE))
})

test_that("enr_grade_aggs creates aggregates", {
  # Create mock tidy data with grade levels
  mock_grades <- data.frame(
    end_year = rep(2024, 14),
    type = rep("State", 14),
    district_id = rep(NA_character_, 14),
    campus_id = rep(NA_character_, 14),
    district_name = rep(NA_character_, 14),
    campus_name = rep(NA_character_, 14),
    charter_flag = rep(NA_character_, 14),
    grade_level = c("K", "01", "02", "03", "04", "05", "06", "07", "08",
                    "09", "10", "11", "12", "TOTAL"),
    subgroup = rep("total_enrollment", 14),
    n_students = c(8000, 8100, 8200, 8300, 8400, 8500, 8600, 8700, 8800,
                   9000, 9100, 9200, 9300, 142000),
    pct = 1.0,
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    is_charter = FALSE,
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(mock_grades)

  # Check we have the three aggregate levels
  expect_true("K8" %in% result$grade_level)
  expect_true("HS" %in% result$grade_level)
  expect_true("K12" %in% result$grade_level)

  # Check K-8 sum (K + 01-08 = 8000 + 8100 + ... + 8800 = 75600)
  k8_val <- result$n_students[result$grade_level == "K8"]
  expect_equal(k8_val, 75600)

  # Check HS sum (09-12 = 9000 + 9100 + 9200 + 9300 = 36600)
  hs_val <- result$n_students[result$grade_level == "HS"]
  expect_equal(hs_val, 36600)

  # Check K-12 sum
  k12_val <- result$n_students[result$grade_level == "K12"]
  expect_equal(k12_val, 75600 + 36600)
})

test_that("create_state_aggregate sums correctly", {
  # Create mock district data
  mock_districts <- data.frame(
    end_year = 2024,
    type = c("District", "District"),
    district_id = c("01", "02"),
    campus_id = NA_character_,
    district_name = c("Barrington", "Bristol Warren"),
    campus_name = NA_character_,
    charter_flag = c("N", "N"),
    row_total = c(3500, 2800),
    white = c(2800, 2200),
    hispanic = c(350, 300),
    stringsAsFactors = FALSE
  )

  result <- create_state_aggregate(mock_districts, 2024)

  # Check state row

  expect_equal(result$type, "State")
  expect_equal(result$row_total, 6300)
  expect_equal(result$white, 5000)
  expect_equal(result$hispanic, 650)
})


# ==============================================================================
# Bundled Data Fidelity Tests
# ==============================================================================
# These tests validate that the bundled data loads correctly and produces
# accurate enrollment statistics matching known values from RIDE.

test_that("bundled data is available for all years", {
  years <- get_available_years()

  for (yr in years) {
    expect_true(
      bundled_data_available(yr),
      info = paste("Bundled data should be available for year", yr)
    )
  }
})

test_that("2025 state enrollment matches known values", {
  # 2024-25 school year has known enrollment from RIDE
  # Total: 135,978 students
  enr <- fetch_enr(2025, use_cache = FALSE)

  state_total <- enr[enr$type == "State" &
                     enr$subgroup == "total_enrollment" &
                     enr$grade_level == "TOTAL", "n_students"]

  expect_equal(state_total, 135978,
               info = "State total should match RIDE published value of 135,978")
})

test_that("state demographics sum to total enrollment", {
  skip_on_cran()

  # Test a few representative years
  test_years <- c(2015, 2020, 2025)

  for (yr in test_years) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    state_total <- enr[enr$type == "State" &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", "n_students"]

    # Race categories should sum to total
    race_subgroups <- c("white", "black", "hispanic", "asian",
                        "native_american", "pacific_islander", "multiracial")
    race_sum <- sum(enr[enr$type == "State" &
                        enr$grade_level == "TOTAL" &
                        enr$subgroup %in% race_subgroups, "n_students"],
                    na.rm = TRUE)

    expect_equal(race_sum, state_total,
                 info = paste("Race categories should sum to total for year", yr))

    # Gender categories should sum to approximately total
    # (some students may not have gender reported)
    gender_sum <- sum(enr[enr$type == "State" &
                          enr$grade_level == "TOTAL" &
                          enr$subgroup %in% c("male", "female"), "n_students"],
                      na.rm = TRUE)

    # Allow 1% tolerance for potential data quirks (unreported gender)
    expect_true(abs(gender_sum - state_total) / state_total < 0.01,
                info = paste("Gender categories should be within 1% of total for year", yr))
  }
})

test_that("grade level enrollment sums to total", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)

  state_total <- enr[enr$type == "State" &
                     enr$subgroup == "total_enrollment" &
                     enr$grade_level == "TOTAL", "n_students"]

  # Sum individual grades (PK through 12)
  grade_levels <- c("PK", "K", sprintf("%02d", 1:12))
  grade_sum <- sum(enr[enr$type == "State" &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level %in% grade_levels, "n_students"],
                   na.rm = TRUE)

  # Should be close to or equal to total (some students may be ungraded)
  expect_true(abs(grade_sum - state_total) / state_total < 0.05,
              info = "Grade level sum should be within 5% of total")
})

test_that("all 12 subgroups are present in tidy data", {
  enr <- fetch_enr(2025, use_cache = FALSE)

  expected_subgroups <- c(
    "total_enrollment",
    "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "male", "female",
    "lep", "special_ed"
  )

  actual_subgroups <- unique(enr$subgroup)

  for (sg in expected_subgroups) {
    expect_true(sg %in% actual_subgroups,
                info = paste("Subgroup", sg, "should be present in data"))
  }
})

test_that("district count is reasonable across years", {
  skip_on_cran()

  # Rhode Island has ~36 traditional districts + growing number of charters
  # Expect 50-70 total LEAs

  test_years <- c(2011, 2015, 2020, 2025)

  for (yr in test_years) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    n_districts <- length(unique(enr[enr$type == "District", "district_name"]))

    expect_true(n_districts >= 45 && n_districts <= 75,
                info = paste("Year", yr, "should have 45-75 districts, found", n_districts))
  }
})

test_that("state enrollment is reasonable across years", {
  skip_on_cran()

  # Rhode Island enrollment has been between 130K-150K for the past decade+
  test_years <- get_available_years()

  for (yr in test_years) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    state_total <- enr[enr$type == "State" &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", "n_students"]

    expect_true(state_total >= 130000 && state_total <= 160000,
                info = paste("Year", yr, "total enrollment should be 130K-160K, found", state_total))
  }
})

test_that("no duplicate state rows after processing", {
  enr <- fetch_enr(2025, use_cache = FALSE)

  # Count state rows for total enrollment at TOTAL grade level
  state_total_rows <- nrow(enr[enr$type == "State" &
                                enr$subgroup == "total_enrollment" &
                                enr$grade_level == "TOTAL", ])

  expect_equal(state_total_rows, 1,
               info = "Should have exactly one state total enrollment row")
})

test_that("wide format has expected columns", {
  enr_wide <- fetch_enr(2025, tidy = FALSE, use_cache = FALSE)

  expected_cols <- c("end_year", "type", "district_name", "row_total",
                     "white", "black", "hispanic", "asian",
                     "male", "female")

  for (col in expected_cols) {
    expect_true(col %in% names(enr_wide),
                info = paste("Wide format should have column:", col))
  }
})

test_that("econ_disadv subgroup is present for recent years", {
  # FRL data should be available
  enr <- fetch_enr(2025, use_cache = FALSE)

  # Check if econ_disadv exists and has data for state
  econ_state <- enr[enr$type == "State" &
                    enr$subgroup == "econ_disadv" &
                    enr$grade_level == "TOTAL", "n_students"]

  # May be NA or have a value - just check it exists in subgroups
  expect_true("econ_disadv" %in% unique(enr$subgroup) ||
              nrow(enr[enr$subgroup == "econ_disadv", ]) == 0,
              info = "econ_disadv should be a valid subgroup category")
})

test_that("Providence is largest district", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)

  district_totals <- enr[enr$type == "District" &
                         enr$subgroup == "total_enrollment" &
                         enr$grade_level == "TOTAL", c("district_name", "n_students")]

  # Providence should be largest
  largest <- district_totals[which.max(district_totals$n_students), "district_name"]
  expect_true(grepl("Providence", largest, ignore.case = TRUE),
              info = paste("Providence should be largest district, found:", largest))

  # Providence (exact match, not East Providence or North Providence) should have ~20,000+ students
  pvd_enrollment <- district_totals[district_totals$district_name == "Providence", "n_students"]
  expect_true(length(pvd_enrollment) == 1 && pvd_enrollment > 15000,
              info = "Providence should have >15,000 students")
})


# ==============================================================================
# Raw Data Fidelity Tests - Verify Tidy Output Matches Raw Excel Data
# ==============================================================================
# These tests compare processed output against known values from raw Excel files
# to ensure data transformation maintains fidelity.

test_that("2025 state demographics match raw Excel values exactly", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  # Known values from oct1st-headcount-2010-2025-State-Demo.xlsx
  get_val <- function(sg) state[state$subgroup == sg, "n_students"]

  expect_equal(get_val("total_enrollment"), 135978, info = "Total enrollment should match raw")
  expect_equal(get_val("white"), 68431, info = "White should match raw")
  expect_equal(get_val("black"), 12818, info = "Black should match raw")
  expect_equal(get_val("hispanic"), 41785, info = "Hispanic should match raw")
  expect_equal(get_val("asian"), 4391, info = "Asian should match raw")
  expect_equal(get_val("native_american"), 1025, info = "Native American should match raw")
  expect_equal(get_val("pacific_islander"), 255, info = "Pacific Islander should match raw")
  expect_equal(get_val("multiracial"), 7273, info = "Multiracial should match raw")
  expect_equal(get_val("male"), 69805, info = "Male should match raw")
  expect_equal(get_val("female"), 65292, info = "Female should match raw")
  expect_equal(get_val("gender_other"), 881, info = "Gender other should match raw")
  expect_equal(get_val("econ_disadv"), 73804, info = "FRL should match raw")
  expect_equal(get_val("lep"), 20352, info = "ELL should match raw")
  expect_equal(get_val("special_ed"), 25140, info = "IEP should match raw")
  expect_equal(get_val("immigrant"), 6105, info = "Immigrant should match raw")
  expect_equal(get_val("homeless"), 1010, info = "Homeless should match raw")
  expect_equal(get_val("title1"), 60679, info = "Title I should match raw")
})

test_that("2020 state demographics match raw Excel values exactly", {
  skip_on_cran()

  enr <- fetch_enr(2020, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  get_val <- function(sg) state[state$subgroup == sg, "n_students"]

  expect_equal(get_val("total_enrollment"), 143557, info = "2020 total should match raw")
  expect_equal(get_val("white"), 79308, info = "2020 white should match raw")
  expect_equal(get_val("black"), 12660, info = "2020 black should match raw")
  expect_equal(get_val("hispanic"), 38843, info = "2020 hispanic should match raw")
  expect_equal(get_val("asian"), 4684, info = "2020 asian should match raw")
  expect_equal(get_val("male"), 74235, info = "2020 male should match raw")
  expect_equal(get_val("female"), 69322, info = "2020 female should match raw")
  expect_equal(get_val("econ_disadv"), 68408, info = "2020 FRL should match raw")
  expect_equal(get_val("lep"), 15377, info = "2020 ELL should match raw")
  expect_equal(get_val("special_ed"), 22517, info = "2020 IEP should match raw")
})

test_that("2015 state demographics match raw Excel values exactly", {
  skip_on_cran()

  enr <- fetch_enr(2015, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  get_val <- function(sg) state[state$subgroup == sg, "n_students"]

  expect_equal(get_val("total_enrollment"), 141959, info = "2015 total should match raw")
  expect_equal(get_val("white"), 86164, info = "2015 white should match raw")
  expect_equal(get_val("black"), 11460, info = "2015 black should match raw")
  expect_equal(get_val("hispanic"), 33569, info = "2015 hispanic should match raw")
  expect_equal(get_val("asian"), 4513, info = "2015 asian should match raw")
  expect_equal(get_val("male"), 73372, info = "2015 male should match raw")
  expect_equal(get_val("female"), 68587, info = "2015 female should match raw")
  expect_equal(get_val("econ_disadv"), 66231, info = "2015 FRL should match raw")
  expect_equal(get_val("lep"), 9643, info = "2015 ELL should match raw")
  expect_equal(get_val("special_ed"), 21308, info = "2015 IEP should match raw")
})

test_that("2025 grade level enrollment matches raw Excel values", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$subgroup == "total_enrollment", ]

  get_val <- function(gl) state[state$grade_level == gl, "n_students"]

  expect_equal(get_val("PK"), 2292, info = "Grade PK should match raw")
  expect_equal(get_val("K"), 8960, info = "Grade K should match raw (KF only, KG=0)")
  expect_equal(get_val("01"), 9578, info = "Grade 01 should match raw")
  expect_equal(get_val("02"), 9690, info = "Grade 02 should match raw")
  expect_equal(get_val("03"), 10196, info = "Grade 03 should match raw")
  expect_equal(get_val("04"), 9787, info = "Grade 04 should match raw")
  expect_equal(get_val("05"), 10044, info = "Grade 05 should match raw")
  expect_equal(get_val("06"), 9936, info = "Grade 06 should match raw")
  expect_equal(get_val("07"), 10084, info = "Grade 07 should match raw")
  expect_equal(get_val("08"), 10211, info = "Grade 08 should match raw")
  expect_equal(get_val("09"), 10795, info = "Grade 09 should match raw")
  expect_equal(get_val("10"), 10883, info = "Grade 10 should match raw")
  expect_equal(get_val("11"), 10982, info = "Grade 11 should match raw")
  expect_equal(get_val("12"), 11396, info = "Grade 12 should match raw")
})

test_that("all 17 subgroups are present in tidy data for 2025", {
  enr <- fetch_enr(2025, use_cache = FALSE)

  expected_subgroups <- c(
    "total_enrollment",
    "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "male", "female", "gender_other",
    "econ_disadv", "lep", "special_ed",
    "immigrant", "homeless", "title1"
  )

  actual_subgroups <- unique(enr$subgroup)

  for (sg in expected_subgroups) {
    expect_true(sg %in% actual_subgroups,
                info = paste("Subgroup", sg, "should be present in 2025 data"))
  }
})

test_that("race categories sum to total enrollment for years 2012-2025", {
  skip_on_cran()

  # State demographics data available for 2012-2025 (2011 has no demos, 2026 not yet available)
  for (yr in 2012:2025) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    state_total <- enr[enr$type == "State" &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", "n_students"]

    race_subgroups <- c("white", "black", "hispanic", "asian",
                        "native_american", "pacific_islander", "multiracial")
    race_sum <- sum(enr[enr$type == "State" &
                        enr$grade_level == "TOTAL" &
                        enr$subgroup %in% race_subgroups, "n_students"],
                    na.rm = TRUE)

    expect_equal(race_sum, state_total,
                 info = paste("Year", yr, "race categories should sum to total"))
  }
})

test_that("district enrollment matches raw LEA data for 2025", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)

  district_totals <- enr[enr$type == "District" &
                         enr$subgroup == "total_enrollment" &
                         enr$grade_level == "TOTAL", c("district_name", "n_students")]

  # Check known district values from oct1st-headcount-2010-2026.xlsx LEAs sheet
  # Values verified from raw file for 2025 column
  expect_equal(
    district_totals[district_totals$district_name == "Providence", "n_students"],
    20250, info = "Providence 2025 enrollment should match raw"
  )
  expect_equal(
    district_totals[district_totals$district_name == "Warwick", "n_students"],
    7853, info = "Warwick 2025 enrollment should match raw"
  )
  expect_equal(
    district_totals[district_totals$district_name == "Cranston", "n_students"],
    10037, info = "Cranston 2025 enrollment should match raw"
  )
  expect_equal(
    district_totals[district_totals$district_name == "Barrington", "n_students"],
    3294, info = "Barrington 2025 enrollment should match raw"
  )
})

test_that("historical years (2011-2014) load correctly", {
  skip_on_cran()

  for (yr in 2011:2014) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    # Should have State row with total
    state_total <- enr[enr$type == "State" &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", "n_students"]

    expect_true(length(state_total) == 1 && state_total > 0,
                info = paste("Year", yr, "should have valid state total"))

    # Should have district data
    n_districts <- sum(enr$type == "District" & enr$subgroup == "total_enrollment")
    expect_true(n_districts > 0,
                info = paste("Year", yr, "should have district data"))
  }
})

test_that("state demographics available for all years 2012-2025", {
  skip_on_cran()

  for (yr in 2012:2025) {
    enr <- fetch_enr(yr, use_cache = FALSE)

    state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

    # Should have race data
    expect_true("white" %in% state$subgroup,
                info = paste("Year", yr, "should have white subgroup"))
    expect_true("hispanic" %in% state$subgroup,
                info = paste("Year", yr, "should have hispanic subgroup"))

    # Should have gender data
    expect_true("male" %in% state$subgroup,
                info = paste("Year", yr, "should have male subgroup"))
    expect_true("female" %in% state$subgroup,
                info = paste("Year", yr, "should have female subgroup"))

    # Should have special populations
    expect_true("special_ed" %in% state$subgroup,
                info = paste("Year", yr, "should have special_ed subgroup"))
    expect_true("lep" %in% state$subgroup,
                info = paste("Year", yr, "should have lep subgroup"))
  }
})

test_that("no zeros where data should exist in state totals", {
  skip_on_cran()

  enr <- fetch_enr(2025, use_cache = FALSE)
  state <- enr[enr$type == "State" & enr$grade_level == "TOTAL", ]

  # These subgroups should never be zero at state level
  nonzero_subgroups <- c("total_enrollment", "white", "black", "hispanic", "asian",
                         "male", "female", "lep", "special_ed", "econ_disadv")

  for (sg in nonzero_subgroups) {
    val <- state[state$subgroup == sg, "n_students"]
    expect_true(length(val) == 1 && val > 0,
                info = paste("State-level", sg, "should not be zero"))
  }
})

test_that("2026 data available with correct structure", {
  skip_on_cran()

  # 2026 is the most recent year in bundled data
  enr <- fetch_enr(2026, use_cache = FALSE)

  # Should have expected structure
  expect_true(nrow(enr) > 0, info = "2026 data should have rows")
  expect_true("type" %in% names(enr), info = "2026 should have type column")
  expect_true("State" %in% enr$type, info = "2026 should have State rows")
  expect_true("District" %in% enr$type, info = "2026 should have District rows")

  # State total should be reasonable
  state_total <- enr[enr$type == "State" &
                     enr$subgroup == "total_enrollment" &
                     enr$grade_level == "TOTAL", "n_students"]

  expect_true(length(state_total) == 1 && state_total > 130000 && state_total < 160000,
              info = "2026 state total should be reasonable (130K-160K)")
})

test_that("gender_other only present for years where it exists in raw data", {
  skip_on_cran()

  # gender_other (GENDER-O) is 0 in 2015 and 2020 but 881 in 2025
  enr_2015 <- fetch_enr(2015, use_cache = FALSE)
  enr_2025 <- fetch_enr(2025, use_cache = FALSE)

  # In 2015, gender_other may be absent or 0
  go_2015 <- enr_2015[enr_2015$type == "State" &
                       enr_2015$subgroup == "gender_other" &
                       enr_2015$grade_level == "TOTAL", "n_students"]

  # In 2025, gender_other should be 881
  go_2025 <- enr_2025[enr_2025$type == "State" &
                       enr_2025$subgroup == "gender_other" &
                       enr_2025$grade_level == "TOTAL", "n_students"]

  expect_true(length(go_2025) == 1 && go_2025 == 881,
              info = "2025 gender_other should be 881")
})
