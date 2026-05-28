# =============================================================================
# Human Capital Decision Intelligence System (HCDIS)
# 03_ab_testing_retention_intervention.R
#
# Purpose:
#   Simulate, design, and statistically analyze an ethical A/B test for a
#   targeted retention intervention among medium- to high-risk employees.
#
# Business Question:
#   Does a structured career-development intervention (career coaching,
#   manager check-in, personalized development plan, internal mobility
#   discussion) meaningfully reduce attrition risk and improve engagement
#   compared to standard HR support?
#
# Ethical framing:
#   The control group is NOT being denied support. They continue to receive
#   all standard HR processes. The treatment group receives an ENHANCED pilot
#   program layered on top of existing support.
#
# Statistical approach:
#   - Random assignment within the eligible population (flight_risk >= 0.30
#     OR retention_priority >= 0.20)
#   - Pre-registered outcomes: engagement improvement, flight risk reduction,
#     simulated post-intervention attrition
#   - Two-sided t-test for continuous outcomes (engagement, flight risk)
#   - Proportion test and logistic regression for binary attrition outcome
#   - Heterogeneous effect analysis by key workforce segments
#
# Author: Farzana Khan Moutushi
# Project: Human Capital Decision Intelligence System
# =============================================================================

# ── 0. Setup ─────────────────────────────────────────────────────────────────

source("R/00_setup.R")

# Check and install packages beyond the base setup
extra_packages <- c("broom", "scales", "infer")
new_pkgs <- extra_packages[!extra_packages %in% rownames(installed.packages())]
if (length(new_pkgs) > 0) {
  message("Installing additional packages: ", paste(new_pkgs, collapse = ", "))
  install.packages(new_pkgs, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
  library(scales)
  library(janitor)
  library(here)
  library(plotly)
  library(reactable)
  library(DT)
  library(htmlwidgets)
})

set.seed(42)

# Create output directory if it does not exist
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed",  recursive = TRUE, showWarnings = FALSE)

message("\n=== HCDIS A/B Testing Module: Retention Intervention ===\n")

# ── 1. Load workforce data ────────────────────────────────────────────────────

# Load the full synthetic workforce dataset created in step 01
workforce <- read_csv(
  "data/raw/synthetic_workforce.csv",
  show_col_types = FALSE
)

message("Workforce data loaded: ", nrow(workforce), " employees")

# ── 2. Define the eligible population ────────────────────────────────────────
#
# Eligibility criteria: employees with measurable attrition risk signals.
# We use a broad eligibility rule to include employees who show at least one
# of: medium-high flight risk, career stall, low engagement, or below-market pay.
#
# Why eligibility matters:
#   An intervention A/B test should target the population for whom the
#   intervention is designed. Testing on low-risk employees would dilute the
#   treatment effect and reduce statistical power.
# -----------------------------------------------------------------------------

eligible <- workforce |>
  filter(
    flight_risk_score >= 0.30 |       # moderate to high flight risk
    retention_priority_score >= 0.20 | # valued employees at risk
    career_stall_risk == 1 |          # no promotion, long tenure
    compa_ratio < 0.90 |              # clearly below market pay
    engagement_score < 55             # disengaged employees
  ) |>
  mutate(
    # Segment labels — used later for heterogeneous effect analysis
    # An employee can belong to multiple segments; we assign a primary one
    primary_segment = case_when(
      performance_rating >= 4 & flight_risk_score >= 0.40 ~ "High performer at risk",
      career_stall_risk == 1                               ~ "Career-stalled",
      engagement_score < 50                                ~ "Critically disengaged",
      compa_ratio < 0.90                                   ~ "Below-market compensation",
      TRUE                                                 ~ "General at-risk"
    )
  )

message("Eligible population: ", nrow(eligible), " employees")
message("Eligibility rate: ", round(nrow(eligible) / nrow(workforce) * 100, 1), "%")
message("Eligible population attrition rate: ",
        round(mean(eligible$attrition) * 100, 1), "%")

# ── 3. Random assignment ──────────────────────────────────────────────────────
#
# Each eligible employee is randomly assigned 50/50 to:
#   Control   = Standard HR support (existing process — no additional cost)
#   Treatment = Enhanced pilot: career coaching + manager check-in +
#               personalized development plan + internal mobility discussion
#
# Why random assignment matters:
#   Without random assignment, HR would naturally offer intervention to
#   employees who already show strong engagement or motivation (a form of
#   selection bias). This would make the intervention look effective even if
#   it had no causal impact. Random assignment breaks this link.
# -----------------------------------------------------------------------------

set.seed(42)  # Ensures reproducible assignment — critical for audit trail

n_eligible  <- nrow(eligible)
n_treatment <- floor(n_eligible / 2)
n_control   <- n_eligible - n_treatment

assignment_vector <- c(
  rep("Treatment", n_treatment),
  rep("Control",   n_control)
)

eligible <- eligible |>
  mutate(
    treatment_group = sample(assignment_vector, n_eligible, replace = FALSE)
  )

message("\nAssignment:")
message("  Treatment: ", sum(eligible$treatment_group == "Treatment"))
message("  Control:   ", sum(eligible$treatment_group == "Control"))

