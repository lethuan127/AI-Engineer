# Vireox (100x) — Work Activity Tracking

> **Engineer:** Lê Văn Thuận
> **Role:** Senior AI Engineer @ Vireox / 100x
> **Generated:** 2026-06-02 (from git history)
> **Scope:** All git repositories under `/Users/thuanit/Documents/100xteam-ai` with activity from the engineer (12 of 18 repos).
> **Primary repositories:**
> - `100x-agent-hub` (backend / agent platform — Python monorepo)
> - `100x-agent-hub-ui` (frontend — Next.js / React / TypeScript)
>
> **Additional repositories** (detailed in §6): `100x-agent-runtime`, `100x-ai-plugins`, `100x-coretools`, `100x-data-platform`, `100x-mcp-gateway`, `100x-scripts`, `100x-web-application`, `100xteam-knowledge`, `LibreCodeInterpreter`, `agno` (upstream OSS).
>
> **Contributor identities matched** (all map to the same person):
> `thuanlerenn <thuan.le@rennlabs.com>`, `thuan-100x <thuan@100xteam.ai>`,
> `thuanle-vireo <thuan.le@vireohealth.com>` / `<Thuan.Le@vireohealth.com>`,
> `lethuan127 <levanthuan127@gmail.com>`, plus name variants
> "Thuan 100x", "thuan ai", "Thuan AI".

---

## 1. Headline Numbers

| Metric | `100x-agent-hub` (backend) | `100x-agent-hub-ui` (frontend) |
|---|---|---|
| Commits (excl. merges) | **583** | **50** |
| Commits (incl. merges) | **878** | 50 |
| Lines added¹ | ~349,000 | ~89,000 |
| Lines deleted¹ | ~62,250 | ~30,000 |
| Active window | **Oct 2025 → Jun 2026** | **Nov 2025 → May 2026** |
| Commit type split | feat 224 · fix 160 · refactor 120 · chore 31 · docs 25 | feat 64 · refactor 24 · fix 15 · chore 4 |

¹ Line totals include generated clients, lock files (`uv.lock`, `package-lock.json`) and Databricks notebooks, so they overstate hand-written volume. Commit counts and feature breadth below are the more meaningful signal.

**Combined across the two primary repos: ~633 non-merge commits across ~8 months**, spanning backend agent infrastructure, a full report-generation platform, a knowledge-base platform, and the React admin UI for all of it — effectively full-stack ownership of the Agent Hub product.

### Cross-repo totals (all 12 active repos)

| Repository | Commits¹ | Window | Domain |
|---|---|---|---|
| `100x-agent-hub` | 583 | 2025-10 → 2026-06 | Backend agent platform (Python) |
| `100x-agent-hub-ui` | 50 | 2025-11 → 2026-05 | Frontend admin (Next.js/TS) |
| `100x-data-platform` | 37 | 2026-03 → 2026-05 | SharePoint→Kanban ETL (Databricks) |
| `100x-ai-plugins` | 25 | 2026-05 → 2026-06 | Claude Code plugin marketplace / SDD harness |
| `100x-coretools` | 13 | 2026-03 | Semantic layer service |
| `100x-agent-runtime` | 12 | 2026-05 → 2026-06 | "Deep Agents" next-gen runtime |
| `100x-mcp-gateway` | 7 | 2026-05 | MCP gateway (TypeScript) |
| `agno` | 6 | 2026-04 → 2026-05 | **Upstream OSS** — Agno framework |
| `100x-scripts` | 3 | 2026-03 | Ops / SSH access scripts |
| `100x-web-application` | 2 | 2026-01 → 2026-02 | Web app API |
| `100xteam-knowledge` | 2 | 2026-05 | Incident investigation playbooks |
| `LibreCodeInterpreter` | 2 | 2026-03 | Code-interpreter sandbox (Docker) |
| **Total** | **~742** | **2025-10 → 2026-06** | |

¹ Unique non-merge commits across all branches. The two primary repos are detailed in §3–§4; the rest in §6.

---

## 2. Activity Timeline (commits per month, excl. merges)

