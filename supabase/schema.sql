-- Money Out — Supabase schema
-- Run this once in the Supabase dashboard: SQL Editor → New query → Run.

create table if not exists public.expenses (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  spent_on   date not null default current_date,
  amount     numeric(12, 2) not null check (amount > 0),
  category   text not null default 'Other expense',
  paid_from  text not null default 'Cash',
  paid_to    text,
  note       text,
  ref_no     text,
  created_at timestamptz not null default now()
);

create index if not exists expenses_user_date_idx
  on public.expenses (user_id, spent_on desc, created_at desc);

alter table public.expenses enable row level security;

-- Each signed-in user sees and changes only their own rows.
drop policy if exists "read own expenses" on public.expenses;
create policy "read own expenses" on public.expenses
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "insert own expenses" on public.expenses;
create policy "insert own expenses" on public.expenses
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "update own expenses" on public.expenses;
create policy "update own expenses" on public.expenses
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "delete own expenses" on public.expenses;
create policy "delete own expenses" on public.expenses
  for delete to authenticated using (auth.uid() = user_id);

-- Optional: if a few staff should share one set of books, create a team
-- table and replace auth.uid() = user_id above with a membership check.
