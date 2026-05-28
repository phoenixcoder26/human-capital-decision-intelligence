# =============================================================================
# Human Capital Decision Intelligence System (HCDIS)
# Module 04: Attrition Modeling, Confusion Matrix, and Threshold Strategy
# =============================================================================
# Author:  Farzana Khan Moutushi
# Purpose: Predict employee attrition using logistic regression, evaluate model
#          performance across multiple thresholds, and produce interactive
#          HTML outputs for HR decision-makers.
# Dataset: data/raw/synthetic_workforce.csv
# Outputs:
#   outputs/figures/14_attrition_model_performance.html
#   outputs/figures/15_confusion_matrix.html
#   outputs/figures/16_roc_curve.html
#   outputs/figures/17_threshold_strategy.html
#   outputs/figures/18_false_positive_negative_tradeoff.html
#   data/raw/attrition_model_predictions.csv
# =============================================================================


# =============================================================================
# SECTION 0 — Safe Package Installation and Loading
# =============================================================================

packages_needed <- c(
  "tidyverse",
  "broom",
  "yardstick",
  "pROC",
  "plotly",
  "reactable",
  "DT",
  "htmlwidgets",
  "scales",
  "janitor",
  "here"
)

for (pkg in packages_needed) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com/", quiet = TRUE)
  }
}

library(tidyverse)
library(broom)
library(yardstick)
library(pROC)
library(plotly)
library(reactable)
library(DT)
library(htmlwidgets)
library(scales)
library(janitor)
library(here)

cat("✅ All packages loaded successfully.\n")


# =============================================================================
# SECTION 1 — Project Path Setup
# =============================================================================

data_path   <- here("data", "raw", "synthetic_workforce.csv")
output_path <- here("outputs", "figures")
data_out    <- here("data", "raw")

dir.create(output_path, recursive = TRUE, showWarnings = FALSE)
dir.create(data_out, recursive = TRUE, showWarnings = FALSE)

cat("📁 Output directory ready:", output_path, "\n")

if (!file.exists(data_path)) {
  stop("❌ synthetic_workforce.csv was not found at: ", data_path)
}


# =============================================================================
# SECTION 2 — Load the Synthetic Workforce Dataset
# =============================================================================

workforce_raw <- read_csv(data_path, show_col_types = FALSE) %>%
  janitor::clean_names()

cat("📊 Dataset loaded.\n")
cat("   Rows:", nrow(workforce_raw), "| Columns:", ncol(workforce_raw), "\n")
cat(
  "   Attrition rate:",
  scales::percent(mean(workforce_raw$attrition, na.rm = TRUE), accuracy = 0.1),
  "\n"
)


# =============================================================================
# SECTION 3 — Feature Selection and Data Preparation
# =============================================================================

model_data <- workforce_raw %>%
  select(
    attrition,
    age,
    tenure_years,
    job_level,
    department,
    job_family,
    remote_work_status,
    salary,
    compa_ratio,
    performance_rating,
    engagement_score,
    manager_rating,
    collaboration_score,
    training_hours,
    overtime,
    absenteeism_days,
    promotion_last_3_years,
    time_since_promotion,
    career_stall_risk,
    burnout_risk_score,
    flight_risk_score,
    retention_priority_score
  ) %>%
  mutate(
    attrition = factor(
      attrition,
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),
    department = factor(department),
    job_family = factor(job_family),
    remote_work_status = factor(remote_work_status),
    career_stall_risk = factor(
      career_stall_risk,
      levels = c(0, 1),
      labels = c("No", "Yes")
    )
  ) %>%
  drop_na()

cat("✅ Feature selection complete.\n")
cat("   Model dataset rows:", nrow(model_data), "| Columns:", ncol(model_data), "\n")
cat("   Attrition breakdown:\n")
print(table(model_data$attrition))


# =============================================================================
# SECTION 4 — Train / Test Split
# =============================================================================

set.seed(42)

