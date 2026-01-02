## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.height = 5
)

# Check if we can fetch data from RIDE
# If not, skip all code chunks that require data
can_fetch_data <- tryCatch({
  # Try a quick fetch to see if RIDE is accessible
  test_data <- rischooldata::fetch_enr(2024, use_cache = TRUE)
  nrow(test_data) > 0 && "n_students" %in% names(test_data)
}, error = function(e) {
 FALSE
})

# Set eval option based on data availability
knitr::opts_chunk$set(eval = can_fetch_data)

## ----load-packages, eval=TRUE-------------------------------------------------
library(rischooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))

## ----data-unavailable, eval=!can_fetch_data, echo=FALSE, results='asis'-------
# cat("
# **Note:** This vignette requires live data from the Rhode Island Department of Education (RIDE) Data Center.
# The data source is currently unavailable. Please try again later or run this vignette locally with an active internet connection.
# 
# To fetch data manually:
# ```r
# library(rischooldata)
# enr <- fetch_enr(2024)

## ----statewide-trend----------------------------------------------------------
enr <- fetch_enr_multi(2011:2026)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals

## ----statewide-chart----------------------------------------------------------
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#003366") +
  geom_point(size = 3, color = "#003366") +

  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Rhode Island Public School Enrollment (2011-2026)",
    subtitle = "Steady decline has cost the state over 15,000 students",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )

## ----top-districts------------------------------------------------------------
enr_2026 <- fetch_enr(2026)

top_districts <- enr_2026 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

top_districts

## ----top-districts-chart------------------------------------------------------
top_districts |>
  mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
  ggplot(aes(x = n_students, y = district_name, fill = district_name)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3.5) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) +
  labs(
    title = "Top 10 Rhode Island Districts by Enrollment (2026)",
    subtitle = "Providence leads, followed by Warwick and Cranston",
    x = "Number of Students",
    y = NULL
  )

## ----covid-impact-------------------------------------------------------------
covid_enr <- fetch_enr_multi(2019:2026)

providence_trend <- covid_enr |>
  filter(district_name == "Providence", is_district,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - first(n_students))

providence_trend

## ----demographics-------------------------------------------------------------
demographics <- enr_2026 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics

## ----demographics-chart-------------------------------------------------------
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Rhode Island Student Demographics (2026)",
    subtitle = "An increasingly diverse student population",
    x = "Number of Students",
    y = NULL
  )

## ----central-falls------------------------------------------------------------
central_falls <- enr_2026 |>
  filter(grepl("Central Falls", district_name), is_district, grade_level == "TOTAL",
         subgroup %in% c("total_enrollment", "econ_disadv", "lep")) |>
  select(district_name, subgroup, n_students, pct) |>
  mutate(pct = round(pct * 100, 1))

central_falls

## ----ell----------------------------------------------------------------------
ell_districts <- enr_2026 |>
  filter(is_district, grade_level == "TOTAL", subgroup == "lep") |>
  filter(n_students >= 100) |>
  arrange(desc(pct)) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(district_name, n_students, pct) |>
  head(10)

ell_districts

## ----regional-chart-----------------------------------------------------------
ell_districts |>
  mutate(district_name = forcats::fct_reorder(district_name, pct)) |>
  ggplot(aes(x = pct, y = district_name, fill = pct)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  scale_fill_gradient(low = "#66B2FF", high = "#003366") +
  labs(
    title = "English Learners by District (2026)",
    subtitle = "Urban districts serve the vast majority of EL students",
    x = "Percent of Enrollment",
    y = NULL
  )

## ----charters-----------------------------------------------------------------
charters <- enr_2026 |>
  filter(is_charter, is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  summarize(
    n_charters = n(),
    total_students = sum(n_students, na.rm = TRUE)
  )

charters

## ----k-trend------------------------------------------------------------------
k_trend <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
  select(end_year, n_students) |>
  mutate(change = n_students - first(n_students))

k_trend

## ----growth-chart-------------------------------------------------------------
k_trend |>
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#E69F00") +
  geom_point(size = 3, color = "#E69F00") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Kindergarten Enrollment (2011-2026)",
    subtitle = "Recovering from COVID-era lows",
    x = "School Year",
    y = "Kindergarten Students"
  )

## ----majority-minority--------------------------------------------------------
race_trends <- enr |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic")) |>
  select(end_year, subgroup, pct) |>
  mutate(pct = round(pct * 100, 1)) |>
  pivot_wider(names_from = subgroup, values_from = pct)

race_trends

## ----district-sizes-----------------------------------------------------------
size_buckets <- enr_2026 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  mutate(size_bucket = case_when(
    n_students < 1000 ~ "Small (<1K)",
    n_students < 5000 ~ "Medium (1K-5K)",
    n_students < 10000 ~ "Large (5K-10K)",
    TRUE ~ "Very Large (10K+)"
  )) |>
  count(size_bucket) |>
  mutate(size_bucket = factor(size_bucket, levels = c("Small (<1K)", "Medium (1K-5K)", "Large (5K-10K)", "Very Large (10K+)")))

size_buckets

