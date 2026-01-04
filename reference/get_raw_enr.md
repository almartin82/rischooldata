# Download raw enrollment data from RIDE

Downloads enrollment data from RIDE's Data Center. Uses the October 1st
Public School Student Headcounts reports.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

## Value

Data frame with raw enrollment data

## Details

NOTE: As of late 2024, the RIDE Data Center requires JavaScript-based
downloads that cannot be accessed programmatically. This function now
primarily uses bundled data files, with network download as a fallback.