n_rows <- nrow(model_data)
train_idx <- sample(seq_len(n_rows), size = floor(0.80 * n_rows))

train_data <- model_data[train_idx, ]
test_data  <- model_data[-train_idx, ]

cat("\n📂 Train/Test Split Complete:\n")
cat("   Training rows:", nrow(train_data), "\n")
cat("   Test rows    :", nrow(test_data), "\n")
cat(
  "   Train attrition rate:",
  scales::percent(mean(train_data$attrition == "Yes"), accuracy = 0.1),
  "\n"
)
cat(
  "   Test  attrition rate:",
  scales::percent(mean(test_data$attrition == "Yes"), accuracy = 0.1),
  "\n"
)


# =============================================================================
# SECTION 5 — Fit Logistic Regression Model
# =============================================================================

cat("\n🔧 Fitting logistic regression model...\n")

attrition_model <- glm(
  attrition ~ .,
  data = train_data,
  family = binomial(link = "logit")
)

cat("✅ Model fitted successfully.\n")
cat("\n--- Tidy Model Summary: First 15 Predictors ---\n")

model_tidy <- broom::tidy(
  attrition_model,
  exponentiate = TRUE,
  conf.int = TRUE
)

print(
  model_tidy %>%
    select(term, estimate, p.value, conf.low, conf.high) %>%
    head(15)
)


# =============================================================================
# SECTION 6 — Generate Predicted Probabilities on the Test Set
# =============================================================================

test_predictions <- test_data %>%
  mutate(
    pred_prob = predict(
      attrition_model,
      newdata = test_data,
      type = "response"
    ),
    pred_class_50 = factor(
      ifelse(pred_prob >= 0.50, "Yes", "No"),
      levels = c("No", "Yes")
    )
  )

cat("\n✅ Predictions generated on test set.\n")
cat(
  "   Predicted high-risk employees at threshold 0.50:",
  sum(test_predictions$pred_class_50 == "Yes"),
  "\n"
)


# =============================================================================
# SECTION 7 — Core Model Evaluation at Default Threshold 0.50
# =============================================================================

roc_obj <- pROC::roc(
  response = as.numeric(test_predictions$attrition == "Yes"),
  predictor = test_predictions$pred_prob,
  quiet = TRUE
)

auc_value <- as.numeric(pROC::auc(roc_obj))

cm_50 <- yardstick::conf_mat(
  data = test_predictions,
  truth = attrition,
  estimate = pred_class_50
)

accuracy_val <- yardstick::accuracy(
  test_predictions,
  truth = attrition,
  estimate = pred_class_50
)$.estimate

precision_val <- yardstick::precision(
  test_predictions,
  truth = attrition,
  estimate = pred_class_50,
  event_level = "second"
)$.estimate

recall_val <- yardstick::recall(
  test_predictions,
  truth = attrition,
  estimate = pred_class_50,
  event_level = "second"
)$.estimate

specificity_val <- yardstick::specificity(
  test_predictions,
  truth = attrition,
  estimate = pred_class_50,
  event_level = "second"
)$.estimate

f1_val <- yardstick::f_meas(
  test_predictions,
  truth = attrition,
  estimate = pred_class_50,
  event_level = "second"
)$.estimate

cat("\n📊 Model Performance at Threshold = 0.50\n")
cat("   ROC-AUC    :", round(auc_value, 4), "\n")
cat("   Accuracy   :", round(accuracy_val, 4), "\n")
cat("   Precision  :", round(precision_val, 4), "\n")
cat("   Recall     :", round(recall_val, 4), "\n")
cat("   Specificity:", round(specificity_val, 4), "\n")
cat("   F1-Score   :", round(f1_val, 4), "\n")


# =============================================================================
# SECTION 8 — Threshold Comparison
# =============================================================================

