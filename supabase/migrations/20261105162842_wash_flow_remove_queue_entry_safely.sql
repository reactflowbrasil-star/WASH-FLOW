-- Remoção segura apenas de itens ainda não iniciados na fila.
create or replace function private.remove_wash_from_queue_impl(p_job_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare j public.wash_queue%rowtype;
begin
 if (select auth.uid()) is null then raise exception 'Não autenticado'; end if;
 select * into j from public.wash_queue where id=p_job_id for update;
 if not found then raise exception 'Item da fila não encontrado'; end if;
 if not (private.is_platform_admin() or private.has_site_role(j.site_id,array['owner','manager','operator'])) then raise exception 'Sem permissão'; end if;
 if j.status<>'NaFila' then raise exception 'Só é possível remover veículos que ainda estão na fila'; end if;
 delete from public.wash_queue where id=j.id;
end $$;
revoke all on function private.remove_wash_from_queue_impl(uuid) from public,anon;
grant execute on function private.remove_wash_from_queue_impl(uuid) to authenticated;
create or replace function public.remove_wash_from_queue(p_job_id uuid) returns void language sql set search_path='' as $$ select private.remove_wash_from_queue_impl(p_job_id) $$;
revoke all on function public.remove_wash_from_queue(uuid) from public,anon;
grant execute on function public.remove_wash_from_queue(uuid) to authenticated;
