# 📉 E-Commerce Churn Intelligence: Strategic RFM Segmentation
**Analytical Tool:** Microsoft SQL Server (SSMS) | **Data Scale:** 100,000+ Records

## 🚀 Project Impact
This project transforms raw transactional data into a **Retention Strategy**. By building an RFM (Recency, Frequency, Monetary) model, I identified that **36% of the customer base is currently lost (Hibernating)**, representing a $5.6M revenue gap.

## 🗄️ Relational Data Architecture
Below is the relational schema designed in SSMS to handle the complex Olist dataset. This structure allows for deep-dive analysis across customers, orders, and payments.
![Database Schema](Database_Schema_Diagram.png)

## 🛠️ Advanced SQL Techniques Used
- **CTEs (Common Table Expressions):** Modularized complex logic for RFM calculation.
- **Statistical Window Functions (NTILE):** Segmented 96k users into statistical quintiles.
- **Advanced Joins:** Merged 9 relational tables to track the customer journey.

## 🏁 Final Segmentation Results
The model categorized the customer base into 5 strategic segments:
![Segmentation Results](Churn_Segments_Results.png)

### 💡 Strategic Recommendations:
- **Champions:** Focus on 'Loyalty Rewards' to maintain high-value engagement.
- **At Risk:** Immediate re-engagement campaigns needed for these high-historical-value users.
- **Lost:** Analyze shipping friction (Logistics) to prevent future churn in this segment.
