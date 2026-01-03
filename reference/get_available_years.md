# Get available years for Rhode Island enrollment data

Returns the range of years available from RIDE. The RIDE Data Center
provides October 1st enrollment headcounts with data going back to
2010-11.

## Usage

``` r
get_available_years()
```

## Value

Integer vector of available end years

## Details

Data Eras:

- Era 1 (2011-2014): Historical data with potentially different format

- Era 2 (2015-present): Current RIDE Data Center format

## Examples

``` r
get_available_years()
#>  [1] 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
#> [16] 2026
```
