# ---- libraries ----
library(tidyverse)
library(lubridate)
library(janitor)
library(skimr)    # optional diagnostics
library(ggplot2)  # ensures ggsave available

# ---- outputs / rds filenames ----
outdir <- file.path(getwd(), "outputs")
if (!dir.exists(outdir)) dir.create(outdir)

rds_daily_activity <- file.path(outdir, "daily_activity_clean.rds")
rds_sleep          <- file.path(outdir, "sleep_clean.rds")
rds_sleep_daily    <- file.path(outdir, "sleep_daily.rds")
rds_weight         <- file.path(outdir, "weight_clean.rds")
rds_activity_sleep_weight <- file.path(outdir, "activity_sleep_weight.rds")
rds_activity_sleep_daily  <- file.path(outdir, "activity_sleep_daily.rds")
rds_heartrate_daily <- file.path(outdir, "heartrate_daily.rds")

# ---- helper: flexible date parser ----
parse_flexible_date <- function(vec) {
  # try common patterns in a robust order; returns POSIXct or NA
  out <- suppressWarnings(ymd_hms(vec))
  if (all(is.na(out))) out <- suppressWarnings(mdy_hms(vec))
  if (all(is.na(out))) out <- suppressWarnings(parse_date_time(vec, orders = c(
    "ymd HMS", "ymd HM", "ymd", "mdy IMS p", "mdy HMS", "mdy HM", "mdy"
  )))
  return(out)
}

# ---- fast path: load .rds if all exist ----
rds_exist <- file.exists(rds_daily_activity) &&
  file.exists(rds_sleep) &&
  file.exists(rds_sleep_daily) &&
  file.exists(rds_weight) &&
  file.exists(rds_activity_sleep_weight) &&
  file.exists(rds_heartrate_daily)

if (rds_exist) {
  message("Loading cleaned .rds files (fast path)...")
  daily_activity        <- readRDS(rds_daily_activity)
  sleep                 <- readRDS(rds_sleep)
  sleep_daily           <- readRDS(rds_sleep_daily)
  weight                <- readRDS(rds_weight)
  activity_sleep_weight <- readRDS(rds_activity_sleep_weight)
  activity_sleep_daily  <- readRDS(rds_activity_sleep_daily)
  heartrate_daily       <- readRDS(rds_heartrate_daily)
  message("Loaded cleaned datasets from outputs/")
} else {
  message("Cleaned .rds files not found — running full cleaning (slow path).")
  
  # ---- Read raw CSVs ----
  daily_activity <- read_csv("data/dailyActivity_merged.csv", show_col_types = FALSE)
  sleep          <- read_csv("data/minuteSleep_merged.csv", show_col_types = FALSE)
  weight         <- read_csv("data/weightLogInfo_merged.csv", show_col_types = FALSE)
  heartrate      <- read_csv("data/heartrate_seconds_merged.csv", show_col_types = FALSE)
  
  # ---- Clean daily_activity ----
  # rename and parse ActivityDate like "3/25/2016"
  daily_activity <- daily_activity %>%
    rename(Date_raw = ActivityDate) %>%
    mutate(Date = mdy(Date_raw)) %>%
    distinct()
  
  # ---- Clean sleep (minute-level) ----
  # sleep columns: Id, date (string), value (minutes), logId
  sleep <- sleep %>%
    rename(Date_raw = date) %>%
    mutate(Time_parsed = parse_flexible_date(Date_raw),
           Date = as_date(Time_parsed)) %>%
    distinct()
  
  # Aggregate minute-level sleep into daily totals
  sleep_daily <- sleep %>%
    group_by(Id, Date) %>%
    summarise(total_sleep_minutes = sum(value, na.rm = TRUE), .groups = "drop") %>%
    mutate(sleep_hours = total_sleep_minutes / 60)
  
  # ---- Clean weight ----
  weight <- weight %>%
    mutate(Time_parsed = parse_flexible_date(Date)) %>%
    mutate(Date = as_date(Time_parsed)) %>%
    distinct()
  
  # ---- Merge activity + daily sleep + weight ----
  activity_sleep_daily <- daily_activity %>%
    left_join(sleep_daily, by = c("Id", "Date"))
  
  activity_sleep_weight <- activity_sleep_daily %>%
    left_join(weight %>% select(Id, Date, WeightKg, BMI), by = c("Id", "Date"))
  
  # ---- Heartrate: parse and aggregate to daily ----
  heartrate <- heartrate %>%
    mutate(Time_parsed = parse_flexible_date(Time),
           Date = as_date(Time_parsed))
  
  heartrate_daily <- heartrate %>%
    group_by(Id, Date) %>%
    summarise(avg_hr = mean(Value, na.rm = TRUE), .groups = "drop")
  
  # ---- Save cleaned objects as .rds ----
  saveRDS(daily_activity, rds_daily_activity)
  saveRDS(sleep, rds_sleep)
  saveRDS(sleep_daily, rds_sleep_daily)
  saveRDS(weight, rds_weight)
  saveRDS(activity_sleep_weight, rds_activity_sleep_weight)
  saveRDS(activity_sleep_daily, rds_activity_sleep_daily)
  saveRDS(heartrate_daily, rds_heartrate_daily)
  
  message("Saved cleaned .rds files to outputs/:")
  print(list.files(outdir, pattern = "\\.rds$", full.names = TRUE))
}

