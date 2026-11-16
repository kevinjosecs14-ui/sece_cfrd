-- ====================================================================
-- SRI ESHWAR COLLEGE OF ENGINEERING
-- Centre for Research and Development
-- Centralized R&D Facility Management System Database Schema
-- ====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Departments Table
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    hod_name VARCHAR(100),
    contact_email VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. User Roles Enum & Profiles Table
CREATE TYPE user_role_type AS ENUM ('user', 'host', 'admin');

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    faculty_id VARCHAR(50) UNIQUE NOT NULL,
    role user_role_type DEFAULT 'user' NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    designation VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Facilities Table
CREATE TYPE facility_status_type AS ENUM ('Available', 'Reserved', 'In Use', 'Under Maintenance', 'Unavailable');

CREATE TABLE IF NOT EXISTS public.facilities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    location VARCHAR(150) NOT NULL,
    capacity INT DEFAULT 1,
    operating_hours VARCHAR(100) DEFAULT '08:30 AM - 05:30 PM',
    description TEXT,
    status facility_status_type DEFAULT 'Available',
    image_url TEXT,
    coordinator_name VARCHAR(100),
    coordinator_email VARCHAR(100),
    guidelines TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Equipment Table
CREATE TYPE equipment_status_type AS ENUM ('Available', 'In Use', 'Under Maintenance', 'Decommissioned');

CREATE TABLE IF NOT EXISTS public.equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    facility_id UUID REFERENCES public.facilities(id) ON DELETE CASCADE,
    model_number VARCHAR(100),
    specifications TEXT,
    status equipment_status_type DEFAULT 'Available',
    calibration_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Facility Requests Table
CREATE TYPE request_status_type AS ENUM (
    'Submitted', 
    'Under Review', 
    'Approved', 
    'Scheduled', 
    'In Progress', 
    'Completed', 
    'Rejected', 
    'On Hold', 
    'Additional Information Required', 
    'Cancelled'
);

CREATE TABLE IF NOT EXISTS public.facility_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_number VARCHAR(30) UNIQUE NOT NULL, -- e.g. SECE-RD-2026-001
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    facility_id UUID REFERENCES public.facilities(id) ON DELETE RESTRICT NOT NULL,
    title VARCHAR(255) NOT NULL,
    purpose TEXT NOT NULL,
    description TEXT NOT NULL,
    preferred_date DATE NOT NULL,
    preferred_start_time TIME NOT NULL,
    preferred_end_time TIME NOT NULL,
    expected_duration VARCHAR(50),
    equipment_required TEXT[],
    additional_requirements TEXT,
    document_attachment_url TEXT,
    status request_status_type DEFAULT 'Submitted' NOT NULL,
    coordinator_remarks TEXT,
    rejection_reason TEXT,
    allocated_date DATE,
    allocated_start_time TIME,
    allocated_end_time TIME,
    is_draft BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Request Status History Table
CREATE TABLE IF NOT EXISTS public.request_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES public.facility_requests(id) ON DELETE CASCADE NOT NULL,
    previous_status request_status_type,
    new_status request_status_type NOT NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Facility Allocations Table
