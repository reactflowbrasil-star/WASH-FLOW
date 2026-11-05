-- Exclusão controlada: apenas proprietário/gerente e somente sem histórico operacional.
create or replace function private.delete_vehicle_impl(p_vehicle_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare v public.vehicles%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into v from public.vehicles where id=p_vehicle_id for update;
 if not found then raise exception 'Veículo não encontrado'; end if;
 if not (private.is_platform_admin() or private.has_site_role(v.site_id,array['owner','manager'])) then raise exception 'Somente proprietário ou gerente pode excluir veículos'; end if;
 if exists(select 1 from public.wash_queue where vehicle_id=v.id and site_id=v.site_id) or exists(select 1 from public.wash_history where vehicle_id=v.id and site_id=v.site_id) then raise exception 'Veículo possui histórico operacional e não pode ser excluído'; end if;
 delete from public.vehicles where id=v.id;
end $$;
revoke all on function private.delete_vehicle_impl(uuid) from public,anon;
grant execute on function private.delete_vehicle_impl(uuid) to authenticated;
create or replace function public.delete_vehicle(p_vehicle_id uuid) returns void language sql set search_path='' as $$ select private.delete_vehicle_impl(p_vehicle_id) $$;
revoke all on function public.delete_vehicle(uuid) from public,anon;
grant execute on function public.delete_vehicle(uuid) to authenticated;