compute_threshold_metrics <- function(probs, actual, threshold) {
  pred <- factor(
    ifelse(probs >= threshold, "Yes", "No"),
    levels = c("No", "Yes")
  )
  
  actual_num <- as.numeric(actual == "Yes")
  pred_num <- as.numeric(pred == "Yes")
  
  TP <- sum(actual_num == 1 & pred_num == 1)
  TN <- sum(actual_num == 0 & pred_num == 0)
  FP <- sum(actual_num == 0 & pred_num == 1)
  FN <- sum(actual_num == 1 & pred_num == 0)
  
  acc <- (TP + TN) / (TP + TN + FP + FN)
  prec <- ifelse((TP + FP) > 0, TP / (TP + FP), NA_real_)
  rec <- ifelse((TP + FN) > 0, TP / (TP + FN), NA_real_)
  spec <- ifelse((TN + FP) > 0, TN / (TN + FP), NA_real_)
  f1 <- ifelse(
    !is.na(prec) & !is.na(rec) & (prec + rec) > 0,
    2 * prec * rec / (prec + rec),
    NA_real_
  )
  
  tibble(
    Threshold = threshold,
    TP = TP,
    TN = TN,
    FP = FP,
    FN = FN,
    Accuracy = round(acc, 4),
    Precision = round(prec, 4),
    Recall = round(rec, 4),
    Specificity = round(spec, 4),
    F1_Score = round(f1, 4)
  )
}

thresholds_to_compare <- c(0.30, 0.40, 0.50, 0.60)

threshold_table <- map_dfr(
  thresholds_to_compare,
  ~ compute_threshold_metrics(
    probs = test_predictions$pred_prob,
    actual = test_predictions$attrition,
    threshold = .x
  )
)

cat("\n📊 Threshold Comparison Table:\n")
print(threshold_table)


# =============================================================================
# SECTION 9 — Save Predictions CSV
# =============================================================================

predictions_export <- test_predictions %>%
  select(
    pred_prob,
    pred_class_50,
    attrition,
    everything()
  ) %>%
  mutate(
    across(where(is.factor), as.character)
  )

write_csv(
  predictions_export,
  file.path(data_out, "attrition_model_predictions.csv")
)

cat("\n💾 Predictions saved to: data/raw/attrition_model_predictions.csv\n")


# =============================================================================
# SECTION 10 — Output 14: Model Performance Summary Table
# =============================================================================

performance_summary <- tibble(
  Metric = c(
    "ROC-AUC",
    "Accuracy",
    "Precision",
    "Recall / Sensitivity",
    "Specificity",
    "F1-Score"
  ),
  Value = c(
    auc_value,
    accuracy_val,
    precision_val,
    recall_val,
    specificity_val,
    f1_val
  ),
  Description = c(
    "Overall discrimination ability. 1.0 = perfect, 0.5 = random.",
    "Percent of all employees correctly classified.",
    "Of flagged employees, percent who actually left.",
    "Of all employees who left, percent correctly flagged.",
    "Of all employees who stayed, percent correctly identified as low risk.",
    "Balanced score combining precision and recall."
  ),
  HR_Interpretation = c(
    "How well the model separates leavers from stayers.",
    "Overall correct classifications, but may be misleading if attrition is rare.",
    "Confidence that a flagged employee is truly a flight risk.",
    "Ability to catch likely leavers before they leave. Low recall means costly missed departures.",
    "Ability to avoid unnecessary intervention for employees who stay.",
    "Useful when balancing missed departures and false alarms."
  )
) %>%
  mutate(Value = round(Value, 4))

tbl_14 <- reactable::reactable(
  performance_summary,
  columns = list(
    Metric = reactable::colDef(
      name = "Metric",
      minWidth = 160,
      style = list(fontWeight = "bold")
    ),
    
    Value = reactable::colDef(
      name = "Value",
      minWidth = 80,
      style = function(value) {
        if (is.na(value)) {
          return(list(color = "#7f8c8d", fontWeight = "bold"))
        }
        
        color <- if (value >= 0.75) {
          "#1a7a4a"
        } else if (value >= 0.60) {
          "#b8860b"
        } else {
          "#c0392b"
        }
        
        list(color = color, fontWeight = "bold")
      }
    ),
    
    Description = reactable::colDef(
      name = "Statistical Description",
      minWidth = 260
    ),
    
    HR_Interpretation = reactable::colDef(
      name = "HR Interpretation",
      minWidth = 340
    )
  ),
  striped = TRUE,
  highlight = TRUE,
  bordered = TRUE,
  defaultPageSize = 10,
  theme = reactable::reactableTheme(
    headerStyle = list(background = "#2c3e50", color = "white")
  )
)