| Month | Backend | Frontend | Notable focus |
|---|---|---|---|
| 2025-10 | 7 | — | Bootstrapping the `onehundredx-report` package, core config |
| 2025-11 | 61 | 5 | Knowledge base platform; report workflow; shadcn/ui foundation |
| 2025-12 | 80 | 7 | Notification agent + Reflect/Sampling agents; KB UI |
| 2026-01 | 90 | 16 | Auto-evals framework; workflow orchestration; agent management UI |
| 2026-02 | 47 | 12 | MCP integration; structured retrieval; reporting UI |
| 2026-03 | 110 | 28 | Unified MCP catalog; memory platform; large UI build-out |
| 2026-04 | 112 | 12 | Agno 2.5 upgrade; Postgres runtime migration (AIP-78); reliability |
| 2026-05 | 74 | 11 | Report V3 background mode (AIP-1); per-draft isolation (AIP-13); tracing |
| 2026-06 | 2 | — | Runtime DB init fixes |

Sustained high output (often 80–112 commits/month) from Jan–May 2026.

> 📅 **Week-by-week breakdown:** see [`weekly/INDEX.md`](./weekly/INDEX.md) — 32 active weeks (13 Oct 2025 → 1 Jun 2026), one file per week (e.g. `weekly/week-of-2026-06-01.md`). Each lists every commit **with its full description/body** (grouped by repo and type) and, for the weeks of 11 May–1 Jun 2026, the **Linear tickets opened/completed that week** woven in at the top.
>
> 🎫 **Linear ticket activity & content:** see [`linear-activity.md`](./linear-activity.md) — 51 issues across 5 teams (AIP, CENG, PENG, INF, ORG), with full status, priority, dates, and issue-body content.

---

## 3. Backend — `100x-agent-hub`

Monorepo (`apps/*` + `packages/*`, managed with `uv`). Most-touched areas by file-change count:

| Area | Changes | What it is |
|---|---|---|
| `packages/vireox-agents` | 422 | Core agent framework / runtime |
| `packages/onehundredx-report` | 353 | Report generation engine |
| `apps/agent-hub-api` | 333 | Main FastAPI service |
| `apps/agent-hub-tool` | 186 | Tool/MCP service |
| `packages/onehundredx-knowledge-base` | 184 | KB platform |
| `packages/vireox-librechat` | 174 | LibreChat integration |
| `packages/vireox-common-libs` | 139 | Shared libraries |
| `packages/vireox-auto-evals` / `onehundredx-auto-evals` | 124 / 113 | Evaluation framework |
| `packages/vireox-data-schemas` | 121 | Shared SQL/data schemas |
| `apps/onehundredx-mcp` / `onehundredx-memory-api` | 71 / 41 | MCP server + memory service |
| `mage-pipeline/`, `databricks/` | 88+ | Data pipelines & notebooks |

### 3.1 Agent Platform & Runtime
- Introduced the **`vireox-agents` package** — unified agent configuration, `AgentHubFactory`, tool retrieval, skill initialization.
- **Migrated Agno runtime session storage from MongoDB → Postgres (AIP-78)**: new `agno_runtime` Postgres engine, lazy getters, isolated `AGNO_POSTGRES_*` settings, forward migration + rollback scripts, NUL-byte sanitization, Semgrep SAST hardening, rollback parity.
- Agent execution hardening: pre-run/post-run hooks, retry mechanism, error handling (`AgentNotFoundError`), tool-call limit raised 10→20, OpenAI Responses API support, GPT-5.5 / GPT-5.5-pro model routing.
- Session summary management replacing live session-state updates; session-summaries config.

### 3.2 Report Generation Platform (`onehundredx-report`)
- Built the package from scratch (Oct 2025) → evolved through **V2, V3, V4, V5**.
- **V3 report path on OpenAI background mode (AIP-1)** for reliability; back-ported background-mode patch to V2 for `OpenAIResponses`.
- **Per-draft agent isolation for V2 + V3 sampling (AIP-13)**.
- Full report **tracing, Slack alerts, cursor-based pagination**; Streamlit viewer + offline accuracy evaluation.
- Email delivery: SES batching, BCC config, retry mechanism, HTML→Markdown conversion, secure email rendering.

