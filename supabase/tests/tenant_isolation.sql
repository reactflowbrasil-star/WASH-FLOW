-- Execute no SQL Editor do projeto de homologação.
-- Todos os registros criados aqui são revertidos por ROLLBACK.
BEGIN;
INSERT INTO public.sites(name,slug) VALUES ('TESTE RLS','teste-rls-smoke-rollback');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
DO $$
BEGIN
 IF (SELECT count(*) FROM public.sites WHERE slug='teste-rls-smoke-rollback') <> 0 THEN
   RAISE EXCEPTION 'FALHA: unidade de outro tenant visível';
 END IF;
END $$;
ROLLBACK;

BEGIN;
DO $$
DECLARE sid uuid; vid uuid; blocked boolean:=false;
BEGIN
 INSERT INTO public.sites(name,slug) VALUES ('TESTE FILA','teste-fila-smoke-rollback') RETURNING id INTO sid;
 INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group) VALUES(sid,'TESTE123','Teste','Teste','Teste') RETURNING id INTO vid;
 INSERT INTO public.wash_queue(site_id,vehicle_id,plate) VALUES(sid,vid,'TESTE123');
 BEGIN
   INSERT INTO public.wash_queue(site_id,vehicle_id,plate) VALUES(sid,vid,'TESTE123');
 EXCEPTION WHEN unique_violation THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'FALHA: lavagem duplicada permitida'; END IF;
END $$;
ROLLBACK;

-- A sessão autenticada sem vínculo não pode avançar a fila.
BEGIN;
DO $$
DECLARE sid uuid; vid uuid; jid uuid; blocked boolean:=false;
BEGIN
 INSERT INTO public.sites(name,slug) VALUES ('TESTE AUTH','teste-auth-smoke-rollback') RETURNING id INTO sid;
 INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group) VALUES(sid,'AUTH123','Teste','Teste','Teste') RETURNING id INTO vid;
 INSERT INTO public.wash_queue(site_id,vehicle_id,plate) VALUES(sid,vid,'AUTH123') RETURNING id INTO jid;
 PERFORM set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000099',true);
 BEGIN
   PERFORM public.transition_wash(jid,'Lavando',NULL);
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM='Sem permissão' THEN blocked:=true; ELSE RAISE; END IF;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'FALHA: usuário externo avançou a fila'; END IF;
END $$;
ROLLBACK;

-- Teste de dois tenants com usuários distintos: leitura e RPC não atravessam unidade.
-- Usa usuários sintéticos dentro da transação; tudo é revertido no final.
BEGIN;
INSERT INTO auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at,is_sso_user,is_anonymous)
VALUES
 ('00000000-0000-4000-8000-0000000000a1','authenticated','authenticated','tenant-a-smoke@example.invalid','',now(),now(),now(),false,false),
 ('00000000-0000-4000-8000-0000000000b2','authenticated','authenticated','tenant-b-smoke@example.invalid','',now(),now(),now(),false,false);
INSERT INTO public.sites(name,slug) VALUES ('TENANT A','tenant-a-rls-smoke'),('TENANT B','tenant-b-rls-smoke');
INSERT INTO public.site_members(site_id,user_id,role)
SELECT id,'00000000-0000-4000-8000-0000000000a1','operator' FROM public.sites WHERE slug='tenant-a-rls-smoke';
INSERT INTO public.site_members(site_id,user_id,role)
SELECT id,'00000000-0000-4000-8000-0000000000b2','operator' FROM public.sites WHERE slug='tenant-b-rls-smoke';
INSERT INTO public.vehicles(site_id,plate,brand,model,vehicle_group)
SELECT id,'TENB123','Teste','Tenant B','AM' FROM public.sites WHERE slug='tenant-b-rls-smoke';
INSERT INTO public.wash_queue(site_id,vehicle_id,plate)
SELECT v.site_id,v.id,v.plate FROM public.vehicles v WHERE v.plate='TENB123';
SELECT set_config('test.job_id',(SELECT id::text FROM public.wash_queue WHERE plate='TENB123'),true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000a1',true);
DO $$
DECLARE visible_count integer; denied boolean:=false; jid uuid;
BEGIN
 SELECT count(*) INTO visible_count FROM public.sites;
 IF visible_count<>1 THEN RAISE EXCEPTION 'FALHA: tenant A viu % unidades; esperado 1',visible_count; END IF;
 SELECT count(*) INTO visible_count FROM public.wash_queue WHERE plate='TENB123';
 IF visible_count<>0 THEN RAISE EXCEPTION 'FALHA: tenant A leu fila de tenant B'; END IF;
 jid:=current_setting('test.job_id')::uuid;
 BEGIN
  PERFORM public.transition_wash(jid,'Lavando',NULL);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM='Sem permissão' THEN denied:=true; ELSE RAISE; END IF;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'FALHA: tenant A alterou lavagem de tenant B'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000b2',true);
DO $$
DECLARE visible_count integer;
BEGIN
 SELECT count(*) INTO visible_count FROM public.sites;
 IF visible_count<>1 THEN RAISE EXCEPTION 'FALHA: tenant B viu % unidades; esperado 1',visible_count; END IF;
END $$;
ROLLBACK;