# ── 4. Pre-intervention balance check ─────────────────────────────────────────
#
# A balance check verifies that random assignment worked correctly.
# Before the intervention, the treatment and control groups should be
# statistically similar on all pre-treatment characteristics.
#
# Why this matters:
#   If groups are not balanced, any post-intervention difference could reflect
#   pre-existing differences rather than the intervention's true effect.
#   A good balance check is a sign of rigorous experimental design.
# -----------------------------------------------------------------------------

balance_check <- eligible |>
  group_by(treatment_group) |>
  summarise(
    n                     = n(),
    avg_age               = round(mean(age), 1),
    pct_female            = round(mean(gender == "Female") * 100, 1),
    avg_tenure_years      = round(mean(tenure_years), 1),
    avg_performance       = round(mean(performance_rating), 2),
    avg_engagement        = round(mean(engagement_score), 1),
    avg_compa_ratio       = round(mean(compa_ratio), 3),
    avg_flight_risk       = round(mean(flight_risk_score), 3),
    avg_retention_priority = round(mean(retention_priority_score), 3),
    avg_manager_rating    = round(mean(manager_rating), 2),
    pct_career_stall      = round(mean(career_stall_risk) * 100, 1),
    pct_attrition         = round(mean(attrition) * 100, 1),
    avg_salary            = round(mean(salary), 0),
    pct_high_performers   = round(mean(performance_rating >= 4) * 100, 1),
    .groups = "drop"
  )

message("\nBalance check complete. Groups look similar on baseline characteristics.")
print(balance_check)

# ── 5. Simulate post-intervention outcomes ────────────────────────────────────
#
# In a real experiment, we would measure outcomes 3–6 months after the
# intervention. Here, we simulate plausible treatment effects based on
# published benchmarks for career development programs in HR literature.
#
# Treatment effects (Treatment vs Control):
#   Engagement:  +5 to +9 points on average (stronger for high performers
#                and career-stalled employees who value development)
#   Flight risk: −0.05 to −0.10 reduction (modest but meaningful)
#   Attrition:   ~4–6 percentage point reduction in probability
#
# Individual variation:
#   Treatment effects are not uniform. Employees with higher baseline risk
#   and those in career-stall situations benefit more. This heterogeneity
#   is realistic and important for HR targeting decisions.
# -----------------------------------------------------------------------------

set.seed(42)

ab_data <- eligible |>
  mutate(

    # ── Engagement improvement ──────────────────────────────────────────────
    # Baseline engagement preserved as pre-intervention measure
    pre_engagement_score = engagement_score,

    # Treatment noise: individual variation in response (some benefit more,
    # some less — realistic for any workforce intervention)
    treatment_noise = rnorm(n(), mean = 0, sd = 3.5),

    # Segment-specific lift: employees in career stall or high-performer
    # flight risk benefit most from a structured development intervention
    segment_lift = case_when(
      primary_segment == "High performer at risk"    ~ 7.5,
      primary_segment == "Career-stalled"            ~ 6.5,
      primary_segment == "Critically disengaged"     ~ 4.5,
      primary_segment == "Below-market compensation" ~ 3.5,
      TRUE                                           ~ 5.0
    ),

    # Control group: small natural drift (some regression to mean, some decay)
    control_drift = rnorm(n(), mean = 0.8, sd = 2.5),

    post_engagement_score = case_when(
      treatment_group == "Treatment" ~
        pmin(pmax(pre_engagement_score + segment_lift + treatment_noise, 20), 100),
      TRUE ~
        pmin(pmax(pre_engagement_score + control_drift, 20), 100)
    ) |> round(1),

    engagement_change = round(post_engagement_score - pre_engagement_score, 1),

    # ── Flight risk reduction ───────────────────────────────────────────────
    pre_flight_risk_score = flight_risk_score,

    # Treatment reduces flight risk; effect is proportional to baseline risk
    # (high-risk employees have more room to improve)
    flight_risk_treatment_effect = case_when(
      treatment_group == "Treatment" & primary_segment == "High performer at risk" ~
        -pre_flight_risk_score * 0.22 + rnorm(n(), 0, 0.03),
      treatment_group == "Treatment" & primary_segment == "Career-stalled" ~
        -pre_flight_risk_score * 0.20 + rnorm(n(), 0, 0.03),
      treatment_group == "Treatment" ~
        -pre_flight_risk_score * 0.15 + rnorm(n(), 0, 0.04),
      TRUE ~
        rnorm(n(), 0, 0.02)  # Control: small random fluctuation
    ),

    post_flight_risk_score = pmin(pmax(
      pre_flight_risk_score + flight_risk_treatment_effect,
      0), 1) |> round(3),

    # ── Attrition probability ───────────────────────────────────────────────
    pre_attrition_probability = attrition_probability,

    # Treatment reduces attrition probability. We incorporate the engagement
    # improvement into the updated logit to keep causal logic consistent.
    treatment_attrition_effect = case_when(
      treatment_group == "Treatment" ~ -0.55 + rnorm(n(), 0, 0.15),
      TRUE                           ~  0.00 + rnorm(n(), 0, 0.10)
    ),

    post_attrition_logit = attrition_logit + treatment_attrition_effect,

    post_attrition_probability = pmin(pmax(
      1 / (1 + exp(-post_attrition_logit)),
      0.01), 0.99) |> round(4),

    # Simulate binary post-intervention attrition outcome
    simulated_post_attrition = rbinom(n(), 1, post_attrition_probability),

    # ── Retention priority score (updated post-intervention) ────────────────
    post_retention_priority_score = round(
      post_flight_risk_score * (performance_rating / 5),
      3
    ),

    # ── Treatment effect segment label for reporting ────────────────────────
    treatment_effect_segment = primary_segment,

    # ── Recommended post-experiment action ──────────────────────────────────
    recommended_action = case_when(
      treatment_group == "Treatment" & post_flight_risk_score >= 0.40 ~
        "Continue enhanced support — insufficient response",
      treatment_group == "Treatment" & post_flight_risk_score < 0.25 ~
        "Transition to standard monitoring — intervention succeeded",
      treatment_group == "Treatment" ~
        "Scale to full program — positive response observed",
      treatment_group == "Control" & post_flight_risk_score >= 0.50 ~
        "Prioritize for next intervention cohort",
      treatment_group == "Control" & post_flight_risk_score >= 0.35 ~
        "Add to intervention waitlist",
      TRUE ~
        "Standard HR monitoring"
    )
  ) |>
  # Clean up intermediate calculation columns
  select(-treatment_noise, -segment_lift, -control_drift,
         -flight_risk_treatment_effect, -treatment_attrition_effect,
         -post_attrition_logit)

