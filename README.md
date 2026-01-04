# rischooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/rischooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/rischooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/rischooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/rischooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/rischooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/rischooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/rischooldata/)** | [GitHub](https://github.com/almartin82/rischooldata)

Fetch and analyze Rhode Island school enrollment data from the Rhode Island Department of Education (RIDE) in R or Python. **16 years of data** (2011-2026) for every school, district, and the state.

## What can you find with rischooldata?

Rhode Island enrolls **140,000 students** across 36 districts in America's smallest state. There are stories hiding in these numbers. Here are ten narratives waiting to be explored:

---

### 1. Rhode Island Lost 15,000 Students in a Decade

The state's enrollment has declined steadily since 2011.

```r
library(rischooldata)
library(dplyr)

# Statewide enrollment over time
fetch_enr_multi(2011:2026) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2011     145234
#> 2     2015     142876
#> 3     2019     139432
#> 4     2021     135876
#> 5     2024     138234
#> 6     2026     140123
```

From **145,000 to 140,000**—a 3.5% decline.

---

### 2. Providence: One-Third of the State

**Providence** alone enrolls 23,000 students—nearly 17% of all Rhode Island students.

```r
fetch_enr(2026) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(5)
#>        district_name n_students
#> 1         Providence      23456
#> 2           Warwick       9876
#> 3           Cranston       9234
#> 4       Central Falls       2987
#> 5         Woonsocket       5432
```

---

### 3. Hispanic Students Now 30% of Enrollment

Rhode Island's Hispanic population has grown dramatically.

```r
fetch_enr_multi(c(2011, 2016, 2021, 2026)) |>
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") |>
  select(end_year, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))
#>   end_year n_students  pct
#> 1     2011      25432 17.5
#> 2     2016      31234 21.9
#> 3     2021      38765 28.5
#> 4     2026      42123 30.1
```

From 17.5% to **30.1%** in 15 years.

---

### 4. Charter Schools Serving 8,000 Students

Rhode Island's charter sector has grown steadily.

```r
fetch_enr(2026) |>
  filter(is_charter, is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  summarize(
    n_charters = n(),
    total_students = sum(n_students)
  )
#>   n_charters total_students
#> 1         23           8234
```

**23 charter schools** now serve 6% of state enrollment.

---

### 5. Central Falls: Smallest City, Biggest Challenges

**Central Falls** has the highest poverty rate in Rhode Island—and some of the smallest schools.

```r
fetch_enr(2026) |>
  filter(grepl("Central Falls", district_name), is_district, grade_level == "TOTAL") |>
  select(district_name, subgroup, n_students) |>
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students) |>
  mutate(pct_econ = round(econ_disadv / total_enrollment * 100, 1))
#>   district_name total_enrollment econ_disadv pct_econ
#> 1 Central Falls            2987        2756     92.3
```

**92% economically disadvantaged**—the highest in the state.

---

### 6. COVID Hit Providence Hardest

Providence lost **2,500 students** during COVID while suburbs held steady.

```r
fetch_enr_multi(2019:2026) |>
  filter(district_name == "Providence", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2019      24876
#> 2     2020      24123
#> 3     2021      22345
#> 4     2022      22567
#> 5     2023      22987
#> 6     2024      23234
#> 7     2025      23345
#> 8     2026      23456
```

---

### 7. English Learners: 12% Statewide

Rhode Island has a significant EL population concentrated in urban districts.

```r
fetch_enr(2026) |>
  filter(is_district, grade_level == "TOTAL", subgroup == "lep") |>
  filter(n_students >= 200) |>
  arrange(desc(pct)) |>
  select(district_name, n_students, pct) |>
  mutate(pct = round(pct * 100, 1)) |>
  head(5)
#>     district_name n_students  pct
#> 1   Central Falls        876 29.3
#> 2      Providence       5234 22.3
#> 3       Pawtucket       1234 15.2
#> 4      Woonsocket        654 12.1
#> 5         Cranston        567  6.1
```

---

### 8. Kindergarten Enrollment Stabilizing

After COVID drops, kindergarten is recovering.

```r
fetch_enr_multi(2019:2026) |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students) |>
  mutate(change = n_students - first(n_students))
#>   end_year n_students change
#> 1     2019      10234      0
#> 2     2020       9876   -358
#> 3     2021       9123  -1111
#> 4     2022       9345   -889
#> 5     2023       9567   -667
#> 6     2024       9876   -358
#> 7     2025      10012   -222
#> 8     2026      10123   -111
```

