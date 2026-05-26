# =============================================================================
# Human Capital Decision Intelligence System
# 01_generate_synthetic_workforce_data.R
# Purpose: Generate first synthetic workforce dataset
# =============================================================================

# Load setup
source("R/00_setup.R")

set.seed(42)

# -----------------------------
# 1. Project settings
# -----------------------------

N_EMPLOYEES <- 1000

START_DATE <- as.Date("2018-01-01")
END_DATE   <- as.Date("2024-12-31")

departments <- c(
  "Data Analytics", "Engineering", "Finance", "HR", "Marketing",
  "Operations", "Product", "Sales", "Customer Success", "Legal"
)

job_families <- c(
  "Individual Contributor", "Manager", "Senior Manager",
  "Director", "VP"
)

locations <- c(
  "New York", "San Francisco", "Chicago", "Austin",
  "London", "Toronto", "Remote"
)

intervention_types <- c(
  "Training Program", "Promotion", "Compensation Adjustment",
  "Manager Change", "Flexible Work", "Career Development",
  "Retention Bonus", "Mentorship"
)

# -----------------------------
# 2. Helper function
# -----------------------------

bounded_normal <- function(n, mean, sd, min_value, max_value) {
  x <- rnorm(n, mean, sd)
  x <- pmax(x, min_value)
  x <- pmin(x, max_value)
  return(x)
}

# -----------------------------
# 3. Generate employee base data
# -----------------------------

workforce <- tibble(
  employee_id = paste0("EMP", stringr::str_pad(1:N_EMPLOYEES, 5, pad = "0")),
  
  age = round(bounded_normal(N_EMPLOYEES, 36, 9, 22, 65)),
  
  gender = sample(
    c("Male", "Female", "Non-binary", "Prefer not to say"),
    N_EMPLOYEES,
    replace = TRUE,
    prob = c(0.48, 0.46, 0.03, 0.03)
  ),
  
  race_ethnicity = sample(
    c("White", "Asian", "Black/African American", "Hispanic/Latino",
      "Two or more races", "Not disclosed"),
    N_EMPLOYEES,
    replace = TRUE,
    prob = c(0.48, 0.20, 0.12, 0.11, 0.05, 0.04)
  ),
  
  department = sample(departments, N_EMPLOYEES, replace = TRUE),
  
  job_family = sample(
    job_families,
    N_EMPLOYEES,
    replace = TRUE,
    prob = c(0.48, 0.25, 0.15, 0.08, 0.04)
  ),
  
  location = sample(locations, N_EMPLOYEES, replace = TRUE),
  
  hire_date = sample(
    seq(START_DATE, as.Date("2024-01-01"), by = "day"),
    N_EMPLOYEES,
    replace = TRUE
  ),
  
  remote_work_status = sample(
    c("Remote", "Hybrid", "On-site"),
    N_EMPLOYEES,
    replace = TRUE,
    prob = c(0.30, 0.45, 0.25)
  )
)

# -----------------------------
# 4. Add job level and tenure
# -----------------------------

workforce <- workforce %>%
  mutate(
    job_level = case_when(
      job_family == "Individual Contributor" ~ 1,
      job_family == "Manager" ~ 2,
      job_family == "Senior Manager" ~ 3,
      job_family == "Director" ~ 4,
      job_family == "VP" ~ 5
    ),
    
    tenure_years = as.numeric(END_DATE - hire_date) / 365.25,
    
    tenure_band = case_when(
      tenure_years < 1 ~ "< 1 year",
      tenure_years < 3 ~ "1–3 years",
      tenure_years < 5 ~ "3–5 years",
      TRUE ~ "5+ years"
    )
  )

# -----------------------------
# 5. Add salary and compa-ratio
# -----------------------------

workforce <- workforce %>%
  mutate(
    base_salary = case_when(
      job_level == 1 ~ 70000,
      job_level == 2 ~ 100000,
      job_level == 3 ~ 130000,
      job_level == 4 ~ 165000,
      job_level == 5 ~ 220000
    ),
    
    department_multiplier = case_when(
      department %in% c("Data Analytics", "Engineering", "Product") ~ 1.18,
      department %in% c("Finance", "Legal") ~ 1.10,
      department %in% c("Sales", "Marketing") ~ 1.05,
      TRUE ~ 1.00
    ),
    
    salary = round(
      base_salary *
        department_multiplier *
        bounded_normal(N_EMPLOYEES, 1, 0.12, 0.75, 1.35),
      -2
    ),
    
    market_salary = base_salary * department_multiplier,
    
    compa_ratio = salary / market_salary
  )

# -----------------------------
# 6. Add performance, engagement, and work signals
# -----------------------------

workforce <- workforce %>%
  mutate(
    performance_rating = round(bounded_normal(N_EMPLOYEES, 3.3, 0.8, 1, 5)),
    engagement_score = round(bounded_normal(N_EMPLOYEES, 68, 16, 20, 100)),
    manager_rating = round(bounded_normal(N_EMPLOYEES, 3.4, 0.7, 1, 5), 1),
    collaboration_score = round(bounded_normal(N_EMPLOYEES, 3.5, 0.7, 1, 5), 1),
    customer_orientation_score = round(bounded_normal(N_EMPLOYEES, 3.4, 0.8, 1, 5), 1),
    
    training_hours = round(bounded_normal(N_EMPLOYEES, 28, 16, 0, 120)),
    overtime = round(bounded_normal(N_EMPLOYEES, 10, 9, 0, 55), 1),
    absenteeism_days = round(bounded_normal(N_EMPLOYEES, 4, 4, 0, 25)),
    
    promotion_last_3_years = sample(
      c(0, 1, 2),
      N_EMPLOYEES,
      replace = TRUE,
      prob = c(0.62, 0.30, 0.08)
    ),
    
    time_since_promotion = round(bounded_normal(N_EMPLOYEES, 26, 18, 1, 72))
  )