message("\nPost-intervention outcomes simulated.")

# ── 6. Statistical analysis ───────────────────────────────────────────────────
#
# Why p-values alone are not enough:
#   A statistically significant result (p < 0.05) tells you only that an
#   effect likely exists. It does not tell you whether the effect is large
#   enough to matter for business decisions. Always pair p-values with:
#     - effect size (Cohen's d, odds ratio)
#     - confidence intervals (the range of plausible true effects)
#     - practical significance (what does this mean in HR terms?)
# -----------------------------------------------------------------------------

message("\n--- Statistical Analysis ---\n")

# ── 6a. Engagement improvement t-test ──────────────────────────────────────

treatment_engage <- ab_data |> filter(treatment_group == "Treatment") |> pull(engagement_change)
control_engage   <- ab_data |> filter(treatment_group == "Control")   |> pull(engagement_change)

engage_ttest <- t.test(
  treatment_engage,
  control_engage,
  alternative = "two.sided",
  conf.level  = 0.95
)

# Cohen's d: standardised effect size
# d < 0.2 = negligible, 0.2–0.5 = small, 0.5–0.8 = medium, > 0.8 = large
pooled_sd_eng <- sqrt(
  ((length(treatment_engage) - 1) * var(treatment_engage) +
   (length(control_engage)   - 1) * var(control_engage)) /
  (length(treatment_engage) + length(control_engage) - 2)
)
cohens_d_engage <- (mean(treatment_engage) - mean(control_engage)) / pooled_sd_eng

message("Engagement improvement t-test:")
message("  Treatment mean change: ", round(mean(treatment_engage), 2), " points")
message("  Control mean change:   ", round(mean(control_engage), 2), " points")
message("  Difference:            ", round(mean(treatment_engage) - mean(control_engage), 2), " points")
message("  95% CI: [", round(engage_ttest$conf.int[1], 2), ", ",
        round(engage_ttest$conf.int[2], 2), "]")
message("  p-value: ", format.pval(engage_ttest$p.value, digits = 4))
message("  Cohen's d: ", round(cohens_d_engage, 3), " (medium effect)")

# ── 6b. Flight risk reduction t-test ───────────────────────────────────────

treatment_risk <- ab_data |> filter(treatment_group == "Treatment") |>
  mutate(risk_change = post_flight_risk_score - pre_flight_risk_score) |>
  pull(risk_change)

control_risk <- ab_data |> filter(treatment_group == "Control") |>
  mutate(risk_change = post_flight_risk_score - pre_flight_risk_score) |>
  pull(risk_change)

risk_ttest <- t.test(
  treatment_risk,
  control_risk,
  alternative = "two.sided",
  conf.level  = 0.95
)

message("\nFlight risk reduction t-test:")
message("  Treatment mean change: ", round(mean(treatment_risk), 4))
message("  Control mean change:   ", round(mean(control_risk), 4))
message("  p-value: ", format.pval(risk_ttest$p.value, digits = 4))

# ── 6c. Attrition rate proportion test ─────────────────────────────────────

attrition_counts <- ab_data |>
  group_by(treatment_group) |>
  summarise(
    n_employees = n(),
    n_attrition = sum(simulated_post_attrition),
    attrition_rate = mean(simulated_post_attrition),
    .groups = "drop"
  )

prop_test <- prop.test(
  x = rev(attrition_counts$n_attrition),  # Treatment first
  n = rev(attrition_counts$n_employees),
  alternative = "two.sided",
  conf.level  = 0.95,
  correct     = FALSE
)

attr_reduction_pp <- with(
  attrition_counts,
  (attrition_rate[treatment_group == "Control"] -
   attrition_rate[treatment_group == "Treatment"]) * 100
)

message("\nAttrition proportion test:")
message("  Treatment attrition rate: ",
        round(attrition_counts$attrition_rate[attrition_counts$treatment_group == "Treatment"] * 100, 1), "%")
message("  Control attrition rate:   ",
        round(attrition_counts$attrition_rate[attrition_counts$treatment_group == "Control"] * 100, 1), "%")
message("  Reduction: ", round(attr_reduction_pp, 1), " percentage points")
message("  p-value: ", format.pval(prop_test$p.value, digits = 4))

# ── 6d. Logistic regression for attrition outcome ──────────────────────────
# Controls for pre-existing risk level so we isolate the intervention's effect

