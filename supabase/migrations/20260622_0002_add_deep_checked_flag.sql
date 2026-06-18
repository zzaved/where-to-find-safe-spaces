-- deep_checked = true once a place has been enriched with a Perplexity
-- web-reputation check.
alter table public.places
  add column deep_checked boolean not null default false;
