# WASH FLOW

PWA multi-tenant de gestão de lavajatos. Supabase: `ubjzgvwukkseutlmonth` (Canal360 / São Paulo).

## Instalação
`npm install && npm run build` e `npm run dev`. Copie `.env.example` para `.env` e informe a chave pública `sb_publishable_...` do projeto Supabase. Nunca versione segredos.

## Situação
Banco com tabelas `sites`, `site_members`, `platform_admins`, `vehicles`, `wash_queue`, `wash_history`, RLS e RPCs `transition_wash` / `complete_wash` já instaladas. Frontend inicial publicado neste repositório. Ainda faltam testes E2E e bootstrap de superadmin; **não é produção**.

## Diretriz mestre
Google Drive: documento PROMPT OBRIGATÓRIO e documentos complementares. O pacote local completo inclui a orquestração GraphOS.