### 3.3 Notification Agent System
- Multi-agent workflow: **Notification Agent + Reflect Agent (reflection loop) + Sampling Agent**, structured outputs, feedback parsing.
- Controls: `num_reports`, `debug_mode`, `reasoning_effort`, skip-reflect / skip-sampling flags, concurrency control.
- Async refactors (pure asyncio / multiprocessing handling), Databricks + Mage pipeline integration (`mage_run_id`, `block_run_id`), trigger notebooks.

### 3.4 Knowledge Base Platform (`onehundredx-knowledge-base`)
- **AWS Bedrock S3 Vector Storage** support; audio/video content; index-name retrieval from S3 Vectors config.
- **Structured retrieval for CSV/XLSX**; document metadata validation & update; filtering endpoints; bulk-delete; manual retry for error-status documents; indexing-status synchronization; entity clarification with OpenSearch.
- `browse_documents` tool + folder-rendering optimization; namespaced chunk metadata under `document.*`.

### 3.5 MCP Integration & Tooling
- **Unified agent MCP integration** with an `mcpserverconfigs` catalog (replacing per-agent bools).
- Apps/tools: database MCP, reasoning MCP (session state), code-execution MCP (file downloads), report-tools MCP, send-mail tool.
- **MCP Gateway** architecture/design docs; dynamic public-MCP discovery for the **LiteLLM AI Gateway** with custom auth.

### 3.6 Auto-Evals Framework
- Introduced **VireoX / OneHundredX Auto-Evaluation** frameworks; accuracy evaluation with user-context tracking; team-agent eval support; Databricks eval notebooks; transition of eval tasks from **Celery → Temporal**.

### 3.7 Workflow Orchestration
- `workflow` package for Agno; **Temporal workflows/activities** + **Celery** background processing; workflow definition model (input dependencies, expected output, conversation/session IDs); quota-exceeded handling; input sanitization.

### 3.8 Auth, Security & Credentials
- **OIDC** custom auth; impersonation header for user context; LiteLLM gateway auth.
- **Databricks credentials**: encrypted credentials table, `TokenEncryption`, `CredentialService`, OAuth2 refresh by principal, service-principal management scripts; nullable-principal backward compatibility.

### 3.9 Observability & Reliability
- OpenTelemetry integration: FastAPI instrumentation, user-context extraction middleware, custom tracing decorators, cursor-based pagination for team histories.
- Notable reliability fixes: **CPU 100% leak**, **MCP connect/close race (`BrokenResourceError`)**, serialized MCPTools connect, bounded **Vertex Gemini** + **Bedrock Claude** request timeouts, runtime-DB init ordering, agentic-state/team-history toggles for performance, duplicate-media-path guards.

### 3.10 Data / Semantic Layer
- `vireox-data-schemas` package (moved SQL schema defs out of services); semantic query history logging & validation; data-source lookup by SQL table names; semantic aliases; **Trello datamart API** (SQL execution, health check, CSV export).

### 3.11 Memory Platform
- `onehundredx-memory` + memory API: MongoDB integration, agent-execution capabilities, memory management API refactor.

---

## 4. Frontend — `100x-agent-hub-ui`

Next.js / React / TypeScript admin app. Most-touched areas:

| Area | Changes |
|---|---|
| `src/components` | 276 |
| `src/app` | 179 |
| `src/types` | 71 |
| `src/store` | 57 |
| `src/services` | 44 |
| `src/hooks` | 10 |