htmlwidgets::saveWidget(
  tbl_14,
  file = file.path(output_path, "14_attrition_model_performance.html"),
  selfcontained = TRUE
)

cat("💾 Saved: outputs/figures/14_attrition_model_performance.html\n")


# =============================================================================
# SECTION 11 — Output 15: Confusion Matrix Heatmap
# =============================================================================

cm_df <- as.data.frame(cm_50$table) %>%
  rename(
    Predicted = Prediction,
    Actual = Truth,
    Count = Freq
  ) %>%
  mutate(
    Label = case_when(
      Actual == "No" & Predicted == "No" ~ "True Negative<br>Correctly identified as low-risk",
      Actual == "Yes" & Predicted == "Yes" ~ "True Positive<br>Correctly flagged as at-risk",
      Actual == "No" & Predicted == "Yes" ~ "False Positive<br>Flagged but stayed — extra HR effort",
      Actual == "Yes" & Predicted == "No" ~ "False Negative<br>Missed leaver — highest business cost",
      TRUE ~ "Other"
    )
  )

fig_15 <- plot_ly(
  data = cm_df,
  x = ~Predicted,
  y = ~Actual,
  z = ~Count,
  type = "heatmap",
  colorscale = list(
    list(0, "#fef9e7"),
    list(0.5, "#f39c12"),
    list(1, "#2c3e50")
  ),
  showscale = TRUE,
  text = ~paste0(
    "<b>", Label, "</b><br>",
    "Count: <b>", Count, "</b>"
  ),
  hovertemplate = "%{text}<extra></extra>"
) %>%
  layout(
    title = list(
      text = "<b>Confusion Matrix — Attrition Prediction</b><br><sup>Threshold = 0.50</sup>",
      font = list(size = 16, color = "#2c3e50")
    ),
    xaxis = list(title = "<b>Predicted</b>"),
    yaxis = list(title = "<b>Actual</b>"),
    margin = list(t = 90, b = 80, l = 80, r = 40)
  )

# Add count labels manually
for (i in seq_len(nrow(cm_df))) {
  fig_15 <- fig_15 %>%
    add_annotations(
      x = cm_df$Predicted[i],
      y = cm_df$Actual[i],
      text = cm_df$Count[i],
      font = list(size = 22, color = "white"),
      showarrow = FALSE
    )
}

fig_15 <- fig_15 %>%
  add_annotations(
    x = 0.5,
    y = -0.25,
    xref = "paper",
    yref = "paper",
    text = paste0(
      "<i>False negatives are missed leavers. False positives are unnecessary HR flags. ",
      "In retention strategy, missed leavers often carry higher business cost.</i>"
    ),
    showarrow = FALSE,
    font = list(size = 11, color = "#7f8c8d"),
    align = "center"
  )

htmlwidgets::saveWidget(
  plotly::as_widget(fig_15),
  file = file.path(output_path, "15_confusion_matrix.html"),
  selfcontained = TRUE
)

cat("💾 Saved: outputs/figures/15_confusion_matrix.html\n")


# =============================================================================
# SECTION 12 — Output 16: ROC Curve
# =============================================================================

roc_data <- data.frame(
  FPR = 1 - roc_obj$specificities,
  TPR = roc_obj$sensitivities,
  Threshold = roc_obj$thresholds
)

