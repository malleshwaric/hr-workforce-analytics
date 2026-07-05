"""
HR Workforce Analytics (Global)
Synthetic Data Generator

Usage:
    pip install faker numpy pandas
    python generate_data.py
"""

import random
import os
import numpy as np
import pandas as pd
from datetime import date, timedelta
from faker import Faker

fake = Faker()
Faker.seed(99)
random.seed(99)
np.random.seed(99)

OUTPUT_DIR = "../data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ------------------------------------------------------------
# 1. Locations
# ------------------------------------------------------------
locations_data = [
    (1, "New York", "USA", "Americas", "HQ"),
    (2, "San Francisco", "USA", "Americas", "Regional"),
    (3, "Toronto", "Canada", "Americas", "Regional"),
    (4, "São Paulo", "Brazil", "Americas", "Remote Hub"),
    (5, "London", "UK", "EMEA", "Regional"),
    (6, "Berlin", "Germany", "EMEA", "Regional"),
    (7, "Dubai", "UAE", "EMEA", "Remote Hub"),
    (8, "Johannesburg", "South Africa", "EMEA", "Remote Hub"),
    (9, "Bengaluru", "India", "APAC", "Regional"),
    (10, "Singapore", "Singapore", "APAC", "Regional"),
    (11, "Tokyo", "Japan", "APAC", "Remote Hub"),
    (12, "Sydney", "Australia", "APAC", "Remote Hub"),
]
locations_df = pd.DataFrame(locations_data, columns=["location_id","city","country","region","office_type"])
locations_df.to_csv(f"{OUTPUT_DIR}/locations.csv", index=False)

# ------------------------------------------------------------
# 2. Departments
# ------------------------------------------------------------
dept_data = [
    (1, "Engineering",        "Product",    12000000, 120),
    (2, "Product Management", "Product",    3000000,  25),
    (3, "Data & Analytics",   "Product",    4000000,  40),
    (4, "Sales",              "Revenue",    8000000,  80),
    (5, "Marketing",          "Revenue",    5000000,  45),
    (6, "Customer Success",   "Support",    4500000,  55),
    (7, "Human Resources",    "Operations", 2500000,  20),
    (8, "Finance",            "Operations", 3000000,  25),
    (9, "Legal & Compliance", "Operations", 2000000,  15),
    (10,"Operations",         "Operations", 3500000,  35),
]
departments_df = pd.DataFrame(dept_data, columns=["department_id","department_name","division","budget_annual","head_count_target"])
departments_df.to_csv(f"{OUTPUT_DIR}/departments.csv", index=False)

# ------------------------------------------------------------
# 3. Job roles
# ------------------------------------------------------------
LEVELS = ["Junior","Mid","Senior","Lead","Manager","Director","VP"]
LEVEL_SALARY = {
    "Junior":   (45000, 70000),
    "Mid":      (70000, 110000),
    "Senior":   (110000, 160000),
    "Lead":     (140000, 190000),
    "Manager":  (130000, 180000),
    "Director": (180000, 250000),
    "VP":       (240000, 350000),
}
role_templates = {
    1: ["Software Engineer", "Backend Engineer", "Frontend Engineer", "DevOps Engineer"],
    2: ["Product Manager", "Associate PM"],
    3: ["Data Analyst", "Data Scientist", "Analytics Engineer"],
    4: ["Account Executive", "Sales Development Rep", "Sales Manager"],
    5: ["Marketing Manager", "Growth Analyst", "Content Strategist"],
    6: ["Customer Success Manager", "Support Specialist"],
    7: ["HR Business Partner", "Recruiter", "L&D Specialist"],
    8: ["Financial Analyst", "Accountant", "FP&A Manager"],
    9: ["Legal Counsel", "Compliance Analyst"],
    10:["Operations Analyst", "Project Manager", "Ops Manager"],
}
roles = []
role_id = 1
for dept_id, titles in role_templates.items():
    for title in titles:
        for level in LEVELS[:5]:  # Junior to Manager
            lo, hi = LEVEL_SALARY[level]
            roles.append({
                "role_id": role_id,
                "role_title": f"{level} {title}" if level not in ["Manager","Director","VP"] else f"{title} {level}",
                "job_level": level,
                "department_id": dept_id,
                "min_salary": lo,
                "max_salary": hi,
            })
            role_id += 1
        for level in ["Director", "VP"]:
            lo, hi = LEVEL_SALARY[level]
            roles.append({
                "role_id": role_id,
                "role_title": f"{title} {level}",
                "job_level": level,
                "department_id": dept_id,
                "min_salary": lo,
                "max_salary": hi,
            })
            role_id += 1
