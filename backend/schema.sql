-- ============================================================
-- AIO Workout Backend — PostgreSQL Schema
-- ============================================================
-- Run: psql -U aio_workout -d aio_workout -f schema.sql
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- fuzzy text search
CREATE EXTENSION IF NOT EXISTS "btree_gist"; -- exclusion constraints

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(320) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100) NOT NULL DEFAULT '',
    avatar_url      TEXT,
    date_of_birth   DATE,
    gender          VARCHAR(20) CHECK (gender IN ('male', 'female', 'other', 'unspecified')),
    height_cm       NUMERIC(5,1) CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg       NUMERIC(5,1) CHECK (weight_kg > 0 AND weight_kg < 500),
    is_premium      BOOLEAN NOT NULL DEFAULT FALSE,
    timezone        VARCHAR(50) NOT NULL DEFAULT 'UTC',
    locale          VARCHAR(10) NOT NULL DEFAULT 'en',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_display_name ON users USING gin(to_tsvector('english', display_name));

-- ============================================================
-- 2. REFRESH TOKENS
-- ============================================================
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL UNIQUE,
    device_info     JSONB NOT NULL DEFAULT '{}',
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at      TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash) WHERE revoked_at IS NULL;

-- ============================================================
-- 3. DEVICES (multi-device support)
-- ============================================================
CREATE TABLE devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_type     VARCHAR(20) NOT NULL CHECK (device_type IN ('ios', 'android', 'watchos', 'wearos', 'web')),
    device_name     VARCHAR(255) NOT NULL DEFAULT '',
    os_version      VARCHAR(50),
    app_version     VARCHAR(20),
    push_token      TEXT,
    push_provider   VARCHAR(20) CHECK (push_provider IN ('fcm', 'apns', 'none')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_sync_at    TIMESTAMPTZ,
    metadata        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_devices_user ON devices(user_id) WHERE deleted_at IS NULL AND is_active = TRUE;
CREATE INDEX idx_devices_push_token ON devices(push_token) WHERE push_token IS NOT NULL AND is_active = TRUE;

-- ============================================================
-- 4. STEP RECORDS (time-series, append-only)
-- ============================================================
-- Partitioned by month for query performance at scale.
-- Each record = one data point from a device (could be 1-min, 15-min, or hourly buckets).
CREATE TABLE step_records (
    id              UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id       UUID REFERENCES devices(id) ON DELETE SET NULL,
    recorded_at     TIMESTAMPTZ NOT NULL,
    bucket_minutes  SMALLINT NOT NULL DEFAULT 60 CHECK (bucket_minutes IN (1, 5, 15, 30, 60)),
    step_count      INTEGER NOT NULL CHECK (step_count >= 0),
    distance_meters NUMERIC(8,2) CHECK (distance_meters >= 0),
    calories        NUMERIC(6,1) CHECK (calories >= 0),
    source          VARCHAR(30) NOT NULL DEFAULT 'phone'
        CHECK (source IN ('phone', 'watch', 'healthkit', 'google_fit', 'manual')),
    metadata        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Create partitions for current + next 12 months
CREATE TABLE step_records_2026_06 PARTITION OF step_records
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE step_records_2026_07 PARTITION OF step_records
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE step_records_2026_08 PARTITION OF step_records
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE step_records_2026_09 PARTITION OF step_records
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE step_records_2026_10 PARTITION OF step_records
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE step_records_2026_11 PARTITION OF step_records
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE step_records_2026_12 PARTITION OF step_records
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');
CREATE TABLE step_records_2027_01 PARTITION OF step_records
    FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');
CREATE TABLE step_records_2027_02 PARTITION OF step_records
    FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');
CREATE TABLE step_records_2027_03 PARTITION OF step_records
    FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');
CREATE TABLE step_records_2027_04 PARTITION OF step_records
    FOR VALUES FROM ('2027-04-01') TO ('2027-05-01');
CREATE TABLE step_records_2027_05 PARTITION OF step_records
    FOR VALUES FROM ('2027-05-01') TO ('2027-06-01');
CREATE TABLE step_records_2027_06 PARTITION OF step_records
    FOR VALUES FROM ('2027-06-01') TO ('2027-07-01');

-- Indexes on the parent table (propagated to all partitions)
CREATE INDEX idx_step_records_user_time ON step_records(user_id, recorded_at DESC);
CREATE INDEX idx_step_records_device ON step_records(device_id, recorded_at DESC) WHERE device_id IS NOT NULL;
CREATE INDEX idx_step_records_source ON step_records(source);

-- ============================================================
-- 5. DAILY STEP SUMMARIES (pre-aggregated for fast reads)
-- ============================================================
-- Upserted nightly by a background job. UI reads this table.
CREATE TABLE daily_step_summaries (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    total_steps     INTEGER NOT NULL DEFAULT 0 CHECK (total_steps >= 0),
    total_distance  NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total_distance >= 0),
    total_calories  NUMERIC(8,1) NOT NULL DEFAULT 0 CHECK (total_calories >= 0),
    active_minutes  INTEGER NOT NULL DEFAULT 0 CHECK (active_minutes >= 0),
    peak_step_hour  SMALLINT CHECK (peak_step_hour >= 0 AND peak_step_hour < 24),
    data_points     INTEGER NOT NULL DEFAULT 0,
    sources         TEXT[] NOT NULL DEFAULT '{}',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, date)
);