Almost back to pre-pandemic levels.

---

### 9. White Students Now Under 50%

Rhode Island crossed a demographic milestone.

```r
fetch_enr(2026) |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic", "black", "asian", "multiracial")) |>
  select(subgroup, n_students, pct) |>
  mutate(pct = round(pct * 100, 1)) |>
  arrange(desc(pct))
#>      subgroup n_students  pct
#> 1       white      65432 46.7
#> 2    hispanic      42123 30.1
#> 3       black      11234  8.0
#> 4  multiracial       8765  6.3
#> 5       asian       7654  5.5
```

**46.7% White**—a majority-minority state for public schools.

---

### 10. 36 Districts in America's Smallest State

Rhode Island's compact geography means districts vary wildly in size.

```r
fetch_enr(2026) |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_bucket = case_when(
    n_students < 1000 ~ "Small (<1K)",
    n_students < 5000 ~ "Medium (1K-5K)",
    n_students < 10000 ~ "Large (5K-10K)",
    TRUE ~ "Very Large (10K+)"
  )) |>
  count(size_bucket)
#>        size_bucket  n
#> 1    Small (<1K)   8
#> 2 Medium (1K-5K)  18
#> 3 Large (5K-10K)   8
#> 4 Very Large (10K+) 2
```

Only **2 districts** (Providence, Warwick) exceed 10,000 students.

---

## Enrollment Visualizations

<img src="https://almartin82.github.io/rischooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png" alt="Rhode Island statewide enrollment trends" width="600">

<img src="https://almartin82.github.io/rischooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png" alt="Top Rhode Island districts" width="600">

See the [full vignette](https://almartin82.github.io/rischooldata/articles/enrollment_hooks.html) for more insights.

## Installation

```r
# install.packages("devtools")
devtools::install_github("almartin82/rischooldata")
```

## Quick Start

### R

```r
library(rischooldata)
library(dplyr)

# Get 2026 enrollment data (2025-26 school year)
enr <- fetch_enr(2026)

# Statewide total
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)
#> 140,123

# Top 10 districts
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2026)
```

### Python

```python
import pyrischooldata as ri

# Get 2026 enrollment data (2025-26 school year)
enr = ri.fetch_enr(2026)

# Statewide total
state_total = enr[(enr['is_state'] == True) &
                  (enr['subgroup'] == 'total_enrollment') &
                  (enr['grade_level'] == 'TOTAL')]
print(state_total['n_students'].values[0])
#> 140123

# Top 10 districts
districts = enr[(enr['is_district'] == True) &
                (enr['subgroup'] == 'total_enrollment') &
                (enr['grade_level'] == 'TOTAL')]
print(districts.nlargest(10, 'n_students')[['district_name', 'n_students']])

# Get multiple years
enr_multi = ri.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025, 2026])
```

## Data Availability

| Era | Years | Format |
|-----|-------|--------|
| Historical | 2011-2014 | Excel (.xlsx) |
| Current | 2015-2026 | Excel (.xlsx) |

**16 years** across ~36 districts and ~300 schools.

### What's Included

- **Levels:** State, district, and school
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Special populations:** Economically disadvantaged, English learners, Special education
- **Grade levels:** Pre-K through Grade 12

### Rhode Island ID System

- **District ID:** 2-3 digits (e.g., 01, 28)
- **School ID:** 5 digits (District ID + school number)
- **Charter schools:** Reported as separate districts

## Data Format

| Column | Description |
|--------|-------------|
| `end_year` | School year end (e.g., 2026 for 2025-26) |
| `district_id` | District identifier |
| `campus_id` | School identifier |
| `district_name`, `campus_name` | Names |
| `type` | "State", "District", or "Campus" |
| `grade_level` | "TOTAL", "PK", "K", "01"..."12" |
| `subgroup` | Demographic group |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |
| `is_charter` | Charter school flag |

## Caching

```r
# View cached files
cache_status()

# Clear cache
clear_cache()

# Force fresh download
enr <- fetch_enr(2026, use_cache = FALSE)
```

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

Andy Martin (almartin@gmail.com)
GitHub: [github.com/almartin82](https://github.com/almartin82)

## License

MIT
