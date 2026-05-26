# =============================================================================
# Human Capital Decision Intelligence System
# 00_setup.R
# Purpose: Basic project setup
# =============================================================================

packages_needed <- c(
  "tidyverse",
  "lubridate",
  "janitor",
  "here",
  "skimr",
  "plotly",
  "reactable",
  "DT",
  "htmlwidgets"
)

installed_packages <- rownames(installed.packages())

packages_to_install <- packages_needed[!packages_needed %in% installed_packages]

if (length(packages_to_install) > 0) {
  install.packages(packages_to_install, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(janitor)
  library(here)
  library(skimr)
  library(plotly)
  library(reactable)
  library(DT)
  library(htmlwidgets)
})

set.seed(42)

options(scipen = 999)
options(digits = 4)

theme_set(theme_minimal(base_size = 13))

hcdis_colors <- list(
  navy = "#1E3A5F",
  blue = "#2D7DD2",
  green = "#059669",
  amber = "#D97706",
  red = "#DC2626",
  gray = "#6B7280"
)

message("HCDIS setup complete. RStudio is ready.")