CREATE INDEX idx_daily_steps_date ON daily_step_summaries(date DESC);
CREATE INDEX idx_daily_steps_user_date ON daily_step_summaries(user_id, date DESC);

-- ============================================================
-- 6. STEP GOALS
-- ============================================================
CREATE TABLE step_goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_type       VARCHAR(20) NOT NULL CHECK (goal_type IN ('daily', 'weekly', 'monthly', 'custom')),
    target_steps    INTEGER NOT NULL CHECK (target_steps > 0),
    start_date      DATE NOT NULL,
    end_date        DATE,          -- NULL = ongoing
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_step_goals_user ON step_goals(user_id, is_active);

-- Ensure only one active goal per type per user (partial unique)
CREATE UNIQUE INDEX idx_step_goals_active_unique
    ON step_goals(user_id, goal_type)
    WHERE is_active = TRUE;

-- ============================================================
-- 7. WORKOUT SESSIONS (migrated from local SharedPreferences)
-- ============================================================
CREATE TABLE workout_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_date        TIMESTAMPTZ NOT NULL,
    week_number         INTEGER NOT NULL CHECK (week_number > 0),
    day_number          INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 7),
    focus               VARCHAR(100) NOT NULL,
    duration_seconds    INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
    steps_during        INTEGER NOT NULL DEFAULT 0 CHECK (steps_during >= 0),
    hydration_liters    NUMERIC(4,2) NOT NULL DEFAULT 0 CHECK (hydration_liters >= 0),
    notes               TEXT,
    synced_from_device  BOOLEAN NOT NULL DEFAULT FALSE,
    device_id           UUID REFERENCES devices(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_sessions_user_date ON workout_sessions(user_id, session_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_sessions_week ON workout_sessions(user_id, week_number, day_number) WHERE deleted_at IS NULL;

-- ============================================================
-- 8. COMPLETED EXERCISES (per session)
-- ============================================================
CREATE TABLE completed_exercises (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_uuid   VARCHAR(100) NOT NULL,
    exercise_name   VARCHAR(200) NOT NULL,
    sets_completed  INTEGER NOT NULL CHECK (sets_completed > 0),
    reps_completed  INTEGER CHECK (reps_completed > 0),
    duration_seconds INTEGER CHECK (duration_seconds > 0),
    weight_kg       NUMERIC(6,1) CHECK (weight_kg >= 0),
    notes           TEXT DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_completed_exercises_session ON completed_exercises(session_id);

-- ============================================================
-- 9. WEIGHT ENTRIES
-- ============================================================
CREATE TABLE weight_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_date      DATE NOT NULL,
    weight_kg       NUMERIC(5,1) NOT NULL CHECK (weight_kg > 0 AND weight_kg < 500),
    notes           TEXT,
    source          VARCHAR(20) NOT NULL DEFAULT 'manual'
        CHECK (source IN ('manual', 'scale', 'healthkit', 'google_fit')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_weight_user_date
    ON weight_entries(user_id, entry_date)
    WHERE deleted_at IS NULL;

-- ============================================================
-- 10. ACHIEVEMENTS
-- ============================================================
CREATE TABLE achievement_definitions (
    id              VARCHAR(50) PRIMARY KEY,
    title           VARCHAR(100) NOT NULL,
    description     TEXT NOT NULL,
    icon_name       VARCHAR(50) NOT NULL,
    category        VARCHAR(30) NOT NULL
        CHECK (category IN ('workout', 'steps', 'streak', 'weight', 'social', 'special')),
    tier            VARCHAR(10) NOT NULL DEFAULT 'bronze'
        CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    threshold_value INTEGER NOT NULL DEFAULT 1,
    threshold_type  VARCHAR(30) NOT NULL DEFAULT 'count'
        CHECK (threshold_type IN ('count', 'streak_days', 'total_value', 'boolean')),
    is_hidden       BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_achievements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id  VARCHAR(50) NOT NULL REFERENCES achievement_definitions(id),
    progress        INTEGER NOT NULL DEFAULT 0,
    unlocked_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id, unlocked_at DESC NULLS LAST);

-- ============================================================
-- 11. SOCIAL — Friend Connections
-- ============================================================
CREATE TABLE friend_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          VARCHAR(10) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at    TIMESTAMPTZ,

    UNIQUE(sender_id, receiver_id),
    CHECK (sender_id != receiver_id)
);

CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id, status) WHERE status = 'pending';
CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id, status);

CREATE TABLE friendships (
    user_id_1       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id_2       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id_1, user_id_2),
    CHECK (user_id_1 < user_id_2)  -- canonical ordering
);

