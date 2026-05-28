# Human Capital Decision Intelligence System

## Advanced R-Based Talent Intelligence and Workforce Analytics Project

### Author

Farzana Khan Moutushi

---

## Project Overview

The **Human Capital Decision Intelligence System (HCDIS)** is an advanced R-based workforce analytics project designed to help HR leaders move beyond descriptive reporting toward predictive, explainable, and strategic talent intelligence.

This project simulates an enterprise people analytics platform that supports decisions related to attrition risk, retention planning, workforce segmentation, pay equity, employee voice analytics, fairness auditing, intervention testing, and model monitoring.

The goal is to create a portfolio-ready analytics system that reflects how a People Analytics, Workforce Strategy, Human Capital Consulting, or HR Decision Intelligence team might support senior HR and business leaders.

---

## Live Project Links

* **Live Dashboard:** [Human Capital Decision Intelligence System](https://phoenixcoder26.github.io/human-capital-decision-intelligence/)
* **GitHub Repository:** [human-capital-decision-intelligence](https://github.com/phoenixcoder26/human-capital-decision-intelligence)

---

## Business Problem

Organizations often have workforce data across performance, engagement, compensation, tenure, promotions, interventions, and attrition, but these signals are rarely connected into one decision-support system.

This project addresses questions such as:

* Which employees or workforce groups are most at risk of leaving?
* Which high-performing employees may require retention intervention?
* Which departments show signs of burnout, low engagement, or compensation risk?
* How can HR leaders prioritize limited retention resources?
* Do targeted retention interventions improve engagement or reduce flight risk?
* Are there pay equity or opportunity equity concerns?
* How can workforce analytics support ethical and explainable decision-making?

---

## Current Project Status

This project is currently in the **data foundation, executive dashboard, and experimental analytics stage**.

### Completed

* Created R project structure
* Set up core R packages
* Created `R/00_setup.R`
* Generated a synthetic workforce dataset in R
* Saved the dataset as CSV and RDS files
* Created foundational workforce variables and engineered risk features
* Built an executive workforce intelligence dashboard
* Deployed dashboard through GitHub Pages
* Built a retention intervention A/B testing module
* Created interactive A/B testing output charts
* Added A/B testing key findings to the project website

### Current Dataset Summary

The first synthetic workforce dataset contains:

* **1,000 employees**
* **Attrition rate:** approximately 15.4%
* **Average engagement score:** approximately 67.3
* **Average salary:** approximately $108,751

---

## Why Synthetic Data?

This project uses synthetic data because public HR datasets are often too limited for advanced workforce analytics.

Common public HR datasets may include basic attrition labels, but they usually do not include:

* attrition dates
* intervention history
* employee survey comments
* compensation benchmarks
* retention program participation
* model monitoring data
* causal inference variables
* detailed pay equity fields

Synthetic data allows this project to demonstrate advanced analytics methods while avoiding the use of real employee information.

> **Data Disclosure:**
> All data used in this project is synthetically generated in R. No real employee information is used. The synthetic data is designed to simulate realistic workforce, compensation, engagement, intervention, and attrition patterns for portfolio demonstration purposes.

---

## Dataset Design

The current synthetic workforce dataset includes employee-level data across several categories.

### Employee Profile

* employee ID
* age
* gender
* race/ethnicity
* department
* job family
* job level
* location
* remote work status
* hire date
* tenure

### Compensation

* salary
* market salary
* compa-ratio
* replacement cost estimate

### Performance and Engagement

* performance rating
* engagement score
* manager rating
* collaboration score
* customer orientation score
* training hours
* overtime
* absenteeism days

### Career Progression

* promotion history
* time since promotion
* promotion velocity
* career stall risk

### Attrition and Retention

* attrition probability
* attrition flag
* attrition date
* event time for survival analysis
* censored status
* flight risk score
* retention priority score
* recommended HR action

### Employee Voice

* survey period
* synthetic survey comment

---

## Engineered Features

The project includes business-oriented workforce features such as:

* `flight_risk_score`
* `retention_priority_score`
* `burnout_risk_score`
* `career_stall_risk`
* `manager_support_index`
* `performance_engagement_gap`
* `promotion_velocity`
* `replacement_cost_estimate`
* `business_criticality_score`
* `recommended_action`

These features are designed to translate raw HR data into actionable talent strategy signals.

---

## Executive Workforce Intelligence Dashboard

The current GitHub Pages dashboard includes:

* executive KPI summary
* attrition rate
* average engagement
* high-risk employee count
* high-performing flight-risk count
* replacement cost exposure
* talent risk priority matrix
* department workforce risk chart
* workforce planning heatmap
* high-performer flight-risk registry
* engagement distribution
* A/B testing key visual results
* A/B testing key findings

Dashboard link:

[Human Capital Decision Intelligence System Dashboard](https://phoenixcoder26.github.io/human-capital-decision-intelligence/)

---

## Completed Module: Retention Intervention A/B Testing

This module simulates an ethical A/B test for a targeted retention intervention among medium- to high-risk employees. Eligible employees were randomly assigned to standard HR support or an enhanced career-development intervention.

The enhanced intervention includes:

* career coaching
* manager check-in
* personalized development plan
* internal mobility discussion

The simulated pilot showed a meaningful engagement lift of approximately **4.6 points** for the treatment group compared with the control group. Flight risk also decreased, while short-term attrition reduction was small and not statistically significant. This suggests the intervention improved leading workforce indicators, while actual attrition may require a longer observation window.

### A/B Testing Design

* Eligible employees: **533**
* Treatment group: **266**
* Control group: **267**
* Treatment: enhanced career-development intervention
* Control: standard HR support
* Main outcomes:

  * engagement change
  * flight risk change
  * simulated post-intervention attrition
  * segment-level treatment effects

### A/B Testing Outputs

* [Experiment Design](https://phoenixcoder26.github.io/human-capital-decision-intelligence/08_ab_test_experiment_design.html)
* [Balance Check](https://phoenixcoder26.github.io/human-capital-decision-intelligence/09_ab_test_balance_check.html)
* [Engagement Lift](https://phoenixcoder26.github.io/human-capital-decision-intelligence/10_ab_test_engagement_lift.html)
* [Attrition Impact](https://phoenixcoder26.github.io/human-capital-decision-intelligence/11_ab_test_attrition_impact.html)
* [Treatment Effect Summary](https://phoenixcoder26.github.io/human-capital-decision-intelligence/12_ab_test_treatment_effect_summary.html)
* [Segment Effects](https://phoenixcoder26.github.io/human-capital-decision-intelligence/13_ab_test_segment_effects.html)

### A/B Testing Interpretation

The A/B testing module shows that the retention intervention produced a meaningful improvement in engagement and flight risk indicators. However, the short-term attrition impact was not statistically significant. This is a realistic workforce analytics result because engagement and risk signals often change before actual attrition outcomes become visible.

The strongest response appeared among:

* high-performing flight risks
* career-stalled employees

This suggests that targeted intervention may be more effective than applying the same retention program uniformly across all employees.

---

## Planned Analytical Modules

The project will continue to be developed in stages.

### 1. Attrition Modeling

Planned models:

* logistic regression
* regularized regression with `glmnet`
* random forest
* XGBoost

Planned evaluation metrics:

* ROC-AUC
* PR-AUC
* precision
* recall / sensitivity
* specificity
* F1-score
* confusion matrix
* threshold optimization

This module will also include business interpretation of false positives and false negatives in workforce decision-making.

### 2. Survival Analysis

Planned analysis:

* Cox proportional hazards model
* survival curves
* attrition probability over time
* censored data interpretation
* time-to-attrition analysis by department, tenure group, job level, and engagement group

### 3. Workforce Segmentation

Planned methods:

* PCA
* clustering
* probabilistic segmentation

Planned employee archetypes:

* high-performing flight risks
* stable core contributors
* career-stalled employees
* compensation-sensitive employees
* burnout-risk employees
* early-career employees needing support

### 4. Pay Equity and Opportunity Equity

Planned analysis:

* adjusted compensation differences
* compa-ratio comparisons
* promotion opportunity gaps
* department-level equity signals
* pay equity risk by job family, level, department, and location

### 5. Causal Inference for Retention Interventions

Planned methods:

* causal forests
* heterogeneous treatment effects
* intervention effectiveness analysis

Potential interventions:

* training programs
* compensation adjustments
* promotions
* manager changes
* flexible work
* mentorship
* retention bonuses

### 6. Employee Voice Analytics

Planned methods:

* text preprocessing
* topic modeling
* employee sentiment and theme analysis
* department-level employee voice dashboard

### 7. Explainability and Fairness Audit

Planned methods:

* feature importance
* SHAP-style explanations
* subgroup performance checks
* disparate impact analysis
* fairness monitoring
* false positive and false negative rates by group

### 8. Model Monitoring and MLOps

Planned components:

* model cards
* performance drift monitoring
* feature drift monitoring
* fairness drift monitoring
* retraining trigger logic

---

## Project Folder Structure

```text
HumanCapitalDecisionIntelligence/
│
├── R/
│   ├── 00_setup.R
│   ├── 01_generate_synthetic_workforce_data.R
│   └── 03_ab_testing_retention_intervention.R
│
├── data/
│   ├── raw/
│   │   ├── synthetic_workforce.csv
│   │   └── ab_test_results.csv
│   │
│   ├── processed/
│   │   ├── synthetic_workforce.rds
│   │   └── ab_test_results.rds
│   │
│   └── synthetic/
│
├── outputs/
│   ├── figures/
│   │   ├── 08_ab_test_experiment_design.html
│   │   ├── 09_ab_test_balance_check.html
│   │   ├── 10_ab_test_engagement_lift.html
│   │   ├── 11_ab_test_attrition_impact.html
│   │   ├── 12_ab_test_treatment_effect_summary.html
│   │   └── 13_ab_test_segment_effects.html
│   │
│   ├── models/
│   └── tables/
│
├── docs/
│   ├── index.html
│   ├── 08_ab_test_experiment_design.html
│   ├── 09_ab_test_balance_check.html
│   ├── 10_ab_test_engagement_lift.html
│   ├── 11_ab_test_attrition_impact.html
│   ├── 12_ab_test_treatment_effect_summary.html
│   └── 13_ab_test_segment_effects.html
│
└── README.md
```

---

## Tools and Packages

Current R packages used:

* `tidyverse`
* `lubridate`
* `janitor`
* `here`
* `skimr`
* `plotly`
* `reactable`
* `DT`
* `htmlwidgets`
* `broom`
* `scales`
* `infer`

Planned packages for later stages:

* `tidymodels`
* `glmnet`
* `ranger`
* `xgboost`
* `survival`
* `survminer`
* `mclust`
* `grf`
* `stm`
* `DALEX`
* `fairmodels`
* `vetiver`
* `shiny`
* `flexdashboard`

---

## How to Run the Project

### Step 1: Open the R Project

Open the project folder in RStudio:

```text
HumanCapitalDecisionIntelligence
```

### Step 2: Run Setup

```r
source("R/00_setup.R")
```

### Step 3: Generate Synthetic Workforce Data

```r
source("R/01_generate_synthetic_workforce_data.R")
```

This creates:

```text
data/raw/synthetic_workforce.csv
data/processed/synthetic_workforce.rds
```

### Step 4: Run the A/B Testing Module

```r
source("R/03_ab_testing_retention_intervention.R")
```

This creates:

```text
data/raw/ab_test_results.csv
data/processed/ab_test_results.rds
outputs/figures/08_ab_test_experiment_design.html
outputs/figures/09_ab_test_balance_check.html
outputs/figures/10_ab_test_engagement_lift.html
outputs/figures/11_ab_test_attrition_impact.html
outputs/figures/12_ab_test_treatment_effect_summary.html
outputs/figures/13_ab_test_segment_effects.html
```

---

## Ethical Considerations

This project is designed as a responsible people analytics prototype.

Important ethical principles include:

* no use of real employee data
* synthetic data disclosure
* human-in-the-loop decision-making
* fairness auditing before model deployment
* careful handling of demographic variables
* transparency around model limitations
* no fully automated employment decisions

Demographic variables such as gender and race/ethnicity are included only to support future fairness auditing and pay equity analysis. They should not be used carelessly as predictive features in employment decisions.

The A/B testing module is framed as standard HR support versus enhanced pilot support. In a real-world deployment, employees in the control group should not be denied necessary support, and any pilot should be reviewed for fairness, transparency, and employee impact.

---

## Portfolio Positioning

This project demonstrates skills in:

* R programming
* workforce analytics
* HR data strategy
* synthetic data generation
* feature engineering
* talent risk scoring
* A/B testing
* experimental design
* treatment-control analysis
* executive analytics
* data storytelling
* responsible AI thinking
* GitHub Pages deployment
* applied machine learning project planning

---

## Project Roadmap

### Phase 1: Data Foundation

Status: Completed

* create project folder
* create setup script
* generate synthetic workforce dataset
* validate dataset quality
* engineer workforce risk features

### Phase 2: Executive Dashboard

Status: Completed

* create executive KPI summary
* create talent risk priority matrix
* create department risk heatmap
* create high-performer flight risk table
* deploy dashboard through GitHub Pages

### Phase 3: Experimental Analytics

Status: Completed

* simulate retention intervention A/B test
* randomly assign treatment and control groups
* run balance checks
* analyze engagement lift
* analyze attrition impact
* analyze segment-level treatment effects
* create interactive A/B testing outputs

### Phase 4: Predictive Modeling

Status: Planned

* train attrition models
* compare model performance
* evaluate with ROC-AUC, recall, precision, F1-score, and confusion matrix
* conduct threshold optimization
* interpret false positive and false negative tradeoffs

### Phase 5: Advanced Workforce Intelligence

Status: Planned

* survival analysis
* segmentation
* pay equity analytics
* causal inference
* NLP employee voice analytics

### Phase 6: Responsible AI and Deployment

Status: Planned

* explainability
* fairness audit
* model monitoring
* dashboard refinement
* model card development

---

## Note

This project is currently under development. The README will be updated as additional modules, charts, models, and dashboards are completed.
