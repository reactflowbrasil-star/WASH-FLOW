-- WASH FLOW: exposição explícita da Data API e privilégios mínimos.
-- Todas as tabelas expostas mantêm RLS; anon não recebe acesso a dados operacionais.
revoke all privileges on table
 public.platform_admins,
 public.sites,
 public.site_members,
 public.vehicles,
 public.wash_queue,
 public.wash_history
from public, anon, authenticated;

grant usage on schema public to authenticated;

grant select on table public.platform_admins to authenticated;
grant select, insert, update on table public.sites to authenticated;
grant select on table public.site_members to authenticated;
grant select, insert, update on table public.vehicles to authenticated;
grant select, insert on table public.wash_queue to authenticated;
grant select on table public.wash_history to authenticated;

-- Funções de trigger não são endpoints RPC e não precisam de EXECUTE por clientes.
revoke all on function private.guard_queue_insert() from public, anon, authenticated;
revoke all on function private.guard_queue_update() from public, anon, authenticated;
revoke all on function private.guard_vehicle_update() from public, anon, authenticated;

-- Garantir que nenhum RPC operacional fique executável por visitantes anônimos.
revoke all on function public.assign_site_member(uuid,text,text) from public, anon;
revoke all on function public.complete_wash(uuid) from public, anon;
revoke all on function public.delete_vehicle(uuid) from public, anon;
revoke all on function public.ensure_default_fleet(uuid) from public, anon;
revoke all on function public.remove_wash_from_queue(uuid) from public, anon;
revoke all on function public.transition_wash(uuid,text,text) from public, anon;
revoke all on function public.update_wash_priority(uuid,text) from public, anon;

grant execute on function public.assign_site_member(uuid,text,text) to authenticated;
grant execute on function public.complete_wash(uuid) to authenticated;
grant execute on function public.delete_vehicle(uuid) to authenticated;
grant execute on function public.ensure_default_fleet(uuid) to authenticated;
grant execute on function public.remove_wash_from_queue(uuid) to authenticated;
grant execute on function public.transition_wash(uuid,text,text) to authenticated;
grant execute on function public.update_wash_priority(uuid,text) to authenticated;