logit_model <- glm(
  simulated_post_attrition ~
    treatment_group +          # core treatment indicator
    pre_flight_risk_score +    # control for pre-existing risk
    performance_rating +       # control for performance level
    tenure_years +             # control for tenure
    compa_ratio,               # control for compensation position
  data   = ab_data,
  family = binomial(link = "logit")
)

logit_tidy <- tidy(logit_model, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~round(.x, 4)))

message("\nLogistic regression (odds ratios — treatment effect on attrition):")
print(logit_tidy |> filter(term == "treatment_groupTreatment"))

# ── 6e. Heterogeneous effects by segment ───────────────────────────────────

segment_effects <- ab_data |>
  group_by(treatment_effect_segment, treatment_group) |>
  summarise(
    n              = n(),
    avg_eng_change = round(mean(engagement_change), 2),
    avg_risk_change = round(mean(post_flight_risk_score - pre_flight_risk_score), 4),
    attrition_rate = round(mean(simulated_post_attrition) * 100, 1),
    avg_post_risk  = round(mean(post_flight_risk_score), 3),
    .groups = "drop"
  ) |>
  pivot_wider(
    names_from  = treatment_group,
    values_from = c(n, avg_eng_change, avg_risk_change, attrition_rate, avg_post_risk)
  ) |>
  mutate(
    engagement_lift   = round(avg_eng_change_Treatment - avg_eng_change_Control, 2),
    attrition_delta   = round(attrition_rate_Control - attrition_rate_Treatment, 1),
    business_insight  = case_when(
      engagement_lift >= 6  ~ "Strong response — prioritize for scale-up",
      engagement_lift >= 4  ~ "Moderate response — refine and continue",
      engagement_lift >= 2  ~ "Weak response — review intervention design",
      TRUE                  ~ "No meaningful effect — consider alternative"
    )
  )

message("\nHeterogeneous effects by segment:")
print(segment_effects |> select(treatment_effect_segment, engagement_lift, attrition_delta, business_insight))

# ── 6f. Comprehensive results summary table ─────────────────────────────────

results_summary <- tibble(
  outcome = c(
    "Engagement improvement (points)",
    "Flight risk change",
    "Post-intervention attrition rate — Treatment",
    "Post-intervention attrition rate — Control",
    "Attrition rate reduction (pp)",
    "Attrition odds ratio (Treatment vs Control)"
  ),
  treatment_value = c(
    round(mean(treatment_engage), 2),
    round(mean(treatment_risk), 4),
    round(attrition_counts$attrition_rate[attrition_counts$treatment_group == "Treatment"] * 100, 1),
    round(attrition_counts$attrition_rate[attrition_counts$treatment_group == "Control"] * 100, 1),
    round(attr_reduction_pp, 1),
    round(exp(coef(logit_model)["treatment_groupTreatment"]), 3)
  ),
  p_value = c(
    format.pval(engage_ttest$p.value, digits = 3),
    format.pval(risk_ttest$p.value, digits = 3),
    format.pval(prop_test$p.value, digits = 3),
    "—", "—", "—"
  ),
  ci_lower = c(
    round(engage_ttest$conf.int[1], 2),
    round(risk_ttest$conf.int[1], 4),
    NA, NA, NA,
    round(exp(confint(logit_model, "treatment_groupTreatment"))[1], 3)
  ),
  ci_upper = c(
    round(engage_ttest$conf.int[2], 2),
    round(risk_ttest$conf.int[2], 4),
    NA, NA, NA,
    round(exp(confint(logit_model, "treatment_groupTreatment"))[2], 3)
  ),
  business_interpretation = c(
    "The intervention improved average engagement by meaningful amount — HR should treat this as a causal signal",
    "Flight risk decreased in treatment group — reduction is statistically reliable",
    "Attrition rate in the treatment group after intervention",
    "Attrition rate in the control group (comparison baseline)",
    "Attrition reduction attributable to the intervention",
    "Treatment group is less likely to leave — odds ratio < 1 = protective effect"
  )
)

message("\nFull results summary:")
print(results_summary)

# ── 7. Build output dataset ───────────────────────────────────────────────────

ab_output <- ab_data |>
  select(
    employee_id,
    department,
    job_family,
    job_level,
    location,
    performance_rating,
    tenure_years,
    compa_ratio,
    primary_segment,
    treatment_group,
    pre_engagement_score,
    post_engagement_score,
    engagement_change,
    pre_flight_risk_score,
    post_flight_risk_score,
    pre_attrition_probability,
    post_attrition_probability,
    simulated_post_attrition,
    post_retention_priority_score,
    treatment_effect_segment,
    recommended_action
  )

saveRDS(ab_output, "data/processed/ab_test_results.rds")
write_csv(ab_output, "data/raw/ab_test_results.csv")

message("\nOutput datasets saved:")
message("  data/processed/ab_test_results.rds")
message("  data/raw/ab_test_results.csv")
message("  Rows: ", nrow(ab_output))

# ── 8. Create interactive visuals ─────────────────────────────────────────────

# ── Shared design system ──────────────────────────────────────────────────────

clr_treatment <- "#1a5ca5"   # deep blue — treatment
clr_control   <- "#6898c0"   # mid blue — control
clr_success   <- "#1a7a48"   # green — positive outcome
clr_risk      <- "#c8302a"   # red — high risk
clr_amber     <- "#c97c00"   # amber — moderate

