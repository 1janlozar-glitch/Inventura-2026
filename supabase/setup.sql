-- =====================================================================
--  POPIS INVENTURE – nastavitev baze
--  Zaženite ENKRAT v Supabase: SQL Editor → New query → prilepite → Run
--
--  PRED ZAGONOM: v vrstici z  values (1, 'ZAMENJAJ_ME')  vpišite PIN ekipe.
--  PIN naj ima VSAJ 8 znakov (črke in številke), ker je stran javna.
--  Dokler je PIN 'ZAMENJAJ_ME', prijava ne deluje.
--  PIN lahko kasneje spremenite z:
--      update public.app_config set pin = 'NOVPIN' where id = 1;
-- =====================================================================

-- ---------- Tabele ----------------------------------------------------

create table if not exists public.app_config (
  id  int  primary key default 1 check (id = 1),
  pin text not null
);

insert into public.app_config (id, pin) values (1, 'ZAMENJAJ_ME')
on conflict (id) do update set pin = excluded.pin;

-- Beleženje napačnih PIN-ov (zaščita pred ugibanjem)
create table if not exists public.pin_fails (
  at timestamptz not null default now()
);
create index if not exists pin_fails_at_idx on public.pin_fails (at);

create table if not exists public.articles (
  code         text primary key,              -- šifra artikla
  ean          text,
  manufacturer text,
  description  text,
  unit         text default 'kos',
  book_qty     numeric,                       -- knjižna zaloga (iz uvoza šifranta)
  source       text default 'popis',          -- 'uvoz' ali 'popis'
  created_by   text,
  updated_at   timestamptz not null default clock_timestamp()
);
create index if not exists articles_ean_idx on public.articles (ean);
create index if not exists articles_upd_idx on public.articles (updated_at, code);

create table if not exists public.entries (
  id                uuid primary key,          -- ustvari telefon (varno ponovno pošiljanje)
  popis             text not null,
  counter           text not null,             -- ime popisovalca
  location          text,
  code              text not null,
  ean               text,
  manufacturer      text,
  description       text,
  quantity          numeric not null,
  unit              text,
  method            text,                      -- koda / rocno / ai
  deleted           boolean not null default false,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  server_updated_at timestamptz not null default now()
);
create index if not exists entries_popis_idx on public.entries (popis);

-- ---------- Zaščita: tabele so zaprte, dostop samo prek funkcij s PIN-om

alter table public.app_config enable row level security;
alter table public.articles   enable row level security;
alter table public.entries    enable row level security;
alter table public.pin_fails  enable row level security;

revoke all on public.app_config, public.articles, public.entries, public.pin_fails from anon, authenticated;

-- ---------- Notranji funkciji (nista dostopni od zunaj) ---------------

-- Po 20 napačnih poskusih v 10 minutah je prijava za 10 minut zaklenjena.
create or replace function public._locked()
returns boolean language sql stable security definer set search_path = public as $$
  select (select count(*) from pin_fails where at > now() - interval '10 minutes') >= 20;
$$;

create or replace function public._pin_ok(p_pin text)
returns boolean language sql stable security definer set search_path = public as $$
  select p_pin is not null
     and p_pin <> 'ZAMENJAJ_ME'
     and not _locked()
     and exists (select 1 from app_config where pin = p_pin);
$$;