fig_16 <- plot_ly() %>%
  add_trace(
    x = c(0, 1),
    y = c(0, 1),
    type = "scatter",
    mode = "lines",
    line = list(dash = "dash", color = "#bdc3c7", width = 1.5),
    name = "Random Classifier",
    hoverinfo = "skip"
  ) %>%
  add_trace(
    data = roc_data,
    x = ~FPR,
    y = ~TPR,
    type = "scatter",
    mode = "lines",
    line = list(color = "#2980b9", width = 2.5),
    name = paste0("Logistic Regression AUC = ", round(auc_value, 3)),
    text = ~paste0(
      "Threshold: ", round(Threshold, 3), "<br>",
      "True Positive Rate: ", round(TPR, 3), "<br>",
      "False Positive Rate: ", round(FPR, 3)
    ),
    hovertemplate = "%{text}<extra></extra>"
  ) %>%
  layout(
    title = list(
      text = paste0(
        "<b>ROC Curve — Attrition Prediction Model</b><br>",
        "<sup>AUC = ", round(auc_value, 3), "</sup>"
      ),
      font = list(size = 15, color = "#2c3e50")
    ),
    xaxis = list(
      title = "<b>False Positive Rate</b>",
      range = c(0, 1),
      zeroline = FALSE
    ),
    yaxis = list(
      title = "<b>True Positive Rate / Recall</b>",
      range = c(0, 1),
      zeroline = FALSE
    ),
    legend = list(x = 0.52, y = 0.10),
    margin = list(t = 90, b = 60, l = 70, r = 40)
  )

htmlwidgets::saveWidget(
  plotly::as_widget(fig_16),
  file = file.path(output_path, "16_roc_curve.html"),
  selfcontained = TRUE
)

cat("💾 Saved: outputs/figures/16_roc_curve.html\n")


# =============================================================================
# SECTION 13 — Output 17: Threshold Strategy Chart
# =============================================================================

threshold_long <- threshold_table %>%
  select(Threshold, Accuracy, Precision, Recall, Specificity, F1_Score) %>%
  pivot_longer(
    cols = -Threshold,
    names_to = "Metric",
    values_to = "Value"
  )

metric_colors <- c(
  Accuracy = "#2980b9",
  Precision = "#27ae60",
  Recall = "#e74c3c",
  Specificity = "#8e44ad",
  F1_Score = "#e67e22"
)

fig_17 <- plot_ly()

for (m in unique(threshold_long$Metric)) {
  df_m <- threshold_long %>% filter(Metric == m)
  
  fig_17 <- fig_17 %>%
    add_trace(
      data = df_m,
      x = ~Threshold,
      y = ~Value,
      type = "scatter",
      mode = "lines+markers",
      name = m,
      line = list(color = metric_colors[[m]], width = 2.5),
      marker = list(color = metric_colors[[m]], size = 9),
      text = ~paste0(
        m,
        " at threshold ",
        Threshold,
        ": ",
        round(Value, 3)
      ),
      hovertemplate = "%{text}<extra></extra>"
    )
}

fig_17 <- fig_17 %>%
  layout(
    title = list(
      text = paste0(
        "<b>Threshold Strategy</b><br>",
        "<sup>Lower threshold catches more leavers; higher threshold reduces false alarms.</sup>"
      ),
      font = list(size = 14, color = "#2c3e50")
    ),
    xaxis = list(
      title = "<b>Decision Threshold</b>",
      tickvals = thresholds_to_compare,
      ticktext = paste0(thresholds_to_compare * 100, "%")
    ),
    yaxis = list(
      title = "<b>Metric Value</b>",
      range = c(0, 1)
    ),
    legend = list(title = list(text = "<b>Metric</b>")),
    hovermode = "x unified",
    margin = list(t = 100, b = 60, l = 70, r = 40)
  )

htmlwidgets::saveWidget(
  plotly::as_widget(fig_17),
  file = file.path(output_path, "17_threshold_strategy.html"),
  selfcontained = TRUE
)

cat("💾 Saved: outputs/figures/17_threshold_strategy.html\n")


