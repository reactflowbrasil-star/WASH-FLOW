-- Smoke test transacional: usuário sem vínculo não altera prioridade nem exclui veículo.
-- Execute apenas em homologação. Todos os dados são revertidos.
BEGIN;
DO $$
DECLARE sid uuid; vid uuid; jid uuid; blocked_priority boolean:=false; blocked_delete boolean:=false;
BEGIN
 INSERT INTO public.sites(name,slug) VALUES('TESTE RPC','teste-rpc-rollback') RETURNING id INTO sid;
 INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group) VALUES(sid,'RPC1234','Teste','Teste','AM') RETURNING id INTO vid;
 INSERT INTO public.wash_queue(site_id,vehicle_id,plate) VALUES(sid,vid,'RPC1234') RETURNING id INTO jid;
 PERFORM set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000099',true);
 BEGIN
  PERFORM public.update_wash_priority(jid,'Urgente');
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='Sem permissão' THEN blocked_priority:=true; ELSE RAISE; END IF;
 END;
 BEGIN
  PERFORM public.delete_vehicle(vid);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='Somente proprietário ou gerente pode excluir veículos' THEN blocked_delete:=true; ELSE RAISE; END IF;
 END;
 IF NOT blocked_priority THEN RAISE EXCEPTION 'FALHA: usuário sem vínculo alterou prioridade'; END IF;
 IF NOT blocked_delete THEN RAISE EXCEPTION 'FALHA: usuário sem papel excluiu veículo'; END IF;
END $$;
ROLLBACK;
