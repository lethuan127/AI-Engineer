---
name: activity-to-resume
description: Convert raw engineering activity (git commit history, Linear tickets, the work-tracking logs in CV/vireox(100x) work tracking/) into resume-ready experience bullets and project entries. Use when the user says "turn my commits into resume bullets", "summarize my Vireox work for the resume", "what did I actually do", or "build experience bullets from the activity logs". This is the bridge from the work-tracking docs to the resume.
---

# Activity → Resume

The signature skill for this candidate: the `CV/vireox(100x) work tracking/` folder already
holds a verified, comprehensive activity record (765 commits across 12 repos + 51 Linear
tickets). This skill distills that raw record into resume material.

> **First:** load `resume-positioning`. Then read the activity sources directly.

## Inputs (read these)

- `CV/vireox(100x) work tracking/work-activity.md` — cross-repo summary, workstreams, stats.
- `CV/vireox(100x) work tracking/linear-activity.md` — ticket content (the "why").
- `CV/vireox(100x) work tracking/weekly/INDEX.md` + weekly files — timeline detail.
- A target role/JD (optional) to bias selection.

## Method

1. **Cluster, don't transcribe.** The logs already group work into workstreams
   (report-generation platform, knowledge base, notification agents, MCP gateway/catalog,
   agent runtime migration, reliability, auto-evals, OSS to Agno). Each workstream → at most
   1–2 resume bullets. Never one bullet per commit.
2. **Rank by resume value:** owned platforms & migrations > production incident response >
   features > chores. Cross-team/architecture work and the Agno OSS contribution rank high
   for the Solution-Architect trajectory.
3. **Attach evidence:** real AIP/CENG tickets and counts (AIP-1, AIP-78, "583 commits across
   12 repos") lend credibility — use sparingly, not on every bullet.
4. **Write with `resume-bullet-writer`'s formula**, quantify with `resume-quantifier`.
5. **Two output shapes:**
   - **Experience bullets** for the Vireox role (4–6, impact-ordered).
   - **A project entry** (overview + achievements + tech stack) if the work merits a
     NOTABLE PROJECTS block (the agent platform clearly does).
6. Mark unsourced metrics `[verify]`.

## Output

Paste-ready markdown: a revised Vireox **experience** block AND a Vireox **project** entry,
each grounded in the logs, with a short provenance note (which workstream → which bullet).

## Worked mapping (from the logs)

| Workstream (in logs) | Resume bullet seed |
|---|---|
| Report platform V2→V5, background mode (AIP-1, AIP-13) | "Architected the report-generation platform behind OpenAI background mode, eliminating recurring 15-min timeout failures…" |
| KB platform: Bedrock S3 Vectors, structured retrieval | "Built a RAG knowledge-base platform on AWS Bedrock S3 Vectors with CSV/XLSX structured retrieval and bulk lifecycle ops." |
| Mongo→Postgres runtime migration (AIP-78) | "Led the Agno runtime session-store migration MongoDB→PostgreSQL with forward/rollback paths + SAST hardening." |
| MCP gateway/catalog, RFC 9728 (AIP-96) | "Designed a unified MCP tool gateway & catalog (RFC 9728 OAuth, per-server PRM)." |
| Upstream Agno fixes (AIP-35) | "Contributed MCP lifecycle-lock & async-session fixes upstream to the Agno OSS framework." |
| Reliability (CPU leak, timeouts, races) | "Hardened the platform: resolved a 100% CPU leak, MCP connect/close races, and bounded Bedrock/Vertex timeouts." |
| Notification multi-agent system | "Built a multi-agent notification system (Reflect + Sampling agents) with reflection loops and SES delivery." |

## Quality bar

- [ ] Workstream-level bullets, not commit-level.
- [ ] Every claim traces to the logs; metrics sourced or `[verify]`.
- [ ] Both AI-engineering and architecture/reliability range represented.
- [ ] Master resume untouched until the user approves the draft.