create or replace function public._require_pin(p_pin text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not _pin_ok(p_pin) then
    perform pg_sleep(1);
    if _locked() then
      raise exception 'Preveč napačnih poskusov – počakajte 10 minut' using errcode = '28000';
    end if;
    raise exception 'Napačen PIN' using errcode = '28000';
  end if;
end $$;

-- ---------- Funkcije za aplikacijo ------------------------------------

create or replace function public.check_pin(p_pin text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if _pin_ok(p_pin) then return true; end if;
  if _locked() then
    raise exception 'Preveč napačnih poskusov – počakajte 10 minut' using errcode = '28000';
  end if;
  insert into pin_fails default values;
  delete from pin_fails where at < now() - interval '1 day';
  perform pg_sleep(1);
  return false;
end $$;

-- Nalaganje vnosov s telefona (novi in spremenjeni; zadnja sprememba zmaga)
create or replace function public.sync_entries(p_pin text, p_entries jsonb)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  perform _require_pin(p_pin);

  insert into entries as e
    (id, popis, counter, location, code, ean, manufacturer, description,
     quantity, unit, method, deleted, created_at, updated_at, server_updated_at)
  select x.id, x.popis, x.counter, x.location, x.code, x.ean, x.manufacturer, x.description,
         x.quantity, x.unit, x.method, coalesce(x.deleted, false), x.created_at, x.updated_at, now()
  from jsonb_to_recordset(p_entries) as x(
         id uuid, popis text, counter text, location text, code text, ean text,
         manufacturer text, description text, quantity numeric, unit text, method text,
         deleted boolean, created_at timestamptz, updated_at timestamptz)
  on conflict (id) do update set
    location          = excluded.location,
    code              = excluded.code,
    ean               = excluded.ean,
    manufacturer      = excluded.manufacturer,
    description       = excluded.description,
    quantity          = excluded.quantity,
    unit              = excluded.unit,
    method            = excluded.method,
    deleted           = excluded.deleted,
    updated_at        = excluded.updated_at,
    server_updated_at = now()
  where e.updated_at <= excluded.updated_at;

  get diagnostics n = row_count;
  return n;
end $$;

-- Uvoz šifranta in artikli, vpisani med popisom
create or replace function public.upsert_articles(p_pin text, p_articles jsonb)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  perform _require_pin(p_pin);

  insert into articles as a
    (code, ean, manufacturer, description, unit, book_qty, source, created_by, updated_at)
  select distinct on (trim(x.code))
         trim(x.code),
         nullif(trim(x.ean), ''),
         nullif(trim(x.manufacturer), ''),
         nullif(trim(x.description), ''),
         coalesce(nullif(trim(x.unit), ''), 'kos'),
         x.book_qty,
         coalesce(nullif(x.source, ''), 'popis'),
         x.created_by,
         clock_timestamp()
  from jsonb_to_recordset(p_articles) as x(
         code text, ean text, manufacturer text, description text, unit text,
         book_qty numeric, source text, created_by text)
  where nullif(trim(x.code), '') is not null
  on conflict (code) do update set
    ean          = coalesce(excluded.ean, a.ean),
    manufacturer = coalesce(excluded.manufacturer, a.manufacturer),
    description  = coalesce(excluded.description, a.description),
    unit         = coalesce(excluded.unit, a.unit),
    book_qty     = coalesce(excluded.book_qty, a.book_qty),
    source       = case when a.source = 'uvoz' then 'uvoz' else excluded.source end,
    updated_at   = clock_timestamp();

  get diagnostics n = row_count;
  return n;
end $$;

-- Prenos artiklov na telefon (po straneh po 5000, samo spremenjeni)
create or replace function public.get_articles(
  p_pin text, p_since timestamptz default '-infinity', p_after_code text default '')
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_pin(p_pin);
  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t.updated_at, t.code)
    from (
      select code, ean, manufacturer, description, unit, book_qty, source, updated_at
      from articles
      where (updated_at, code) > (coalesce(p_since, '-infinity'::timestamptz), coalesce(p_after_code, ''))
      order by updated_at, code
      limit 5000
    ) t), '[]'::jsonb);
end $$;

-- Vsi vnosi enega popisa (za stran Pregled)
create or replace function public.get_entries(p_pin text, p_popis text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_pin(p_pin);
  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t.created_at desc)
    from (
      select id, popis, counter, location, code, ean, manufacturer, description,
             quantity, unit, method, created_at, updated_at
      from entries
      where popis = p_popis and not deleted
    ) t), '[]'::jsonb);
end $$;

-- Seznam popisov (za izbiro ob prijavi)
create or replace function public.list_popisi(p_pin text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_pin(p_pin);
  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t.last_change desc)
    from (
      select popis, count(*) filter (where not deleted) as entries, max(updated_at) as last_change
      from entries group by popis
    ) t), '[]'::jsonb);
end $$;

-- ---------- Pravice ---------------------------------------------------

revoke execute on function public._locked()          from public, anon, authenticated;
revoke execute on function public._pin_ok(text)      from public, anon, authenticated;
revoke execute on function public._require_pin(text) from public, anon, authenticated;

grant execute on function public.check_pin(text)                      to anon, authenticated;
grant execute on function public.sync_entries(text, jsonb)            to anon, authenticated;
grant execute on function public.upsert_articles(text, jsonb)         to anon, authenticated;
grant execute on function public.get_articles(text, timestamptz, text) to anon, authenticated;
grant execute on function public.get_entries(text, text)              to anon, authenticated;
grant execute on function public.list_popisi(text)                    to anon, authenticated;

notify pgrst, 'reload schema';