CREATE TABLE IF NOT EXISTS public.facility_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES public.facility_requests(id) ON DELETE CASCADE NOT NULL,
    facility_id UUID REFERENCES public.facilities(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    allocated_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    allocated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'Confirmed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info', -- 'submitted', 'approved', 'rejected', 'allocated', 'info', etc.
    request_id UUID REFERENCES public.facility_requests(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Facility Maintenance Table
CREATE TABLE IF NOT EXISTS public.facility_maintenance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facility_id UUID REFERENCES public.facilities(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    performed_by VARCHAR(150),
    status VARCHAR(50) DEFAULT 'Scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Activity Logs Table
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. User Feedback Table
CREATE TABLE IF NOT EXISTS public.user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES public.facility_requests(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    facility_id UUID REFERENCES public.facilities(id) ON DELETE CASCADE NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_facility_requests_user ON public.facility_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_facility_requests_status ON public.facility_requests(status);
CREATE INDEX IF NOT EXISTS idx_facility_requests_facility ON public.facility_requests(facility_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_allocations_facility_date ON public.facility_allocations(facility_id, allocated_date);

-- Row Level Security (RLS) setup
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facility_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Sample Policies
-- Departments & Facilities & Equipment are readable by all authenticated users
CREATE POLICY "Public departments readable" ON public.departments FOR SELECT USING (true);
CREATE POLICY "Public facilities readable" ON public.facilities FOR SELECT USING (true);
CREATE POLICY "Public equipment readable" ON public.equipment FOR SELECT USING (true);

-- User Profiles
CREATE POLICY "Users can view own profile or Hosts can view all" ON public.profiles
    FOR SELECT USING (
        auth.uid() = id OR 
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Facility Requests
CREATE POLICY "Users can view own requests or Hosts can view all" ON public.facility_requests
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Users can insert own requests" ON public.facility_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own draft or pending requests" ON public.facility_requests
    FOR UPDATE USING (
        (auth.uid() = user_id AND status IN ('Submitted', 'On Hold', 'Additional Information Required')) OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

-- Notifications
CREATE POLICY "Users view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

<<<<<<< HEAD
-- ====================================================================
-- 8. RESEARCH & DEVELOPMENT TASK MANAGEMENT TABLES
-- ====================================================================

CREATE TYPE task_department_enum AS ENUM ('Research', 'Development');
CREATE TYPE task_priority_enum AS ENUM ('Low', 'Medium', 'High', 'Critical');
CREATE TYPE task_status_enum AS ENUM ('Pending', 'In Progress', 'Under Review', 'Completed', 'Revision Required', 'Overdue');

CREATE TABLE IF NOT EXISTS public.rd_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    department_type task_department_enum NOT NULL,
    academic_department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    academic_department_name VARCHAR(150),
    assigned_faculty_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_faculty_name VARCHAR(150) NOT NULL,
    assigned_faculty_code VARCHAR(50) NOT NULL,
    assigned_faculty_email VARCHAR(255) NOT NULL,
    priority task_priority_enum DEFAULT 'High' NOT NULL,
    status task_status_enum DEFAULT 'Pending' NOT NULL,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    assigned_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    submission_notes TEXT,
    submission_url TEXT,
    revision_feedback TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.task_progress_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES public.rd_tasks(id) ON DELETE CASCADE,
    updated_by_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    updated_by_name VARCHAR(150) NOT NULL,
    previous_status task_status_enum,
    new_status task_status_enum NOT NULL,
    previous_percentage INT DEFAULT 0,
    new_percentage INT NOT NULL,
    remarks TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for R&D Tasks
ALTER TABLE public.rd_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_progress_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Faculty can view own tasks or Hosts can view all" ON public.rd_tasks
    FOR SELECT USING (
        auth.uid() = assigned_faculty_id OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Faculty can update own assigned task progress" ON public.rd_tasks
    FOR UPDATE USING (
        auth.uid() = assigned_faculty_id OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Hosts can create and manage tasks" ON public.rd_tasks
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Task updates viewable by assigned faculty and hosts" ON public.task_progress_updates
    FOR SELECT USING (
        auth.uid() = updated_by_id OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Authenticated users can insert progress updates" ON public.task_progress_updates
    FOR INSERT WITH CHECK (auth.uid() = updated_by_id);

-- ====================================================================
-- 9. COLLEGE TRIP MANAGEMENT TABLES
-- ====================================================================

CREATE TYPE trip_status_enum AS ENUM ('Planning', 'Active', 'Completed', 'Cancelled');
CREATE TYPE trip_task_status_enum AS ENUM ('Not Started', 'In Progress', 'Pending', 'Completed');

CREATE TABLE IF NOT EXISTS public.college_trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_code VARCHAR(50) UNIQUE NOT NULL,
    trip_name VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    department VARCHAR(150),
    faculty_coordinator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    faculty_coordinator_name VARCHAR(150),
    budget_per_student NUMERIC(10, 2) DEFAULT 0.00,
    total_students_registered INT DEFAULT 0,
    status trip_status_enum DEFAULT 'Planning' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trip_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.college_trips(id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_to_name VARCHAR(150) NOT NULL,
    assigned_to_email VARCHAR(255) NOT NULL,
    status trip_task_status_enum DEFAULT 'Not Started' NOT NULL,
    due_date DATE,
    comments TEXT,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_by VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS public.trip_students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.college_trips(id) ON DELETE CASCADE,
    student_name VARCHAR(150) NOT NULL,
    roll_number VARCHAR(50) NOT NULL,
    department VARCHAR(100),
    year_of_study VARCHAR(50),
    contact_number VARCHAR(20),
    emergency_contact VARCHAR(20),
    dietary_or_medical_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trip_announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.college_trips(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    posted_by VARCHAR(150) NOT NULL,
    importance VARCHAR(20) DEFAULT 'Normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trip_task_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES public.trip_tasks(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES public.college_trips(id) ON DELETE CASCADE,
    updated_by_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    updated_by_name VARCHAR(150) NOT NULL,
    previous_status trip_task_status_enum NOT NULL,
    new_status trip_task_status_enum NOT NULL,
    comment TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for College Trips
ALTER TABLE public.college_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_task_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trips viewable by all authenticated users" ON public.college_trips FOR SELECT USING (true);
CREATE POLICY "Admin can manage college trips" ON public.college_trips FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
);

CREATE POLICY "Faculty view own assigned trip tasks or Admins view all" ON public.trip_tasks
    FOR SELECT USING (
        auth.uid() = assigned_to_id OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Faculty can update their assigned trip task status" ON public.trip_tasks
    FOR UPDATE USING (
        auth.uid() = assigned_to_id OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );

CREATE POLICY "Admins can manage all trip tasks" ON public.trip_tasks
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
    );




-- ====================================================================
-- SMART RESEARCH & DEVELOPMENT MANAGEMENT SYSTEM MODULE SCHEMA
-- ====================================================================

-- 1. Smart R&D Projects
CREATE TABLE IF NOT EXISTS public.smart_rd_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    domain VARCHAR(100) NOT NULL,
    lead_investigator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    lead_investigator_name VARCHAR(150) NOT NULL,
    team_members JSONB DEFAULT '[]'::jsonb,
    start_date DATE NOT NULL,
    target_launch_date DATE NOT NULL,
    budget_inr NUMERIC(15, 2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'Active',
    milestones JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Smart R&D Continuous Tasks
CREATE TABLE IF NOT EXISTS public.smart_rd_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_code VARCHAR(50) UNIQUE NOT NULL,
    project_id UUID REFERENCES public.smart_rd_projects(id) ON DELETE CASCADE,
    project_name VARCHAR(255) NOT NULL,
    task_title VARCHAR(255) NOT NULL,
    detailed_description TEXT,
    assigned_team_member_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_team_member_name VARCHAR(150) NOT NULL,
    assigned_team_member_email VARCHAR(255),
    task_priority VARCHAR(20) DEFAULT 'High',
    assigned_date DATE NOT NULL,
    start_date DATE NOT NULL,
    deadline DATE NOT NULL,
    expected_completion_date DATE NOT NULL,
    current_status VARCHAR(50) DEFAULT 'Assigned',
    completion_percentage INT DEFAULT 0,
    comments TEXT,
    uploaded_documents JSONB DEFAULT '[]'::jsonb,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_by VARCHAR(150),
    stages JSONB DEFAULT '[]'::jsonb,
    activity_history JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Smart R&D 18-Stage Research Papers
CREATE TABLE IF NOT EXISTS public.smart_rd_papers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    paper_code VARCHAR(50) UNIQUE NOT NULL,
    project_id UUID REFERENCES public.smart_rd_projects(id) ON DELETE SET NULL,
    title VARCHAR(300) NOT NULL,
    target_journal VARCHAR(200) NOT NULL,
    indexing VARCHAR(50) DEFAULT 'Scopus',
    lead_author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    lead_author_name VARCHAR(150) NOT NULL,
    co_authors JSONB DEFAULT '[]'::jsonb,
    current_stage_index INT DEFAULT 0,
    stages JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN DEFAULT FALSE,
    doi VARCHAR(150),
    publication_date DATE,
    confirmed_by VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Smart R&D 12-Stage Patent Pipeline
CREATE TABLE IF NOT EXISTS public.smart_rd_patents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patent_code VARCHAR(50) UNIQUE NOT NULL,
    patent_title VARCHAR(300) NOT NULL,
    inventors JSONB DEFAULT '[]'::jsonb,
    application_number VARCHAR(100),
    filing_date DATE,
    ip_disclosure_acknowledged BOOLEAN DEFAULT FALSE,
    current_stage_index INT DEFAULT 0,
    stages JSONB DEFAULT '[]'::jsonb,
    is_filed BOOLEAN DEFAULT FALSE,
    is_granted BOOLEAN DEFAULT FALSE,
    grant_number VARCHAR(100),
    grant_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Smart R&D 12-Stage Product Commercialization
CREATE TABLE IF NOT EXISTS public.smart_rd_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    project_id UUID REFERENCES public.smart_rd_projects(id) ON DELETE SET NULL,
    lead_engineer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    lead_engineer_name VARCHAR(150) NOT NULL,
    current_stage_index INT DEFAULT 0,
    stages JSONB DEFAULT '[]'::jsonb,
    is_launched BOOLEAN DEFAULT FALSE,
    launch_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Smart R&D Notifications
CREATE TABLE IF NOT EXISTS public.smart_rd_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_role VARCHAR(20) DEFAULT 'all',
    recipient_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    project_name VARCHAR(255),
    task_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for Smart R&D Tables
ALTER TABLE public.smart_rd_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_rd_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_rd_papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_rd_patents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_rd_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_rd_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Smart R&D projects readable by authenticated users" ON public.smart_rd_projects FOR SELECT USING (true);
CREATE POLICY "Smart R&D tasks readable by authenticated users" ON public.smart_rd_tasks FOR SELECT USING (true);
CREATE POLICY "Smart R&D papers readable by authenticated users" ON public.smart_rd_papers FOR SELECT USING (true);
CREATE POLICY "Smart R&D patents readable by authenticated users" ON public.smart_rd_patents FOR SELECT USING (true);
CREATE POLICY "Smart R&D products readable by authenticated users" ON public.smart_rd_products FOR SELECT USING (true);
CREATE POLICY "Smart R&D notifications readable by recipient" ON public.smart_rd_notifications FOR SELECT USING (
    recipient_role = 'all' OR recipient_user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
);

-- ====================================================================
-- HOST / ADMIN DASHBOARD & COLLEGE CMS MODULE SCHEMA
-- ====================================================================

-- 1. Admin Departments Table
CREATE TABLE IF NOT EXISTS public.admin_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    hod_name VARCHAR(150),
    hod_email VARCHAR(150),
    hod_phone VARCHAR(50),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(50),
    image_url TEXT,
    courses JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Admin Staff Table
CREATE TABLE IF NOT EXISTS public.admin_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    department_id VARCHAR(50) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    designation VARCHAR(150) NOT NULL,
    qualification TEXT,
    experience_years INT DEFAULT 0,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(50),
    photo_url TEXT,
    status VARCHAR(50) DEFAULT 'Active',
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Admin Students Table
CREATE TABLE IF NOT EXISTS public.admin_students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    roll_number VARCHAR(50) UNIQUE NOT NULL,
    register_number VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    department_id VARCHAR(50) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    course VARCHAR(150) NOT NULL,
    batch_year VARCHAR(50) NOT NULL,
    semester INT DEFAULT 1,
    email VARCHAR(150),
    phone VARCHAR(50),
    academic_standing VARCHAR(50) DEFAULT 'Good',
    status VARCHAR(50) DEFAULT 'Active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Admin Courses Table
CREATE TABLE IF NOT EXISTS public.admin_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_code VARCHAR(50) UNIQUE NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    degree_type VARCHAR(50) NOT NULL,
    department_id VARCHAR(50) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    duration_years INT DEFAULT 4,
    total_semesters INT DEFAULT 8,
    intake_capacity INT DEFAULT 60,
    syllabus_url TEXT,
    description TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Admin Events Table
CREATE TABLE IF NOT EXISTS public.admin_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    end_date DATE,
    venue VARCHAR(200),
    organizing_department VARCHAR(200),
    coordinator_name VARCHAR(150),
    description TEXT,
    image_url TEXT,
    registration_link TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Admin Announcements Table
CREATE TABLE IF NOT EXISTS public.admin_announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'All',
    announcement_date DATE NOT NULL,
    expiry_date DATE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Admin Banners Table
CREATE TABLE IF NOT EXISTS public.admin_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    cta_text VARCHAR(100),
    cta_link TEXT,
    image_url TEXT NOT NULL,
    slide_order INT DEFAULT 1,
    is_published BOOLEAN DEFAULT TRUE,
    draft_version JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Admin Audit Logs
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100),
    entity_name VARCHAR(255),
    description TEXT,
    performed_by VARCHAR(150) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for Admin CMS Tables
ALTER TABLE public.admin_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view published departments" ON public.admin_departments FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view published staff" ON public.admin_staff FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view published courses" ON public.admin_courses FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view published events" ON public.admin_events FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view published announcements" ON public.admin_announcements FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view published banners" ON public.admin_banners FOR SELECT USING (is_published = true);

CREATE POLICY "Admins have full access to admin tables" ON public.admin_departments FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('host', 'admin'))
);
=======
>>>>>>> de5fd1a (fix(vercel): include complete src, public assets, and vercel.json SPA rewrites)
