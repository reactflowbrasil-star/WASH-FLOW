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
create or replace function private.guard_queue_update() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.id<>old.id or new.site_id<>old.site_id or new.vehicle_id<>old.vehicle_id or new.plate<>old.plate or new.created_at<>old.created_at then raise exception 'Campos imutáveis'; end if;
 if old.status='Concluido' then raise exception 'Lavagem concluída não pode ser editada'; end if;
 if new.status='Concluido' and current_user<>'postgres' then raise exception 'Conclua via complete_wash'; end if;
 if private.has_site_role(old.site_id,array['inspector']) and not(private.is_platform_admin() or private.has_site_role(old.site_id,array['owner','manager','operator'])) then
  if old.status<>'AguardandoConferencia' or new.status<>'Refazer' or new.rejection_reason is null then raise exception 'Inspetor só pode solicitar retrabalho'; end if;
  if new.priority<>old.priority or new.notes is distinct from old.notes or new.started_at is distinct from old.started_at then raise exception 'Alteração não autorizada'; end if;
 end if;
 return new;
end $$;
drop trigger if exists trg_guard_queue_update on public.wash_queue;
create trigger trg_guard_queue_update before update on public.wash_queue for each row execute function private.guard_queue_update();
