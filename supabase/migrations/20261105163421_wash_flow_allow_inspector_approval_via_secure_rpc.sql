-- A restrição especial de inspetor se aplica a DML direto; RPCs SECURITY DEFINER
-- fazem sua própria autorização e precisam concluir a aprovação atômica.
create or replace function private.guard_queue_update() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.id<>old.id or new.site_id<>old.site_id or new.vehicle_id<>old.vehicle_id or new.plate<>old.plate or new.created_at<>old.created_at then raise exception 'Campos imutáveis'; end if;
 if old.status='Concluido' then raise exception 'Lavagem concluída não pode ser editada'; end if;
 if new.status='Concluido' and current_user<>'postgres' then raise exception 'Conclua via complete_wash'; end if;
 if current_user<>'postgres' and private.has_site_role(old.site_id,array['inspector']) and not(private.is_platform_admin() or private.has_site_role(old.site_id,array['owner','manager','operator'])) then
  if old.status<>'AguardandoConferencia' or new.status<>'Refazer' or new.rejection_reason is null then raise exception 'Inspetor só pode solicitar retrabalho'; end if;
  if new.priority<>old.priority or new.notes is distinct from old.notes or new.started_at is distinct from old.started_at then raise exception 'Alteração não autorizada'; end if;
 end if;
 return new;
end $$;
