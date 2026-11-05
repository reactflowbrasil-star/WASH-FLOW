-- Migração incremental: aplicar somente depois do schema inicial do WASH FLOW.
-- O banco remoto já recebeu estas alterações.
create unique index if not exists uq_wash_one_active_vehicle on public.wash_queue(site_id,vehicle_id) where status <> 'Concluido';
create or replace function private.guard_queue_insert() returns trigger language plpgsql security invoker set search_path='' as $$
declare v_plate text;
begin
 if new.status <> 'NaFila' then raise exception 'Nova lavagem deve iniciar na fila'; end if;
 select plate into v_plate from public.vehicles where id=new.vehicle_id and site_id=new.site_id;
 if v_plate is null then raise exception 'Veículo não pertence à unidade'; end if;
 new.plate:=v_plate;new.started_at:=null;new.finished_at:=null;new.rejection_reason:=null;
 return new;
end $$;
drop trigger if exists trg_guard_queue_insert on public.wash_queue;
create trigger trg_guard_queue_insert before insert on public.wash_queue for each row execute function private.guard_queue_insert();
create or replace function public.assign_site_member(p_site_id uuid,p_email text,p_role text) returns void language plpgsql security definer set search_path='' as $$
declare target_user uuid;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 if not (private.is_platform_admin() or private.has_site_role(p_site_id,array['owner'])) then raise exception 'Sem permissão'; end if;
 if p_role not in ('owner','manager','operator','inspector') then raise exception 'Função inválida'; end if;
 select id into target_user from auth.users where lower(email)=lower(trim(p_email));
 if target_user is null then raise exception 'Usuário ainda não possui conta'; end if;
 insert into public.site_members(site_id,user_id,role) values(p_site_id,target_user,p_role)
 on conflict(site_id,user_id) do update set role=excluded.role;
end $$;
revoke all on function public.assign_site_member(uuid,text,text) from public,anon;
grant execute on function public.assign_site_member(uuid,text,text) to authenticated;
revoke insert,update,delete on public.platform_admins from anon,authenticated;
revoke insert,update,delete on public.wash_history from anon,authenticated;
revoke delete on public.vehicles,public.wash_queue from anon,authenticated;
revoke update on public.site_members from anon,authenticated;
create or replace function private.guard_vehicle_update() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.id<>old.id or new.site_id<>old.site_id or new.created_at<>old.created_at then raise exception 'Identificadores e unidade são imutáveis'; end if;
 return new;
end $$;
drop trigger if exists trg_guard_vehicle_update on public.vehicles;
create trigger trg_guard_vehicle_update before update on public.vehicles for each row execute function private.guard_vehicle_update();

-- Privileged implementations are stored in non-exposed private schema.
-- Public RPC entrypoints are SECURITY INVOKER wrappers; authorization remains
-- enforced inside the private SECURITY DEFINER implementations.
create or replace function private.complete_wash_impl(p_job_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Lavagem não encontrada'; end if;
 if not (private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','inspector'])) then raise exception 'Sem permissão'; end if;
 if j.status<>'AguardandoConferencia' then raise exception 'Lavagem não está em conferência'; end if;
 insert into public.wash_history(site_id,vehicle_id,plate,priority,source_job_id,duration_seconds)
 values(j.site_id,j.vehicle_id,j.plate,j.priority,j.id,case when j.started_at is not null then greatest(0,extract(epoch from now()-j.started_at)::integer) else null end);
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