roles_df = pd.DataFrame(roles)
roles_df.to_csv(f"{OUTPUT_DIR}/job_roles.csv", index=False)

# ------------------------------------------------------------
# 4. Employees
# ------------------------------------------------------------
N_EMP = 3000
GENDERS = ["Male", "Female", "Non-binary"]
GENDER_W = [0.51, 0.44, 0.05]
WORK_MODES = ["On-site", "Hybrid", "Remote"]
WORK_W = [0.25, 0.48, 0.27]
EDUCATION = ["High School", "Diploma", "Bachelor's", "Master's", "PhD"]
EDU_W = [0.05, 0.08, 0.52, 0.30, 0.05]
TERM_REASONS = ["Voluntary", "Performance", "Layoff", "Retirement"]
TERM_W = [0.58, 0.18, 0.16, 0.08]

dept_roles = roles_df.groupby("department_id")["role_id"].apply(list).to_dict()

employees = []
for eid in range(1, N_EMP + 1):
    dept = departments_df.sample(1).iloc[0]
    role_pool = dept_roles.get(dept["department_id"], roles_df["role_id"].tolist())
    role_id_sel = random.choice(role_pool)
    role = roles_df[roles_df.role_id == role_id_sel].iloc[0]
    location = locations_df.sample(1).iloc[0]

    hire_date = fake.date_between(start_date="-10y", end_date="-1m")
    dob = fake.date_of_birth(minimum_age=22, maximum_age=62)
    years_exp = round(random.uniform(0.5, min(30, (date.today() - hire_date).days / 365 + 3)), 1)

    # Attrition: ~22% leave overall
    is_terminated = random.random() < 0.22
    termination_date = None
    termination_reason = None
    status = "Active"
    if is_terminated:
        max_term_days = max(91, (date.today() - hire_date).days - 30)
        term_days = random.randint(90, max_term_days)
        termination_date = hire_date + timedelta(days=term_days)
        termination_reason = random.choices(TERM_REASONS, weights=TERM_W)[0]
        status = {"Voluntary": "Resigned", "Performance": "Terminated",
                  "Layoff": "Terminated", "Retirement": "Retired"}.get(termination_reason, "Terminated")

    employees.append({
        "employee_id": eid,
        "full_name": fake.name(),
        "gender": random.choices(GENDERS, weights=GENDER_W)[0],
        "date_of_birth": dob,
        "nationality": fake.country(),
        "hire_date": hire_date,
        "termination_date": termination_date,
        "employment_status": status,
        "termination_reason": termination_reason,
        "department_id": dept["department_id"],
        "role_id": role_id_sel,
        "location_id": location["location_id"],
        "manager_id": None,  # will fill below
        "work_mode": random.choices(WORK_MODES, weights=WORK_W)[0],
        "education_level": random.choices(EDUCATION, weights=EDU_W)[0],
        "years_experience": years_exp,
    })

# Assign manager_ids from Senior+ employees
employees_df = pd.DataFrame(employees)
senior_ids = employees_df[employees_df["role_id"].isin(
    roles_df[roles_df["job_level"].isin(["Senior","Lead","Manager","Director","VP"])]["role_id"]
)]["employee_id"].tolist()
for i, row in employees_df.iterrows():
    if senior_ids and row["employee_id"] not in senior_ids[:50]:
        employees_df.at[i, "manager_id"] = random.choice(senior_ids[:200])

employees_df.to_csv(f"{OUTPUT_DIR}/employees.csv", index=False)

# ------------------------------------------------------------
# 5. Salary history
# ------------------------------------------------------------
salary_records = []
sal_id = 1
CHANGE_REASONS = ["Hire", "Promotion", "Merit Increase", "Adjustment"]