# ---- Sanity check / diagnostics ----
message("Sanity checks:")
if (exists("daily_activity")) message("daily_activity rows:", nrow(daily_activity))
if (exists("activity_sleep_daily")) message("activity_sleep_daily rows:", nrow(activity_sleep_daily))
if (exists("activity_sleep_weight")) message("activity_sleep_weight rows:", nrow(activity_sleep_weight))
if (exists("sleep_daily")) message("sleep_daily rows:", nrow(sleep_daily))
if (exists("heartrate_daily")) message("heartrate_daily rows:", nrow(heartrate_daily))

# ---- Start analysis & create plot objects ----

# Steps: average per user & overall average
avg_steps_by_user <- daily_activity %>%
  group_by(Id) %>%
  summarise(avg_steps = mean(TotalSteps, na.rm = TRUE), .groups = "drop")

overall_avg_steps <- avg_steps_by_user %>% summarise(overall_avg = mean(avg_steps, na.rm = TRUE))
message("Overall average steps per user (mean of user averages): ", round(overall_avg_steps$overall_avg, 1))

# 1) Steps by weekday (bar) -> p_steps_weekday
p_steps_weekday <- daily_activity %>%
  mutate(weekday = weekdays(Date)) %>%
  group_by(weekday) %>%
  summarise(avg_steps = mean(TotalSteps, na.rm = TRUE), .groups = "drop") %>%
  mutate(weekday = factor(weekday, levels = c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))) %>%
  arrange(weekday) %>%
  ggplot(aes(x = reorder(weekday, avg_steps), y = avg_steps, fill = weekday)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Average Steps by Day of Week", x = "Day of Week", y = "Average Steps") +
  theme_minimal()

# 2) Steps vs Calories scatter + linear model -> p_steps_calories
p_steps_calories <- ggplot(daily_activity, aes(x = TotalSteps, y = Calories)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  labs(title = "Steps vs Calories Burned", x = "Steps", y = "Calories") +
  theme_minimal()

# 3) Activity intensity breakdown -> p_intensity
p_intensity <- daily_activity %>%
  summarise(
    sedentary = mean(SedentaryMinutes, na.rm = TRUE),
    light = mean(LightlyActiveMinutes, na.rm = TRUE),
    moderate = mean(FairlyActiveMinutes, na.rm = TRUE),
    very_active = mean(VeryActiveMinutes, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = everything(), names_to = "intensity", values_to = "minutes") %>%
  ggplot(aes(x = intensity, y = minutes, fill = intensity)) +
  geom_col(show.legend = FALSE) +
  labs(title = "Average Daily Activity Intensity Breakdown", x = "Activity Intensity", y = "Minutes") +
  theme_minimal()

# 4) Sleep: aggregate already created as sleep_daily; merge to daily_activity if not present
if (!exists("activity_sleep_daily") && exists("sleep_daily")) {
  activity_sleep_daily <- daily_activity %>%
    left_join(sleep_daily, by = c("Id", "Date"))
}

# Cleaned activity_sleep_clean (for plotting and stats)
activity_sleep_clean <- activity_sleep_daily %>%
  filter(!is.na(sleep_hours)) %>%
  filter(sleep_hours > 0 & sleep_hours < 20)

p_sleep_steps <- activity_sleep_clean %>%
  ggplot(aes(x = sleep_hours, y = TotalSteps)) +
  geom_point(alpha = 0.5, color = "purple", size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, color = "black") +
  labs(title = "Sleep Hours vs Daily Steps",
       subtitle = "Each point = 1 user-day (joined daily activity & sleep)",
       x = "Sleep (hours)", y = "Daily Steps") +
  theme_minimal()

# compute correlation and linear model (safe)
if (nrow(activity_sleep_clean) >= 5 && var(activity_sleep_clean$sleep_hours, na.rm = TRUE) > 0) {
  cor_val <- cor(activity_sleep_clean$sleep_hours, activity_sleep_clean$TotalSteps, use = "complete.obs")
  lm_fit <- lm(TotalSteps ~ sleep_hours, data = activity_sleep_clean)
  message("Pearson correlation (sleep_hours vs TotalSteps): ", round(cor_val, 3))
} else {
  cor_val <- NA; lm_fit <- NULL
  warning("Not enough data or zero variance to compute correlation / lm for sleep vs steps.")
}

# 5) Heart rate plots
# p_hr_overall: overall daily average hr
if (exists("heartrate_daily")) {
  p_hr_overall <- heartrate_daily %>%
    group_by(Date) %>%
    summarise(overall_avg_hr = mean(avg_hr, na.rm = TRUE), .groups = "drop") %>%
    ggplot(aes(x = Date, y = overall_avg_hr)) +
    geom_line() +
    geom_smooth(method = "loess", se = TRUE) +
    labs(title = "Overall Daily Average Heart Rate", x = "Date", y = "Avg HR (bpm)") +
    theme_minimal()
  
  # p_hr_sample: sample top users (keeps it readable)
  top_users <- heartrate_daily %>% count(Id, name = "n_days") %>% arrange(desc(n_days)) %>% slice_head(n = 6) %>% pull(Id)
  p_hr_sample <- heartrate_daily %>%
    filter(Id %in% top_users) %>%
    ggplot(aes(x = Date, y = avg_hr, color = factor(Id), group = factor(Id))) +
    geom_line() +
    labs(title = "Daily Avg Heart Rate — sample users", subtitle = paste("Top", length(top_users), "users by recorded days"),
         x = "Date", y = "Avg HR (bpm)", color = "Id") +
    theme_minimal()
}

# 6) Weight logs summary
weight_logs <- NULL
if (exists("weight")) {
  weight_logs <- weight %>% group_by(Id) %>% summarise(log_count = n(), avg_BMI = mean(BMI, na.rm = TRUE), .groups = "drop")
}

# ---- Save individual plots & summaries to outputs/ ----

# helper: safe save
save_plot_safe <- function(plot_obj, filename, width = 9, height = 5, dpi = 300) {
  outpath <- file.path(outdir, filename)
  tryCatch({
    ggsave(outpath, plot = plot_obj, width = width, height = height, dpi = dpi)
    message("Saved: ", outpath)
  }, error = function(e) message("Failed to save ", filename, " : ", e$message))
}

# Save PNGs (only when objects exist)
save_plot_safe(p_steps_weekday, "steps_by_weekday.png", 8, 4)
save_plot_safe(p_steps_calories, "steps_vs_calories.png", 8, 5)
save_plot_safe(p_intensity, "activity_intensity_breakdown.png", 8, 5)
save_plot_safe(p_sleep_steps, "sleep_hours_vs_steps.png", 8, 5)
if (exists("p_hr_overall")) save_plot_safe(p_hr_overall, "heartrate_overall_daily.png", 9, 4)
if (exists("p_hr_sample")) save_plot_safe(p_hr_sample, "heartrate_sample_users.png", 9, 4)

# Save summary CSVs
write_csv(avg_steps_by_user, file.path(outdir, "avg_steps_by_user.csv"))
message("Saved avg_steps_by_user.csv")

if (exists("sleep_daily")) {
  write_csv(sleep_daily, file.path(outdir, "sleep_daily_by_user_date.csv"))
  message("Saved sleep_daily_by_user_date.csv")
}

if (exists("heartrate_daily")) {
  write_csv(heartrate_daily, file.path(outdir, "heartrate_daily.csv"))
  message("Saved heartrate_daily.csv")
}

if (!is.null(weight_logs)) {
  write_csv(weight_logs, file.path(outdir, "weight_logs_summary.csv"))
  message("Saved weight_logs_summary.csv")
}

# Save lm summary and correlation (if available)
if (!is.null(lm_fit)) {
  sink(file.path(outdir, "lm_sleep_vs_steps_summary.txt"))
  print(summary(lm_fit))
  sink()
  message("Saved lm_sleep_vs_steps_summary.txt")
}
if (!is.na(cor_val)) {
  write_lines(paste0("Pearson correlation (sleep_hours vs TotalSteps): ", round(cor_val, 4)),
              file.path(outdir, "correlation_sleep_steps.txt"))
  message("Saved correlation_sleep_steps.txt")
}

# Save cleaned R objects for reproducibility (RDS)
safe_save_rds <- function(obj, fname) {
  outpath <- file.path(outdir, fname)
  tryCatch({
    saveRDS(obj, outpath)
    message("Saved RDS: ", outpath)
  }, error = function(e) message("Failed saveRDS(", fname, "): ", e$message))
}

safe_save_rds(daily_activity, "daily_activity_clean.rds")
safe_save_rds(sleep, "sleep_clean.rds")
if (exists("sleep_daily")) safe_save_rds(sleep_daily, "sleep_daily.rds")
if (exists("activity_sleep_daily")) safe_save_rds(activity_sleep_daily, "activity_sleep_daily.rds")
if (exists("activity_sleep_weight")) safe_save_rds(activity_sleep_weight, "activity_sleep_weight.rds")
if (exists("heartrate_daily")) safe_save_rds(heartrate_daily, "heartrate_daily.rds")

# Save workspace snapshot (optional)
save.image(file.path(outdir, "workspace_after_analysis.RData"))

# Final: list saved files
message("Files saved to outputs/:")
print(list.files(outdir, full.names = TRUE))

