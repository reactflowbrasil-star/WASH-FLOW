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