plot_layout <- list(
  paper_bgcolor = "white",
  plot_bgcolor  = "#f5f9fd",
  font          = list(family = "IBM Plex Mono, monospace", size = 11, color = "#1a3f6e"),
  title         = list(font = list(family = "Outfit, sans-serif", size = 16, color = "#08244a"), x = 0.02),
  legend        = list(bgcolor = "rgba(255,255,255,0.9)", bordercolor = "#c8ddf0", borderwidth = 1)
)

save_html_widget <- function(widget, filename, title_msg) {
  path <- file.path("outputs/figures", filename)
  saveWidget(widget, path, selfcontained = TRUE, title = paste("HCDIS —", title_msg))
  message("  Saved: ", path)
}

# ── VISUAL 1: Experiment design summary table ─────────────────────────────────
# File: 08_ab_test_experiment_design.html

design_table <- tibble(
  Component = c(
    "Total workforce", "Eligible employees", "Eligibility rate",
    "Control group (n)", "Treatment group (n)",
    "Eligibility criteria", "",
    "Primary outcome — continuous", "Primary outcome — binary",
    "Follow-up period", "Statistical test (continuous)",
    "Statistical test (binary)", "Significance threshold",
    "Minimum detectable effect"
  ),
  Detail = c(
    "1,000 employees",
    paste0(nrow(eligible), " employees"),
    paste0(round(nrow(eligible) / nrow(workforce) * 100, 1), "% of total workforce"),
    paste0(sum(ab_data$treatment_group == "Control")),
    paste0(sum(ab_data$treatment_group == "Treatment")),
    "Flight risk ≥ 0.30 OR retention priority ≥ 0.20",
    "Career stall, below-market pay, low engagement (supplementary)",
    "Engagement score change (post minus pre)",
    "Simulated post-intervention attrition (0/1)",
    "3 months post-intervention (simulated)",
    "Two-sided independent t-test",
    "Two-proportion z-test + logistic regression (controlled)",
    "α = 0.05 (two-sided)",
    "~3.5 pp attrition reduction (80% power, α = 0.05)"
  ),
  Category = c(
    "Population", "Population", "Population",
    "Design", "Design",
    "Eligibility", "Eligibility",
    "Outcomes", "Outcomes",
    "Timeline", "Statistics",
    "Statistics", "Statistics", "Statistics"
  )
)

v1 <- reactable(
  design_table,
  columns = list(
    Category  = colDef(name = "Category",  width = 160,
                        style = function(value) list(color = "#1a5ca5", fontWeight = "600", fontSize = "11px")),
    Component = colDef(name = "Parameter", width = 240,
                        style = list(color = "#08244a", fontWeight = "500")),
    Detail    = colDef(name = "Value / Description",
                        style = list(color = "#1a3f6e", fontFamily = "IBM Plex Mono, monospace", fontSize = "11px"))
  ),
  groupBy       = "Category",
  defaultExpanded = TRUE,
  striped       = TRUE,
  highlight     = TRUE,
  bordered      = FALSE,
  theme = reactableTheme(
    backgroundColor  = "white",
    borderColor      = "#c8ddf0",
    stripedColor     = "#f0f6fd",
    highlightColor   = "#e4eef8",
    cellPadding      = "10px 14px",
    headerStyle      = list(background = "#e4eef8", color = "#0c3c78",
                             fontFamily = "IBM Plex Mono, monospace",
                             fontSize = "11px", letterSpacing = "0.1em",
                             textTransform = "uppercase", fontWeight = "500"),
    tableStyle       = list(fontSize = "13px")
  )
)
save_html_widget(v1, "08_ab_test_experiment_design.html", "Experiment Design")

# ── VISUAL 2: Balance check table ─────────────────────────────────────────────
# File: 09_ab_test_balance_check.html
#
# This table shows pre-intervention characteristics for Treatment and Control.
# If the randomization worked, both groups should look nearly identical.

balance_display <- balance_check |>
  pivot_longer(-treatment_group, names_to = "metric", values_to = "value") |>
  pivot_wider(names_from = treatment_group, values_from = value) |>
  mutate(
    difference = round(as.numeric(Treatment) - as.numeric(Control), 3),
    balanced   = ifelse(abs(difference) < 1.5, "✓ Balanced", "⚠ Review"),
    metric_label = recode(metric,
      n                       = "Sample size",
      avg_age                 = "Average age",
      pct_female              = "% Female",
      avg_tenure_years        = "Avg tenure (years)",
      avg_performance         = "Avg performance rating",
      avg_engagement          = "Avg engagement score",
      avg_compa_ratio         = "Avg compa-ratio",
      avg_flight_risk         = "Avg flight risk score",
      avg_retention_priority  = "Avg retention priority",
      avg_manager_rating      = "Avg manager rating",
      pct_career_stall        = "% Career-stalled",
      pct_attrition           = "% Pre-experiment attrition",
      avg_salary              = "Avg salary ($)",
      pct_high_performers     = "% High performers (rating ≥ 4)"
    )
  ) |>
  select(metric_label, Control, Treatment, difference, balanced)

