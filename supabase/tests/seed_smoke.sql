-- Seed padrão automático e idempotente por unidade vazia.
-- Usuário e unidade sintéticos; toda a transação é revertida.
BEGIN;
INSERT INTO auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at,is_sso_user,is_anonymous)
VALUES('00000000-0000-4000-8000-0000000000d1','authenticated','authenticated','seed-smoke@example.invalid','',now(),now(),now(),false,false);
INSERT INTO public.sites(name,slug) VALUES('SEED TEST','seed-once-smoke');
INSERT INTO public.site_members(site_id,user_id,role)
SELECT id,'00000000-0000-4000-8000-0000000000d1','operator' FROM public.sites WHERE slug='seed-once-smoke';
SELECT set_config('test.seed_site',(SELECT id::text FROM public.sites WHERE slug='seed-once-smoke'),true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000000d1',true);
SELECT public.ensure_default_fleet(current_setting('test.seed_site')::uuid);
DO $$ DECLARE n integer; BEGIN
 SELECT count(*) INTO n FROM public.vehicles WHERE site_id=current_setting('test.seed_site')::uuid;
 IF n<>10 THEN RAISE EXCEPTION 'Esperados 10 veículos; obtidos %',n; END IF;
END $$;
SELECT public.ensure_default_fleet(current_setting('test.seed_site')::uuid);
DO $$ DECLARE n integer; BEGIN
 SELECT count(*) INTO n FROM public.vehicles WHERE site_id=current_setting('test.seed_site')::uuid;
 IF n<>10 THEN RAISE EXCEPTION 'Seed duplicou veículos: %',n; END IF;
END $$;
ROLLBACK;
