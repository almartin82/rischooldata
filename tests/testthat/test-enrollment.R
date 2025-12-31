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
  expect_true(max(years) >= 2025)
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