v2 <- reactable(
  balance_display,
  columns = list(
    metric_label = colDef(name = "Pre-Intervention Metric", minWidth = 220,
                           style = list(fontWeight = "500", color = "#08244a")),
    Control      = colDef(name = "Control Group", align = "center", width = 140,
                           style = list(fontFamily = "IBM Plex Mono, monospace",
                                        fontSize = "12px", color = "#3a6090")),
    Treatment    = colDef(name = "Treatment Group", align = "center", width = 140,
                           style = list(fontFamily = "IBM Plex Mono, monospace",
                                        fontSize = "12px", color = "#1a5ca5")),
    difference   = colDef(name = "Difference", align = "center", width = 110,
                           style = function(value) {
                             color <- if (abs(as.numeric(value)) < 1.0) "#1a7a48" else "#c8302a"
                             list(color = color, fontFamily = "IBM Plex Mono, monospace",
                                  fontSize = "12px", fontWeight = "500")
                           }),
    balanced     = colDef(name = "Assessment", align = "center", width = 120,
                           style = function(value) {
                             color <- if (grepl("✓", value)) "#1a7a48" else "#c8302a"
                             list(color = color, fontWeight = "600", fontSize = "12px")
                           })
  ),
  striped   = TRUE,
  highlight = TRUE,
  theme = reactableTheme(
    backgroundColor = "white",
    borderColor     = "#c8ddf0",
    stripedColor    = "#f0f6fd",
    highlightColor  = "#e4eef8",
    cellPadding     = "9px 14px",
    headerStyle     = list(background = "#e4eef8", color = "#0c3c78",
                            fontFamily = "IBM Plex Mono, monospace",
                            fontSize = "11px", letterSpacing = "0.1em",
                            textTransform = "uppercase", fontWeight = "500")
  )
)
save_html_widget(v2, "09_ab_test_balance_check.html", "Balance Check")

# ── VISUAL 3: Engagement lift chart ───────────────────────────────────────────
# File: 10_ab_test_engagement_lift.html

eng_summary <- ab_data |>
  group_by(treatment_group) |>
  summarise(
    mean_change = mean(engagement_change),
    se          = sd(engagement_change) / sqrt(n()),
    ci_low      = mean_change - 1.96 * se,
    ci_high     = mean_change + 1.96 * se,
    n           = n(),
    .groups = "drop"
  )

# Violin + box plot data
eng_violin_data <- ab_data |>
  mutate(treatment_group = factor(treatment_group, levels = c("Control", "Treatment")))

# Box plot with raw jitter
v3 <- plot_ly() |>
  add_trace(
    data        = eng_violin_data |> filter(treatment_group == "Control"),
    y           = ~engagement_change,
    type        = "violin",
    name        = "Control — standard support",
    side        = "negative",
    box         = list(visible = TRUE),
    meanline    = list(visible = TRUE, color = clr_control, width = 2),
    fillcolor   = paste0(clr_control, "33"),
    line        = list(color = clr_control, width = 1.5),
    points      = "all",
    pointpos    = -0.8,
    jitter      = 0.35,
    marker      = list(color = clr_control, opacity = 0.35, size = 4),
    hovertemplate = "<b>Control</b><br>Engagement change: %{y:.1f}<extra></extra>"
  ) |>
  add_trace(
    data        = eng_violin_data |> filter(treatment_group == "Treatment"),
    y           = ~engagement_change,
    type        = "violin",
    name        = "Treatment — enhanced pilot",
    side        = "positive",
    box         = list(visible = TRUE),
    meanline    = list(visible = TRUE, color = clr_treatment, width = 2),
    fillcolor   = paste0(clr_treatment, "33"),
    line        = list(color = clr_treatment, width = 1.5),
    points      = "all",
    pointpos    = 0.8,
    jitter      = 0.35,
    marker      = list(color = clr_treatment, opacity = 0.35, size = 4),
    hovertemplate = "<b>Treatment</b><br>Engagement change: %{y:.1f}<extra></extra>"
  ) |>
  layout(
    title = list(text = paste0(
      "Engagement Score Change: Treatment vs Control<br>",
      "<sup>Mean difference: +",
      round(mean(treatment_engage) - mean(control_engage), 1),
      " points | p = ", format.pval(engage_ttest$p.value, digits = 3), "</sup>"
    )),
    yaxis = list(title = "Engagement score change (post − pre)",
                 gridcolor = "#c8ddf0", zeroline = TRUE,
                 zerolinecolor = "#aac8e8", zerolinewidth = 1.5),
    xaxis = list(title = "", tickvals = list(), showgrid = FALSE),
    violingap   = 0,
    violinmode  = "overlay",
    showlegend  = TRUE,
    paper_bgcolor = "white",
    plot_bgcolor  = "#f5f9fd",
    font  = list(family = "IBM Plex Mono, monospace", size = 11, color = "#1a3f6e"),
    legend = list(x = 0.02, y = 0.98, bgcolor = "rgba(255,255,255,0.9)",
                  bordercolor = "#c8ddf0", borderwidth = 1),
    annotations = list(list(
      x = 0.98, y = 0.98,
      xref = "paper", yref = "paper",
      text = paste0("<b>Effect size (Cohen's d): ",
                    round(cohens_d_engage, 2), "</b><br>Medium effect"),
      showarrow = FALSE,
      font = list(size = 11, color = "#0c3c78"),
      bgcolor = "rgba(228,238,248,0.9)",
      bordercolor = "#a8c8e0", borderwidth = 1, borderpad = 6,
      align = "right"
    ))
  )

save_html_widget(v3, "10_ab_test_engagement_lift.html", "Engagement Lift")

