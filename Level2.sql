SELECT d.dept_name, ROUND(AVG(e.base_salary),2) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

SELECT emp_name, performance_rating
FROM employees
WHERE performance_rating >= 4.5;

-- 3. Total hours per project
SELECT p.project_name, SUM(ep.hours_worked) AS total_hours
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_name;

SELECT emp_name, COUNT(project_id) AS project_count
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
GROUP BY emp_name
HAVING COUNT(project_id) > 1;

CREATE OR REPLACE FUNCTION calc_bonus()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.bonus IS NULL) THEN
     IF (SELECT performance_rating FROM employees WHERE emp_id = NEW.emp_id) > 4.5 THEN
        NEW.bonus := NEW.gross_salary * 0.10;
     ELSE
        NEW.bonus := NEW.gross_salary * 0.05;
     END IF;
  END IF;
  NEW.tax := NEW.gross_salary * 0.15;
  NEW.net_salary := NEW.gross_salary + NEW.bonus - NEW.tax;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payroll_bonus
BEFORE INSERT ON payroll
FOR EACH ROW EXECUTE FUNCTION calc_bonus();


INSERT INTO payroll (emp_id, month, gross_salary) VALUES (2, '2024-04-01', 8000);
SELECT * FROM payroll;
