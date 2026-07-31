# Sales Performance Analysis

## Project Overview

This project analyzes sales performance beyond revenue.

Instead of simply identifying who sold the most, the objective is to determine **which sales representatives acquired the most valuable customers** by combining customer acquisition, initial revenue, and Customer Lifetime Value (LTV).

---

## Business Question

> **Who are the company's best sales representatives?**

To answer this question, I evaluated sales performance using four business KPIs instead of revenue alone.

- Customers Acquired
- Initial Revenue
- Total Customer Lifetime Value (LTV)
- Average Customer Lifetime Value

---

## My Approach

The analysis followed these steps:

1. Audited the data to identify quality issues.
2. Defined business rules for customer acquisition.
3. Converted all revenue to USD.
4. Assigned each customer to the correct sales representative.
5. Calculated Customer Lifetime Value (LTV).
6. Built a Power BI dashboard to compare sales performance.

---

## Dashboard

![Sales Performance Dashboard](images/sales_performance_dashboard.png)

---

## Project Structure

```
sales-performance-analysis/
│
├── sql/
│   ├── 01_data_quality_checks.sql
│   ├── 02_business_rules_and_attribution.sql
│   ├── 03_customer_ltv_calculation.sql
│   └── 04_sales_performance_analysis.sql
│
├── docs/
│
└── images/
```

---

## Tools Used

- SQL Server
- T-SQL
- Power BI
- Git
- GitHub

---

## Key Takeaways

This project demonstrates how business rules can improve sales performance evaluation.

Instead of ranking sales representatives only by revenue, the analysis incorporates customer quality through Lifetime Value (LTV), providing a more complete view of long-term business impact.

---

## Author

**Yxel Morillo**

Business Analyst | Data Analyst

- LinkedIn: https://www.linkedin.com/in/yxel-morillo/
- GitHub: https://github.com/yxelmorillo
