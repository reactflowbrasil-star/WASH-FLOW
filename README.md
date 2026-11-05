# WASH FLOW

PWA multi-tenant de gestão de lavajatos. Supabase: `ubjzgvwukkseutlmonth` (Canal360 / São Paulo).

## Instalação
`npm install && npm run build` e `npm run dev`. Copie `.env.example` para `.env` e informe a chave pública `sb_publishable_...` do projeto Supabase. Nunca versione segredos.

## Situação
Banco com tabelas `sites`, `site_members`, `platform_admins`, `vehicles`, `wash_queue`, `wash_history`, RLS e RPCs `transition_wash` / `complete_wash` já instaladas. Frontend inicial publicado neste repositório. Ainda faltam testes E2E e bootstrap de superadmin; **não é produção**.

## Diretriz mestre
Google Drive: documento PROMPT OBRIGATÓRIO e documentos complementares. O pacote local completo inclui a orquestração GraphOS.

## Primeiro acesso administrativo

1. Copie `.env.example` para `.env` e execute `npm install && npm run dev`.
2. Cadastre uma conta pelo formulário **Criar conta** e confirme o e-mail, se exigido.
3. No SQL Editor do projeto Supabase, execute o comando abaixo **substituindo o e-mail** pela conta que você controla:

```sql
insert into public.platform_admins(user_id)
select id from auth.users where lower(email)=lower('SEU_EMAIL_AQUI')
on conflict (user_id) do nothing;
```

4. Entre novamente. O menu **Admin** permitirá cadastrar unidades. Depois vincule a equipe por e-mail.

**Não execute o bootstrap para uma conta desconhecida.** No momento da implantação inicial, o projeto Supabase ainda não tinha usuários cadastrados.

## Verificações pendentes

- Build do frontend e teste real do workflow CI.
- Testes E2E com contas de unidades diferentes e conferentes.
- Importação XLSX (CSV já implementado).
- Auditoria das funções `SECURITY DEFINER` (avisos do Supabase).
- Publicação em hospedagem e validação do service worker PWA.
