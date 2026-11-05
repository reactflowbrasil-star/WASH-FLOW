# GraphOS schemas

## Task
Required fields: id, description, owner, priority, dependencies, resources, status, acceptance. Statuses: BACKLOG, READY, RUNNING, REVIEW, TESTING, INTEGRATED, DONE, BLOCKED, FAILED, CANCELLED, RETRY.

## Agent
Required fields: id and specialty. Registry mode must describe actual execution capability. WASH FLOW currently uses logical-only profiles.

## Knowledge
Nodes use unique id, type and label. Edges use valid from/to node IDs and a non-empty relation type. Duplicate edges are rejected.

## Scheduling
Tasks in DONE or INTEGRATED are considered satisfied dependencies and are not rescheduled. BLOCKED, FAILED and CANCELLED tasks are not scheduled; their dependent tasks remain blocked. Ready tasks may share an execution wave only when their resource sets do not intersect. Cycles are reported as blocked rather than silently run.

## Event journal
Every event should include timestamp, sender, receiver, task_id, event_type, summary, dependencies, artifacts, required_action and status.