### Major UI workstreams
- **Agent management**: AgentCard / AgentDetails / ToolsTab / BasicTab, model options (incl. GPT-5.5), reasoning-effort field, visibility (replacing status), Skills + MCP indicators, Artifacts tab, Session Summaries tab, member counts.
- **Knowledge Base UI**: documents tab with **infinite scroll, search, filter, redesigned upload** (drag-and-drop, expanded file types), structured-retrieval feature + warnings, Data Sources management, metadata/schema handling, **error remediation + document retry**, bulk delete, sync indexing status, document counts.
- **Reporting UI**: report workflows with status/date filtering, **cursor-based pagination**, **full report tracing**, `EmailBodyPreview` (secure rendering), search + recipient filters, Insight/Workflow session labeling.
- **Workflows UI**: create-workflow page (extraction + inline modes), session/conversation-ID tracking, error handling.
- **LibreChat / Conversations**: conversation management, conversation-tree UI, agent-data integration, render optimization.
- **Sessions & Analytics**: Analytics page (session metrics + charts), **Runs Visualization** component, infinite scroll + cursor pagination for sessions.
- **Memory Manager UI** + API service integration.
- **Auto-evals UI** + design/integration docs; Test Cases page.
- **Skills management** feature (UI + service).
- **Auth**: migrated **Azure AD → OpenID Connect**, streamlined token management, fixed **logout loop on refresh-token error**, scope cleanup.
- **Design system**: introduced **shadcn/ui**, Tailwind design tokens, oklch color fallbacks; OpenAPI-driven client generation.

---

## 5. Tracked Tickets (AIP)

- **AIP-1** — V3 report path on OpenAI background mode; report-generation reliability.
- **AIP-13** — Per-draft agent isolation for V2 + V3 sampling.
- **AIP-23** — (referenced in backend work).
- **AIP-78** — Agno runtime session storage migration MongoDB → Postgres (incl. SAST + rollback parity).
- **AIP-80** — (referenced in backend work).

---

## 6. Additional Repositories

Beyond the two primary repos, Thuan contributed across the wider 100x/Vireox ecosystem — next-generation runtime, developer tooling, data pipelines, infra gateway, and even upstream open source.

### 6.1 `100x-agent-runtime` — "Deep Agents" next-gen runtime (12 commits, May–Jun 2026)
A from-scratch agent runtime, distinct from the Agno-based Agent Hub. Tickets **AIP-77, AIP-94, AIP-103**.
- **Deep Agents runtime MVP** on **Postgres + Daytona + plugins** (AIP-94).
- **MCP OAuth vault** + per-user vault paths; **per-user plugin installs** with a catalog API and a **plugin console UI**.
- **Self-hosted Daytona stack** + local compose stack for sandboxed execution.
- Conceptual **H1–H11 components architecture** (ARCHITECTURE.md); renamed the "harness" layer → "brain" across docs and the runtime package (AIP-103).
- Strong test discipline: substantial `tests/unit` + `tests/e2e` suites; CI lint/pre-commit fixes; addressed Bugbot PR feedback.
- Vertical plugins present: `vireox-askdata`, `co3-pipeline-copilot`.

### 6.2 `100x-ai-plugins` — Claude Code plugin marketplace & SDD harness (25 commits, May–Jun 2026)
Agent/developer tooling: a plugin marketplace plus the **spec-driven-development (SDD) harness**. Tickets **AIP-81, AIP-84, AIP-99**.
- **Phase 0 harness + marketplace spine**; `.claude/commands` + `.cursor/commands`.
- **`100x-sdd-harness` agent plugin (AIP-81)** with an **SDD tier ladder** (phases optional by task complexity).
- **`linear-toolkit` vertical plugin (AIP-84)** encoding the VireoX Linear operating standard.
- **`100x-observability-plugin`** — VPC-tunneled trace debugging, investigation playbooks, self-improvement loop, platform-architecture skill references.
- **VireoX AskData agent + toolkit (AIP-99)**.
- **CACO + CO3 Pipeline Copilots** and the **chicago-atlantic-toolkit** (deal-analyst rules for Chicago Atlantic credit pipelines).
- Marketplace taxonomy: toolkit / finance categories; starter-plugin template.

### 6.3 `100x-data-platform` — SharePoint → Kanban ETL (37 commits, Mar–May 2026)
Databricks-notebook data engineering syncing enterprise documents into the knowledge base.
- **`etl_company_to_kanban`** and **`etl_company_to_caco_kanban`** ETL pipelines: SharePoint + **Microsoft Graph API** → Kanban → Knowledge Base, with S3 synchronization.
- Document lifecycle: indexing, **dedup (skip duplicate files)**, deletion logic (incl. PPTX handling), modified-doc detection, metadata enrichment (`filepath`, `fileUrl`, datasource_id), indexing-attempt tracking.
- Reliability: `KnowledgeBaseAPIError` handling, duplicate-key handling, raised `GRAPH_HTTP_TIMEOUT_SEC` 60→180s, bronze-snapshot loading (replacing state tables for memory efficiency), OAuth client improvements.
- Business rules: skip indexing for `Closed`-status companies or >500-file companies; deal-folder filtering; vectorization-column config.