-- ============================================================
-- 12. SOCIAL — Challenges
-- ============================================================
CREATE TABLE challenges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    challenge_type  VARCHAR(30) NOT NULL
        CHECK (challenge_type IN ('daily_steps', 'weekly_steps', 'total_steps', 'streak', 'distance')),
    target_value    INTEGER NOT NULL CHECK (target_value > 0),
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    status          VARCHAR(15) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (end_date > start_date)
);

CREATE TABLE challenge_participants (
    challenge_id    UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_value   INTEGER NOT NULL DEFAULT 0,
    completed_at    TIMESTAMPTZ,

    PRIMARY KEY (challenge_id, user_id)
);

CREATE INDEX idx_challenge_participants_user ON challenge_participants(user_id);

-- ============================================================
-- 13. LEADERBOARD (materialized, refreshed periodically)
-- ============================================================
CREATE TABLE leaderboard_entries (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period_type     VARCHAR(10) NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly')),
    period_start    DATE NOT NULL,
    total_steps     INTEGER NOT NULL DEFAULT 0,
    rank            INTEGER,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, period_type, period_start)
);

CREATE INDEX idx_leaderboard_rank ON leaderboard_entries(period_type, period_start, total_steps DESC);

-- ============================================================
-- 14. NOTIFICATIONS LOG
-- ============================================================
CREATE TABLE notification_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB NOT NULL DEFAULT '{}',
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered       BOOLEAN NOT NULL DEFAULT FALSE,
    opened          BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_notification_log_user ON notification_log(user_id, sent_at DESC);

-- ============================================================
-- 15. USER PREFERENCES (flexible key-value)
-- ============================================================
CREATE TABLE user_preferences (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pref_key        VARCHAR(100) NOT NULL,
    pref_value      JSONB NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, pref_key)
);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_step_goals_updated_at
    BEFORE UPDATE ON step_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_workout_sessions_updated_at
    BEFORE UPDATE ON workout_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_weight_entries_updated_at
    BEFORE UPDATE ON weight_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Daily step summary upsert function (called by background job)
CREATE OR REPLACE FUNCTION upsert_daily_step_summary(
    p_user_id UUID,
    p_date DATE,
    p_steps INTEGER,
    p_distance NUMERIC,
    p_calories NUMERIC,
    p_active_minutes INTEGER,
    p_source TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO daily_step_summaries (user_id, date, total_steps, total_distance, total_calories, active_minutes, data_points, sources)
    VALUES (p_user_id, p_date, p_steps, p_distance, p_calories, p_active_minutes, 1, ARRAY[p_source])
    ON CONFLICT (user_id, date) DO UPDATE SET
        total_steps = daily_step_summaries.total_steps + EXCLUDED.total_steps,
        total_distance = daily_step_summaries.total_distance + EXCLUDED.total_distance,
        total_calories = daily_step_summaries.total_calories + EXCLUDED.total_calories,
        active_minutes = daily_step_summaries.active_minutes + EXCLUDED.active_minutes,
        data_points = daily_step_summaries.data_points + 1,
        sources = array_cat(daily_step_summaries.sources, ARRAY[EXCLUDED.source]),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
