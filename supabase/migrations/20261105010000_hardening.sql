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