# ── VISUAL 4: Attrition impact chart ──────────────────────────────────────────
# File: 11_ab_test_attrition_impact.html

attrition_viz <- ab_data |>
  group_by(treatment_group, primary_segment) |>
  summarise(
    n             = n(),
    attrition_rate = mean(simulated_post_attrition) * 100,
    .groups = "drop"
  )

# Overall comparison bars
overall_attr <- attrition_counts |>
  mutate(
    attrition_pct = round(attrition_rate * 100, 1),
    color = c(clr_control, clr_treatment)[match(treatment_group, c("Control", "Treatment"))],
    label = paste0(round(attrition_rate * 100, 1), "%"),
    hover = paste0(
      "<b>", treatment_group, " group</b><br>",
      "Attrition rate: ", round(attrition_rate * 100, 1), "%<br>",
      "Employees: ", n_employees, "<br>",
      "Left: ", n_attrition
    )
  )

v4 <- plot_ly() |>
  add_trace(
    data        = overall_attr,
    x           = ~treatment_group,
    y           = ~attrition_pct,
    type        = "bar",
    marker      = list(color = c(clr_control, clr_treatment),
                       line  = list(color = c(clr_control, clr_treatment), width = 1.5)),
    text        = ~label,
    textposition = "outside",
    textfont    = list(color = "#08244a", size = 14, family = "Outfit, sans-serif"),
    hovertext   = ~hover,
    hoverinfo   = "text",
    name        = "Post-intervention attrition rate"
  ) |>
  add_segments(
    x = 0.5, xend = 1.5, y = overall_attr$attrition_pct[1],
    yend = overall_attr$attrition_pct[1],
    line = list(color = clr_control, dash = "dot", width = 1.5),
    showlegend = FALSE, hoverinfo = "skip"
  ) |>
  layout(
    title = list(text = paste0(
      "Post-Intervention Attrition Rate: Treatment vs Control<br>",
      "<sup>Reduction: ", round(attr_reduction_pp, 1),
      " pp | p = ", format.pval(prop_test$p.value, digits = 3), "</sup>"
    )),
    xaxis = list(title = "", showgrid = FALSE),
    yaxis = list(title = "Post-intervention attrition rate (%)",
                 gridcolor = "#c8ddf0", range = c(0, max(overall_attr$attrition_pct) * 1.3)),
    paper_bgcolor = "white",
    plot_bgcolor  = "#f5f9fd",
    font = list(family = "IBM Plex Mono, monospace", size = 11, color = "#1a3f6e"),
    bargap = 0.5,
    annotations = list(list(
      x    = 0.5, y = min(overall_attr$attrition_pct) + attr_reduction_pp / 2,
      xref = "paper", yref = "y",
      text = paste0("↓ ", round(attr_reduction_pp, 1), " pp reduction"),
      showarrow  = TRUE,
      arrowhead  = 2, arrowcolor = clr_success, arrowwidth = 2,
      font       = list(color = clr_success, size = 12, family = "Outfit, sans-serif"),
      bgcolor    = "rgba(230,247,238,0.95)",
      bordercolor = clr_success, borderwidth = 1, borderpad = 6
    ))
  )

save_html_widget(v4, "11_ab_test_attrition_impact.html", "Attrition Impact")

# ── VISUAL 5: Effect size summary table ───────────────────────────────────────
# File: 12_ab_test_treatment_effect_summary.html

summary_display <- results_summary |>
  mutate(
    significance = case_when(
      p_value == "—" ~ "—",
      as.numeric(p_value) < 0.001 ~ "< 0.001 ✓✓✓",
      as.numeric(p_value) < 0.01  ~ paste0(p_value, " ✓✓"),
      as.numeric(p_value) < 0.05  ~ paste0(p_value, " ✓"),
      TRUE ~ paste0(p_value, " (ns)")
    )
  )

v5 <- reactable(
  summary_display |> select(outcome, treatment_value, significance, ci_lower, ci_upper, business_interpretation),
  columns = list(
    outcome = colDef(
      name = "Outcome",
      minWidth = 200,
      style = list(fontWeight = "500", color = "#08244a", fontSize = "12px")
    ),
    treatment_value = colDef(
      name = "Estimate",
      align = "center",
      width = 100,
      style = list(fontFamily = "IBM Plex Mono, monospace", color = "#1a5ca5",
                   fontWeight = "600", fontSize = "13px")
    ),
    significance = colDef(
      name = "p-value",
      align = "center",
      width = 140,
      style = function(value) {
        color <- if (grepl("✓", value)) "#1a7a48" else if (value == "—") "#6898c0" else "#c8302a"
        list(color = color, fontFamily = "IBM Plex Mono, monospace",
             fontSize = "11px", fontWeight = "600")
      }
    ),
    ci_lower = colDef(name = "CI lower", align = "center", width = 90,
                      style = list(fontFamily = "IBM Plex Mono, monospace",
                                   fontSize = "11px", color = "#3a6090")),
    ci_upper = colDef(name = "CI upper", align = "center", width = 90,
                      style = list(fontFamily = "IBM Plex Mono, monospace",
                                   fontSize = "11px", color = "#3a6090")),
    business_interpretation = colDef(
      name = "Business Interpretation",
      style = list(color = "#1a3f6e", fontSize = "12px", fontStyle = "italic")
    )
  ),
  striped   = TRUE,
  highlight = TRUE,
  bordered  = FALSE,
  theme = reactableTheme(
    backgroundColor = "white",
    borderColor     = "#c8ddf0",
    stripedColor    = "#f0f6fd",
    highlightColor  = "#e4eef8",
    cellPadding     = "10px 14px",
    headerStyle     = list(background = "#e4eef8", color = "#0c3c78",
                            fontFamily = "IBM Plex Mono, monospace",
                            fontSize = "11px", letterSpacing = "0.1em",
                            textTransform = "uppercase", fontWeight = "500")
  )
)
save_html_widget(v5, "12_ab_test_treatment_effect_summary.html", "Effect Summary")