for _, emp in employees_df.iterrows():
    role = roles_df[roles_df.role_id == emp["role_id"]].iloc[0]
    base = round(np.random.uniform(role["min_salary"], role["max_salary"]), -2)
    bonus_pct = round(random.uniform(5, 25), 1)

    salary_records.append({
        "salary_id": sal_id, "employee_id": emp["employee_id"],
        "effective_date": emp["hire_date"], "base_salary": base,
        "bonus_pct": bonus_pct, "currency": "USD", "change_reason": "Hire"
    })
    sal_id += 1

    # 0-3 additional salary events during tenure
    end_date = emp["termination_date"] if emp["termination_date"] else date.today()
    tenure_days = (end_date - pd.to_datetime(emp["hire_date"]).date()).days
    n_changes = random.choices([0, 1, 2, 3], weights=[0.3, 0.35, 0.25, 0.10])[0]
    for j in range(n_changes):
        days_offset = random.randint(180, max(181, tenure_days - 30))
        change_date = pd.to_datetime(emp["hire_date"]).date() + timedelta(days=days_offset)
        if change_date >= end_date:
            continue
        reason = random.choices(CHANGE_REASONS[1:], weights=[0.3, 0.55, 0.15])[0]
        if reason == "Promotion":
            base = round(base * random.uniform(1.08, 1.18), -2)
        else:
            base = round(base * random.uniform(1.02, 1.07), -2)
        salary_records.append({
            "salary_id": sal_id, "employee_id": emp["employee_id"],
            "effective_date": change_date, "base_salary": min(base, role["max_salary"] * 1.05),
            "bonus_pct": round(random.uniform(5, 30), 1), "currency": "USD", "change_reason": reason
        })
        sal_id += 1

salary_df = pd.DataFrame(salary_records)
salary_df.to_csv(f"{OUTPUT_DIR}/salary_history.csv", index=False)

# ------------------------------------------------------------
# 6. Performance reviews (annual, last 4 years)
# ------------------------------------------------------------
reviews = []
rev_id = 1
RATINGS = ["Exceeds", "Meets", "Below", "PIP"]
RATING_W = [0.20, 0.60, 0.14, 0.06]
RECOMMENDATIONS = ["Promote", "Retain", "PIP", "Exit"]

for _, emp in employees_df.iterrows():
    hire_yr = pd.to_datetime(emp["hire_date"]).year
    end_yr = pd.to_datetime(emp["termination_date"]).year if emp["termination_date"] else date.today().year
    for yr in range(max(hire_yr + 1, date.today().year - 3), min(end_yr + 1, date.today().year)):
        rating = random.choices(RATINGS, weights=RATING_W)[0]
        score = round({
            "Exceeds": random.uniform(4.0, 5.0),
            "Meets":   random.uniform(2.8, 3.9),
            "Below":   random.uniform(1.8, 2.7),
            "PIP":     random.uniform(1.0, 1.7),
        }[rating], 1)
        recommendation = {
            "Exceeds": random.choices(["Promote","Retain"], weights=[0.55, 0.45])[0],
            "Meets":   "Retain",
            "Below":   random.choices(["Retain","PIP"], weights=[0.4, 0.6])[0],
            "PIP":     random.choices(["PIP","Exit"], weights=[0.5, 0.5])[0],
        }[rating]
        reviews.append({
            "review_id": rev_id,
            "employee_id": emp["employee_id"],
            "review_year": yr,
            "rating": rating,
            "score": score,
            "goals_met_pct": round(random.uniform(40, 100), 1),
            "manager_recommendation": recommendation,
            "review_date": date(yr, random.randint(11, 12), random.randint(1, 28)),
        })
        rev_id += 1

reviews_df = pd.DataFrame(reviews)
reviews_df.to_csv(f"{OUTPUT_DIR}/performance_reviews.csv", index=False)

print("Data generation complete:")
print(f"  locations.csv          -> {len(locations_df)} rows")
print(f"  departments.csv        -> {len(departments_df)} rows")
print(f"  job_roles.csv          -> {len(roles_df)} rows")
print(f"  employees.csv          -> {len(employees_df)} rows")
print(f"  salary_history.csv     -> {len(salary_df)} rows")
print(f"  performance_reviews.csv-> {len(reviews_df)} rows")
