# Latest execution report — 2026-11-05

## Verified
- GitHub Actions GraphOS 8 tests + Knowledge Graph (11 nodes/11 edges) + npm install + TypeScript/Vite build passed on commit d3da145ac2fc0d7d0f36f3219b62683ea9073e5a.
- GraphOS v2 scheduler passed eight tests in GitHub Actions; it schedules only pending tasks, respects shared-resource locks, skips DONE/INTEGRATED and reports WF-005/WF-008 blocked. Knowledge Graph validated with 11 nodes and 11 edges.
- Supabase Security Advisor: zero findings.
- All 15 applied Supabase migration versions have matching SQL files in supabase/migrations.
- Transaction tests passed for two-tenant RLS, owner/manager/operator/inspector role matrix, generated priority weights, safe deletion/removal and idempotent seed.
- The inspector approval guard defect was found by the role matrix, fixed in migration 20261105163421 and retested successfully.
- Supabase currently has zero Auth users, zero platform admins, zero sites and zero operational records; all synthetic test data was rolled back.

## Current implementation
- React + TypeScript + Vite responsive PWA; Supabase Auth, PostgreSQL, RLS, Realtime and private RPCs.
- XLSX/XLS/CSV import with line diagnostics; plate lookup and validation; dependent brand/model selectors; group dictionary.
- Four priority levels with generated database weight, live ordering, queue removal only before service starts, and no duplicate active vehicle.
- QA rejection modal, Sonner notifications for urgent/conference/rework, history snapshot and exact daily/monthly KPIs.
- Automatic idempotent seed of ten reference vehicles once per empty unit, plus manual restore.
- GraphOS Intelligence skill, Task/Agent/Knowledge graphs, L1-L4 memory and execution journal.

## CI caveat
Older GitHub Actions runs had transient startup_failure with no jobs; the latest run above is green.

## Not production
- First real superadmin account and bootstrap are pending.
- Physical-device/browser E2E with two live tenant accounts is pending.
- Hosting is not connected; there is no public production URL.
