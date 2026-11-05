create or replace function public.complete_wash(p_job_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Lavagem não encontrada'; end if;
 if not (private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','inspector'])) then raise exception 'Sem permissão'; end if;
 if j.status<>'AguardandoConferencia' then raise exception 'Lavagem não está em conferência'; end if;
 insert into public.wash_history(site_id,vehicle_id,plate,priority,source_job_id,duration_seconds) values(j.site_id,j.vehicle_id,j.plate,j.priority,j.id,case when j.started_at is not null then greatest(0,extract(epoch from now()-j.started_at)::integer) else null end);
 update public.wash_queue set status='Concluido',finished_at=now() where id=j.id;
end $$;
revoke all on function public.complete_wash(uuid) from public,anon;
grant execute on function public.complete_wash(uuid) to authenticated;