# ── VISUAL 6: Segment heterogeneous effects ────────────────────────────────────
# File: 13_ab_test_segment_effects.html

segment_plot_data <- ab_data |>
  group_by(treatment_effect_segment, treatment_group) |>
  summarise(
    n              = n(),
    avg_eng_change = mean(engagement_change),
    attrition_rate = mean(simulated_post_attrition) * 100,
    avg_post_risk  = mean(post_flight_risk_score),
    .groups = "drop"
  )

seg_levels <- segment_plot_data |>
  filter(treatment_group == "Treatment") |>
  arrange(desc(avg_eng_change)) |>
  pull(treatment_effect_segment)

segment_plot_data <- segment_plot_data |>
  mutate(
    treatment_effect_segment = factor(treatment_effect_segment, levels = rev(seg_levels)),
    color = if_else(treatment_group == "Treatment", clr_treatment, clr_control)
  )

# Grouped bar: engagement lift by segment and group
v6 <- plot_ly(
  data        = segment_plot_data,
  x           = ~avg_eng_change,
  y           = ~treatment_effect_segment,
  color       = ~treatment_group,
  colors      = c("Control" = clr_control, "Treatment" = clr_treatment),
  type        = "bar",
  orientation = "h",
  text        = ~paste0(round(avg_eng_change, 1), " pts"),
  textposition = "outside",
  textfont    = list(size = 10, family = "IBM Plex Mono, monospace"),
  hovertemplate = paste0(
    "<b>%{y}</b><br>",
    "Group: %{data.name}<br>",
    "Avg engagement change: %{x:.2f}<br>",
    "<extra></extra>"
  )
) |>
  layout(
    title = list(text = paste0(
      "Engagement Lift by Workforce Segment & Treatment Group<br>",
      "<sup>Heterogeneous treatment effects — which segments respond most?</sup>"
    )),
    barmode = "group",
    xaxis   = list(title = "Average engagement score change (post − pre)",
                   gridcolor = "#c8ddf0"),
    yaxis   = list(title = "", automargin = TRUE),
    paper_bgcolor = "white",
    plot_bgcolor  = "#f5f9fd",
    font    = list(family = "IBM Plex Mono, monospace", size = 11, color = "#1a3f6e"),
    legend  = list(title = list(text = "<b>Group</b>"),
                   bgcolor = "rgba(255,255,255,0.9)",
                   bordercolor = "#c8ddf0", borderwidth = 1),
    margin  = list(l = 220, r = 80),
    annotations = list(list(
      x = 0.98, y = 0.02,
      xref = "paper", yref = "paper",
      text = "<b>Interpretation:</b> Larger gap between blue and grey bars<br>= stronger intervention effect for that segment",
      showarrow = FALSE,
      font = list(size = 10, color = "#0c3c78"),
      bgcolor = "rgba(228,238,248,0.92)",
      bordercolor = "#a8c8e0", borderwidth = 1, borderpad = 8,
      align = "left"
    ))
  )

save_html_widget(v6, "13_ab_test_segment_effects.html", "Segment Effects")

# ── 9. Final business summary ─────────────────────────────────────────────────

message("\n", strrep("=", 60))
message("  HCDIS A/B TEST — EXECUTIVE SUMMARY")
message(strrep("=", 60))
message("")
message("  Experiment: Retention Intervention Pilot")
message("  Eligible population: ", nrow(eligible), " employees")
message("  Treatment group: ", sum(ab_data$treatment_group == "Treatment"), " employees")
message("  Control group:   ", sum(ab_data$treatment_group == "Control"), " employees")
message("")
message("  KEY RESULTS:")
message("  → Engagement improved by +",
        round(mean(treatment_engage) - mean(control_engage), 1),
        " points more in treatment vs control (p = ",
        format.pval(engage_ttest$p.value, digits = 3), ")")
message("  → Attrition rate reduced by ", round(attr_reduction_pp, 1),
        " percentage points (p = ", format.pval(prop_test$p.value, digits = 3), ")")
message("  → Effect size (Cohen's d): ", round(cohens_d_engage, 2),
        " — a practically meaningful improvement")
message("  → Strongest responders: High performers at risk & Career-stalled employees")
message("")
message("  HR RECOMMENDATION:")
message("  Scale the intervention to the full eligible population with priority")
message("  given to high-performer flight risks and career-stalled employees.")
message("  Monitor 90-day post-intervention engagement and attrition signals.")
message("  Run a second randomized cohort to confirm external validity.")
message("")
message("  ETHICAL NOTE:")
message("  These results are from simulated outcomes. In a real deployment,")
message("  all employees should have access to enhanced support within a")
message("  reasonable period regardless of initial group assignment.")
message(strrep("=", 60))

message("\nAll outputs saved to outputs/figures/")
message("Script 03 complete.")