# =============================================================================
# SECTION 14 — Output 18: False Positive / False Negative Tradeoff
# =============================================================================

fp_fn_data <- threshold_table %>%
  select(Threshold, FP, FN) %>%
  pivot_longer(
    cols = c(FP, FN),
    names_to = "Type",
    values_to = "Count"
  ) %>%
  mutate(
    Threshold_Label = paste0(Threshold * 100, "%"),
    Type_Label = case_when(
      Type == "FP" ~ "False Positives: flagged but stayed",
      Type == "FN" ~ "False Negatives: left but missed",
      TRUE ~ Type
    )
  )

fig_18 <- plot_ly(
  data = fp_fn_data,
  x = ~Threshold_Label,
  y = ~Count,
  color = ~Type,
  colors = c(
    "FP" = "#3498db",
    "FN" = "#e74c3c"
  ),
  type = "bar",
  text = ~paste0(Type_Label, "<br>Count: ", Count),
  hovertemplate = "%{text}<extra></extra>",
  textposition = "outside"
) %>%
  layout(
    barmode = "group",
    title = list(
      text = paste0(
        "<b>False Positive vs False Negative Tradeoff</b><br>",
        "<sup>Red = missed leavers; Blue = unnecessary flags.</sup>"
      ),
      font = list(size = 14, color = "#2c3e50")
    ),
    xaxis = list(title = "<b>Decision Threshold</b>"),
    yaxis = list(title = "<b>Number of Employees</b>"),
    legend = list(title = list(text = "<b>Error Type</b>")),
    margin = list(t = 100, b = 80, l = 70, r = 40)
  ) %>%
  add_annotations(
    x = 0.5,
    y = -0.25,
    xref = "paper",
    yref = "paper",
    text = paste0(
      "<i>Business logic: false negatives are usually more costly because HR misses employees who leave. ",
      "Lower thresholds reduce missed leavers but increase HR workload.</i>"
    ),
    showarrow = FALSE,
    font = list(size = 10, color = "#7f8c8d"),
    align = "center"
  )

htmlwidgets::saveWidget(
  plotly::as_widget(fig_18),
  file = file.path(output_path, "18_false_positive_negative_tradeoff.html"),
  selfcontained = TRUE
)

cat("💾 Saved: outputs/figures/18_false_positive_negative_tradeoff.html\n")


# =============================================================================
# SECTION 15 — Final Completion Summary
# =============================================================================

cat("\n")
cat("=============================================================\n")
cat(" ✅ MODULE 04 COMPLETE — Attrition Modeling and Evaluation\n")
cat("=============================================================\n")
cat("\n📂 Files saved:\n")
cat("   data/raw/attrition_model_predictions.csv\n")
cat("   outputs/figures/14_attrition_model_performance.html\n")
cat("   outputs/figures/15_confusion_matrix.html\n")
cat("   outputs/figures/16_roc_curve.html\n")
cat("   outputs/figures/17_threshold_strategy.html\n")
cat("   outputs/figures/18_false_positive_negative_tradeoff.html\n")

cat("\n📊 Key Model Results:\n")
cat("   ROC-AUC    :", round(auc_value, 4), "\n")
cat("   Accuracy   :", round(accuracy_val, 4), "\n")
cat("   Precision  :", round(precision_val, 4), "\n")
cat("   Recall     :", round(recall_val, 4), "\n")
cat("   Specificity:", round(specificity_val, 4), "\n")
cat("   F1-Score   :", round(f1_val, 4), "\n")

cat("\n📋 Threshold Recommendations:\n")
cat("   Use threshold 0.30 if interventions are low cost.\n")
cat("   Use threshold 0.50 as a balanced statistical baseline.\n")
cat("   Use threshold 0.60 if interventions are high cost.\n")

cat("\n⚠️  Important HR Interpretation:\n")
cat("   False negatives are missed leavers and are usually more costly.\n")
cat("   False positives increase HR workload but may be acceptable if interventions are low cost.\n")
cat("=============================================================\n")