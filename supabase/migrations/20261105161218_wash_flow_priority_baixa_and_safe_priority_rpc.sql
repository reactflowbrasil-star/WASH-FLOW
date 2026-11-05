-- WASH FLOW: prioridade Baixa e alteração de prioridade autorizada no servidor.
alter table public.wash_queue drop constraint if exists wash_queue_priority_check;
alter table public.wash_queue add constraint wash_queue_priority_check check(priority in ('Urgente','Alta','Normal','Baixa'));

create or replace function private.update_wash_priority_impl(p_job_id uuid,p_priority text) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 if p_priority not in ('Urgente','Alta','Normal','Baixa') then raise exception 'Prioridade inválida'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Lavagem não encontrada'; end if;
 if not (private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','operator'])) then raise exception 'Sem permissão'; end if;
 if j.status='Concluido' then raise exception 'Lavagem concluída não pode ser alterada'; end if;
 update public.wash_queue set priority=p_priority where id=p_job_id;
end $$;
revoke all on function private.update_wash_priority_impl(uuid,text) from public,anon;
grant execute on function private.update_wash_priority_impl(uuid,text) to authenticated;
create or replace function public.update_wash_priority(p_job_id uuid,p_priority text) returns void language sql set search_path='' as $$ select private.update_wash_priority_impl(p_job_id,p_priority) $$;
revoke all on function public.update_wash_priority(uuid,text) from public,anon;
grant execute on function public.update_wash_priority(uuid,text) to authenticated;