### 6.4 `100x-coretools` — Semantic layer service (13 commits, Mar 2026)
- Introduced a **semantic layer service** with **YAML-based cube definitions**; `SemanticMetadata` typing (Literal types, unique aliases).
- `SemanticService` **dependency injection**; datasource schema response refactor; tool-guide generation.
- Security/robustness: **OAuth2 email-comparison normalization**; replaced `hashlib` with `secrets` for CSV-download URL hash keys; empty-data handling.

### 6.5 `100x-mcp-gateway` — MCP gateway (7 commits, May 2026, TypeScript)
- **Aligned `mcp_servers` schema with the Claude/MCP standard (ADR-006)**.
- **OAuth RFC 9728**: per-server Protected Resource Metadata in 401 responses, `protected_resources` on the Authorization Server.
- Bootstrapped the **multi-agent harness + SDD workflow** in-repo; tunnel/metadata test scripts; RFC 9728 discovery tests; addressed Cursor Bugbot review findings.

### 6.6 `agno` — Upstream open-source contributions (6 commits, Apr–May 2026)
Contributions to the **Agno agent framework** itself (the runtime powering Agent Hub):
- **`serialize MCPTools connect/close to prevent BrokenResourceError`** — the upstream fix for the same MCP race resolved downstream in Agent Hub.
- **`AsyncMongoDb.get_session`** query-consistency fix (removed extra `session_type` filter) + consolidated unit tests.
- Feature: **`add_team_media_to_delegation`** for delegated member kwargs.

### 6.7 Smaller / supporting repos
- **`100xteam-knowledge`** (2) — authored incident **investigation playbooks** (chat-UI table-artifact not rendering, agent toolset string/array schema error, Bedrock output-cap truncation) + playbook index/template.
- **`LibreCodeInterpreter`** (2) — Docker setup (`docker-compose`, GHCR images, build scripts) for the code-interpreter sandbox.
- **`100x-scripts`** (3) — operational SSH access scripts for staging/production/CAG Postgres & MongoDB.
- **`100x-web-application`** (2) — minor API app feat/fix.

---

## 7. Technology Footprint (evidenced by commits)

**Backend / AI:** Python, FastAPI, Agno (agent runtime, upgraded to 2.5.x), LiteLLM AI Gateway, OpenAI Responses API + background mode, AWS Bedrock (Claude) + S3 Vectors, Vertex Gemini, Celery, Temporal, APScheduler, OpenSearch, PostgreSQL, MongoDB, Databricks, Mage pipelines, OpenTelemetry, SES, OIDC/OAuth2, Semgrep (SAST), `uv` monorepo tooling.

**Frontend:** Next.js, React, TypeScript, shadcn/ui, Tailwind CSS (design tokens), client state store, OpenAPI-generated clients, Markdown rendering, charts/analytics.

---

## 8. Scope Summary

Over ~8 months Thuan operated as a **full-stack AI platform engineer with end-to-end ownership** of the Vireox Agent Hub:
- **Architecture & infra**: agent runtime, MCP gateway/catalog, workflow orchestration (Temporal/Celery), data-storage migrations.
- **Product features**: report-generation platform (V2→V5), knowledge-base platform, notification/reflection agent system, auto-evals, memory platform.
- **Quality & reliability**: production incident fixes (CPU leak, MCP races, timeouts), observability/tracing, SAST hardening, auth migration.
- **Frontend**: built and maintained the React admin UI surfacing every backend capability above.

This is consistent with the CV claim of *"full ownership of agent and product architecture"* and *"agent-driven team automation"* — backed by 224 backend feature commits, the notification-agent automation system, and the auto-evals framework.
