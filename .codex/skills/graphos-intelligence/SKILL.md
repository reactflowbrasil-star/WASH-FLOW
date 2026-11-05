---
name: graphos-intelligence
description: Orchestrate WASH FLOW engineering work with Task Graph, Agent Graph, Knowledge Graph, conflict-aware parallel scheduling, bi-neural review and persistent L1-L4 memory.
---

# GraphOS Intelligence Skill

Use this skill when continuing project development, decomposing work, coordinating parallel tasks, reviewing changes, resuming after interruption, or updating project memory.

## Operating contract
1. Recover strategic memory, current working memory, task graph, agent registry, resource locks and latest execution journal before editing.
2. Inspect repository state, CI, Supabase migration history, security advisories and source-of-truth Drive documents.
3. Decompose work into tasks with unique IDs, priorities, owners, dependencies, resources and acceptance evidence.
4. Schedule only ready tasks. Do not schedule DONE/INTEGRATED work again. Report blocked tasks separately.
5. Do not edit the same resource concurrently. Serialize migrations and same-file Git writes.
6. Verify every database change with a transaction or migration test; verify frontend changes with CI.
7. Run cross-review proportional to risk, record the cause and fix for discovered bugs, and update L1-L4 memory.
8. Never claim real subagents are active unless the host provides and confirms their execution. The current registry is logical-only.
9. Never claim production deployment before the build, role-matrix E2E, real admin bootstrap and hosting verification pass.

## Bi-neural workflow
- Neural-A: implementation, tests, diagnostics and evidence.
- Neural-B: strategy, dependency review, risk analysis and memory consolidation.
- Synchronize both through: Planning → Execution → Verification → Reflection → Consolidation → Replanning.

These are logical responsibility layers, not separate model instances or autonomous learning processes.

## Graphs
- Task Graph: .codex/orchestration/task-graph.json
- Agent Graph: .codex/orchestration/agents-registry.json
- Knowledge Graph: .codex/knowledge/knowledge-graph.json
- Resource locks: .codex/orchestration/resource-locks.json
- Execution journal: .codex/orchestration/execution-journal.jsonl

## Memory levels
- L1 Working: .codex/memory/working/current.json
- L2 Project: .codex/memory/project/architecture.json
- L3 Evolutionary: .codex/memory/evolutionary/lessons.json
- L4 Strategic: .codex/memory/strategic/project.json

Keep memory versioned and evidence-based. Do not store credentials, tokens, passwords or unnecessary personal data.

## Commands
- Validate tests and produce the current schedule: python3 .codex/graphos.py --test
- The scheduler outputs execution_waves and blocked_tasks. Resolve blockers or update their dependency before replanning.
- CI runs GraphOS validation and the TypeScript/Vite build on pushes and pull requests to main.

## WASH FLOW safety rules
- Supabase is multi-tenant; enforce site_id scope and RLS.
- Privileged functions live in private schema and validate auth.uid() plus role.
- Do not expose service_role in frontend.
- Preserve the immutable wash_history trail.
- Only allow removal of unstarted queue entries through the authorized RPC.
- First platform admin must be a real, controlled Auth account; never bootstrap an arbitrary account.
- Apply reversible tests inside transactions and confirm rollback leaves no records.
