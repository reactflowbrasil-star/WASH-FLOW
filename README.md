# WASH FLOW

PWA multi-tenant para gestão de lavajatos, frota, fila operacional, conferência de qualidade e histórico. Frontend React + TypeScript + Vite; backend Supabase PostgreSQL/Auth/RLS/Realtime.

## Diretriz normativa
O documento PROMPT OBRIGATÓRIO no Google Drive é a diretriz mestre. Consulte também os documentos skill obrigatória, Instruções Mestre - CarWash Pro, DB, 01 e o arquivo REFERENCIA_ORIGINAL.html. O núcleo de orquestração e a memória persistente ficam em .codex/.

## Funcionalidades implementadas
- Autenticação Supabase e seleção de unidade conforme vínculo do usuário.
- Painel superadministrativo: indicadores globais, cadastro de unidades e suspensão/reativação.
- Equipe por unidade, com papéis owner, manager, operator e inspector.
- Cadastro de frota com dicionário de marcas/modelos, grupos e opções manuais.
- Importação de XLSX, XLS e CSV com identificação de placas em qualquer coluna, diagnóstico por linha e limite de 5.000 veículos por lote.
- Pesquisa de frota e seed automático, idempotente, dos dez veículos de referência na primeira abertura de cada unidade vazia; restauração manual também disponível.
- Entrada na fila com prioridade Baixa/Normal/Alta/Urgente e observações/avarias.
- Peso de prioridade calculado no PostgreSQL (1–4), ordenação por peso e horário, alteração autorizada e prevenção de duplicidade.
- Busca de placa na recepção, preenchimento dos dados do veículo e bloqueio de placa não cadastrada.
- Fluxo NaFila → Lavando → AguardandoConferencia → Concluido ou Refazer.
- Conferência com modal de motivo obrigatório para retrabalho e aprovação atômica por conferente autorizado.
- Remoção controlada de itens ainda não iniciados na fila, validada por RPC.
- Histórico com snapshot de marca/modelo/grupo, horários, observações e duração.
- KPIs de lavagens hoje e no mês, com contagens completas no banco.
- Supabase Realtime por unidade, contadores nas abas e notificações Sonner para urgentes, conferência e retrabalho.
- Manifest PWA, orientação portrait-primary, metadados mobile/iOS, botão de instalação com prompt Android/Chrome e instruções de instalação manual no iPhone; Service Worker versionado com pré-cache dos assets JS/CSS compilados, fallback de navegação offline e limpeza de caches antigos.

## Instalação e desenvolvimento
1. npm install
2. Copie .env.example para .env.
3. O `.env.example` já contém a URL e a publishable key pública deste projeto. Copie para `.env` quando necessário; nunca use service_role/secret key no frontend.
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
- Task Graph, Agent Graph, Knowledge Graph e memórias L1 Working, L2 Project, L3 Evolutionary e L4 Strategic versionados em .codex/.
- Skill reutilizável em .codex/skills/graphos-intelligence/; planejador DAG valida IDs, dependências, ciclos, status e conflitos de recursos, e o Knowledge Graph valida nós/arestas.
- Neural-A representa execução/verificação; Neural-B representa estratégia/revisão.
- A equipe está em modo logical-only: os perfis especializados são responsabilidades registradas, não processos externos de subagentes ativos.
- O GitHub Actions executa os testes GraphOS e o build TypeScript/Vite.

## Testes automatizados
- `npm test`: sete cenários do parser de importação, cobrindo cabeçalhos com acentos e colunas fora de ordem, placas Mercosul/antigas, linhas inválidas, duplicidades, grupos e isolamento por unidade.
- CI executa os testes antes do build TypeScript/Vite.

## Evolução recente (05/11/2026)
- SheetJS: leitura XLSX/XLS/CSV, normalização de placas, upsert em lote e diagnóstico da planilha.
- Service Worker wash-flow-v3: pré-cache dos assets compilados detectados no HTML, fallback offline e remoção de versões antigas; sintaxe validada com Node.
- Publicação Realtime confirmada para vehicles, wash_queue e wash_history.
- Segurança Supabase: zero findings; performance advisor mostra quatro índices ainda não utilizados no banco vazio (informativo).

## Evidências recentes
- GitHub Actions: build aprovado no commit 40a6a3c1410bb0ffc4df46a3611a4fb5f48f7647.
- GraphOS: oito testes do planejador/DAG e Knowledge Graph; escalonador ignora tarefas DONE/INTEGRATED e reporta bloqueadas sem reexecutá-las.
- Supabase Security Advisor: zero findings na última auditoria.
- Supabase Performance Advisor: somente avisos informativos de índices ainda sem uso, esperados porque o banco de homologação está vazio.
- Testes SQL versionados em `supabase/tests/`: isolamento RLS, bloqueio de duplicidade e regressão de privilégios mínimos (sem acesso anon; sem DML direto proibido; RPCs apenas para authenticated).

## Pendências antes de produção
- Criar e vincular o primeiro superadministrador real.
- Executar E2E com duas unidades e a matriz completa de papéis.
- Validar notificações e Realtime em dois dispositivos físicos.
- Verificar instalação PWA e comportamento de reconexão em dispositivos reais.
- Conectar hospedagem (Vercel/Netlify) e validar uma URL pública.
- Revisão final de segurança e aceite humano antes de release.

**Estado atual: build e planejamento automatizado validados; sistema em homologação, ainda não publicado em produção.**
