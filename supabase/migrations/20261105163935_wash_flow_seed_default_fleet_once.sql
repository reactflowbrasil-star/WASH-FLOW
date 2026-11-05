-- Carrega a frota de referência uma única vez por unidade vazia.
alter table public.sites add column if not exists default_fleet_seeded boolean not null default false;
create or replace function private.ensure_default_fleet_impl(p_site_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare already_seeded boolean; vehicle_count integer;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 if not (private.is_platform_admin() or private.has_site_role(p_site_id,array['owner','manager','operator','inspector'])) then raise exception 'Sem permissão'; end if;
 select default_fleet_seeded into already_seeded from public.sites where id=p_site_id and status='active' for update;
 if not found then raise exception 'Unidade não encontrada ou suspensa'; end if;
 if already_seeded then return; end if;
 select count(*) into vehicle_count from public.vehicles where site_id=p_site_id;
 if vehicle_count=0 then
  insert into public.vehicles(site_id,plate,brand,model,vehicle_group) values
  (p_site_id,'BHZ7A01','Toyota','Corolla','AM'),
  (p_site_id,'BHZ7B02','Jeep','Compass','SU'),
  (p_site_id,'BHZ7A03','Chevrolet','Onix','B'),
  (p_site_id,'BHZ7A04','Fiat','Strada','BS'),
  (p_site_id,'BHZ7A05','Volkswagen','Polo','EA'),
  (p_site_id,'BHZ7A06','Hyundai','HB20','CA'),
  (p_site_id,'BHZ7A07','Renault','Kwid','SU'),
  (p_site_id,'BHZ7A08','Honda','Civic','AM'),
  (p_site_id,'BHZ7A09','Nissan','Kicks','SU'),
  (p_site_id,'BHZ7A10','Toyota','Hilux','AT')
  on conflict(site_id,plate) do nothing;
 end if;
 update public.sites set default_fleet_seeded=true where id=p_site_id;
end $$;
revoke all on function private.ensure_default_fleet_impl(uuid) from public,anon;
grant execute on function private.ensure_default_fleet_impl(uuid) to authenticated;
create or replace function public.ensure_default_fleet(p_site_id uuid) returns void language sql security invoker set search_path='' as $$ select private.ensure_default_fleet_impl(p_site_id) $$;
revoke all on function public.ensure_default_fleet(uuid) from public,anon;
grant execute on function public.ensure_default_fleet(uuid) to authenticated;
