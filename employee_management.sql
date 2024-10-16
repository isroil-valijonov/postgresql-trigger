CREATE TYPE EMPLOYEE_LEVEL AS ENUM ('JUNIOR', 'MIDDLE', 'SENIOR', 'LEAD');

CREATE TABLE Employee
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    salary      NUMERIC(10, 2),
    birth_date  DATE,
    level       EMPLOYEE_LEVEL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Employee_Log
(
    log_id      SERIAL PRIMARY KEY,
    emp_id      INT REFERENCES Employee (id),
    old_salary  NUMERIC(10, 2),
    new_salary  NUMERIC(10, 2),
    old_level   EMPLOYEE_LEVEL,
    new_level   EMPLOYEE_LEVEL,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Daraja o'zgarishiga qarab xodimning maoshini yangilaydigan funksiya
CREATE OR REPLACE FUNCTION update_employee_salary_based_on_level(emp_id INT, new_level EMPLOYEE_LEVEL)
    RETURNS NUMERIC AS $$
DECLARE
    current_salary NUMERIC;
    new_salary NUMERIC;
    current_level EMPLOYEE_LEVEL;
    birth_month INT;
    current_month INT;
BEGIN
    -- Hozirgi maosh va darajani olish
    SELECT salary, level, EXTRACT(MONTH FROM birth_date)
    INTO current_salary, current_level, birth_month
    FROM Employee
    WHERE id = emp_id;

    -- Yangi darajaga qarab maoshni aniqlash
    CASE
        WHEN current_level = 'JUNIOR' AND new_level = 'MIDDLE' THEN new_salary := current_salary * 1.1; -- Oshirish
        WHEN current_level = 'MIDDLE' AND new_level = 'SENIOR' THEN new_salary := current_salary * 1.25; -- Oshirish
        WHEN current_level = 'SENIOR' AND new_level = 'LEAD' THEN new_salary := current_salary * 1.5; -- Oshirish

        WHEN current_level = 'MIDDLE' AND new_level = 'JUNIOR' THEN new_salary := current_salary * 0.9; -- Pasaytirish
        WHEN current_level = 'SENIOR' AND new_level = 'MIDDLE' THEN new_salary := current_salary * 0.8; -- Pasaytirish
        WHEN current_level = 'LEAD' AND new_level = 'SENIOR' THEN new_salary := current_salary * 0.75; -- Pasaytirish
        ELSE
            new_salary := current_salary;
        END CASE;

    -- Hozirgi oyning raqamini olish
    SELECT EXTRACT(MONTH FROM CURRENT_DATE) INTO current_month;

    -- Agar tug'ilgan oy hozirgi oygacha to'g'ri kelsa, bonus qo'shish
    IF birth_month = current_month THEN
        new_salary := new_salary * 1.5;
    END IF;

    -- Xodimning maoshini yangilash
    UPDATE Employee
    SET salary = new_salary,
        level = new_level,
        change_date = CURRENT_TIMESTAMP
    WHERE id = emp_id;

    RETURN new_salary;
END;
$$ LANGUAGE plpgsql;


-- Xodimning darajasi yoki maoshi o'zgarganda logga yozish uchun protsedura
CREATE OR REPLACE PROCEDURE log_employee_changes(emp_id INT, old_salary NUMERIC, new_salary NUMERIC, old_level EMPLOYEE_LEVEL, new_level EMPLOYEE_LEVEL)
    LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Employee_Log (emp_id, old_salary, new_salary, old_level, new_level, change_time)
    VALUES (emp_id, old_salary, new_salary, old_level, new_level, CURRENT_TIMESTAMP);
END;
$$;

-- trigger funksiyasi ya'ni logga yozish protsedurasini ishlatish
CREATE OR REPLACE FUNCTION trigger_employee_update()
    RETURNS TRIGGER AS $$
BEGIN
    -- Protsedurani chaqiramiz, eski va yangi ma'lumotlarni uzatamiz
    CALL log_employee_changes(NEW.id, OLD.salary, NEW.salary, OLD.level, NEW.level);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger - trigger funksiyasi qachon ishlashi
CREATE TRIGGER employee_level_change
    AFTER UPDATE OF level ON Employee
    FOR EACH ROW
    WHEN (OLD.level IS DISTINCT FROM NEW.level OR OLD.salary IS DISTINCT FROM NEW.salary)
EXECUTE FUNCTION trigger_employee_update();

