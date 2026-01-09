# rischooldata

**[Documentation](https://almartin82.github.io/rischooldata/)** \|
[GitHub](https://github.com/almartin82/rischooldata)

Fetch and analyze Rhode Island school enrollment data from the Rhode
Island Department of Education (RIDE) in R or Python. **16 years of
data** (2011-2026) for every school, district, and the state.

## What can you find with rischooldata?

Rhode Island enrolls **134,000 students** across districts in America’s
smallest state. Explore enrollment trends across 16 years of data
(2011-2026).

See the [enrollment
vignette](https://almartin82.github.io/rischooldata/articles/enrollment_hooks.html)
for detailed analysis of:

- Statewide enrollment trends
- District comparisons and rankings
- Demographic shifts over time
- Urban vs suburban enrollment patterns
- COVID-19 impact analysis

------------------------------------------------------------------------

## Enrollment Visualizations

![Rhode Island statewide enrollment
trends](https://almartin82.github.io/rischooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

![Top Rhode Island
districts](https://almartin82.github.io/rischooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

See the [full
vignette](https://almartin82.github.io/rischooldata/articles/enrollment_hooks.html)
for more insights.

## Installation

``` r
# install.packages("devtools")
devtools::install_github("almartin82/rischooldata")
```

## Quick Start

### R

``` r
library(rischooldata)
library(dplyr)

# Fetch 2025 enrollment data (2024-25 school year)
enr_2025 <- fetch_enr(2025)

# See the structure
glimpse(enr_2025)
```

**State total:**

``` r
enr_2025 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(n_students)
```

**Top 10 districts:**

``` r
enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)
```

### Python

``` python
import pyrischooldata as ri

# Get 2025 enrollment data (2024-25 school year)
enr = ri.fetch_enr(2025)

# Statewide total
state_total = enr[(enr['is_state'] == True) &
                  (enr['subgroup'] == 'total_enrollment') &
                  (enr['grade_level'] == 'TOTAL')]
print(state_total['n_students'].values[0])
#> 135978

# Top 10 districts
districts = enr[(enr['is_district'] == True) &
                (enr['subgroup'] == 'total_enrollment') &
                (enr['grade_level'] == 'TOTAL')]
print(districts.nlargest(10, 'n_students')[['district_name', 'n_students']])

# Get multiple years
enr_multi = ri.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])
```

## Data Availability

| Era        | Years     | Format        |
|------------|-----------|---------------|
| Historical | 2011-2014 | Excel (.xlsx) |
| Current    | 2015-2026 | Excel (.xlsx) |

**16 years** across 64 districts and 307 schools.

### What’s Included

- **Levels:** State, district, and school
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Special populations:** Economically disadvantaged, English learners,
  Special education
- **Grade levels:** Pre-K through Grade 12

### Rhode Island ID System

- **District ID:** 2-3 digits (e.g., 01, 28)
- **School ID:** 5 digits (District ID + school number)
- **Charter schools:** Reported as separate districts

## Data Format

| Column                         | Description                              |
|--------------------------------|------------------------------------------|
| `end_year`                     | School year end (e.g., 2026 for 2025-26) |
| `district_id`                  | District identifier                      |
| `campus_id`                    | School identifier                        |
| `district_name`, `campus_name` | Names                                    |
| `type`                         | “State”, “District”, or “Campus”         |
| `grade_level`                  | “TOTAL”, “PK”, “K”, “01”…“12”            |
| `subgroup`                     | Demographic group                        |
| `n_students`                   | Enrollment count                         |
| `pct`                          | Percentage of total                      |
| `is_charter`                   | Charter school flag                      |

## Caching

``` r
# View cached files
cache_status()

# Clear cache
clear_cache()

# Force fresh download
enr <- fetch_enr(2025, use_cache = FALSE)
```

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (<almartin@gmail.com>) GitHub:
[github.com/almartin82](https://github.com/almartin82)

## License

MIT
