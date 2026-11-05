# Protocolo de comunicação

Mensagens persistentes devem conter message_id, timestamp, sender, receiver, task_id, event_type, summary, dependencies, artifacts, required_action e status.

Eventos: TASK_CREATED, TASK_ASSIGNED, TASK_STARTED, DEPENDENCY_RESOLVED, BLOCKER_DETECTED, REVIEW_REQUESTED, TEST_FAILED, TASK_COMPLETED, MEMORY_UPDATED e INTEGRATION_APPROVED.

Quando comunicação direta entre agentes não estiver disponível, registrar no task-graph.json e execution-journal.jsonl. Não inventar mensagens nem processos.
