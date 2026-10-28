create table if not exists public.app_ping (id int primary key, message text not null);
alter table public.app_ping enable row level security;
insert into public.app_ping (id, message) values (1, 'BLOB cloud connection OK') on conflict (id) do nothing;
grant select on public.app_ping to anon, authenticated;
create policy "ping readable by everyone" on public.app_ping for select to anon, authenticated using (true);
