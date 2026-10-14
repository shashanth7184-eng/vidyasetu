-- VidyaSetu Phase 1 schema
-- Run this in the Supabase SQL Editor for a new project.
-- All personal student records are protected by row-level security.
-- New accounts receive the least-privileged parent role until an admin assigns
-- their school and role. Bootstrap the first admin from the SQL Editor after
-- creating the first school and signing in once; do not grant admin from the UI.
-- Example (replace both UUIDs with values from public.schools and auth.users):
-- UPDATE public.profiles
-- SET role = 'admin', school_id = '00000000-0000-0000-0000-000000000000'
-- WHERE id = '00000000-0000-0000-0000-000000000000';

DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin', 'teacher', 'volunteer', 'parent');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.reading_level AS ENUM ('beginner', 'letter', 'word', 'paragraph', 'story');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.math_level AS ENUM ('beginner', 'number_recognition', 'addition', 'subtraction', 'division');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.attendance_status AS ENUM ('present', 'absent');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.resource_type AS ENUM ('pdf', 'audio', 'video', 'worksheet');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.dropout_flag_status AS ENUM ('open', 'in_progress', 'resolved');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.schools (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  village text NOT NULL,
  district text NOT NULL,
  state text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  role public.app_role NOT NULL DEFAULT 'parent',
  phone text,
  school_id uuid REFERENCES public.schools(id) ON DELETE SET NULL,
  village text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  grade smallint NOT NULL CHECK (grade BETWEEN 1 AND 12),
  section text NOT NULL DEFAULT 'A',
  teacher_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, grade, section)
);

CREATE TABLE IF NOT EXISTS public.students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  gender text,
  dob date,
  class_id uuid NOT NULL REFERENCES public.classes(id) ON DELETE RESTRICT,
  parent_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  guardian_phone text,
  village text,
  enrolled_on date NOT NULL DEFAULT CURRENT_DATE,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  assessed_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  reading_level public.reading_level NOT NULL,
  math_level public.math_level NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  date date NOT NULL DEFAULT CURRENT_DATE,
  status public.attendance_status NOT NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_id, date)
);

