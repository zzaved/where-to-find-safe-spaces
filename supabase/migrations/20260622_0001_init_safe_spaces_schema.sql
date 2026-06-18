-- ============================================================
-- Safe Spaces — initial schema
-- places: cache of Google Places enriched with safety classification
-- favorites / search_history: per-device persistence
-- ============================================================

create table public.places (
  id                      uuid primary key default gen_random_uuid(),
  google_place_id         text not null unique,
  name                    text not null,
  primary_type            text,
  types                   text[] not null default '{}',
  address                 text,
  lat                     double precision not null,
  lng                     double precision not null,
  google_rating           numeric(2,1),
  google_ratings_total    integer not null default 0,
  price_level             integer,
  website                 text,
  google_maps_uri         text,
  phone                   text,
  photo_name              text,
  safety_score            integer not null default 50,
  safety_label            text not null default 'neutral'
                            check (safety_label in ('safe','neutral','not_safe')),
  classification_summary  text,
  positive_signals        text[] not null default '{}',
  negative_signals        text[] not null default '{}',
  web_citations           jsonb  not null default '[]'::jsonb,
  reviews                 jsonb  not null default '[]'::jsonb,
  classified_at           timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);
create index places_geo_idx   on public.places (lat, lng);
create index places_label_idx on public.places (safety_label);

create table public.favorites (
  id          uuid primary key default gen_random_uuid(),
  device_id   text not null,
  place_id    uuid not null references public.places(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (device_id, place_id)
);
create index favorites_device_idx on public.favorites (device_id);

create table public.search_history (
  id            uuid primary key default gen_random_uuid(),
  device_id     text not null,
  lat           double precision not null,
  lng           double precision not null,
  category      text,
  result_count  integer not null default 0,
  created_at    timestamptz not null default now()
);
create index search_history_device_idx on public.search_history (device_id, created_at desc);

-- keep updated_at fresh on places
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
create trigger places_set_updated_at
  before update on public.places
  for each row execute function public.set_updated_at();

-- ============================================================
-- Row Level Security
-- places: public read (public reputation data); writes via service role only
-- favorites / history: device-scoped at the application layer
-- ============================================================
alter table public.places         enable row level security;
alter table public.favorites      enable row level security;
alter table public.search_history enable row level security;

create policy "places_public_read" on public.places
  for select to anon, authenticated using (true);

create policy "favorites_rw" on public.favorites
  for all to anon, authenticated using (true) with check (true);

create policy "history_rw" on public.search_history
  for all to anon, authenticated using (true) with check (true);
