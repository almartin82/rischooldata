# Get school year ID for RIDE Data Center

Maps end_year to the schoolyearid parameter used by RIDE Data Center.
Based on observed patterns: schoolyearid=11 corresponds to 2010-11,
schoolyearid=19 corresponds to 2018-19, etc.

## Usage

``` r
get_schoolyear_id(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Integer schoolyearid for RIDE Data Center