CREATE TABLE IF NOT EXISTS public.tutoring_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  volunteer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  subject text NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  duration_min integer NOT NULL CHECK (duration_min > 0),
  topic text,
  outcome_notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.learning_centers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  village text NOT NULL,
  schedule text NOT NULL,
  volunteer_lead_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  capacity integer NOT NULL CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.center_enrollments (
  center_id uuid NOT NULL REFERENCES public.learning_centers(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  enrolled_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (center_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  subject text NOT NULL,
  grade smallint NOT NULL CHECK (grade BETWEEN 1 AND 12),
  type public.resource_type NOT NULL,
  file_url text NOT NULL,
  language text NOT NULL DEFAULT 'en',
  offline_available boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dropout_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  risk_score numeric(5, 4) NOT NULL CHECK (risk_score BETWEEN 0 AND 1),
  reasons text[] NOT NULL DEFAULT '{}',
  flagged_on date NOT NULL DEFAULT CURRENT_DATE,
  status public.dropout_flag_status NOT NULL DEFAULT 'open',
  action_taken text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS profiles_school_id_idx ON public.profiles(school_id);
CREATE INDEX IF NOT EXISTS classes_school_grade_idx ON public.classes(school_id, grade);
CREATE INDEX IF NOT EXISTS classes_teacher_id_idx ON public.classes(teacher_id);
CREATE INDEX IF NOT EXISTS students_class_active_idx ON public.students(class_id, active);
CREATE INDEX IF NOT EXISTS students_parent_id_idx ON public.students(parent_id);
CREATE INDEX IF NOT EXISTS assessments_student_date_idx ON public.assessments(student_id, date DESC);
CREATE INDEX IF NOT EXISTS attendance_student_date_idx ON public.attendance(student_id, date DESC);
CREATE INDEX IF NOT EXISTS attendance_date_status_idx ON public.attendance(date, status);
CREATE INDEX IF NOT EXISTS tutoring_volunteer_date_idx ON public.tutoring_sessions(volunteer_id, date DESC);
CREATE INDEX IF NOT EXISTS tutoring_student_date_idx ON public.tutoring_sessions(student_id, date DESC);
CREATE INDEX IF NOT EXISTS centers_village_idx ON public.learning_centers(village);
CREATE INDEX IF NOT EXISTS center_enrollments_student_idx ON public.center_enrollments(student_id);
CREATE INDEX IF NOT EXISTS resources_subject_grade_idx ON public.resources(subject, grade);
CREATE INDEX IF NOT EXISTS dropout_flags_status_risk_idx ON public.dropout_flags(status, risk_score DESC);
CREATE INDEX IF NOT EXISTS dropout_flags_student_date_idx ON public.dropout_flags(student_id, flagged_on DESC);

-- SECURITY DEFINER helpers avoid recursive RLS checks while keeping policies
-- readable. They expose only the current caller's role and permitted relations.
CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS public.app_role
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT p.role FROM public.profiles AS p WHERE p.id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.current_profile_school_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT p.school_id FROM public.profiles AS p WHERE p.id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.current_profile_village()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT p.village FROM public.profiles AS p WHERE p.id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT COALESCE(public.current_app_role() = 'admin'::public.app_role, false)
$$;

CREATE OR REPLACE FUNCTION public.is_teacher_for_school(target_school_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT COALESCE(
    public.current_app_role() = 'teacher'::public.app_role
    AND public.current_profile_school_id() = target_school_id,
    false
  )
$$;

CREATE OR REPLACE FUNCTION public.is_parent_of_student(target_student_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.students AS s
    WHERE s.id = target_student_id AND s.parent_id = auth.uid()
  )
$$;

CREATE OR REPLACE FUNCTION public.is_teacher_for_student(target_student_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.students AS s
    JOIN public.classes AS c ON c.id = s.class_id
    WHERE s.id = target_student_id
      AND public.is_teacher_for_school(c.school_id)
  )
$$;

CREATE OR REPLACE FUNCTION public.is_volunteer_assigned_to_student(target_student_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT COALESCE(
    public.current_app_role() = 'volunteer'::public.app_role
    AND (
      EXISTS (
        SELECT 1
        FROM public.center_enrollments AS ce
        JOIN public.learning_centers AS lc ON lc.id = ce.center_id
        WHERE ce.student_id = target_student_id
          AND lc.volunteer_lead_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.tutoring_sessions AS ts
        WHERE ts.student_id = target_student_id
          AND ts.volunteer_id = auth.uid()
      )
    ),
    false
  )
$$;

CREATE OR REPLACE FUNCTION public.can_view_student(target_student_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT public.is_admin()
    OR public.is_teacher_for_student(target_student_id)
    OR public.is_parent_of_student(target_student_id)
    OR public.is_volunteer_assigned_to_student(target_student_id)
$$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
DECLARE
  generated_name text;
BEGIN
  generated_name := COALESCE(
    NULLIF(NEW.raw_user_meta_data ->> 'full_name', ''),
    NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''),
    NULLIF(NEW.phone, ''),
    'New user'
  );

  INSERT INTO public.profiles (id, full_name, role, phone)
  VALUES (NEW.id, generated_name, 'parent', NEW.phone)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_profile_assignment_fields()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
BEGIN
  IF auth.uid() = OLD.id AND NOT public.is_admin()
     AND (NEW.role IS DISTINCT FROM OLD.role
          OR NEW.school_id IS DISTINCT FROM OLD.school_id) THEN
    RAISE EXCEPTION 'Only an administrator can change a profile role or school.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

DROP TRIGGER IF EXISTS protect_profile_assignment_fields ON public.profiles;
CREATE TRIGGER protect_profile_assignment_fields
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_assignment_fields();

ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tutoring_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.center_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dropout_flags ENABLE ROW LEVEL SECURITY;

-- Schools
DROP POLICY IF EXISTS schools_select_visible ON public.schools;
CREATE POLICY schools_select_visible ON public.schools
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR public.current_profile_school_id() = id
    OR EXISTS (
      SELECT 1
      FROM public.students AS s
      JOIN public.classes AS c ON c.id = s.class_id
      WHERE s.parent_id = auth.uid() AND c.school_id = schools.id
    )
  );
DROP POLICY IF EXISTS schools_admin_manage ON public.schools;
CREATE POLICY schools_admin_manage ON public.schools
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Profiles: users can read their own row, teachers can see their school team,
-- and only admins can create accounts, change roles/schools, or delete profiles.
DROP POLICY IF EXISTS profiles_select_allowed ON public.profiles;
CREATE POLICY profiles_select_allowed ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR public.is_admin()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND school_id = public.current_profile_school_id()
    )
  );
DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = public.current_app_role()
    AND school_id IS NOT DISTINCT FROM public.current_profile_school_id()
  );
DROP POLICY IF EXISTS profiles_admin_manage ON public.profiles;
CREATE POLICY profiles_admin_manage ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Classes
DROP POLICY IF EXISTS classes_select_allowed ON public.classes;
CREATE POLICY classes_select_allowed ON public.classes
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_school(school_id)
    OR EXISTS (
      SELECT 1 FROM public.students AS s
      WHERE s.class_id = classes.id AND public.is_parent_of_student(s.id)
    )
    OR EXISTS (
      SELECT 1 FROM public.students AS s
      WHERE s.class_id = classes.id AND public.is_volunteer_assigned_to_student(s.id)
    )
  );
