-- app_config: server-side key/value vault for third-party API keys.
-- RLS is enabled with NO policies, so only the service role (used by the
-- edge functions, which bypasses RLS) can read or write it. The anon client
-- can never see these values. Actual key values are inserted out-of-band and
-- are intentionally NOT stored in version control.
create table public.app_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;
