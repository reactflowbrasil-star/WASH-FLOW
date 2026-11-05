# WASH FLOW

PWA multi-tenant para gestão de lavajatos, frota, fila operacional, conferência de qualidade e histórico. Frontend React + TypeScript + Vite; backend Supabase PostgreSQL/Auth/RLS/Realtime.

## Diretriz normativa
O documento PROMPT OBRIGATÓRIO no Google Drive é a diretriz mestre. Consulte também os documentos skill obrigatória, Instruções Mestre - CarWash Pro, DB, 01 e o arquivo REFERENCIA_ORIGINAL.html. O núcleo de orquestração e a memória persistente ficam em .codex/.

## Funcionalidades implementadas
- Autenticação Supabase e seleção de unidade conforme vínculo do usuário.
- Painel superadministrativo: indicadores globais, cadastro de unidades e suspensão/reativação.
- Equipe por unidade, com papéis owner, manager, operator e inspector.
- Cadastro de frota com dicionário de marcas/modelos, grupos e opções manuais.
- Importação de XLSX, XLS e CSV com diagnóstico por linha e limite de 1.000 veículos por lote.
- Pesquisa de frota e restauração confirmada dos dez veículos de referência.
- Entrada na fila com prioridade Baixa/Normal/Alta/Urgente e observações/avarias.
- Ordenação por prioridade, alteração autorizada de prioridade e prevenção de duplicidade.
- Fluxo NaFila → Lavando → AguardandoConferencia → Concluido ou Refazer.
- Conferência com modal de motivo obrigatório para retrabalho e aprovação atômica.
- Remoção controlada de itens ainda não iniciados na fila, validada por RPC.
- Histórico com snapshot de marca/modelo/grupo, horários, observações e duração.
- KPIs de lavagens hoje e no mês, com contagens completas no banco.
- Supabase Realtime por unidade, contadores nas abas e notificações Sonner para urgentes, conferência e retrabalho.
- Manifest PWA, orientação portrait-primary, metadados mobile/iOS e service worker para cache básico da interface.

## Instalação e desenvolvimento
1. npm install
2. Copie .env.example para .env.
3. Configure VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY com os valores públicos do projeto.
4. npm run dev
5. npm run build
6. python3 .codex/graphos.py --test

Nunca coloque service_role, tokens privados ou credenciais administrativas no frontend ou no Git.

## Supabase
Projeto de desenvolvimento: ubjzgvwukkseutlmonth (Primary / Canal360, região São Paulo).

As migrações aplicadas no banco estão espelhadas em supabase/migrations/. As seis tabelas públicas possuem RLS habilitada. Implementações privilegiadas ficam no schema private; funções RPC expostas usam wrappers SECURITY INVOKER com verificação de identidade e papel nas implementações internas.

### Primeiro superadministrador
O banco está vazio de usuários e unidades. Para ativar o primeiro administrador:
1. Cadastre uma conta pelo formulário Criar conta e confirme o e-mail, se exigido.
2. No SQL Editor do projeto Supabase, substitua o e-mail pela conta que você controla e execute:

```sql
insert into public.platform_admins(user_id)
select id from auth.users where lower(email)=lower('SEU_EMAIL_AQUI')
on conflict (user_id) do nothing;
```

3. Entre novamente e crie a primeira unidade pelo menu Admin.

Não existe bootstrap público de superadmin. Não associe contas desconhecidas.

## GraphOS e coordenação bi-neural
- Task Graph, Agent Graph e Knowledge/Strategic Memory versionados em .codex/.
- Planejador DAG valida IDs, dependências, ciclos e conflitos de recursos.
- Neural-A representa execução/verificação; Neural-B representa estratégia/revisão.
- A equipe está em modo logical-only: os perfis especializados são responsabilidades registradas, não processos externos de subagentes ativos.
- O GitHub Actions executa os testes GraphOS e o build TypeScript/Vite.

## Evidências recentes
- GitHub Actions: build aprovado no commit 40a6a3c1410bb0ffc4df46a3611a4fb5f48f7647.
- GraphOS: cinco testes do planejador aprovados.
- Supabase Security Advisor: zero findings na última auditoria.
- Supabase Performance Advisor: somente avisos informativos de índices ainda sem uso, esperados porque o banco de homologação está vazio.
- Testes transacionais versionados em supabase/tests/tenant_isolation.sql: isolamento RLS, bloqueio de duplicidade e bloqueio de transição por usuário sem vínculo.

## Pendências antes de produção
- Criar e vincular o primeiro superadministrador real.
- Executar E2E com duas unidades e a matriz completa de papéis.
- Validar notificações e Realtime em dois dispositivos físicos.
- Verificar instalação PWA e comportamento de reconexão em dispositivos reais.
- Conectar hospedagem (Vercel/Netlify) e validar uma URL pública.
- Revisão final de segurança e aceite humano antes de release.

**Estado atual: build e planejamento automatizado validados; sistema em homologação, ainda não publicado em produção.**
