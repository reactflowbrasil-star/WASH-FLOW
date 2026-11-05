-- Preserva os dados do veículo e os horários operacionais no histórico imutável.
alter table public.wash_history
 add column if not exists brand text,
 add column if not exists model text,
 add column if not exists vehicle_group text,
 add column if not exists notes text,
 add column if not exists queued_at timestamptz,
 add column if not exists started_at timestamptz;

create or replace function private.complete_wash_impl(p_job_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Lavagem não encontrada'; end if;
 if not (private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','inspector'])) then raise exception 'Sem permissão'; end if;
 if j.status<>'AguardandoConferencia' then raise exception 'Lavagem não está em conferência'; end if;
 insert into public.wash_history(site_id,vehicle_id,plate,priority,source_job_id,duration_seconds,brand,model,vehicle_group,notes,queued_at,started_at)
 select j.site_id,j.vehicle_id,j.plate,j.priority,j.id,case when j.started_at is not null then greatest(0,extract(epoch from now()-j.started_at)::integer) else null end,v.brand,v.model,v.vehicle_group,j.notes,j.created_at,j.started_at
 from public.vehicles v where v.id=j.vehicle_id and v.site_id=j.site_id;
 if not found then raise exception 'Veículo vinculado não encontrado'; end if;
 update public.wash_queue set status='Concluido',finished_at=now() where id=j.id;
end $$;
revoke all on function private.complete_wash_impl(uuid) from public,anon;
grant execute on function private.complete_wash_impl(uuid) to authenticated;
