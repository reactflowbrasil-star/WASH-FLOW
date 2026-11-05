create or replace function public.transition_wash(p_job_id uuid,p_next_status text,p_reason text default null) returns void language plpgsql security definer set search_path='' as $$
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
revoke all on function public.transition_wash(uuid,text,text) from public,anon;
grant execute on function public.transition_wash(uuid,text,text) to authenticated;
revoke update on public.wash_queue from authenticated;
