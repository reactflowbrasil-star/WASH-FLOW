-- Execute como postgres para validar grants/RPC sem criar dados.
do $$
declare
  t text;
begin
  foreach t in array array['platform_admins','sites','site_members','vehicles','wash_queue','wash_history'] loop
    if has_table_privilege('anon','public.'||t,'select')
       or has_table_privilege('anon','public.'||t,'insert')
       or has_table_privilege('anon','public.'||t,'update')
       or has_table_privilege('anon','public.'||t,'delete') then
      raise exception 'anon possui privilégio inesperado em public.%',t;
    end if;
  end loop;
  if not has_table_privilege('authenticated','public.vehicles','select')
     or not has_table_privilege('authenticated','public.vehicles','insert')
     or not has_table_privilege('authenticated','public.wash_queue','insert')
     or not has_table_privilege('authenticated','public.wash_history','select') then
    raise exception 'Privilégios necessários do app ausentes';
  end if;
  if has_table_privilege('authenticated','public.wash_queue','update')
     or has_table_privilege('authenticated','public.wash_history','insert')
     or has_table_privilege('authenticated','public.platform_admins','insert') then
    raise exception 'Privilégio direto proibido concedido';
  end if;
  if has_function_privilege('anon','public.complete_wash(uuid)','execute')
     or has_function_privilege('anon','public.transition_wash(uuid,text,text)','execute') then
    raise exception 'anon pode executar RPC operacional';
  end if;
  if has_function_privilege('authenticated','private.guard_queue_update()','execute') then
    raise exception 'Cliente pode executar função interna de trigger';
  end if;
end $$;
