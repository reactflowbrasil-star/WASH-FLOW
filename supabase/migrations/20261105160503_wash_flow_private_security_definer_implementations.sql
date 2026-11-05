-- Implementações privilegiadas isoladas no schema private; RPCs públicas invocam wrappers SECURITY INVOKER.
create or replace function private.complete_wash_impl(p_job_id uuid) returns void language plpgsql security definer set search_path='' as $$
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
revoke all on function private.complete_wash_impl(uuid) from public,anon;
grant execute on function private.complete_wash_impl(uuid) to authenticated;
create or replace function public.complete_wash(p_job_id uuid) returns void language sql security invoker set search_path='' as $$ select private.complete_wash_impl(p_job_id) $$;
revoke all on function public.complete_wash(uuid) from public,anon;
grant execute on function public.complete_wash(uuid) to authenticated;

create or replace function private.transition_wash_impl(p_job_id uuid,p_next_status text,p_reason text default null) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype; allowed boolean;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Lavagem não encontrada'; end if;
 allowed:=private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','operator']);
 if j.status='AguardandoConferencia' and p_next_status='Refazer' then allowed:=private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','inspector']); end if;
 if not allowed then raise exception 'Sem permissão'; end if;
 if not ((j.status='NaFila' and p_next_status='Lavando') or (j.status='Refazer' and p_next_status='Lavando') or (j.status='Lavando' and p_next_status='AguardandoConferencia') or (j.status='AguardandoConferencia' and p_next_status='Refazer')) then raise exception 'Transição inválida'; end if;
 if p_next_status='Refazer' and nullif(trim(p_reason),'') is null then raise exception 'Motivo da refação obrigatório'; end if;
 update public.wash_queue set status=p_next_status,started_at=case when p_next_status='Lavando' then now() else started_at end,finished_at=case when p_next_status='AguardandoConferencia' then now() else null end,rejection_reason=case when p_next_status='Refazer' then trim(p_reason) else rejection_reason end where id=p_job_id;
end $$;
revoke all on function private.transition_wash_impl(uuid,text,text) from public,anon;
grant execute on function private.transition_wash_impl(uuid,text,text) to authenticated;
create or replace function public.transition_wash(p_job_id uuid,p_next_status text,p_reason text default null) returns void language sql security invoker set search_path='' as $$ select private.transition_wash_impl(p_job_id,p_next_status,p_reason) $$;
revoke all on function public.transition_wash(uuid,text,text) from public,anon;
grant execute on function public.transition_wash(uuid,text,text) to authenticated;

create or replace function private.assign_site_member_impl(p_site_id uuid,p_email text,p_role text) returns void language plpgsql security definer set search_path='' as $$
declare target_user uuid;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 if not (private.is_platform_admin() or private.has_site_role(p_site_id,array['owner'])) then raise exception 'Sem permissão'; end if;
 if p_role not in ('owner','manager','operator','inspector') then raise exception 'Função inválida'; end if;
 if nullif(trim(p_email),'') is null then raise exception 'E-mail obrigatório'; end if;
 select id into target_user from auth.users where lower(email)=lower(trim(p_email));
 if target_user is null then raise exception 'Usuário ainda não possui conta'; end if;
 insert into public.site_members(site_id,user_id,role) values(p_site_id,target_user,p_role) on conflict(site_id,user_id) do update set role=excluded.role;
end $$;
revoke all on function private.assign_site_member_impl(uuid,text,text) from public,anon;
grant execute on function private.assign_site_member_impl(uuid,text,text) to authenticated;
create or replace function public.assign_site_member(p_site_id uuid,p_email text,p_role text) returns void language sql security invoker set search_path='' as $$ select private.assign_site_member_impl(p_site_id,p_email,p_role) $$;
revoke all on function public.assign_site_member(uuid,text,text) from public,anon;
grant execute on function public.assign_site_member(uuid,text,text) to authenticated;
