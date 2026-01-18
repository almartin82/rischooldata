# Getting Started with rischooldata

This vignette provides a quick introduction to the `rischooldata`
package for accessing Rhode Island public school enrollment data.

## Installation

``` r
# Install from GitHub
remotes::install_github("your-repo/rischooldata")
```

## Basic Usage

The main function is
[`fetch_enr()`](https://almartin82.github.io/rischooldata/reference/fetch_enr.md)
which downloads and processes enrollment data for a specific school
year:

``` r
library(rischooldata)
library(dplyr)

# Fetch 2025 enrollment data (2024-25 school year)
enr_2025 <- fetch_enr(2025)

# See the structure
glimpse(enr_2025)
#> Rows: 402
#> Columns: 16
#> $ end_year         <int> 2025, 2025, 2025, 2025, 2025, 2025, 2025, 2025, 2025,…
#> $ type             <chr> "State", "District", "District", "District", "Distric…
#> $ district_id      <chr> "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA",…
#> $ campus_id        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ district_name    <chr> NA, "Achievement First Rhode Island", "Barrington", "…
#> $ campus_name      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ charter_flag     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ grade_level      <chr> "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL", "TOTAL",…
#> $ subgroup         <chr> "total_enrollment", "total_enrollment", "total_enroll…
#> $ n_students       <dbl> 135978, 3209, 3294, 363, 357, 2253, 2693, 1993, 2560,…
#> $ pct              <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ aggregation_flag <chr> "district", "district", "district", "district", "dist…
#> $ is_state         <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ is_district      <lgl> FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE…
#> $ is_campus        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ is_charter       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
```

## Understanding the Data

### Year Convention

The `end_year` parameter uses the END year of the school year: -
`end_year = 2025` means the **2024-25** school year - `end_year = 2011`
means the **2010-11** school year

### Data Levels

The package provides three levels of data, indicated by the `type`
column:

| Type     | Description                        |
|----------|------------------------------------|
| State    | Statewide totals                   |
| District | LEA (Local Education Agency) level |
| Campus   | Individual school level            |

Boolean flags make filtering easy:

``` r
# State total
enr_2025 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(n_students)
#>   n_students
#> 1     135978

# All districts
enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(5) |>
  select(district_name, n_students)
#>   district_name n_students
#> 1    Providence      20250
#> 2      Cranston      10037
#> 3       Warwick       7853
#> 4     Pawtucket       7816
#> 5    Woonsocket       5541
```

### Subgroups

The data includes 17 subgroups covering demographics and special
populations:

``` r
unique(enr_2025$subgroup)
#>  [1] "total_enrollment" "white"            "black"            "hispanic"        
#>  [5] "asian"            "native_american"  "pacific_islander" "multiracial"     
#>  [9] "male"             "female"           "gender_other"     "special_ed"      
#> [13] "lep"              "econ_disadv"      "immigrant"        "homeless"        
#> [17] "title1"
```

| Category            | Subgroups                                                                                   |
|---------------------|---------------------------------------------------------------------------------------------|
| Total               | `total_enrollment`                                                                          |
| Race/Ethnicity      | `white`, `black`, `hispanic`, `asian`, `native_american`, `pacific_islander`, `multiracial` |
| Gender              | `male`, `female`, `gender_other`                                                            |
| Special Populations | `econ_disadv` (FRL), `lep` (ELL), `special_ed` (IEP), `immigrant`, `homeless`, `title1`     |

### Grade Levels

Individual grade levels are available:

``` r
# Get kindergarten enrollment
enr_2025 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(n_students)
#>   n_students
#> 1       8960

# Grade breakdown for state
enr_2025 |>
  filter(is_state, subgroup == "total_enrollment", !grade_level %in% c("TOTAL")) |>
  select(grade_level, n_students) |>
  arrange(grade_level)
#>    grade_level n_students
#> 1           01       9578
#> 2           02       9690
#> 3           03      10196
#> 4           04       9787
#> 5           05      10044
#> 6           06       9936
#> 7           07      10084
#> 8           08      10211
#> 9           09      10795
#> 10          10      10883
#> 11          11      10982
#> 12          12      11396
#> 13           K       8960
#> 14          PK       2292
```

## Multiple Years

Use
[`fetch_enr_multi()`](https://almartin82.github.io/rischooldata/reference/fetch_enr_multi.md)
to get data for multiple years:

``` r
# Get 5 years of data
multi_year <- fetch_enr_multi(2021:2025)

# Track state enrollment over time
multi_year |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  arrange(end_year)
#>   end_year n_students
#> 1     2021     139184
#> 2     2022     138566
#> 3     2023     137449
#> 4     2024     136154
#> 5     2025     135978
```

## Available Years

Check what years are available:

``` r
get_available_years()
#>  [1] 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
#> [16] 2026
```

Data is available from **2011** (2010-11 school year) through **2026**
(2025-26 school year).

Note: State demographic data (race, gender, special populations) is
available for 2012-2025. For 2011 and 2026, only district/school totals
are available.

## Wide Format

For analysis requiring a wide format, use `tidy = FALSE`:

``` r
wide_data <- fetch_enr(2025, tidy = FALSE)
names(wide_data)
#>  [1] "end_year"         "type"             "district_id"      "campus_id"       
#>  [5] "district_name"    "campus_name"      "charter_flag"     "row_total"       
#>  [9] "white"            "black"            "hispanic"         "asian"           
#> [13] "native_american"  "pacific_islander" "multiracial"      "male"            
#> [17] "female"           "gender_other"     "econ_disadv"      "lep"             
#> [21] "special_ed"       "immigrant"        "homeless"         "title1"          
#> [25] "grade_pk"         "grade_k"          "grade_01"         "grade_02"        
#> [29] "grade_03"         "grade_04"         "grade_05"         "grade_06"        
#> [33] "grade_07"         "grade_08"         "grade_09"         "grade_10"        
#> [37] "grade_11"         "grade_12"
```

## Caching

The package caches downloaded data locally to speed up repeated
requests:

``` r
# Check cache status
cache_status()

# Clear cache if needed
clear_cache()

# Force fresh download (ignore cache)
fresh_data <- fetch_enr(2025, use_cache = FALSE)
```

## Example: Demographic Analysis

``` r
# Get 2025 demographics at state level
state_demos <- enr_2025 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) |>
  select(subgroup, n_students, pct) |>
  mutate(pct = round(pct * 100, 1)) |>
  arrange(desc(n_students))

state_demos
#>      subgroup n_students  pct
#> 1       white      68431 50.3
#> 2    hispanic      41785 30.7
#> 3       black      12818  9.4
#> 4 multiracial       7273  5.3
#> 5       asian       4391  3.2
```

## Example: District Comparison

``` r
# Compare top districts
top_districts <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

top_districts
#>       district_name n_students
#> 1        Providence      20250
#> 2          Cranston      10037
#> 3           Warwick       7853
#> 4         Pawtucket       7816
#> 5        Woonsocket       5541
#> 6   East Providence       5225
#> 7        Cumberland       4881
#> 8          Coventry       4056
#> 9   North Kingstown       3786
#> 10 North Providence       3488
```

## Data Source

All data comes from the Rhode Island Department of Education (RIDE) Data
Center, specifically the October 1st Public School Student Headcounts
reports.

- Website: [datacenter.ride.ri.gov](https://datacenter.ride.ri.gov)
- Data updated annually in October/November

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] dplyr_1.1.4        rischooldata_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.0       cli_3.6.5         knitr_1.51        rlang_1.1.7      
#>  [5] xfun_0.55         purrr_1.2.1       generics_0.1.4    textshaping_1.0.4
#>  [9] jsonlite_2.0.0    glue_1.8.0        htmltools_0.5.9   ragg_1.5.0       
#> [13] sass_0.4.10       readxl_1.4.5      rappdirs_0.3.4    rmarkdown_2.30   
#> [17] cellranger_1.1.0  tibble_3.3.1      evaluate_1.0.5    jquerylib_0.1.4  
#> [21] fastmap_1.2.0     yaml_2.3.12       lifecycle_1.0.5   compiler_4.5.2   
#> [25] codetools_0.2-20  fs_1.6.6          pkgconfig_2.0.3   systemfonts_1.3.1
#> [29] digest_0.6.39     R6_2.6.1          tidyselect_1.2.1  pillar_1.11.1    
#> [33] magrittr_2.0.4    bslib_0.9.0       withr_3.0.2       tools_4.5.2      
#> [37] pkgdown_2.2.0     cachem_1.1.0      desc_1.4.3
```
