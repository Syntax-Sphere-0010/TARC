-- ==============================================================================
-- SUPABASE DATABASE SCHEMA & ROW LEVEL SECURITY (RLS) FOR SCHEDULE REMINDER APP
-- ==============================================================================
-- Project ID: helwfjurtvgzfnfvbwlr
-- How to apply:
-- 1. Open your Supabase Dashboard: https://supabase.com/dashboard/project/helwfjurtvgzfnfvbwlr
-- 2. Click on "SQL Editor" on the left navigation panel.
-- 3. Click "New query", paste this entire script, and click "Run".
-- ==============================================================================

-- 1. SCHEDULES TABLE
CREATE TABLE IF NOT EXISTS public.schedules (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    date TEXT NOT NULL,
    time TEXT NOT NULL,
    reminder_date_time TEXT NOT NULL,
    repeat_type TEXT NOT NULL DEFAULT 'None',
    repeat_interval INTEGER NOT NULL DEFAULT 1,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    notification_id INTEGER NOT NULL DEFAULT 0,
    priority TEXT NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for fast user queries and date sorting
CREATE INDEX IF NOT EXISTS idx_schedules_user_id ON public.schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON public.schedules(date);
CREATE INDEX IF NOT EXISTS idx_schedules_created_at ON public.schedules(created_at);

-- 2. GOALS TABLE
CREATE TABLE IF NOT EXISTS public.goals (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL DEFAULT '',
    progress NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    category TEXT NOT NULL DEFAULT 'General',
    from_schedule BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for fast user queries and category filtering
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_created_at ON public.goals(created_at);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on both tables
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- SCHEDULES POLICIES
-- ------------------------------------------------------------------------------

-- Allow authenticated users full CRUD over their own records
CREATE POLICY "Users can view their own schedules"
    ON public.schedules
    FOR SELECT
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL -- Supports local demo/guest access
    );

CREATE POLICY "Users can insert their own schedules"
    ON public.schedules
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL -- Supports local demo/guest access
    );

CREATE POLICY "Users can update their own schedules"
    ON public.schedules
    FOR UPDATE
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

CREATE POLICY "Users can delete their own schedules"
    ON public.schedules
    FOR DELETE
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

-- ------------------------------------------------------------------------------
-- GOALS POLICIES
-- ------------------------------------------------------------------------------

-- Allow authenticated users full CRUD over their own records
CREATE POLICY "Users can view their own goals"
    ON public.goals
    FOR SELECT
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL -- Supports local demo/guest access
    );

CREATE POLICY "Users can insert their own goals"
    ON public.goals
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

CREATE POLICY "Users can update their own goals"
    ON public.goals
    FOR UPDATE
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

CREATE POLICY "Users can delete their own goals"
    ON public.goals
    FOR DELETE
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

-- ==============================================================================
-- AUTOMATIC updated_at TRIGGER FUNCTION
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_schedules_updated_at ON public.schedules;
CREATE TRIGGER trigger_schedules_updated_at
    BEFORE UPDATE ON public.schedules
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_goals_updated_at ON public.goals;
CREATE TRIGGER trigger_goals_updated_at
    BEFORE UPDATE ON public.goals
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
