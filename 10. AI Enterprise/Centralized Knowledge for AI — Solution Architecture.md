# Centralized Knowledge for AI — Solution Architecture

> **Audience:** architects and senior engineers. The reference architecture for giving an enterprise's
> AI one shared, governed source of truth that every person and AI tool can read and write. The *Enterprise
> Brief* is the non-technical version; the deep-dive notes in this folder cover each component. Claude-first.

## 1. Scope & quality goals

**In scope:** how documents, operational data, and agent-authored knowledge are connected to AI agents,
discovered, governed, and written back. **Out of scope:** model selection, app UX.

Quality goals (drive every decision below): **single source of truth** (no drift) · **read + write** ·
**least-privilege + auditable** · **lean, relevant context** · **portable across machines/platforms** ·
**no authoritative copies in a vendor store**.

## 2. Architecture principles

1. **Connect, don't copy** — canonical data stays in the source system; agents reach in. Indexes are
   regenerable, never authoritative.
2. **Two connection mechanisms** — local files (synced folder) and live tool calls (MCP); computer-use is
   the no-API/no-file fallback. The taxonomy is closed.
3. **Understanding is retrieval, not pre-loading** — discover/orient on demand (P6: context is finite).
4. **Draft, don't execute** — risk scales with the write target; system-of-record writes are gated.
5. **Capability is bounded by the actor's permissions** — agents never exceed the signed-in user.
6. **Nothing the agent authors is special** — memory, skills, artifacts are files or calls, governed the
   same way (skills/semantic-model via git + PR).

