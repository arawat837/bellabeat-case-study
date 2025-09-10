 Bellabeat Case Study – Google Data Analytics Capstone
📌 Project Overview

This project analyzes Fitbit fitness tracker data to uncover trends in daily activity, sleep, calories, weight, and heart rate.

The goal is to generate insights and provide actionable recommendations for Bellabeat, a high-tech company that manufactures health-focused smart devices for women.

The case study follows the Google Data Analytics Capstone framework:
Ask → Prepare → Process → Analyze → Share → Act

📊 Dataset

Source: Fitbit Fitness Tracker Dataset on Kaggle

Users: 33 unique individuals

Timeframe: March–May 2016

Note:

❌ Raw data is not included in this repository due to size.

Please download directly from Kaggle to reproduce the analysis.

This repo contains only scripts, outputs (charts/tables), and the final report/presentation.

🛠️ Tools & Methods

Tools: RStudio

Packages: tidyverse, lubridate, ggplot2, janitor, skimr

Steps:

Parsed and standardized date/time columns

Removed duplicates

Aggregated sleep (minute → daily totals)

Aggregated heart rate (seconds → daily averages)

Merged datasets by User ID + Date

Exported cleaned summaries → used for visualization & analysis

🔍 Key Findings

Daily Activity: Average steps < 10,000/day; activity higher on weekdays than weekends.

Calories vs Steps: Strong positive correlation → steps are a reliable predictor of calorie burn.

Sleep Patterns: Average sleep = 5–7 hrs/night (below recommended 7–8 hrs). Weak positive link with steps.

Activity Intensity: Majority of user time is sedentary.

Weight Tracking: Very few users log weight or BMI consistently.

Heart Rate: Group averages stable, but individual variability suggests personalization opportunities.

✅ Recommendations

Encourage daily movement with step reminders & challenges

Promote active breaks to reduce sedentary time

Enhance sleep coaching features (bedtime reminders, tips, insights)

Boost weekend activity with gamified challenges

Improve weight tracking adoption (smart scale integration, easier logging)

Personalize heart rate insights for fitness and stress management

📜 License

This project is for educational purposes as part of the Google Data Analytics Capstone.
Dataset © Fitbit via Kaggle.
Code, outputs, and documentation are released under the MIT License.
