CREATE TABLE COURSE (
    CourseNo NUMBER PRIMARY KEY,
    Description VARCHAR2(100),
    Cost NUMBER(10,2),
    Prerequisite NUMBER,
    CONSTRAINT fk_course_prerequisite
        FOREIGN KEY (Prerequisite)
        REFERENCES COURSE(CourseNo)
);

CREATE TABLE INSTRUCTOR (
    InstructorID NUMBER PRIMARY KEY,
    FirstName VARCHAR2(50),
    LastName VARCHAR2(50)
);
CREATE TABLE STUDENT (
    StudentID NUMBER PRIMARY KEY,
    FirstName VARCHAR2(50),
    LastName VARCHAR2(50),
    RegistrationDate DATE
);
CREATE TABLE CLASS (
    ClassID NUMBER PRIMARY KEY,
    CourseNo NUMBER,
    ClassNo NUMBER,
    StartDateTime DATE,
    InstructorID NUMBER,
    Capacity NUMBER,
    
    CONSTRAINT fk_class_course
        FOREIGN KEY (CourseNo)
        REFERENCES COURSE(CourseNo),

    CONSTRAINT fk_class_instructor
        FOREIGN KEY (InstructorID)
        REFERENCES INSTRUCTOR(InstructorID)
);
CREATE TABLE ENROLLMENT (
    StudentID NUMBER,
    ClassID NUMBER,
    EnrollDate DATE,
    FinalGrade NUMBER(5,2),

    CONSTRAINT pk_enrollment PRIMARY KEY (StudentID, ClassID),

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (StudentID)
        REFERENCES STUDENT(StudentID),

    CONSTRAINT fk_enrollment_class
        FOREIGN KEY (ClassID)
        REFERENCES CLASS(ClassID)
);
CREATE TABLE GRADE (
    StudentID NUMBER,
    ClassID NUMBER,
    Grade VARCHAR2(2),
    Comments VARCHAR2(255),

    CONSTRAINT pk_grade PRIMARY KEY (StudentID, ClassID),

    CONSTRAINT fk_grade_enrollment
        FOREIGN KEY (StudentID, ClassID)
        REFERENCES ENROLLMENT(StudentID, ClassID)
);

CREATE TABLE Cau1 (
    ID NUMBER,
    NAME VARCHAR2(50)
);

CREATE SEQUENCE Cau1Seq
START WITH 1
INCREMENT BY 1;

SET SERVEROUTPUT ON;

DECLARE
    v_name VARCHAR2(100);
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    -- [d] SV đăng ký nhiều môn nhất
    SELECT firstname || ' ' || lastname
    INTO v_name
    FROM student
    WHERE studentid = (
        SELECT studentid
        FROM enrollment
        GROUP BY studentid
        HAVING COUNT(*) = (
            SELECT MAX(COUNT(*))
            FROM enrollment
            GROUP BY studentid
        )
        FETCH FIRST 1 ROWS ONLY
    );

    INSERT INTO Cau1 VALUES (Cau1Seq.NEXTVAL, v_name);
    SAVEPOINT sp_a;

    -- [e] SV đăng ký ít môn nhất
    SELECT firstname || ' ' || lastname
    INTO v_name
    FROM student
    WHERE studentid = (
        SELECT studentid
        FROM enrollment
        GROUP BY studentid
        HAVING COUNT(*) = (
            SELECT MIN(COUNT(*))
            FROM enrollment
            GROUP BY studentid
        )
        FETCH FIRST 1 ROWS ONLY
    );

    INSERT INTO Cau1 VALUES (Cau1Seq.NEXTVAL, v_name);
    SAVEPOINT sp_b;

    -- [f] GV dạy nhiều lớp nhất
    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM class
        GROUP BY instructorid
        HAVING COUNT(*) = (
            SELECT MAX(COUNT(*))
            FROM class
            GROUP BY instructorid
        )
        FETCH FIRST 1 ROWS ONLY
    );

    INSERT INTO Cau1 VALUES (Cau1Seq.NEXTVAL, v_name);
    SAVEPOINT sp_c;

    -- [g] Lấy ID vừa insert
    SELECT id INTO v_id
    FROM Cau1
    WHERE name = v_name;

    DBMS_OUTPUT.PUT_LINE('ID GV nhiều lớp: ' || v_id);

    -- [h] rollback
    ROLLBACK TO sp_b;

    -- [i] GV ít lớp nhất (dùng lại ID)
    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM class
        GROUP BY instructorid
        HAVING COUNT(*) = (
            SELECT MIN(COUNT(*))
            FROM class
            GROUP BY instructorid
        )
        FETCH FIRST 1 ROWS ONLY
    );

    INSERT INTO Cau1 VALUES (v_id, v_name);

    -- [j] thêm lại GV nhiều lớp
    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM class
        GROUP BY instructorid
        HAVING COUNT(*) = (
            SELECT MAX(COUNT(*))
            FROM class
            GROUP BY instructorid
        )
        FETCH FIRST 1 ROWS ONLY
    );

    INSERT INTO Cau1 VALUES (Cau1Seq.NEXTVAL, v_name);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        ROLLBACK;
END;
/

SET SERVEROUTPUT ON;