## 3. Reference architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│ CONSUMERS        Cowork (employees) · Claude Code (devs) · claude.ai ·        │
│                  external agent runtime · People (native SaaS UI)             │
├────────────────────────────────────────────────────────────────────────────┤
│ CONTROL PLANE    Identity/SSO · Permission inheritance · Human-in-the-loop    │
│ (cross-cutting)  approval · Audit log · DLP/policy · Observability/tracing     │
├────────────────────────────────────────────────────────────────────────────┤
│ KNOWLEDGE        Semantic layer (metrics) · Retrieval/RAG (progressive        │
│ SERVICES         disclosure) · Memory store · Context mgmt (evict/compact)    │
├────────────────────────────────────────────────────────────────────────────┤
│ CONNECTION       Sync client → Synced folder    │    MCP servers/connectors   │
│ LAYER            (FILES mechanism)               │    (TOOL-CALL mechanism)    │
│                              Computer use (fallback, GUI)                      │
├────────────────────────────────────────────────────────────────────────────┤
│ SOURCES OF       Documents (Drive/SharePoint/git) · Operational data          │
│ TRUTH            (CRM/SQL/BI) · Agent-authored (skills/memory/artifacts)      │
└────────────────────────────────────────────────────────────────────────────┘
```

## 4. Component responsibilities

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **Sources** | Documents · Operational data · Agent-authored | The canonical stores; own the truth, the permissions, the audit |
| **Connection** | **Sync client + synced folder** | Mirror cloud document stores + file-memory + skills to the edge; read/write local files |
| | **MCP servers / connectors** | Live tool access to operational systems, semantic layer, memory server, retrieval app |
| | **Computer use** | Drive a GUI when a system has no file and no API (fallback) |
| **Knowledge services** | **Semantic layer** | Governed metrics/dimensions/joins → validated SQL; the trustworthy surface over operational data |
| | **Retrieval / RAG** | Source-derived index for large-corpus discovery; exposed via MCP with **progressive disclosure by filename** |
| | **Memory store** | Capture/store/recall/forget of agent-authored knowledge (files default; MCP memory server at scale) |
| | **Context management** | Eviction/compaction/offloading to keep the window lean at runtime |
| **Control plane** | Identity, permission inheritance, HITL approval, audit, DLP, observability | Enforce who-can-do-what, gate writes, record everything |
| **Consumers** | Cowork / Code / claude.ai / runtime / people | Read & write the same sources; people via SaaS UI, agents via the connection layer |

## 5. Key flows

**Document discovery (read):** question → consumer → *filesystem agentic search* (small/curated) **or**
*retrieval app via MCP* (large) → **progressive disclosure** (filenames → outline → section) → answer
with citations. Oversized docs recurse: index by the document's own structure.

**Operational-data query (read):** **orient** (schema + semantic layer) → **ground** (sample/profile) →
**verify** (read-only SQL + EXPLAIN) → answer. At scale, semantic-layer MCP compiles a structured query
to governed SQL; large schemas use progressive disclosure over the catalog.

**Write (any source):** agent **drafts** → control plane checks **permission inheritance** + policy →
**human approval** for system-of-record / semantic-model / shared-memory writes → execute (file save /
MCP mutation in a transaction / git PR) → **audit**. Semantic-model & skill changes go through **PR + CI**,
never live edits.

**Memory lifecycle:** capture salient/non-derivable facts → store (file/MCP/memory-tool) → recall (load
for small, retrieve for large; native eviction/compaction manage the window) → forget (decay, dedup,
contradiction-resolution).

## 6. Integration pattern — which mechanism per source

| Source | Mechanism | Notes |
|--------|-----------|-------|
| Documents (Office/PDF/MD/code) | **Synced folder** (read+write) | connector is read-mostly for native Docs |
| Operational data (CRM/SQL/BI) | **MCP** — prefer a **semantic-layer** surface for governed answers | no filesystem path; orient-before-act |
| Large document corpus | **Self-built RAG via MCP** (source-derived index) | not managed RAG (that's a vendor-store copy) |
| Agent memory (learned facts) | **Synced folder** default → **MCP memory server** at scale | per "is hierarchical recall necessary" |
| Skills / workflows / semantic model | **git** (files) + **PR/CI** | procedural knowledge = code |
| No file + no API system | **Computer use** | fallback only |

## 7. Cross-cutting concerns (NFRs)

| Concern | Approach |
|---------|----------|
| **Security** | Cowork **VM sandbox** for code execution; per-folder scoped mounts; **egress allowlist**; host credentials never enter the guest |
| **Authorization** | **Permission inheritance** (acts-as-user); enforce at query time (RLS/masking); injection contained at the auth layer, not the prompt |
| **Governance** | Read-first/least-privilege; **draft-before-execute** (HITL) for systems of record; "negative space" by default |
| **Data residency** | Keep canonical copies in enterprise systems; avoid authoritative copies in the vendor store; ZDR where required |
| **Observability** | Tracing + audit on every tool call and write; review path for shared-memory/model changes |
| **Cost** | Prompt caching for stable prefixes; **retrieve over load**; context management to cap tokens |
| **Performance / scale** | Progressive disclosure; RAG flat-cost at scale; semantic-layer pushes compute to the warehouse |
| **Portability** | Files/git across machines; **MCP memory server** for cross-platform/cross-vendor single store |

## 8. Deployment topology — where things run

| Tier | Runs | Hosts |
|------|------|-------|
| **Edge (employee machine)** | Cowork (VM sandbox) · Claude Code · synced folders | macOS/Windows endpoints |
| **Enterprise infra (self-hosted)** | MCP servers (semantic layer, memory, RAG app, custom connectors) · vector store · sync of source data | your cloud/VPC |
| **SaaS sources** | Drive/SharePoint · CRM · warehouse/BI | vendor clouds |
| **Anthropic** | Model inference · optional memory tool / context-management | Anthropic API |

> Trust boundary: agent **reasoning** runs on the host / Anthropic; **code execution** is sandboxed in the
> VM; **canonical data** stays in your SaaS/infra. Connectors and credentials live in the control plane,
> not inside the execution sandbox.

## 9. Architecture decisions (ADR summary)

| # | Decision | Rationale | Trade-off |
|---|----------|-----------|-----------|
| 1 | Source of truth stays in enterprise systems | no drift; governance/residency | must connect, not upload |
| 2 | Two mechanisms (synced folder + MCP), computer-use fallback | closed, exhaustive reach | computer-use is brittle |
| 3 | Self-built RAG via MCP, not managed RAG | keeps it a source-derived index, governed | you run the index pipeline |
| 4 | Semantic-layer MCP for operational data | governed, validatable answers; no hallucinated SQL | only answers what's modeled |
| 5 | File-based memory default; MCP memory server at scale | zero infra small; lean+concurrent large | server is ops to run |
| 6 | Draft-before-execute for system-of-record & model changes | contains blast radius; injection-resistant | adds a human step |
| 7 | Use native eviction/compaction; add archival recall only if cross-session/by-relevance | avoid over-engineering | hand-build only when needed |
| 8 | Cowork sandbox for employee execution; push/PR via host or GitHub-MCP | isolation by default | extra step to publish |

## 10. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| **Memory poisoning** (false facts persist) | validate on write · provenance · review shared-memory writes · isolation |
| **Prompt injection → tool chains** | authorization at the infra layer; least-privilege scoped tools |
| **Stale high-relevance facts** | contradiction-detection on write · re-verification · don't memorize derivable facts |
| **Over-broad write access** | restricted-by-default · per-action approval · audit |
| **Sync conflicts** (multi-writer files) | conventions, or move shared/concurrent memory to an MCP server (single write authority) |
| **Data leakage to vendor store** | exclude managed-RAG/upload paths; keep canonical data in your systems |

## 11. Build sequence (rollout)

1. **Stand up the shared filesystem** (synced folder + git) — one move centralizes documents + file-memory
   + skills.
2. **Populate procedural knowledge** (skills/workflows) — highest leverage, lowest risk.
3. **Curate shared semantic memory** (conventions/definitions) — with review.
4. **Connect operational data — read** via MCP (+ semantic layer for the valuable metrics).
5. **Enable operational data — write**, gated, after read is trusted.
6. **Add an MCP memory server / archival recall** only when memory outgrows files or must span platforms.

## Go deeper (component specs)

- *Centralized Knowledge for AI — Comprehensive* — the framework & principles
- *Operational Data for AI — Reach, Understand, Act* — the operational-data tier
- *Semantic-Layer MCP — Design* — the governed-answer surface
- *System Memory for AI — Capture, Store, Recall, Forget* — the memory tier
- *Claude Cowork — Sandbox Architecture* — the execution trust boundary
- *Context Window Management* (Prompt & Context Engineering) — runtime context management

## References

- [Anthropic — Use connectors to extend Claude's capabilities](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)
- [Anthropic — MCP connector (Claude API)](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector)
- [Anthropic — How we contain Claude across products](https://www.anthropic.com/engineering/how-we-contain-claude)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Building agents for financial services](https://www.anthropic.com/news/finance-agents)
