\# Bellabeat Case Study – Google Data Analytics Capstone



\## 📌 Project Overview

This project analyzes \*\*Fitbit fitness tracker data\*\* to uncover trends in user activity, sleep, calories, weight, and heart rate.  

The goal is to generate insights and provide \*\*actionable recommendations\*\* for Bellabeat, a high-tech company that manufactures health-focused smart devices for women.



The case study follows the \*\*Google Data Analytics Capstone framework\*\*:  

\*\*Ask → Prepare → Process → Analyze → Share → Act\*\*



---



\## 📊 Dataset

\- \*\*Source:\*\* \[Fitbit Fitness Tracker Dataset on Kaggle](https://www.kaggle.com/datasets/arashnic/fitbit)  

\- \*\*Users:\*\* 33 unique individuals  

\- \*\*Timeframe:\*\* March–May 2016  

\- \*\*Important:\*\*  

&nbsp; - ❌ Raw data is \*\*not included in this repository\*\* (due to size).  

&nbsp; - To reproduce analysis, please download the dataset directly from Kaggle.  

&nbsp; - This repo contains \*\*only scripts, visual outputs, and the final report/presentation\*\*.



---



\## 🛠️ Tools \& Methods

\- \*\*Tools:\*\* RStudio  

\- \*\*Libraries:\*\* tidyverse, lubridate, ggplot2, janitor, skimr  

\- \*\*Data Preparation Steps:\*\*  

&nbsp; - Parsed and standardized date/time columns  

&nbsp; - Removed duplicates  

&nbsp; - Aggregated sleep (minute → daily)  

&nbsp; - Aggregated heart rate (seconds → daily average)  

&nbsp; - Merged datasets by User ID and Date  

&nbsp; - Exported cleaned/aggregated results to CSV and used for analysis  



---



\## 🔍 Key Findings

1\. \*\*Daily Activity:\*\* Users average < 10,000 steps/day; activity higher on weekdays.  

2\. \*\*Calories vs Steps:\*\* Strong positive correlation → steps are reliable calorie predictor.  

3\. \*\*Sleep Patterns:\*\* Avg 5–7 hrs/night, below recommended 7–8 hrs. Weak positive correlation with steps.  

4\. \*\*Activity Intensity:\*\* Majority of time spent sedentary.  

5\. \*\*Weight Tracking:\*\* Very few users log weight/BMI consistently.  

6\. \*\*Heart Rate:\*\* Population averages stable, but individual variability suggests potential for personalization.  



---



\## ✅ Recommendations

\- Encourage \*\*daily movement\*\* with step reminders \& challenges.  

\- Promote \*\*active breaks\*\* to reduce sedentary time.  

\- Enhance \*\*sleep coaching features\*\* with reminders \& insights.  

\- Boost \*\*weekend activity\*\* with gamified challenges.  

\- Improve \*\*weight tracking adoption\*\* (smart scale integration).  

\- Personalize \*\*heart rate insights\*\* for fitness and stress management.  



---



\## 📂 Repository Structure



