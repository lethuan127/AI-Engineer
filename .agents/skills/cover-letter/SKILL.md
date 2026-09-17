---
name: cover-letter
description: Draft a tailored, concise cover letter for a Senior AI/Software Engineer or AI Solution Architect application. Maps the candidate's real, sourced achievements to a specific company/role. Use when the user says "write a cover letter", "draft an application note", or pastes a job/company to write for.
---

# Cover Letter

A short, specific, non-generic cover letter — three tight paragraphs, grounded in real work.

> **First:** load `resume-positioning`. Achievements come from the CV / work logs.

## When to use

- An application asks for (or allows) a cover letter or intro note.
- The user wants a tailored message to a specific company.

## Structure (≤ 300 words)

1. **Hook (2–3 sentences):** the role + why *this* company/problem, with one sharp,
   specific reason (their product, their AI direction) — not "I am passionate about tech".
2. **Proof (1 paragraph):** 2–3 concrete, quantified achievements that map to the JD's top
   needs — e.g. "built and hardened a production LLM report platform (eliminated recurring
   timeout failures, added tracing + per-draft isolation)", "led a zero-loss Mongo→Postgres
   runtime migration", "contributed fixes upstream to the Agno agent framework". Pick the
   ones the JD cares about.
3. **Fit + close (2–3 sentences):** the trajectory (senior AI/SWE → solution architecture)
   matched to where the role is going; clear, confident close.

## Method

1. Get company + JD (ask if missing). Identify their top 2–3 needs and any AI/product angle.
2. Pull 2–3 matching achievements (sourced); mirror the JD's language honestly.
3. Draft ≤ 300 words. Specific company reference in para 1. No clichés, no restating the
   resume line-by-line.
4. Save to `CV/cover-letters/<company-role>.md`.

## Quality bar

- [ ] ≤ 300 words, three paragraphs.
- [ ] Para 1 names something real and specific about the company.
- [ ] Achievements are sourced and quantified; mapped to the JD's needs.
- [ ] No generic filler ("hard-working team player", "passionate about technology").
- [ ] Confident, not boastful; honest about scope.