DROP POLICY IF EXISTS classes_teacher_manage ON public.classes;
CREATE POLICY classes_teacher_manage ON public.classes
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_school(school_id))
  WITH CHECK (public.is_admin() OR public.is_teacher_for_school(school_id));

-- Students
DROP POLICY IF EXISTS students_select_allowed ON public.students;
CREATE POLICY students_select_allowed ON public.students
  FOR SELECT TO authenticated
  USING (public.can_view_student(id));
DROP POLICY IF EXISTS students_teacher_insert ON public.students;
CREATE POLICY students_teacher_insert ON public.students
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.classes AS c
      WHERE c.id = students.class_id AND public.is_teacher_for_school(c.school_id)
    )
  );
DROP POLICY IF EXISTS students_teacher_update ON public.students;
CREATE POLICY students_teacher_update ON public.students
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(id))
  WITH CHECK (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.classes AS c
      WHERE c.id = students.class_id AND public.is_teacher_for_school(c.school_id)
    )
  );
DROP POLICY IF EXISTS students_teacher_delete ON public.students;
CREATE POLICY students_teacher_delete ON public.students
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(id));

-- Assessments
DROP POLICY IF EXISTS assessments_select_allowed ON public.assessments;
CREATE POLICY assessments_select_allowed ON public.assessments
  FOR SELECT TO authenticated
  USING (public.can_view_student(student_id));
DROP POLICY IF EXISTS assessments_teacher_insert ON public.assessments;
CREATE POLICY assessments_teacher_insert ON public.assessments
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS assessments_teacher_update ON public.assessments;
CREATE POLICY assessments_teacher_update ON public.assessments
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id))
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS assessments_teacher_delete ON public.assessments;
CREATE POLICY assessments_teacher_delete ON public.assessments
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id));

-- Attendance
DROP POLICY IF EXISTS attendance_select_allowed ON public.attendance;
CREATE POLICY attendance_select_allowed ON public.attendance
  FOR SELECT TO authenticated
  USING (public.can_view_student(student_id));
DROP POLICY IF EXISTS attendance_teacher_insert ON public.attendance;
CREATE POLICY attendance_teacher_insert ON public.attendance
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS attendance_teacher_update ON public.attendance;
CREATE POLICY attendance_teacher_update ON public.attendance
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id))
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS attendance_teacher_delete ON public.attendance;
CREATE POLICY attendance_teacher_delete ON public.attendance
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id));

-- Tutoring sessions: volunteers can record their own sessions for assigned
-- students; parents can read their child's session history.
DROP POLICY IF EXISTS tutoring_sessions_select_allowed ON public.tutoring_sessions;
CREATE POLICY tutoring_sessions_select_allowed ON public.tutoring_sessions
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR public.is_parent_of_student(student_id)
    OR (volunteer_id = auth.uid() AND public.is_volunteer_assigned_to_student(student_id))
  );
DROP POLICY IF EXISTS tutoring_sessions_insert_allowed ON public.tutoring_sessions;
CREATE POLICY tutoring_sessions_insert_allowed ON public.tutoring_sessions
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR (
      volunteer_id = auth.uid()
      AND public.is_volunteer_assigned_to_student(student_id)
    )
  );
DROP POLICY IF EXISTS tutoring_sessions_update_allowed ON public.tutoring_sessions;
CREATE POLICY tutoring_sessions_update_allowed ON public.tutoring_sessions
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR (volunteer_id = auth.uid() AND public.is_volunteer_assigned_to_student(student_id))
  )
  WITH CHECK (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR (
      volunteer_id = auth.uid()
      AND public.is_volunteer_assigned_to_student(student_id)
    )
  );
DROP POLICY IF EXISTS tutoring_sessions_delete_allowed ON public.tutoring_sessions;
CREATE POLICY tutoring_sessions_delete_allowed ON public.tutoring_sessions
  FOR DELETE TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR (volunteer_id = auth.uid() AND public.is_volunteer_assigned_to_student(student_id))
  );

-- Learning centers
DROP POLICY IF EXISTS learning_centers_select_allowed ON public.learning_centers;
CREATE POLICY learning_centers_select_allowed ON public.learning_centers
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR volunteer_lead_id = auth.uid()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND village = public.current_profile_village()
    )
    OR EXISTS (
      SELECT 1
      FROM public.center_enrollments AS ce
      JOIN public.students AS s ON s.id = ce.student_id
      WHERE ce.center_id = learning_centers.id
        AND public.is_teacher_for_student(s.id)
    )
  );
