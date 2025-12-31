# rischooldata

An R package for fetching, processing, and analyzing school enrollment data from Rhode Island's Department of Education (RIDE).

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("almartin82/rischooldata")
```
## Quick Start

```r
library(rischooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View state totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)
```

## Data Availability

### Overview

| Item | Value |
|------|-------|
| **State Agency** | Rhode Island Department of Education (RIDE) |
| **Primary Data Portal** | [RIDE Data Center](https://datacenter.ride.ri.gov/) |
| **Data System Name** | October 1st Public School Student Headcounts |
| **Data Collection Date** | October 1st of each school year |

### Available Years

- **Earliest available year**: 2015 (2014-15 school year)
- **Most recent available year**: 2026 (2025-26 school year)
- **Total years of data**: 12 years

### Format Eras

| Era | Years | File Format | Key Differences |
|-----|-------|-------------|-----------------|
| RIDE Data Center | 2015-present | Excel (.xlsx) | Consistent format with school/district/state breakdowns |

### What's Available

**Aggregation Levels:**
- State-level totals
- District-level (LEA) data
- School-level (campus) data

**Demographics:**
- Race/Ethnicity: White, Black/African American, Hispanic/Latino, Asian, Native American/Alaska Native, Pacific Islander, Multiracial
- Gender: Male, Female
- Special populations: Economically Disadvantaged (Free/Reduced Lunch), English Learners (EL/LEP), Students with Disabilities (IEP/Special Ed)

**Grade Levels:**
- Pre-K through Grade 12

### What's NOT Available

- Pre-2015 data (historical data before RIDE Data Center was established)
- Private school enrollment
- Homeschool enrollment
- Detailed breakdown by specific disability categories
- Teacher/staff data (separate data source)

### Known Caveats

1. **Small cell suppression**: Values less than 5 or 10 students may be suppressed for privacy
2. **Charter schools**: Reported as separate districts in Rhode Island
3. **October 1st snapshot**: Enrollment represents a single point in time, not average daily membership
4. **Dual enrollment**: Students may be counted in multiple schools/programs

## Rhode Island Identifier System

| Identifier | Format | Example | Notes |
|------------|--------|---------|-------|
| District ID | 2-3 digits | 01, 28 | Unique LEA identifier |
| School ID | 5 digits | 01001 | District ID + school number |

**Special Cases:**
- Rhode Island has approximately 36 traditional school districts
- Charter schools are treated as their own LEAs (districts)
- State-operated schools (e.g., Davies Career & Technical) have unique codes

## Standard Output Schema

### Wide Format (`tidy = FALSE`)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24 school year) |
| district_id | character | District identifier |
| campus_id | character | School identifier (NA for district rows) |
| district_name | character | District name |
| campus_name | character | School name (NA for district rows) |
| type | character | "State", "District", or "Campus" |
| charter_flag | character | "Y" for charter schools |
| row_total | integer | Total enrollment |
| white | integer | White student count |
| black | integer | Black/African American student count |
| hispanic | integer | Hispanic/Latino student count |
| asian | integer | Asian student count |
| native_american | integer | American Indian/Alaska Native count |
| pacific_islander | integer | Native Hawaiian/Pacific Islander count |
| multiracial | integer | Two or more races count |
| male | integer | Male student count |
| female | integer | Female student count |
| econ_disadv | integer | Economically disadvantaged count |
| lep | integer | English Learner count |
| special_ed | integer | Special education count |
| grade_pk through grade_12 | integer | Grade-level enrollment |

### Tidy Format (`tidy = TRUE`, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| district_id | character | District identifier |
| campus_id | character | School identifier |
| district_name | character | District name |
| campus_name | character | School name |
| type | character | Aggregation level |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | "total_enrollment", "white", "black", etc. |
| n_students | integer | Student count |
| pct | numeric | Percentage of total (0-1 scale) |
| is_state | logical | TRUE for state-level rows |
| is_district | logical | TRUE for district-level rows |
| is_campus | logical | TRUE for school-level rows |
| is_charter | logical | TRUE for charter schools |

## Examples

### View enrollment trends

```r
library(rischooldata)
library(dplyr)
library(ggplot2)

# Get multi-year data
enr <- fetch_enr_multi(2015:2024)

# State enrollment over time
state_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line() +
  geom_point() +
  labs(title = "Rhode Island Public School Enrollment",
       x = "School Year End",
       y = "Total Students") +
  scale_y_continuous(labels = scales::comma)
```

### District comparison

```r
# Largest districts
largest_districts <- fetch_enr(2024) %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)

print(largest_districts)
```

### Demographic breakdown

```r
# State demographics
demographics <- fetch_enr(2024) %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic", "black", "asian", "multiracial")) %>%
  select(subgroup, n_students, pct)

print(demographics)
```

## Caching

Downloaded data is cached locally to avoid repeated downloads:

```r
# View cache status
cache_status()

# Clear cache for specific year
clear_cache(2024)

# Clear all cached data
clear_cache()

# Bypass cache and force fresh download
enr <- fetch_enr(2024, use_cache = FALSE)
```

## Data Sources

- **RIDE Data Center**: https://datacenter.ride.ri.gov/
- **RIDE Education Data**: https://ride.ri.gov/information-accountability/ri-education-data
- **FRED (Frequently Requested Education Data)**: https://www.ride.ri.gov/InformationAccountability/RIEducationData/FrequentlyRequestedEducationData(FRED).aspx

## License

MIT
