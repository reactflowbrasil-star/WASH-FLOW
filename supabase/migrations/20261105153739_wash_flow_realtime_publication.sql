do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='vehicles') then alter publication supabase_realtime add table public.vehicles; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='wash_queue') then alter publication supabase_realtime add table public.wash_queue; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='wash_history') then alter publication supabase_realtime add table public.wash_history; end if;
end $$;
