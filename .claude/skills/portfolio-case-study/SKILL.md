---
name: portfolio-case-study
description: Write a portfolio / case-study writeup of a project for a Senior AI/Software Engineer or AI Solution Architect — for a personal site, GitHub README, or interview "walk me through a project" prep. Uses the Situation-Task-Action-Result + architecture-decisions structure. Use when the user says "write a case study", "document this project for my portfolio", or "I need a project writeup for interviews".
---

# Portfolio Case Study Writer

Turn one project (e.g. the Vireox report-generation platform or the agent-runtime
migration) into a narrative case study that demonstrates architecture-level thinking.

> **First:** load `resume-positioning`. Pull facts from the work-tracking logs / project repo.

## When to use

- Building a portfolio site or a polished GitHub README.
- Prepping a "tell me about a project you're proud of" interview answer.
- Demonstrating Solution-Architect judgment (tradeoffs, not just features).

## Structure (STAR + architecture)

1. **Context** (2–3 sentences) — the product, the users, why it mattered to the business.
2. **Problem / Task** — the concrete problem and constraints (scale, reliability, cost,
   deadline). State what made it hard.
3. **Approach & Architecture** — the design. Include a small diagram (ASCII/Mermaid),
   the key components, and **the decisions + tradeoffs** (build-vs-buy, why Postgres over
   Mongo, why background mode, why this orchestration framework). *This is the section that
   signals architect.*
4. **Implementation highlights** — the 2–3 hardest/most interesting technical pieces.
5. **Results** — quantified outcomes (latency, cost, reliability, adoption). Sourced.
6. **What I'd do differently / next** — reflection. Senior signal.
7. **Stack** — concise tech list.

## Method

1. Pick the project; read its workstream section in `work-activity.md` + related AIP tickets
   in `linear-activity.md`.
2. Draft each section. Foreground **decisions and tradeoffs**, not a feature tour.
3. Add a Mermaid/ASCII architecture sketch if it clarifies the system.
4. Quantify results from the logs; `[verify]` anything unsourced.
5. Keep it skimmable: headers, short paragraphs, one diagram.

## Output

A standalone markdown case study saved under `CV/portfolio/<project-slug>.md` (don't touch
the resume). Length: 1–2 pages.

## Strong candidate projects (from the logs)

- **Report-generation platform** (V2→V5, OpenAI background mode, per-draft isolation,
  tracing/alerts) — reliability + LLM-systems story.
- **Agent runtime session-store migration** MongoDB→PostgreSQL (AIP-78) — data-architecture
  + zero-loss-migration story.
- **MCP tool gateway & catalog** (RFC 9728 OAuth) — platform/standards story.
- **Knowledge-base / RAG platform** (Bedrock S3 Vectors, structured retrieval) — applied-AI
  retrieval story.

## Quality bar

- [ ] Has a real Approach/Architecture section with explicit tradeoffs.
- [ ] Results are quantified and sourced.
- [ ] Reads as engineering judgment, not a feature changelog.
- [ ] Includes a "what I'd do differently".
