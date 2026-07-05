# Power BI & DAX Guide — HR Workforce Analytics (Global)

## 1. Data Model

```
departments (1) ──< job_roles (1) ──< employees
                                          │
                                          ├──< salary_history
                                          │
                                          └──< performance_reviews

locations (1) ──< employees
```

Relationships:
- `departments[department_id]` → `job_roles[department_id]`
- `job_roles[role_id]` → `employees[role_id]`
- `departments[department_id]` → `employees[department_id]`
- `locations[location_id]` → `employees[location_id]`
- `employees[employee_id]` → `salary_history[employee_id]`
- `employees[employee_id]` → `performance_reviews[employee_id]`

Create two **Date tables**: one for `employees[hire_date]` (active) and one for `employees[termination_date]` (inactive, use USERELATIONSHIP in attrition measures). Or use a single Date table and manage with USERELATIONSHIP.

---

## 2. Key DAX Measures

### Headcount
```dax
Total Headcount =
CALCULATE(COUNTROWS(employees), employees[employment_status] = "Active")

Total Ever Employed =
COUNTROWS(employees)

New Hires =
CALCULATE(
    COUNTROWS(employees),
    USERELATIONSHIP('Date'[Date], employees[hire_date])
)

Headcount Target =
SUM(departments[head_count_target])

Headcount vs Target =
[Total Headcount] - [Headcount Target]
```

### Attrition
```dax
Total Exits =
CALCULATE(COUNTROWS(employees), employees[employment_status] <> "Active")

Attrition Rate % =
DIVIDE([Total Exits], [Total Ever Employed], 0)

Voluntary Attrition Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(employees), employees[termination_reason] = "Voluntary"),
    [Total Ever Employed], 0
)

Avg Tenure (Leavers) Years =
AVERAGEX(
    FILTER(employees, employees[employment_status] <> "Active"),
    DATEDIFF(employees[hire_date], employees[termination_date], DAY) / 365.25
)

Avg Tenure (Active) Years =
AVERAGEX(
    FILTER(employees, employees[employment_status] = "Active"),
    DATEDIFF(employees[hire_date], TODAY(), DAY) / 365.25
)
```

### Compensation
```dax
-- Use latest salary record per employee
Avg Base Salary =
AVERAGEX(
    VALUES(salary_history[employee_id]),
    CALCULATE(
        MAX(salary_history[base_salary]),
        TOPN(1, salary_history, salary_history[effective_date], DESC)
    )
)

Total Salary Spend =
SUMX(
    VALUES(salary_history[employee_id]),
    CALCULATE(
        MAX(salary_history[base_salary]),
        TOPN(1, salary_history, salary_history[effective_date], DESC)
    )
)

Total Comp Spend =
SUMX(
    VALUES(salary_history[employee_id]),
    VAR LatestSal =
        CALCULATE(
            MAXX(salary_history, salary_history[base_salary]),
            TOPN(1, salary_history, salary_history[effective_date], DESC)
        )
    VAR LatestBonus =
        CALCULATE(
            MAXX(salary_history, salary_history[bonus_pct]),
            TOPN(1, salary_history, salary_history[effective_date], DESC)
        )
    RETURN LatestSal * (1 + LatestBonus / 100)
)

Budget Utilisation % =
DIVIDE([Total Comp Spend], SUM(departments[budget_annual]), 0)

Gender Pay Gap % =
VAR MaleAvg = CALCULATE([Avg Base Salary], employees[gender] = "Male")
VAR FemaleAvg = CALCULATE([Avg Base Salary], employees[gender] = "Female")
RETURN DIVIDE(MaleAvg - FemaleAvg, MaleAvg, 0)
```

### Performance
```dax
Avg Performance Score =
AVERAGE(performance_reviews[score])

Exceeds Rating % =
DIVIDE(
    CALCULATE(COUNTROWS(performance_reviews), performance_reviews[rating] = "Exceeds"),
    COUNTROWS(performance_reviews), 0
)

PIP Count =
CALCULATE(COUNTROWS(performance_reviews), performance_reviews[rating] = "PIP")

Promotion Pipeline Count =
CALCULATE(
    DISTINCTCOUNT(performance_reviews[employee_id]),
    performance_reviews[manager_recommendation] = "Promote"
)

High Performers (Score >= 4) =
CALCULATE(
    COUNTROWS(performance_reviews),
    performance_reviews[score] >= 4
)
```

