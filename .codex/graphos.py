#!/usr/bin/env python3
"""GraphOS: scheduler DAG, Knowledge Graph validator and persistent planning output.
The registry is logical-only unless the host platform actually provides subagent execution.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).parent
GRAPH = ROOT / "orchestration" / "task-graph.json"
KNOWLEDGE = ROOT / "knowledge" / "knowledge-graph.json"
DONE = {"DONE", "INTEGRATED"}
BLOCKED = {"BLOCKED", "FAILED", "CANCELLED"}


def schedule(tasks):
    ids = [task["id"] for task in tasks]
    if len(ids) != len(set(ids)):
        raise ValueError("IDs de tarefa duplicados")
    known = set(ids)
    for task in tasks:
        missing = set(task.get("dependencies", [])) - known
        if missing:
            raise ValueError(f"Dependências inexistentes em {task['id']}: {sorted(missing)}")

    status = {task["id"]: task.get("status", "READY").upper() for task in tasks}
    done = {task_id for task_id, state in status.items() if state in DONE}
    blocked = {task_id for task_id, state in status.items() if state in BLOCKED}
    remaining = {task["id"]: task for task in tasks
                 if status[task["id"]] not in DONE | BLOCKED}
    result = []

    while remaining:
        ready = [task for task in remaining.values()
                 if set(task.get("dependencies", [])) <= done]
        if not ready:
            blocked.update(remaining.keys())
            break
        ready.sort(key=lambda task: (-task.get("priority", 0), task["id"]))
        wave = []
        locked = set()
        for task in ready:
            resources = set(task.get("resources", []))
            if not resources.intersection(locked):
                wave.append(task)
                locked.update(resources)
        if not wave:
            blocked.update(remaining.keys())
            break
        completed = [task["id"] for task in wave]
        result.append(completed)
        done.update(completed)
        for task_id in completed:
            remaining.pop(task_id)

    return {"execution_waves": result, "blocked_tasks": sorted(blocked)}


def validate_knowledge(graph):
    nodes = [node["id"] for node in graph.get("nodes", [])]
    if len(nodes) != len(set(nodes)):
        raise ValueError("IDs duplicados no Knowledge Graph")
    known = set(nodes)
    seen_edges = set()
    for edge in graph.get("edges", []):
        if edge.get("from") not in known or edge.get("to") not in known:
            raise ValueError("Aresta aponta para nó inexistente")
        if not edge.get("type"):
            raise ValueError("Aresta sem tipo")
        key = (edge["from"], edge["to"], edge["type"])
        if key in seen_edges:
            raise ValueError("Aresta duplicada no Knowledge Graph")
        seen_edges.add(key)
    return True


def run_tests():
    assert schedule([{"id": "a"}, {"id": "b", "dependencies": ["a"]}])["execution_waves"] == [["a"], ["b"]]
    assert schedule([{"id": "a", "resources": ["x"]}, {"id": "b", "resources": ["x"]}])["execution_waves"] == [["a"], ["b"]]
    assert schedule([{"id": "a", "status": "DONE"}, {"id": "b", "dependencies": ["a"]}])["execution_waves"] == [["b"]]
    plan = schedule([{"id": "done", "status": "DONE"}, {"id": "blocked", "status": "BLOCKED"}, {"id": "wait", "dependencies": ["blocked"]}, {"id": "ready"}])
    assert plan["execution_waves"] == [["ready"]] and plan["blocked_tasks"] == ["blocked", "wait"]
    cycle = schedule([{"id": "a", "dependencies": ["b"]}, {"id": "b", "dependencies": ["a"]}])
    assert cycle["execution_waves"] == [] and cycle["blocked_tasks"] == ["a", "b"]
    try:
        schedule([{"id": "a", "dependencies": ["missing"]}])
        raise AssertionError("Dependência inexistente não detectada")
    except ValueError:
        pass
    try:
        schedule([{"id": "a"}, {"id": "a"}])
        raise AssertionError("ID duplicado não detectado")
    except ValueError:
        pass
    assert validate_knowledge({"nodes": [{"id": "a"}, {"id": "b"}], "edges": [{"from": "a", "to": "b", "type": "depends"}]})
    try:
        validate_knowledge({"nodes": [{"id": "a"}], "edges": [{"from": "a", "to": "missing", "type": "depends"}]})
        raise AssertionError("Aresta inválida não detectada")
    except ValueError:
        pass
    print("GraphOS: 8 testes aprovados")


if __name__ == "__main__":
    tasks = json.loads(GRAPH.read_text(encoding="utf-8"))["tasks"]
    knowledge = json.loads(KNOWLEDGE.read_text(encoding="utf-8"))
    validate_knowledge(knowledge)
    if "--test" in sys.argv:
        run_tests()
    output = schedule(tasks)
    output["knowledge_nodes"] = len(knowledge["nodes"])
    output["knowledge_edges"] = len(knowledge["edges"])
    print(json.dumps(output, ensure_ascii=False, indent=2))
