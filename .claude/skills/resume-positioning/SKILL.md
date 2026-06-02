---
name: resume-positioning
description: Shared career-positioning context for Lê Văn Thuận's resume/career skills. Defines the target role (Senior AI/Software Engineer → AI Solution Architect), the balanced full-stack + AI framing, the metric taxonomy, the voice, and the canonical source files. Load this first whenever rewriting the resume, writing bullets, tailoring to a JD, optimizing LinkedIn, or prepping for interviews. Not invoked directly — other resume-* skills read it.
---

# Resume Positioning (shared context)

This is the **single source of truth** for *how* to frame this candidate across every
resume/career skill in this repo. Other skills (`resume-bullet-writer`,
`resume-skills-section`, `jd-tailor`, `linkedin-optimizer`, `cover-letter`,
`interview-prep`, …) load this before producing anything.

## Canonical source files (read these for facts — never invent)

- **Resume (current):** `CV/LÊ VĂN THUẬN.md` — a **symlink to the latest dated version**.
- **Verified work activity (git):** `CV/vireox(100x) work tracking/work-activity.md`
- **Weekly journal (commits + Linear):** `CV/vireox(100x) work tracking/weekly/INDEX.md`
- **Linear ticket content:** `CV/vireox(100x) work tracking/linear-activity.md`

> Every claim on the resume must trace to one of these or to the candidate. If a
> number isn't sourced, mark it `[verify]` rather than fabricating it.

## Resume versioning (read before editing the resume itself)

The resume is versioned by time as `CV/LÊ VĂN THUẬN-YYYY-MM.md`, and
`CV/LÊ VĂN THUẬN.md` is a symlink pointing at the newest one. The changelog is
`CV/VERSIONS.md`.

- **Reading facts** → use the symlink `CV/LÊ VĂN THUẬN.md` (always current).
- **Tailored, job-specific outputs** (jd-tailor, cover-letter, …) → save under
  `CV/variants/`, `CV/cover-letters/`, etc. **Never** touch the dated resume files.
- **Cutting a new master version** (a real content update to the resume, e.g. after
  `activity-to-resume`):
  1. `cp` the current dated file to a new `CV/LÊ VĂN THUẬN-<YYYY>-<MM>.md`.
  2. Apply edits to the **new** dated file only.
  3. Re-point the symlink: `ln -sf "LÊ VĂN THUẬN-<YYYY>-<MM>.md" "CV/LÊ VĂN THUẬN.md"`.
  4. Add a row to `CV/VERSIONS.md` summarising what changed.
  Never edit a past dated snapshot, and never overwrite the symlink with a real file.

## Target positioning

**Now:** Senior AI / Software Engineer. **Trajectory:** AI Solution Architect.

Frame the candidate as a **balanced full-stack + AI engineer** who owns systems
end-to-end and is moving up the abstraction ladder toward architecture:

- **AI engineering depth** — agent runtimes (Agno, LangChain, custom Deep-Agents),
  multi-agent orchestration, RAG / knowledge bases (vector + S3 Vectors / Bedrock),
  MCP tool ecosystems & gateways, LLM cost/latency optimization, evals & reliability,
  prompt + reasoning-loop design, observability for LLM systems (OpenTelemetry).
- **Software/backend depth** — microservices, domain-driven design, Node/NestJS,
  Python/FastAPI, Postgres/Mongo/Redis, event streaming (Kafka/Flink), high-scale
  (100k+ daily txns), 90% latency wins.
- **Solution-architecture signals** — owns design decisions and tradeoffs
  (build-vs-buy, reliability/cost/scale), platform thinking, data-storage migrations,
  cross-team coordination (15+ engineers, 4 functions), mentoring, and translating
  business goals into technical architecture.

Keep AI and classical-engineering weight roughly **equal** — do not bury the backend
strengths, and do not let AI read as buzzword garnish. Both are evidence for the
architect trajectory.

## Voice

- **Bullets:** `Strong verb + what you built/owned + technical how + measurable impact.`
  Past tense; no "responsible for"; no first-person pronouns.
- **Altitude:** senior → lead with the decision/architecture, not the ticket.
- **Honesty:** confident, never inflated. Prefer a real, specific number over a vague
  superlative. Don't claim team-lead scope for IC work or vice-versa.
- **Metrics:** bold the number (`**90%**`, `**100k+**`, `**60%**`). One headline metric
  per bullet; two max.

## Metric taxonomy (what "impact" means for this candidate)

| Dimension | Example sources from the activity logs |
|---|---|
| **Latency / performance** | 90% API response improvement; report background-mode timeout fix |
| **Cost** | 60% LLM operational cost reduction; batch API / sampling-model swaps |
| **Scale** | 100k+ daily transactions; multi-tenant agent platform |
| **Reliability** | CPU-leak fix, MCP race fix, Bedrock/Vertex timeout bounding, 99.9% uptime |
| **Velocity** | 40% faster feature dev (DDD restructuring); 60–80% AI-assisted coding |
| **Adoption / breadth** | 583 commits, 12 repos, report/KB/notification platforms, 51 Linear tickets |
| **Ownership** | full agent+product architecture; Mongo→Postgres migration (AIP-78); OSS contrib to Agno |

When a bullet has no metric, prefer a **scope/ownership** signal (e.g. "platform used by
N teams", "owned end-to-end") over an empty adjective.

## Keyword bank (for ATS + skills; group, don't dump)

`LLM agents · multi-agent orchestration · Agno · LangChain · RAG · knowledge base ·
vector search · AWS Bedrock · MCP (Model Context Protocol) · MCP gateway · LLM evals ·
prompt engineering · reasoning loops · agent memory · OpenTelemetry · LiteLLM ·
Python · FastAPI · Node.js · NestJS · TypeScript · microservices · domain-driven design ·
PostgreSQL · MongoDB · Redis · Kafka · Flink · AWS · Kubernetes · Docker · Temporal ·
Celery · Databricks · React · Next.js · system design · solution architecture · cost optimization`

## Anti-patterns to reject

- Generic Vireox bullets ("Lead the design and implementation of AI agents") — replace
  with the specific, sourced platforms (report generation, knowledge base, notification
  agents, MCP gateway, runtime migration).
- Skill lists with 40 flat items — group into ≤6 categories.
- Unsourced metrics, or the same metric repeated on every bullet.
- Buzzword AI with no system behind it.
