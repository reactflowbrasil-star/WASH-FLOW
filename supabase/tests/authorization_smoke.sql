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

-- Usuário sem vínculo não pode remover um item da fila.
BEGIN;
DO $$
DECLARE sid uuid; vid uuid; jid uuid; blocked_remove boolean:=false;
BEGIN
 INSERT INTO public.sites(name,slug) VALUES('TESTE REMOÇÃO','teste-remove-rollback') RETURNING id INTO sid;
 INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group) VALUES(sid,'RMV1234','Teste','Teste','AM') RETURNING id INTO vid;
 INSERT INTO public.wash_queue(site_id,vehicle_id,plate) VALUES(sid,vid,'RMV1234') RETURNING id INTO jid;
 PERFORM set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000099',true);
 BEGIN
  PERFORM public.remove_wash_from_queue(jid);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='Sem permissão' THEN blocked_remove:=true; ELSE RAISE; END IF;
 END;
 IF NOT blocked_remove THEN RAISE EXCEPTION 'FALHA: usuário sem vínculo removeu item da fila'; END IF;
END $$;
ROLLBACK;

-- Matriz de papéis: owner convida; manager não convida; operator executa; inspector devolve e aprova.
BEGIN;
INSERT INTO auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at,is_sso_user,is_anonymous)
VALUES
 ('00000000-0000-4000-8000-0000000000c1','authenticated','authenticated','owner-smoke@example.invalid','',now(),now(),now(),false,false),
 ('00000000-0000-4000-8000-0000000000c2','authenticated','authenticated','operator-smoke@example.invalid','',now(),now(),now(),false,false),
 ('00000000-0000-4000-8000-0000000000c3','authenticated','authenticated','inspector-smoke@example.invalid','',now(),now(),now(),false,false),
 ('00000000-0000-4000-8000-0000000000c4','authenticated','authenticated','manager-smoke@example.invalid','',now(),now(),now(),false,false),
 ('00000000-0000-4000-8000-0000000000c5','authenticated','authenticated','new-member-smoke@example.invalid','',now(),now(),now(),false,false);
INSERT INTO public.sites(name,slug) VALUES('ROLE MATRIX','role-matrix-smoke');
INSERT INTO public.site_members(site_id,user_id,role) SELECT id,'00000000-0000-4000-8000-0000000000c1','owner' FROM public.sites WHERE slug='role-matrix-smoke';
INSERT INTO public.site_members(site_id,user_id,role) SELECT id,'00000000-0000-4000-8000-0000000000c2','operator' FROM public.sites WHERE slug='role-matrix-smoke';
INSERT INTO public.site_members(site_id,user_id,role) SELECT id,'00000000-0000-4000-8000-0000000000c3','inspector' FROM public.sites WHERE slug='role-matrix-smoke';
INSERT INTO public.site_members(site_id,user_id,role) SELECT id,'00000000-0000-4000-8000-0000000000c4','manager' FROM public.sites WHERE slug='role-matrix-smoke';
INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group) SELECT id,'ROLE123','Teste','Veículo','AM' FROM public.sites WHERE slug='role-matrix-smoke';
INSERT INTO public.wash_queue(site_id,vehicle_id,plate) SELECT v.site_id,v.id,v.plate FROM public.vehicles v WHERE v.plate='ROLE123';
SELECT set_config('test.site_id',(SELECT id::text FROM public.sites WHERE slug='role-matrix-smoke'),true);
SELECT set_config('test.job_id',(SELECT id::text FROM public.wash_queue WHERE plate='ROLE123'),true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c1',true);
SELECT public.assign_site_member(current_setting('test.site_id')::uuid,'new-member-smoke@example.invalid','operator');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c4',true);
DO $$ DECLARE blocked boolean:=false; BEGIN
 BEGIN PERFORM public.assign_site_member(current_setting('test.site_id')::uuid,'new-member-smoke@example.invalid','operator');
 EXCEPTION WHEN OTHERS THEN IF SQLERRM='Sem permissão' THEN blocked:=true; ELSE RAISE; END IF; END;
 IF NOT blocked THEN RAISE EXCEPTION 'FALHA: gerente convidou usuário sem permissão'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c2',true);
SELECT public.transition_wash(current_setting('test.job_id')::uuid,'Lavando',NULL);
SELECT public.transition_wash(current_setting('test.job_id')::uuid,'AguardandoConferencia',NULL);
DO $$ DECLARE blocked boolean:=false; BEGIN
 BEGIN PERFORM public.complete_wash(current_setting('test.job_id')::uuid);
 EXCEPTION WHEN OTHERS THEN IF SQLERRM='Sem permissão' THEN blocked:=true; ELSE RAISE; END IF; END;
 IF NOT blocked THEN RAISE EXCEPTION 'FALHA: operador aprovou lavagem'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c3',true);
SELECT public.transition_wash(current_setting('test.job_id')::uuid,'Refazer','Vidros traseiros manchados');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c2',true);
SELECT public.transition_wash(current_setting('test.job_id')::uuid,'Lavando',NULL);
SELECT public.transition_wash(current_setting('test.job_id')::uuid,'AguardandoConferencia',NULL);
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000c3',true);
SELECT public.complete_wash(current_setting('test.job_id')::uuid);
DO $$ BEGIN
 IF (SELECT count(*) FROM public.wash_history WHERE plate='ROLE123')<>1 THEN RAISE EXCEPTION 'FALHA: histórico não foi criado exatamente uma vez'; END IF;
END $$;
ROLLBACK;
