---
name: resume-skills-section
description: Build or restructure the SKILLS section of the resume for a Senior AI/Software Engineer moving toward AI Solution Architect. Produces a grouped, balanced full-stack + AI taxonomy with honest proficiency levels. Use when the user says "rewrite the skills section", "organize my skills", "my skills list is too long/flat", or "add the AI skills".
---

# Resume Skills Section Builder

Produce a tight, grouped, ATS-friendly skills section that is **balanced full-stack + AI**
and signals the **AI Solution Architect** trajectory.

> **First:** load `resume-positioning` for the keyword bank, balance rule, and target framing.

## Principles

- **≤ 6 categories.** Flat 40-item dumps read junior and hurt ATS parsing.
- **Lead with AI/LLM engineering, immediately follow with backend/architecture** — equal
  weight, AI first because it's the differentiator.
- **Proficiency labels** (Expert / Advanced / Intermediate) only where defensible from real
  use. Don't label everything "Expert".
- **Real tools only** — every item must trace to the work logs or prior CV. No résumé-driven
  development (don't list tech you haven't shipped).
- Put a tool in **one** category, the most senior-signaling one.

## Recommended category set (tune to the candidate)

1. **AI / LLM Engineering** — LLM agents & multi-agent orchestration (Agno, LangChain,
   custom Deep-Agents); RAG & knowledge bases (vector search, AWS Bedrock / S3 Vectors);
   MCP tool ecosystems & gateways; LLM evals & reliability; prompt / reasoning-loop design;
   agent memory & context management; LLM cost & latency optimization; LiteLLM.
2. **Backend & Architecture** — Microservices, Domain-Driven Design, RESTful & event-driven
   API design; Node.js/NestJS, Python/FastAPI, .NET; system design; solution architecture.
3. **Data & Streaming** — PostgreSQL, MongoDB, Redis, vector DBs; Kafka, Flink; Databricks;
   ETL pipelines.
4. **Cloud & Platform** — AWS (Solutions Architect – Associate), Kubernetes, Docker;
   Temporal, Celery; CI/CD (GitHub Actions).
5. **Observability & Quality** — OpenTelemetry, Elastic APM, Sentry; LLM/agent tracing &
   evals; testing (Jest, unit/e2e), SAST.
6. **Frontend** *(keep brief — it's range, not the headline)* — React, Next.js, Angular,
   TypeScript.

## Method

1. Load `resume-positioning`; read the current SKILLS block in `CV/LÊ VĂN THUẬN.md`.
2. Cross-reference the work logs to add AI/agent tech the current resume is missing
   (MCP, Agno, RAG/KB, Bedrock, evals, Temporal, LiteLLM…).
3. Slot every tool into exactly one of ≤6 categories; drop anything unsourced.
4. Apply proficiency labels conservatively.
5. Order categories AI → backend → data → cloud → observability → frontend.

## Output

The full SKILLS section in markdown, ready to replace the existing one, plus a one-line
note of what was **added** (new AI tech) and **removed/merged** (dedup).

## Quality bar

- [ ] ≤ 6 categories; no flat mega-list.
- [ ] AI engineering is first and substantive (not 2 items).
- [ ] Backend/architecture depth preserved (balance, not AI-only).
- [ ] Every item is sourced; proficiency labels are defensible.
- [ ] Solution-architecture keywords present (system design, solution architecture, DDD,
      cost/scale/reliability).