# -----------------------------
# 7. Add interventions
# -----------------------------

workforce <- workforce %>%
  mutate(
    intervention_received = sample(
      c(TRUE, FALSE),
      N_EMPLOYEES,
      replace = TRUE,
      prob = c(0.35, 0.65)
    ),
    
    intervention_type = ifelse(
      intervention_received,
      sample(intervention_types, N_EMPLOYEES, replace = TRUE),
      NA
    )
  )

# -----------------------------
# 8. Create attrition probability
# -----------------------------

workforce <- workforce %>%
  mutate(
    attrition_logit =
      -2.2 +
      0.80 * (engagement_score < 50) +
      0.70 * (compa_ratio < 0.90) +
      0.60 * (time_since_promotion > 36) +
      0.45 * (overtime > 25) +
      0.45 * (manager_rating < 3) +
      0.40 * (tenure_years < 2) -
      0.50 * intervention_received -
      0.30 * (performance_rating >= 4),
    
    attrition_probability = 1 / (1 + exp(-attrition_logit)),
    
    attrition = rbinom(N_EMPLOYEES, 1, attrition_probability)
  )

# -----------------------------
# 9. Add attrition dates and survival fields
# -----------------------------

workforce <- workforce %>%
  rowwise() %>%
  mutate(
    max_possible_days = as.numeric(END_DATE - hire_date),
    
    exit_days = ifelse(
      attrition == 1,
      sample(90:max(90, max_possible_days), 1),
      NA
    ),
    
    attrition_date = ifelse(
      attrition == 1,
      hire_date + exit_days,
      as.Date(NA)
    ),
    
    attrition_date = as.Date(attrition_date, origin = "1970-01-01"),
    
    event_time_days = ifelse(
      attrition == 1,
      as.numeric(attrition_date - hire_date),
      as.numeric(END_DATE - hire_date)
    ),
    
    censored = ifelse(attrition == 0, 1, 0)
  ) %>%
  ungroup() %>%
  select(-max_possible_days, -exit_days)

# -----------------------------
# 10. Add survey comments for NLP later
# -----------------------------

survey_topics <- c(
  "Compensation feels below market and career growth is unclear.",
  "Manager support is strong and the team culture is positive.",
  "Workload is high and burnout risk is increasing.",
  "I want clearer promotion paths and more development opportunities.",
  "Flexible work options help improve work-life balance.",
  "The tools and systems need improvement.",
  "I feel recognized and valued by my team."
)

workforce <- workforce %>%
  mutate(
    survey_period = sample(
      c("2023-Q1", "2023-Q2", "2023-Q3", "2023-Q4", "2024-Q1", "2024-Q2"),
      N_EMPLOYEES,
      replace = TRUE
    ),
    
    survey_comment = sample(survey_topics, N_EMPLOYEES, replace = TRUE)
  )

# -----------------------------
# 11. Feature engineering
# -----------------------------

workforce <- workforce %>%
  mutate(
    performance_engagement_gap = performance_rating - (engagement_score / 20),
    
    manager_support_index = (manager_rating + collaboration_score) / 2,
    
    promotion_velocity = promotion_last_3_years / pmax(tenure_years, 0.5),
    
    career_stall_risk = ifelse(
      time_since_promotion > 36 &
        tenure_years > 3 &
        performance_rating >= 3,
      1,
      0
    ),
    
    burnout_risk_score = pmin(
      (overtime / 55 * 0.40) +
        (absenteeism_days / 25 * 0.25) +
        ((100 - engagement_score) / 100 * 0.35),
      1
    ),
    
    flight_risk_score = pmin(
      0.25 * (engagement_score < 50) +
        0.20 * (compa_ratio < 0.90) +
        0.20 * (time_since_promotion > 36) +
        0.15 * (overtime > 25) +
        0.10 * (manager_rating < 3) +
        0.10 * career_stall_risk,
      1
    ),
    
    retention_priority_score = flight_risk_score * (performance_rating / 5),
    
    replacement_cost_estimate = salary * case_when(
      job_level == 1 ~ 0.50,
      job_level == 2 ~ 0.75,
      job_level == 3 ~ 1.00,
      job_level == 4 ~ 1.50,
      job_level == 5 ~ 2.00
    ),
    
    business_criticality_score = case_when(
      department %in% c("Data Analytics", "Engineering", "Product") ~ 0.90,
      department %in% c("Finance", "Sales") ~ 0.75,
      TRUE ~ 0.60
    ),
    
    recommended_action = case_when(
      retention_priority_score >= 0.50 ~ "Immediate retention intervention",
      flight_risk_score >= 0.50 ~ "Monitor closely",
      career_stall_risk == 1 ~ "Career development plan",
      compa_ratio < 0.90 ~ "Compensation review",
      burnout_risk_score >= 0.60 ~ "Manager support intervention",
      TRUE ~ "No immediate action"
    )
  )

# -----------------------------
# 12. Save files
# -----------------------------

write_csv(workforce, "data/raw/synthetic_workforce.csv")
saveRDS(workforce, "data/processed/synthetic_workforce.rds")

# -----------------------------
# 13. Quick checks
# -----------------------------

message("Synthetic workforce dataset created successfully.")

message("Number of employees: ", nrow(workforce))
message("Attrition rate: ", round(mean(workforce$attrition) * 100, 1), "%")
message("Average engagement score: ", round(mean(workforce$engagement_score), 1))
message("Average salary: $", round(mean(workforce$salary), 0))

glimpse(workforce)

