# Alternative download method for RIDE enrollment data

Uses the eRIDE FRED (Frequently Requested Education Data) system as a
fallback when the Data Center is unavailable.

## Usage

``` r
download_ride_enrollment_alt(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Data frame or NULL if download fails
