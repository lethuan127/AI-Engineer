---
name: linkedin-optimizer
description: Optimize the LinkedIn profile (headline, About, experience, skills, featured) for a Senior AI/Software Engineer positioning toward AI Solution Architect, tuned for recruiter search and keyword match. Use when the user says "optimize my LinkedIn", "write my headline", "rewrite my About section", or "make my profile findable".
---

# LinkedIn Optimizer

Make the profile recruiter-findable and consistent with the resume — LinkedIn is read by
humans *and* by recruiter search, so it's keyword-driven but more narrative than the resume.

> **First:** load `resume-positioning`. Keep claims consistent with `CV/LÊ VĂN THUẬN.md`.

## When to use

- Refreshing the profile after the resume rewrite.
- Headline / About / experience not surfacing in recruiter searches.

## Sections to produce

1. **Headline (≤ 220 chars):** title + specialties + value. Pack searchable terms.
   - e.g. *"Senior AI / Software Engineer → Solution Architect | LLM Agents, RAG, MCP &
     Multi-Agent Orchestration | Python · Node · AWS | building reliable AI platforms"*
2. **About (3–5 short paragraphs, first person):**
   - Para 1: who you are + the headline value, with a hook.
   - Para 2: AI-engineering proof (agent platforms, RAG/KB, MCP, evals, cost/latency).
   - Para 3: classical-engineering + architecture proof (microservices, scale, reliability,
     leadership) — keep the balance.
   - Para 4: trajectory (toward AI Solution Architecture) + what you want next.
   - Close: a line of grouped keywords for search.
3. **Experience:** mirror the resume's strongest 3–4 bullets per recent role (LinkedIn allows
   slightly more narrative; expand the "why it mattered").
4. **Skills (pin top 3):** pin the AI ones (LLM agents / RAG / system design) for endorsements.
5. **Featured:** suggest linking the GitHub, a portfolio case study (`portfolio-case-study`),
   or the Agno OSS contribution.

## Method

1. Load positioning + read the current resume for consistency.
2. Draft each section; first person, warmer than the resume, still specific and quantified.
3. Front-load recruiter-search keywords in headline + About + skills.
4. Save to `CV/linkedin/profile.md` for the user to paste in.

## Quality bar

- [ ] Headline is keyword-rich and ≤ 220 chars.
- [ ] About balances AI and classical-engineering, ends with a keyword line.
- [ ] Consistent with the resume (no inflated or conflicting claims).
- [ ] Top-3 skills chosen for recruiter search + endorsements.
