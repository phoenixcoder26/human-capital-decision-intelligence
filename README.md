# Human Capital Decision Intelligence System  
## Advanced R-Based Talent Intelligence and Workforce Analytics Project

### Author
Farzana Khan Moutushi  

---

## Project Overview

The **Human Capital Decision Intelligence System (HCDIS)** is an advanced R-based workforce analytics project designed to help HR leaders move beyond descriptive reporting toward predictive, explainable, and strategic talent intelligence.

This project simulates an enterprise people analytics platform that supports decisions related to attrition risk, retention planning, workforce segmentation, pay equity, employee voice analytics, fairness auditing, and model monitoring.

The goal is to create a portfolio-ready analytics system that reflects how a People Analytics, Workforce Strategy, or Human Capital Consulting team might support senior HR and business leaders.

---

## Business Problem

Organizations often have workforce data across performance, engagement, compensation, tenure, promotions, and attrition, but these signals are rarely connected into one decision-support system.

This project addresses questions such as:

- Which employees or workforce groups are most at risk of leaving?
- Which high-performing employees may require retention intervention?
- Which departments show signs of burnout, low engagement, or compensation risk?
- How can HR leaders prioritize limited retention resources?
- Are there pay equity or opportunity equity concerns?
- How can workforce analytics support ethical and explainable decision-making?

---

## Current Project Status

This project is currently in the **data foundation and executive analytics stage**.

### Completed

- Created R project structure
- Set up core R packages
- Created `00_setup.R`
- Generated a synthetic workforce dataset
- Saved the dataset as both CSV and RDS files
- Created foundational workforce variables and engineered risk features

### Current Dataset Summary

The first synthetic dataset contains:

- **1,000 employees**
- **Attrition rate:** approximately 15.4%
- **Average engagement score:** approximately 67.3
- **Average salary:** approximately $108,751

---

## Why Synthetic Data?

This project uses synthetic data because public HR datasets are often too limited for advanced workforce analytics.

Common public HR datasets may include basic attrition labels, but they usually do not include:

- attrition dates
- intervention history
- employee survey comments
- compensation benchmarks
- retention program participation
- model monitoring data
- causal inference variables
- detailed pay equity fields

Synthetic data allows this project to demonstrate advanced analytics methods while avoiding the use of real employee information.

> **Data Disclosure:**  
> All data used in this project is synthetically generated in R. No real employee information is used. The synthetic data is designed to simulate realistic workforce, compensation, engagement, and attrition patterns for portfolio demonstration purposes.

---

## Dataset Design

The current synthetic workforce dataset includes employee-level data across several categories.

### Employee Profile

- employee ID
- age
- gender
- race/ethnicity
- department
- job family
- job level
- location
- remote work status
- hire date
- tenure

### Compensation

- salary
- market salary
- compa-ratio
- replacement cost estimate

### Performance and Engagement

- performance rating
- engagement score
- manager rating
- collaboration score
- customer orientation score
- training hours
- overtime
- absenteeism days

### Career Progression

- promotion history
- time since promotion
- promotion velocity
- career stall risk

### Attrition and Retention

- attrition probability
- attrition flag
- attrition date
- event time for survival analysis
- censored status
- flight risk score
- retention priority score
- recommended HR action

### Employee Voice

- survey period
- synthetic survey comment

---

## Engineered Features

The project includes business-oriented workforce features such as:

- `flight_risk_score`
- `retention_priority_score`
- `burnout_risk_score`
- `career_stall_risk`
- `manager_support_index`
- `performance_engagement_gap`
- `promotion_velocity`
- `replacement_cost_estimate`
- `business_criticality_score`
- `recommended_action`

These features are designed to translate raw HR data into actionable talent strategy signals.

---

## Planned Analytical Modules

The project will be developed in stages.

### 1. Executive Workforce Risk Dashboard

Planned visuals include:

- executive KPI summary
- talent risk priority matrix
- department workforce risk heatmap
- burnout and compensation risk quadrant
- high-performer flight risk drilldown
- retention action portfolio

### 2. Attrition Modeling

Planned models:

- logistic regression
- regularized regression with `glmnet`
- random forest
- XGBoost

Planned evaluation metrics:

- ROC-AUC
- PR-AUC
- precision
- recall / sensitivity
- specificity
- F1-score
- confusion matrix
- threshold optimization

### 3. Survival Analysis

Planned analysis:

- Cox proportional hazards model
- survival curves
- attrition probability over time
- censored data interpretation

### 4. Workforce Segmentation

Planned methods:

- PCA
- clustering
- probabilistic segmentation

Planned employee archetypes:

- high-performing flight risks
- stable core contributors
- career-stalled employees
- compensation-sensitive employees
- burnout-risk employees
- early-career employees needing support

### 5. Pay Equity and Opportunity Equity

Planned analysis:

- adjusted compensation differences
- compa-ratio comparisons
- promotion opportunity gaps
- department-level equity signals

### 6. Causal Inference for Retention Interventions

Planned methods:

- causal forests
- heterogeneous treatment effects
- intervention effectiveness analysis

Potential interventions:

- training programs
- compensation adjustments
- promotions
- manager changes
- flexible work
- mentorship
- retention bonuses

### 7. Employee Voice Analytics

Planned methods:

- text preprocessing
- topic modeling
- employee sentiment and theme analysis
- department-level employee voice dashboard

### 8. Explainability and Fairness Audit

Planned methods:

- feature importance
- SHAP-style explanations
- subgroup performance checks
- disparate impact analysis
- fairness monitoring

### 9. Model Monitoring and MLOps

Planned components:

- model cards
- performance drift monitoring
- feature drift monitoring
- fairness drift monitoring
- retraining trigger logic

---

## Project Folder Structure

```text
HumanCapitalDecisionIntelligence/
│
├── R/
│   ├── 00_setup.R
│   └── 01_generate_synthetic_workforce_data.R
│
├── data/
│   ├── raw/
│   │   └── synthetic_workforce.csv
│   │
│   ├── processed/
│   │   └── synthetic_workforce.rds
│   │
│   └── synthetic/
│
├── outputs/
│   ├── figures/
│   ├── models/
│   └── tables/
│
├── dashboard/
├── reports/
├── docs/
└── README.md