### Diversity
```dax
Female % =
DIVIDE(
    CALCULATE(COUNTROWS(employees), employees[gender] = "Female"),
    [Total Headcount], 0
)

Remote Workers % =
DIVIDE(
    CALCULATE(COUNTROWS(employees), employees[work_mode] = "Remote"),
    [Total Headcount], 0
)

Leadership Female % =
DIVIDE(
    CALCULATE(
        COUNTROWS(employees),
        employees[gender] = "Female",
        job_roles[job_level] IN {"Director", "VP"}
    ),
    CALCULATE(
        COUNTROWS(employees),
        job_roles[job_level] IN {"Director", "VP"}
    ), 0
)
```

### Time Intelligence
```dax
New Hires MTD =
CALCULATE(
    [New Hires],
    DATESMTD('Date'[Date])
)

Attrition Rate YoY % =
VAR PriorYear = CALCULATE([Attrition Rate %], SAMEPERIODLASTYEAR('Date'[Date]))
RETURN DIVIDE([Attrition Rate %] - PriorYear, PriorYear, 0)

12M Cohort Retention % =
CALCULATE(
    DIVIDE(
        CALCULATE(COUNTROWS(employees), employees[employment_status] = "Active"),
        COUNTROWS(employees)
    ),
    DATESINPERIOD('Date'[Date], LASTDATE('Date'[Date]), -12, MONTH)
)
```

---

## 3. Calculated Columns

```dax
-- Age band
Age Band =
VAR Age = DATEDIFF(employees[date_of_birth], TODAY(), YEAR)
RETURN SWITCH(TRUE(),
    Age < 25, "Gen Z (<25)",
    Age < 35, "Millennial (25-34)",
    Age < 45, "Millennial (35-44)",
    Age < 55, "Gen X (45-54)",
    "Boomer (55+)"
)

-- Tenure bucket
Tenure Bucket =
VAR End = IF(ISBLANK(employees[termination_date]), TODAY(), employees[termination_date])
VAR Yrs = DATEDIFF(employees[hire_date], End, DAY) / 365.25
RETURN SWITCH(TRUE(),
    Yrs < 1, "< 1 Year",
    Yrs < 3, "1-3 Years",
    Yrs < 5, "3-5 Years",
    Yrs < 10, "5-10 Years",
    "10+ Years"
)

-- Is active flag
Is Active =
IF(employees[employment_status] = "Active", 1, 0)
```

---

## 4. Suggested Report Pages

1. **Workforce Overview** — KPI cards (Headcount, Attrition %, Avg Tenure, Avg Salary), headcount by department bar, region map, work mode donut.
2. **Attrition Deep Dive** — Monthly exits trend, reason breakdown (Voluntary/Layoff/Performance/Retirement), attrition by department and tenure bucket, early attrition (<1yr) flag.
3. **Compensation & Budget** — Avg salary by job level and department, gender pay gap waterfall, budget utilisation % by dept, salary distribution box plot (use scatter approximation).
4. **Performance & Talent** — Rating distribution by dept (stacked bar), avg score trend by year, promotion pipeline table, high performers at risk (filtered table).
5. **Diversity & Inclusion** — Gender split by level (stacked bar), Female % in leadership KPI, age band pie, work mode by region matrix, nationality diversity index.

---

## 5. Design Tips

- Use a **slicer panel** with Region, Department, Job Level, and Employment Status slicers that cascade — selecting Region should filter Department options.
- For gender pay gap, use a **waterfall chart** (male avg → gap → female avg) to make the comparison visually clear.
- For the attrition trend, show both the raw count (bar) and the rolling 3-month rate (line) on the same dual-axis chart.
- The performance-attrition connection is a compelling story: build a **scatter chart** of avg performance score (x) vs attrition rate (y) by department.
