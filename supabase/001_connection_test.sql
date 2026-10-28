create table if not exists public.app_ping (id int primary key, message text not null);
alter table public.app_ping enable row level security;
drop policy if exists "app_ping_select_anon" on public.app_ping;
create policy "app_ping_select_anon" on public.app_ping for select to anon using (true);
insert into public.app_ping (id, message) values (1, 'ok') on conflict (id) do nothing;
