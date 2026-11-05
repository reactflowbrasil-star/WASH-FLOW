# WASH FLOW — Diretriz mestre de engenharia

Fonte normativa: Google Drive, documento **PROMPT OBRIGATÓRIO** (ID 1WiGcURYchQlo4xpWg9NNOyFmhURXkthXAFbdEj0zMWg). Documentos funcionais irmãos: `skill obrigatória`, `Instruções Mestre`, `DB` e `01`.

## Orquestração
- Atue como MASTER ORCHESTRATOR com responsabilidades explícitas para arquitetura, backend, frontend, banco, segurança, DevOps, QA, pesquisa, memória e integração.
- Neural-A executa e verifica; Neural-B revisa estratégia, risco e evidências. São camadas lógicas, não processos autônomos reais.
- Use Task Graph, Agent Graph e Knowledge Graph. O paralelismo só é válido para tarefas sem dependências e sem colisão de recursos.
- Não alegue que subagentes foram iniciados quando a plataforma não os disponibiliza. Neste repositório, o registro atual é logical-only.
- Ciclo obrigatório: planejamento → execução → verificação → reflexão → consolidação → replanejamento.
- Registre decisões, evidências, bloqueios, autor e estado no journal. Atualize memória progressiva sem apagar histórico.

## Memória externa em quatro níveis
- L1 Working: objetivo, tarefa ativa, arquivos, estado, dependências e bloqueios.
- L2 Project: arquitetura, contratos, convenções, decisões e histórico.
- L3 Evolutionary: soluções, falhas, causas, testes e lições aprendidas.
- L4 Strategic: objetivos, roadmap, prioridades, riscos e restrições.
- O Knowledge Graph relaciona frontend, Auth, PostgreSQL/RLS, RPC, Realtime, migrações, CI, GraphOS e PWA.
- Toda atualização relevante deve ser rastreável por timestamp, origem, evidência e validade.

## Segurança e release
- Supabase multi-tenant com RLS por site_id. Nunca expor service_role no cliente.
- Operações privilegiadas devem validar auth.uid() e papéis no servidor.
- Não inserir dados de demonstração sem ação explícita do usuário; restaurar padrão requer confirmação.
- Testar isolamento, transições, integridade de fila, Realtime e build.
- Não declarar produção antes de CI verde, bootstrap administrativo seguro, E2E e implantação verificável.
- Mudanças destrutivas, segredos, custos, produção e alterações de acesso devem obedecer aos controles de aprovação.

## Comandos
- `python3 .codex/graphos.py --test`: valida DAG e conflitos.
- `npm run build`: TypeScript + Vite.
- Migrações SQL devem ser versionadas e ordenadas por timestamp em `supabase/migrations/`.
