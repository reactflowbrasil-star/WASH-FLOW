# Resolução de conflitos

1. Declarar recursos/arquivos afetados antes de editar.
2. Não executar gravações concorrentes no mesmo arquivo.
3. Serializar alterações no Supabase e manter migrações idempotentes quando possível.
4. Resolver divergências com requisitos do Drive, esquema real, testes e evidências.
5. Nunca sobrescrever mudanças de outro agente sem comparação explícita.
