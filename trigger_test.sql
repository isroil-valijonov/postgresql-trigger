-- Xodimlar ma'lumotlarini kiritish
INSERT INTO Employee (name, salary, birth_date, level)
VALUES ('John Doe', 5000, '1990-10-15', 'JUNIOR'),
       ('Jane Smith', 6000, '1985-06-20', 'MIDDLE'),
       ('Robert Brown', 7000, '1987-04-18', 'SENIOR');

SELECT update_employee_salary_based_on_level(3, 'JUNIOR');

-- Logni tekshirish uchun
SELECT * FROM Employee_Log;

-- Xodimlar jadvalini tekshirish
SELECT * FROM Employee;