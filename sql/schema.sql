-- ============================================================
-- HR Workforce Analytics (Global)
-- Database Schema
-- ============================================================

DROP TABLE IF EXISTS performance_reviews;
DROP TABLE IF EXISTS salary_history;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS job_roles;
DROP TABLE IF EXISTS locations;

-- ------------------------------------------------------------
-- 1. Locations (company offices globally)
-- ------------------------------------------------------------
CREATE TABLE locations (
    location_id      INT PRIMARY KEY AUTO_INCREMENT,
    city             VARCHAR(50) NOT NULL,
    country          VARCHAR(50) NOT NULL,
    region           VARCHAR(30) NOT NULL,   -- Americas / EMEA / APAC
    office_type      VARCHAR(20) NOT NULL    -- HQ / Regional / Remote Hub
);

-- ------------------------------------------------------------
-- 2. Departments
-- ------------------------------------------------------------
CREATE TABLE departments (
    department_id    INT PRIMARY KEY AUTO_INCREMENT,
    department_name  VARCHAR(50) NOT NULL,   -- Engineering, Sales, HR, Finance, etc.
    division         VARCHAR(30) NOT NULL,   -- Product / Revenue / Support / Operations
    budget_annual    DECIMAL(15,2) NOT NULL,
    head_count_target INT NOT NULL
);

-- ------------------------------------------------------------
-- 3. Job roles
-- ------------------------------------------------------------
CREATE TABLE job_roles (
    role_id          INT PRIMARY KEY AUTO_INCREMENT,
    role_title       VARCHAR(80) NOT NULL,
    job_level        VARCHAR(20) NOT NULL,   -- Junior / Mid / Senior / Lead / Manager / Director / VP
    department_id    INT NOT NULL,
    min_salary       DECIMAL(12,2) NOT NULL,
    max_salary       DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- ------------------------------------------------------------
-- 4. Employees: core dimension
-- ------------------------------------------------------------
CREATE TABLE employees (
    employee_id       INT PRIMARY KEY AUTO_INCREMENT,
    full_name         VARCHAR(100) NOT NULL,
    gender            VARCHAR(10) NOT NULL,
    date_of_birth     DATE NOT NULL,
    nationality       VARCHAR(50),
    hire_date         DATE NOT NULL,
    termination_date  DATE,                  -- NULL if still active
    employment_status VARCHAR(20) NOT NULL,  -- Active / Resigned / Terminated / Retired
    termination_reason VARCHAR(50),          -- Voluntary / Performance / Layoff / Retirement
    department_id     INT NOT NULL,
    role_id           INT NOT NULL,
    location_id       INT NOT NULL,
    manager_id        INT,                   -- Self-referential FK to employees
    work_mode         VARCHAR(20) NOT NULL,  -- On-site / Hybrid / Remote
    education_level   VARCHAR(30) NOT NULL,  -- Bachelor's / Master's / PhD / Diploma / High School
    years_experience  DECIMAL(4,1) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (role_id) REFERENCES job_roles(role_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- ------------------------------------------------------------
-- 5. Salary history (tracks changes over time)
-- ------------------------------------------------------------
CREATE TABLE salary_history (
    salary_id         INT PRIMARY KEY AUTO_INCREMENT,
    employee_id       INT NOT NULL,
    effective_date    DATE NOT NULL,
    base_salary       DECIMAL(12,2) NOT NULL,
    bonus_pct         DECIMAL(5,2) NOT NULL,  -- % of base
    currency          VARCHAR(5) NOT NULL DEFAULT 'USD',
    change_reason     VARCHAR(50),            -- Hire / Promotion / Merit Increase / Adjustment / Termination
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- ------------------------------------------------------------
-- 6. Performance reviews (annual)
-- ------------------------------------------------------------
CREATE TABLE performance_reviews (
    review_id           INT PRIMARY KEY AUTO_INCREMENT,
    employee_id          INT NOT NULL,
    review_year           INT NOT NULL,
    rating                VARCHAR(20) NOT NULL, -- Exceeds / Meets / Below / PIP
    score                  DECIMAL(3,1) NOT NULL, -- 1.0 to 5.0
    goals_met_pct          DECIMAL(5,2),           -- % of annual goals met
    manager_recommendation  VARCHAR(30),           -- Promote / Retain / PIP / Exit
    review_date             DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------
CREATE INDEX idx_emp_dept ON employees(department_id);
CREATE INDEX idx_emp_role ON employees(role_id);
CREATE INDEX idx_emp_location ON employees(location_id);
CREATE INDEX idx_emp_status ON employees(employment_status);
CREATE INDEX idx_emp_hire ON employees(hire_date);
CREATE INDEX idx_emp_term ON employees(termination_date);
CREATE INDEX idx_sal_emp ON salary_history(employee_id);
CREATE INDEX idx_review_emp ON performance_reviews(employee_id);
CREATE INDEX idx_review_year ON performance_reviews(review_year);
