#!/usr/bin/env python3
"""GraphOS: planejador DAG com validação de dependências e conflitos de recursos.
Executa planejamento local; não inicia subagentes externos.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).parent
GRAPH = ROOT / "orchestration" / "task-graph.json"
KNOWLEDGE = ROOT / "knowledge" / "knowledge-graph.json"


def waves(tasks):
    ids = [task["id"] for task in tasks]
    if len(ids) != len(set(ids)):
        raise ValueError("IDs de tarefa duplicados")
    known = set(ids)
    for task in tasks:
        missing = set(task.get("dependencies", [])) - known
        if missing:
            raise ValueError(f"Dependências inexistentes em {task['id']}: {sorted(missing)}")
    remaining = {task["id"]: task for task in tasks}
    done = set()
    result = []
    while remaining:
        ready = [task for task in remaining.values()
                 if set(task.get("dependencies", [])) <= done]
        if not ready:
            raise ValueError("Ciclo detectado no grafo de dependências")
        ready.sort(key=lambda task: (-task.get("priority", 0), task["id"]))
        wave = []
        locked = set()
        for task in ready:
            resources = set(task.get("resources", []))
            if not resources.intersection(locked):
                wave.append(task)
                locked.update(resources)
        if not wave:
            raise ValueError("Escalonador não encontrou tarefa segura")
        completed = [task["id"] for task in wave]
        result.append(completed)
        done.update(completed)
        for task_id in completed:
            remaining.pop(task_id)
    return result



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
    assert waves([{"id": "a"}, {"id": "b", "dependencies": ["a"]}]) == [["a"], ["b"]]
    assert waves([{"id": "a", "resources": ["x"]}, {"id": "b", "resources": ["x"]}]) == [["a"], ["b"]]
    try:
        waves([{"id": "a", "dependencies": ["b"]}, {"id": "b", "dependencies": ["a"]}])
        raise AssertionError("Ciclo não detectado")
    except ValueError:
        pass
    try:
        waves([{"id": "a", "dependencies": ["missing"]}])
        raise AssertionError("Dependência inexistente não detectada")
    except ValueError:
        pass
    try:
        waves([{"id": "a"}, {"id": "a"}])
        raise AssertionError("ID duplicado não detectado")
    except ValueError:
        pass
    assert validate_knowledge({"nodes":[{"id":"a"},{"id":"b"}],"edges":[{"from":"a","to":"b","type":"depends"}]}) is True
    try:
        validate_knowledge({"nodes":[{"id":"a"}],"edges":[{"from":"a","to":"missing","type":"depends"}]})
        raise AssertionError("Aresta inválida não detectada")
    except ValueError:
        pass
    print("GraphOS: 6 testes aprovados")


if __name__ == "__main__":
    tasks = json.loads(GRAPH.read_text(encoding="utf-8"))["tasks"]
    knowledge = json.loads(KNOWLEDGE.read_text(encoding="utf-8"))
    validate_knowledge(knowledge)
    if "--test" in sys.argv:
        run_tests()
    print(json.dumps({"execution_waves": waves(tasks), "knowledge_nodes": len(knowledge["nodes"]), "knowledge_edges": len(knowledge["edges"])}, ensure_ascii=False, indent=2))
