-- School module schema (multi-tenant)
-- Conventions:
-- - Every table includes tenant_id and composite primary key on (tenant_id, id)
-- - Required metadata columns: created_by, assignee_id, shared_with
-- - All FKs include tenant_id to avoid cross-tenant references

BEGIN;

-- Ensure required extensions (safe if already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- Root School entity (for manifest form/list)
-- =====================================================================

CREATE TABLE IF NOT EXISTS school_schools (
    tenant_id       UUID            NOT NULL,
    id              UUID            NOT NULL DEFAULT uuid_generate_v4(),
    code            VARCHAR(64),
    name            VARCHAR(255)    NOT NULL,
    display_name    VARCHAR(255),
    principal_name  VARCHAR(255),
    address         VARCHAR(500),
    phone           VARCHAR(50),
    email           VARCHAR(255),
    website         VARCHAR(255),
    description     TEXT,

    created_by      UUID,
    assignee_id     UUID,
    shared_with     UUID[],

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX IF NOT EXISTS idx_school_schools_code ON school_schools(tenant_id, code);
CREATE INDEX IF NOT EXISTS idx_school_schools_name ON school_schools(tenant_id, name);

-- =====================================================================
-- Core entities
-- =====================================================================

-- Subjects offered in the school
CREATE TABLE IF NOT EXISTS school_subjects (
    tenant_id      UUID            NOT NULL,
    id             UUID            NOT NULL DEFAULT uuid_generate_v4(),
    code           VARCHAR(64)     NOT NULL,
    name           VARCHAR(255)    NOT NULL,
    description    TEXT,

    -- required metadata
    created_by     UUID,
    assignee_id    UUID,
    shared_with    UUID[],

    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_subject_code_per_tenant UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_school_subjects_name ON school_subjects(tenant_id, name);

-- Teachers
CREATE TABLE IF NOT EXISTS school_teachers (
    tenant_id      UUID            NOT NULL,
    id             UUID            NOT NULL DEFAULT uuid_generate_v4(),
    code           VARCHAR(64),
    first_name     VARCHAR(100)    NOT NULL,
    last_name      VARCHAR(100)    NOT NULL,
    email          VARCHAR(255),
    phone          VARCHAR(50),
    hire_date      DATE,

    -- required metadata
    created_by     UUID,
    assignee_id    UUID,
    shared_with    UUID[],

    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_teacher_email_per_tenant UNIQUE (tenant_id, email)
);

CREATE INDEX IF NOT EXISTS idx_school_teachers_name ON school_teachers(tenant_id, last_name, first_name);

-- Classes (homerooms)
CREATE TABLE IF NOT EXISTS school_classes (
    tenant_id            UUID            NOT NULL,
    id                   UUID            NOT NULL DEFAULT uuid_generate_v4(),
    code                 VARCHAR(64)     NOT NULL,
    name                 VARCHAR(255)    NOT NULL,
    grade_level          SMALLINT,
    homeroom_teacher_id  UUID,

    -- required metadata
    created_by           UUID,
    assignee_id          UUID,
    shared_with          UUID[],

    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_class_code_per_tenant UNIQUE (tenant_id, code),
    CONSTRAINT fk_class_homeroom_teacher
        FOREIGN KEY (tenant_id, homeroom_teacher_id)
        REFERENCES school_teachers(tenant_id, id)
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_school_classes_name ON school_classes(tenant_id, name);

-- Students
CREATE TABLE IF NOT EXISTS school_students (
    tenant_id      UUID            NOT NULL,
    id             UUID            NOT NULL DEFAULT uuid_generate_v4(),
    code           VARCHAR(64),
    first_name     VARCHAR(100)    NOT NULL,
    last_name      VARCHAR(100)    NOT NULL,
    dob            DATE,
    email          VARCHAR(255),
    phone          VARCHAR(50),

    -- required metadata
    created_by     UUID,
    assignee_id    UUID,
    shared_with    UUID[],

    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_student_email_per_tenant UNIQUE (tenant_id, email)
);

CREATE INDEX IF NOT EXISTS idx_school_students_name ON school_students(tenant_id, last_name, first_name);

-- Enrollment of students to classes (many-to-many over time)
CREATE TABLE IF NOT EXISTS school_enrollments (
    tenant_id   UUID        NOT NULL,
    student_id  UUID        NOT NULL,
    class_id    UUID        NOT NULL,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    active      BOOLEAN     NOT NULL DEFAULT TRUE,

    -- required metadata
    created_by  UUID,
    assignee_id UUID,
    shared_with UUID[],

    PRIMARY KEY (tenant_id, student_id, class_id),
    CONSTRAINT fk_enroll_student
        FOREIGN KEY (tenant_id, student_id)
        REFERENCES school_students(tenant_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_enroll_class
        FOREIGN KEY (tenant_id, class_id)
        REFERENCES school_classes(tenant_id, id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_school_enrollments_class ON school_enrollments(tenant_id, class_id);

-- Subject assignment to classes (which subjects a class studies)
CREATE TABLE IF NOT EXISTS school_class_subjects (
    tenant_id   UUID    NOT NULL,
    class_id    UUID    NOT NULL,
    subject_id  UUID    NOT NULL,

    -- required metadata
    created_by  UUID,
    assignee_id UUID,
    shared_with UUID[],

    PRIMARY KEY (tenant_id, class_id, subject_id),
    CONSTRAINT fk_cs_class
        FOREIGN KEY (tenant_id, class_id)
        REFERENCES school_classes(tenant_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cs_subject
        FOREIGN KEY (tenant_id, subject_id)
        REFERENCES school_subjects(tenant_id, id)
        ON DELETE CASCADE
);

-- Timetable slots for each class/subject/teacher
CREATE TABLE IF NOT EXISTS school_timetable (
    tenant_id   UUID            NOT NULL,
    id          UUID            NOT NULL DEFAULT uuid_generate_v4(),
    class_id    UUID            NOT NULL,
    subject_id  UUID            NOT NULL,
    teacher_id  UUID            NOT NULL,
    day_of_week SMALLINT        NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    starts_at   TIME            NOT NULL,
    ends_at     TIME            NOT NULL,

    -- required metadata
    created_by  UUID,
    assignee_id UUID,
    shared_with UUID[],

    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT fk_tt_class
        FOREIGN KEY (tenant_id, class_id)
        REFERENCES school_classes(tenant_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tt_subject
        FOREIGN KEY (tenant_id, subject_id)
        REFERENCES school_subjects(tenant_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tt_teacher
        FOREIGN KEY (tenant_id, teacher_id)
        REFERENCES school_teachers(tenant_id, id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_time_order CHECK (starts_at < ends_at)
);

CREATE INDEX IF NOT EXISTS idx_school_timetable_class_day ON school_timetable(tenant_id, class_id, day_of_week);

-- Grades
CREATE TABLE IF NOT EXISTS school_grades (
    tenant_id   UUID        NOT NULL,
    id          UUID        NOT NULL DEFAULT uuid_generate_v4(),
    student_id  UUID        NOT NULL,
    subject_id  UUID        NOT NULL,
    term        VARCHAR(32) NOT NULL, -- e.g. "2025_S1"
    score       NUMERIC(5,2),
    comment     TEXT,

    -- required metadata
    created_by  UUID,
    assignee_id UUID,
    shared_with UUID[],

    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_grade_student_subject_term UNIQUE (tenant_id, student_id, subject_id, term),
    CONSTRAINT fk_grade_student
        FOREIGN KEY (tenant_id, student_id)
        REFERENCES school_students(tenant_id, id)
        ON DELETE CASCADE,
    CONSTRAINT fk_grade_subject
        FOREIGN KEY (tenant_id, subject_id)
        REFERENCES school_subjects(tenant_id, id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_school_grades_student ON school_grades(tenant_id, student_id);

-- Touch-up triggers for updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_subjects_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_subjects_updated_at BEFORE UPDATE ON school_subjects
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_schools_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_schools_updated_at BEFORE UPDATE ON school_schools
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_teachers_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_teachers_updated_at BEFORE UPDATE ON school_teachers
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_classes_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_classes_updated_at BEFORE UPDATE ON school_classes
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_students_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_students_updated_at BEFORE UPDATE ON school_students
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_timetable_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_timetable_updated_at BEFORE UPDATE ON school_timetable
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

DO $$ BEGIN
    PERFORM 1 FROM pg_trigger WHERE tgname = 't_school_grades_updated_at';
    IF NOT FOUND THEN
        CREATE TRIGGER t_school_grades_updated_at BEFORE UPDATE ON school_grades
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

COMMIT;


