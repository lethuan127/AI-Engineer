---
name: interview-prep
description: Generate interview preparation for a Senior AI/Software Engineer or AI Solution Architect role — behavioral (STAR from real experience), AI/system-design questions, and deep-dives on the candidate's own projects. Use when the user says "prep me for an interview", "behavioral questions", "system design practice", "mock interview", or pastes a JD/company to prep against.
---

# Interview Prep

Produce a focused prep pack grounded in the candidate's real work, tuned to the target role.

> **First:** load `resume-positioning`. Behavioral stories come from the work logs / CV.

## When to use

- An interview is scheduled (optionally with a known company/JD).
- The user wants behavioral, system-design, or project-deep-dive practice.

## Four prep tracks

### 1. Behavioral (STAR)
- Map likely prompts (conflict, failure, leadership, ambiguity, biggest impact, mentoring)
  to **real stories** from the logs: production incident response (Rocky Mountain report
  failures, CPU leak), the Mongo→Postgres migration, cross-team coordination, the Agno OSS
  contribution.
- For each: a tight **S-T-A-R** with a quantified result. 5–7 stories cover most interviews.

### 2. AI / LLM system design
- Likely prompts for this candidate: *design a RAG system / a multi-agent workflow / an
  agent platform with tool use / an LLM eval pipeline / cost-and-latency optimization for
  an LLM product / reliable long-running LLM jobs.*
- Provide a reusable framing: requirements → data/retrieval → orchestration → tools/MCP →
  reliability (timeouts, retries, background mode) → evals → cost → observability.
- Tie each back to something the candidate actually built.

### 3. Classic system design + coding
- Senior backend: design a high-throughput service (the 100k+ txn logistics systems),
  event-driven pipelines (Kafka/Flink), caching, data modeling.
- Note coding-round prep is on the candidate; this skill focuses on design + behavioral.

### 4. Project deep-dive
- Anticipated drill-down questions on the report platform / runtime migration / MCP gateway
  ("why background mode?", "why Postgres?", "how did you guarantee no session loss?",
  "how do you evaluate agent quality?"). Prepare crisp answers + the tradeoffs.

## Method

1. Get the target role/company/JD (ask if absent; default to "Senior AI/SWE → AI Solution
   Architect").
2. Generate the four tracks, biased toward the JD's emphasis.
3. For behavioral, draft full STAR answers; for design, draft frameworks + the candidate's
   real example; add **likely follow-up questions**.
4. End with **questions for the interviewer** (architecture ownership, AI roadmap, team).

## Output

A markdown prep pack saved under `CV/interview-prep/<company-or-role>.md`:
behavioral stories, design frameworks, project deep-dive Q&A, and questions to ask.

## Quality bar

- [ ] Behavioral stories are real and quantified (no invented anecdotes).
- [ ] AI system-design framings tie back to shipped work.
- [ ] Includes anticipated follow-ups and reverse questions.