DROP POLICY IF EXISTS learning_centers_insert_allowed ON public.learning_centers;
CREATE POLICY learning_centers_insert_allowed ON public.learning_centers
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND village = public.current_profile_village()
    )
  );
DROP POLICY IF EXISTS learning_centers_update_allowed ON public.learning_centers;
CREATE POLICY learning_centers_update_allowed ON public.learning_centers
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND village = public.current_profile_village()
    )
    OR volunteer_lead_id = auth.uid()
  )
  WITH CHECK (
    public.is_admin()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND village = public.current_profile_village()
    )
    OR volunteer_lead_id = auth.uid()
  );
DROP POLICY IF EXISTS learning_centers_delete_allowed ON public.learning_centers;
CREATE POLICY learning_centers_delete_allowed ON public.learning_centers
  FOR DELETE TO authenticated
  USING (
    public.is_admin()
    OR (
      public.current_app_role() = 'teacher'::public.app_role
      AND village = public.current_profile_village()
    )
  );

-- Center enrollments
DROP POLICY IF EXISTS center_enrollments_select_allowed ON public.center_enrollments;
CREATE POLICY center_enrollments_select_allowed ON public.center_enrollments
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR public.is_parent_of_student(student_id)
    OR EXISTS (
      SELECT 1 FROM public.learning_centers AS lc
      WHERE lc.id = center_enrollments.center_id
        AND lc.volunteer_lead_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS center_enrollments_insert_allowed ON public.center_enrollments;
CREATE POLICY center_enrollments_insert_allowed ON public.center_enrollments
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
  );
DROP POLICY IF EXISTS center_enrollments_delete_allowed ON public.center_enrollments;
CREATE POLICY center_enrollments_delete_allowed ON public.center_enrollments
  FOR DELETE TO authenticated
  USING (
    public.is_admin()
    OR public.is_teacher_for_student(student_id)
    OR EXISTS (
      SELECT 1 FROM public.learning_centers AS lc
      WHERE lc.id = center_enrollments.center_id
        AND lc.volunteer_lead_id = auth.uid()
    )
  );

-- Learning resources are shared across roles after sign-in; only admins
-- maintain the catalog and storage references.
DROP POLICY IF EXISTS resources_select_authenticated ON public.resources;
CREATE POLICY resources_select_authenticated ON public.resources
  FOR SELECT TO authenticated
  USING (true);
DROP POLICY IF EXISTS resources_admin_manage ON public.resources;
CREATE POLICY resources_admin_manage ON public.resources
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Dropout risk details are limited to admins and teachers at the student's school.
DROP POLICY IF EXISTS dropout_flags_select_allowed ON public.dropout_flags;
CREATE POLICY dropout_flags_select_allowed ON public.dropout_flags
  FOR SELECT TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS dropout_flags_teacher_insert ON public.dropout_flags;
CREATE POLICY dropout_flags_teacher_insert ON public.dropout_flags
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS dropout_flags_teacher_update ON public.dropout_flags;
CREATE POLICY dropout_flags_teacher_update ON public.dropout_flags
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id))
  WITH CHECK (public.is_admin() OR public.is_teacher_for_student(student_id));
DROP POLICY IF EXISTS dropout_flags_teacher_delete ON public.dropout_flags;
CREATE POLICY dropout_flags_teacher_delete ON public.dropout_flags
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_teacher_for_student(student_id));

GRANT USAGE ON SCHEMA public TO authenticated;
REVOKE ALL ON
  public.schools,
  public.profiles,
  public.classes,
  public.students,
  public.assessments,
  public.attendance,
  public.tutoring_sessions,
  public.learning_centers,
  public.center_enrollments,
  public.resources,
  public.dropout_flags
FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON
  public.schools,
  public.profiles,
  public.classes,
  public.students,
  public.assessments,
  public.attendance,
  public.tutoring_sessions,
  public.learning_centers,
  public.center_enrollments,
  public.resources,
  public.dropout_flags
TO authenticated;

REVOKE ALL ON FUNCTION public.current_app_role() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.current_profile_school_id() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.current_profile_village() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_teacher_for_school(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_parent_of_student(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_teacher_for_student(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_volunteer_assigned_to_student(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_view_student(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.protect_profile_assignment_fields() FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.current_app_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_profile_school_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_profile_village() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_teacher_for_school(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_parent_of_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_teacher_for_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_volunteer_assigned_to_student(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_view_student(uuid) TO authenticated;
