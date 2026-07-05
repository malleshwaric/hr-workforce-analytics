# HR Workforce Analytics — Global

## 🚀 Live Interactive Dashboard

**[View Dashboard →](https://malleshwaric.github.io/hr-workforce-analytics/dashboard.html)**

Fully interactive — charts, tabs, KPI cards. No login required, opens in any browser.

---


End-to-end HR analytics project simulating a global tech company's workforce data: headcount, attrition, compensation, performance reviews, and diversity. Built to demonstrate SQL, Python, and Power BI skills for a Data Analyst portfolio.

## Project Overview

An HR team wants to understand:
- What is our attrition rate, and which departments/roles are bleeding talent?
- Is there a gender pay gap across job levels?
- Who are the high performers at risk of leaving (not promoted despite strong reviews)?
- How is our budget distributed across departments?
- What does our diversity profile look like across regions and leadership levels?

## Tech Stack

- **Python** (pandas, numpy, faker) — synthetic data generation
- **SQL** (MySQL/PostgreSQL-compatible) — schema + analysis queries
- **Power BI** — DAX measures and dashboard guide

## Repository Structure

```
hr-workforce-analytics/
├── data/
│   ├── locations.csv
│   ├── departments.csv
│   ├── job_roles.csv
│   ├── employees.csv
│   ├── salary_history.csv
│   └── performance_reviews.csv
├── python/
│   └── generate_data.py
├── sql/
│   ├── schema.sql
│   └── analysis_queries.sql
├── powerbi/
│   └── DAX_Guide.md
└── README.md
```

## Data Model

6 tables, 3,000 employees across 12 global offices, 4 years of performance history:

- **locations** — 12 offices across Americas, EMEA, and APAC
- **departments** — 10 departments with annual budget and headcount targets
- **job_roles** — 196 roles across 7 levels (Junior → VP) with salary bands
- **employees** — full lifecycle: hire, role, location, work mode, termination reason (22% attrition)
- **salary_history** — full salary change history (Hire, Promotion, Merit Increase) in USD
- **performance_reviews** — annual review scores (1–5), ratings, and manager recommendations

Attrition, salary growth, and performance distributions are all modeled to be internally consistent — high performers have lower attrition, promotions lead to salary bumps, etc.

## How to Run

```bash
# 1. Generate data
cd python
pip install faker numpy pandas
python generate_data.py

# 2. Load into SQL
mysql -u user -p db < ../sql/schema.sql
# Import CSVs from /data

# 3. Run analysis
mysql -u user -p db < ../sql/analysis_queries.sql

# 4. Power BI
# Import CSVs or connect to DB. Follow powerbi/DAX_Guide.md.
```

## Key Analysis Questions Answered

1. What is the overall and department-level attrition rate?
2. What are the most common exit reasons (voluntary vs performance vs layoff)?
3. Is there a gender pay gap across job levels?
4. Which employees are high performers not yet promoted (flight risk)?
5. How does salary spend compare to department budget?
6. What is the work mode distribution (Remote/Hybrid/On-site) by region?
7. What does the 12-month cohort retention look like by hire year?
8. Who is in the promotion pipeline?

See `sql/analysis_queries.sql` for the full query set.

## Sample Insights (from generated data)

- Overall attrition is ~22%, with voluntary exits making up ~58% of all departures
- Junior and Mid-level roles show the highest early attrition (< 1 year)
- Engineering and Sales have the largest headcount but also highest absolute exits
- A meaningful gender pay gap exists at Senior+ levels — visible in the compensation page
- ~20% of active employees have a "Promote" manager recommendation but no recent salary bump

## Author

Malleshwari C — Data Analyst portfolio project.
See related: [ShopKart India](../shopkart-india-analytics) | [SwiftMove India](../swiftmove-india-analytics) | [Loan Risk India](../loan-risk-india) | [UPI Finance India](../upi-finance-india)
