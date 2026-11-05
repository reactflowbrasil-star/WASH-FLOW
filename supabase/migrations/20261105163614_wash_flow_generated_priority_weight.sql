alter table public.wash_queue add column if not exists priority_weight integer generated always as (case priority when 'Urgente' then 1 when 'Alta' then 2 when 'Normal' then 3 when 'Baixa' then 4 else 99 end) stored;
create index if not exists idx_queue_site_priority on public.wash_queue(site_id,status,priority_weight,created_at);
