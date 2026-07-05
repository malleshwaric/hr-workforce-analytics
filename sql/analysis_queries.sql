-- ============================================================
-- HR Workforce Analytics (Global)
-- Business Analysis Queries
-- ============================================================

-- 1. Overall headcount and attrition summary
SELECT
    d.department_name,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) AS active_count,
    COUNT(CASE WHEN e.employment_status != 'Active' THEN 1 END) AS terminated_count,
    COUNT(*) AS total_ever_employed,
    ROUND(COUNT(CASE WHEN e.employment_status != 'Active' THEN 1 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY attrition_rate_pct DESC;

-- 2. Monthly attrition trend (last 24 months)
SELECT
    DATE_FORMAT(termination_date, '%Y-%m') AS termination_month,
    termination_reason,
    COUNT(*) AS exits
FROM employees
WHERE termination_date IS NOT NULL
  AND termination_date >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
GROUP BY termination_month, termination_reason
ORDER BY termination_month;

-- 3. Average tenure by department (completed employees)
SELECT
    d.department_name,
    ROUND(AVG(DATEDIFF(COALESCE(e.termination_date, CURDATE()), e.hire_date) / 365.25), 2) AS avg_tenure_years,
    MIN(DATEDIFF(COALESCE(e.termination_date, CURDATE()), e.hire_date) / 365.25) AS min_tenure_years,
    MAX(DATEDIFF(COALESCE(e.termination_date, CURDATE()), e.hire_date) / 365.25) AS max_tenure_years
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_tenure_years;

-- 4. Gender pay gap analysis by job level
SELECT
    jr.job_level,
    e.gender,
    COUNT(*) AS employee_count,
    ROUND(AVG(sh.base_salary), 2) AS avg_base_salary,
    ROUND(MAX(sh.base_salary), 2) AS max_salary,
    ROUND(MIN(sh.base_salary), 2) AS min_salary
FROM employees e
JOIN salary_history sh ON e.employee_id = sh.employee_id
JOIN job_roles jr ON e.role_id = jr.role_id
WHERE e.employment_status = 'Active'
  AND sh.effective_date = (
      SELECT MAX(sh2.effective_date) FROM salary_history sh2 WHERE sh2.employee_id = e.employee_id
  )
GROUP BY jr.job_level, e.gender
ORDER BY jr.job_level, e.gender;

-- 5. Performance rating distribution by department
SELECT
    d.department_name,
    pr.rating,
    COUNT(*) AS count,
    ROUND(AVG(pr.score), 2) AS avg_score,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY d.department_name), 2) AS pct_of_dept
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE pr.review_year = YEAR(CURDATE()) - 1
GROUP BY d.department_name, pr.rating
ORDER BY d.department_name, pr.score DESC;

-- 6. High performers at risk of attrition (high score, long tenure, no recent promotion)
SELECT
    e.employee_id,
    e.full_name,
    d.department_name,
    jr.job_level,
    ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) AS tenure_years,
    pr.score AS latest_review_score,
    sh.base_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_roles jr ON e.role_id = jr.role_id
JOIN performance_reviews pr ON e.employee_id = pr.employee_id
JOIN salary_history sh ON e.employee_id = sh.employee_id
WHERE e.employment_status = 'Active'
  AND pr.score >= 4.0
  AND pr.review_year = YEAR(CURDATE()) - 1
  AND DATEDIFF(CURDATE(), e.hire_date) / 365.25 > 2
  AND sh.effective_date = (
      SELECT MAX(sh2.effective_date) FROM salary_history sh2 WHERE sh2.employee_id = e.employee_id
  )
  AND sh.change_reason NOT IN ('Promotion', 'Merit Increase')
ORDER BY pr.score DESC, tenure_years DESC;

-- 7. Salary budget utilisation by department
SELECT
    d.department_name,
    d.budget_annual,
    SUM(sh.base_salary * (1 + sh.bonus_pct / 100)) AS total_comp_spend,
    ROUND(SUM(sh.base_salary * (1 + sh.bonus_pct / 100)) / d.budget_annual * 100, 2) AS budget_used_pct
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN salary_history sh ON e.employee_id = sh.employee_id
WHERE e.employment_status = 'Active'
  AND sh.effective_date = (
      SELECT MAX(sh2.effective_date) FROM salary_history sh2 WHERE sh2.employee_id = e.employee_id
  )
GROUP BY d.department_name, d.budget_annual
ORDER BY budget_used_pct DESC;

-- 8. Work mode distribution (Remote vs Hybrid vs On-site) by region
SELECT
    l.region,
    e.work_mode,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY l.region), 2) AS pct_of_region
FROM employees e
JOIN locations l ON e.location_id = l.location_id
WHERE e.employment_status = 'Active'
GROUP BY l.region, e.work_mode
ORDER BY l.region, employee_count DESC;

-- 9. Promotion pipeline (Exceeds rating + Promote recommendation not yet promoted)
SELECT
    e.employee_id,
    e.full_name,
    d.department_name,
    jr.job_level AS current_level,
    pr.score,
    pr.manager_recommendation,
    sh.base_salary,
    ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) AS tenure_years
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
JOIN job_roles jr ON e.role_id = jr.role_id
JOIN salary_history sh ON e.employee_id = sh.employee_id
WHERE pr.review_year = YEAR(CURDATE()) - 1
  AND pr.manager_recommendation = 'Promote'
  AND e.employment_status = 'Active'
  AND sh.effective_date = (
      SELECT MAX(sh2.effective_date) FROM salary_history sh2 WHERE sh2.employee_id = e.employee_id
  )
ORDER BY pr.score DESC;

-- 10. New hire cohort retention (12-month survival by hire year)
SELECT
    YEAR(hire_date) AS hire_year,
    COUNT(*) AS hired,
    SUM(CASE WHEN employment_status = 'Active'
             OR DATEDIFF(COALESCE(termination_date, CURDATE()), hire_date) >= 365 THEN 1 ELSE 0 END) AS retained_12m,
    ROUND(SUM(CASE WHEN employment_status = 'Active'
                   OR DATEDIFF(COALESCE(termination_date, CURDATE()), hire_date) >= 365 THEN 1 ELSE 0 END)
              * 100.0 / COUNT(*), 2) AS retention_12m_pct
FROM employees
GROUP BY hire_year
ORDER BY hire_year;
