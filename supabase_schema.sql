-- =============================================================================
-- Supabase schema for expiryrange_bot_v3_1hz10v.py
-- Matches SupabaseStore field names EXACTLY (see BUG 3 in the file header --
-- a prior mismatch here caused PGRST204 errors, so keep these names in sync
-- with SupabaseStore.log_trade / log_overlay / save_config / save_daily_summary
-- if you ever edit the bot's field names).
-- Safe to run multiple times: uses CREATE TABLE IF NOT EXISTS.
-- =============================================================================

-- ── 1. bot_expiryrange_log ───────────────────────────────────────────────
-- One row per EXPIRYRANGE trade. Written by SupabaseStore.log_trade().
create table if not exists bot_expiryrange_log (
    id                   bigint generated always as identity primary key,
    ts                   timestamptz not null default now(),
    symbol               text        not null,
    entry_price          numeric     not null,
    upper_barrier        numeric     not null,
    lower_barrier        numeric     not null,
    barrier_width        numeric     not null,
    upper_abs            numeric     not null default 0,
    lower_abs            numeric     not null default 0,
    upper_ratio          numeric     not null default 1.0,
    lower_ratio          numeric     not null default 1.0,
    bias                 numeric     not null default 0,
    drift_per_tick       numeric     not null default 0,
    drift_total          numeric     not null default 0,
    duration_secs        integer     not null,
    n_steps              integer     not null default 0,
    stake                numeric     not null,
    mg_step              integer     not null default 0,
    mg_active            boolean     not null default false,
    consec_losses_before integer     not null default 0,
    won                  boolean     not null,
    profit               numeric     not null,
    ask_price            numeric     not null default 0,
    breach_prob          numeric     not null,
    win_prob             numeric     not null default 0,
    ci_lower             numeric     not null default 0,
    weighted_score       numeric     not null default 0,
    ev_conservative       numeric    not null default 0,
    ev_optimistic         numeric    not null default 0,
    vol_per_tick         numeric     not null,
    vol_terminal         numeric     not null default 0,
    barrier_sigma        numeric     not null default 0,
    used_garch           boolean     not null,
    adx_val              numeric     not null default 0,
    vol_trust            numeric     not null default 0,
    hawkes_intensity     numeric     not null default 0,
    n_sims               integer     not null default 0
);

create index if not exists idx_bot_expiryrange_log_symbol_ts
    on bot_expiryrange_log (symbol, ts);

-- ── 2. bot_expiryrange_config ────────────────────────────────────────────
-- Key/value store used to warm-start duration/barrier/vol weights on
-- restart. Written/read by SupabaseStore.save_config() / load_config().
create table if not exists bot_expiryrange_config (
    key        text primary key,
    value      jsonb       not null,
    updated_at timestamptz not null default now()
);

-- ── 3. bot_expiryrange_daily ─────────────────────────────────────────────
-- One row per (date, symbol) daily self-improvement summary. Written by
-- SupabaseStore.save_daily_summary(). Upserted, so needs a composite
-- unique constraint for "resolution=merge-duplicates" to work correctly.
create table if not exists bot_expiryrange_daily (
    date_utc      date    not null,
    symbol        text    not null,
    n_trades      integer not null default 0,
    n_wins        integer not null default 0,
    win_rate      numeric not null default 0,
    total_profit  numeric not null default 0,
    best_duration integer not null default 0,
    best_barrier  numeric not null default 0,
    updated_at    timestamptz not null default now(),
    primary key (date_utc, symbol)
);

-- ── 4. bot_overlay_log ───────────────────────────────────────────────────
-- One row per directional (CALL/PUT) overlay trade. Written by
-- SupabaseStore.log_overlay().
create table if not exists bot_overlay_log (
    id              bigint generated always as identity primary key,
    ts              timestamptz not null default now(),
    symbol          text        not null,
    direction       text        not null,
    entry_price     numeric     not null,
    duration_secs   integer     not null,
    stake           numeric     not null,
    bias            numeric     not null,
    bias_floor_used numeric     not null,
    er_win_prob     numeric     not null,
    er_upper_ratio  numeric     not null,
    er_lower_ratio  numeric     not null,
    won             boolean     not null,
    profit          numeric     not null,
    ask_price       numeric     not null default 0
);

create index if not exists idx_bot_overlay_log_symbol_ts
    on bot_overlay_log (symbol, ts);

-- =============================================================================
-- Row Level Security
-- The bot authenticates with the SERVICE ROLE key (see .env.example), which
-- bypasses RLS entirely. If you ever switch the bot to use the anon key
-- instead, you'll need policies like the ones below. Left disabled by
-- default since service-role access doesn't need them.
-- =============================================================================
-- alter table bot_expiryrange_log    enable row level security;
-- alter table bot_expiryrange_config enable row level security;
-- alter table bot_expiryrange_daily  enable row level security;
-- alter table bot_overlay_log        enable row level security;