DECLARE
    v_check NUMBER;
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    SELECT COUNT(*) INTO v_check
    FROM instructor
    WHERE instructorid = &ma_giao_vien;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Không tìm thấy giáo viên');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM class
    WHERE instructorid = &ma_giao_vien;

    DBMS_OUTPUT.PUT_LINE('Số lớp: ' || v_count);
END;
/
select * from INSTRUCTOR
select * from CLASS
SET SERVEROUTPUT ON;

DECLARE
    v_sid NUMBER := &ma_sinh_vien;
    v_cid NUMBER := &ma_lop;

    v_score NUMBER;
    v_grade VARCHAR2(2);
    v_check NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);    
    SELECT COUNT(*) INTO v_check
    FROM student
    WHERE studentid = v_sid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loi: Ma sinh vien ' || v_sid || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_check
    FROM class
    WHERE classid = v_cid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loi: Ma lop ' || v_cid || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT finalgrade
    INTO v_score
    FROM enrollment
    WHERE studentid = v_sid AND classid = v_cid;

    CASE
        WHEN v_score >= 90 THEN v_grade := 'A';
        WHEN v_score >= 80 THEN v_grade := 'B';
        WHEN v_score >= 70 THEN v_grade := 'C';
        WHEN v_score >= 50 THEN v_grade := 'D';
        ELSE v_grade := 'F';
    END CASE;

    DBMS_OUTPUT.PUT_LINE(
        'Diem so: ' || v_score || ' -> Diem chu: ' || v_grade
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'Sinh vien chua dang ky lop nay hoac chua co diem!'
        );
END;
/
select * from class
DECLARE
    CURSOR cur_course IS
        SELECT courseno, description FROM course;

    CURSOR cur_class(p_courseno NUMBER) IS
        SELECT c.classno, COUNT(e.studentid) AS so_sv
        FROM class c
        LEFT JOIN enrollment e ON c.classid = e.classid
        WHERE c.courseno = p_courseno
        GROUP BY c.classno;

BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    FOR course_rec IN cur_course LOOP
        DBMS_OUTPUT.PUT_LINE(course_rec.courseno || ' ' || course_rec.description);

        FOR class_rec IN cur_class(course_rec.courseno) LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  Lop: ' || class_rec.classno ||
                ' - SV: ' || class_rec.so_sv
            );
        END LOOP;
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE find_sname(
    i_student_id IN NUMBER,
    o_first OUT VARCHAR2,
    o_last OUT VARCHAR2
)
IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    SELECT firstname, lastname
    INTO o_first, o_last
    FROM student
    WHERE studentid = i_student_id;
END;
/
DECLARE
    v_first VARCHAR2(50);
    v_last VARCHAR2(50);
BEGIN
    find_sname(102, v_first, v_last);
    DBMS_OUTPUT.PUT_LINE(v_first || ' ' || v_last);
END;
/

CREATE OR REPLACE PROCEDURE print_student_name(i_student_id IN NUMBER)
IS
    v_first VARCHAR2(50);
    v_last VARCHAR2(50);
BEGIN
    find_sname(i_student_id, v_first, v_last);
    DBMS_OUTPUT.PUT_LINE(v_first || ' ' || v_last);
END;
/

BEGIN
    print_student_name(101);
END;
/

CREATE OR REPLACE FUNCTION total_cost_for_student(p_student_id NUMBER)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    SELECT SUM(c.cost)
    INTO v_total
    FROM enrollment e
    JOIN class cl ON e.classid = cl.classid
    JOIN course c ON cl.courseno = c.courseno
    WHERE e.studentid = p_student_id;

    RETURN NVL(v_total, 0);
END;
/


CREATE OR REPLACE PROCEDURE Discount
IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
    FOR rec IN (
        SELECT c.courseno, c.description, c.cost
        FROM course c
        WHERE (
            SELECT COUNT(*)
            FROM enrollment e
            JOIN class cl ON e.classid = cl.classid
            WHERE cl.courseno = c.courseno
        ) > 15
    ) LOOP

        -- Giảm giá 5%
        UPDATE course
        SET cost = cost * 0.95
        WHERE courseno = rec.courseno;

        DBMS_OUTPUT.PUT_LINE(
            'Da giam gia mon: ' || rec.description ||
            ' | Gia cu: ' || rec.cost ||
            ' | Gia moi: ' || ROUND(rec.cost * 0.95, 2)
        );

    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Hoan tat giam gia.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Loi: ' || SQLERRM);
END;


BEGIN
    Discount;
END;
/
SELECT total_cost_for_student(101) FROM dual;

CREATE OR REPLACE TRIGGER trg_student_audit
BEFORE INSERT OR UPDATE ON student
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by   := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by   := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_enrollment_audit
BEFORE INSERT OR UPDATE ON enrollment
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by   := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by   := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_instructor_audit
BEFORE INSERT OR UPDATE ON instructor
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by   := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by   := USER;
    :NEW.modified_date := SYSDATE;
END;
/
CREATE OR REPLACE TRIGGER trg_grade_audit
BEFORE INSERT OR UPDATE ON grade
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by   := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by   := USER;
    :NEW.modified_date := SYSDATE;
END;
/
