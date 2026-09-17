---
name: resume-bullet-writer
description: Write or rewrite resume experience bullets for a Senior AI/Software Engineer. Turns raw responsibilities, tasks, or commit/ticket activity into tight achievement bullets (action + technical how + measurable impact). Use when the user says "write bullets", "rewrite this experience", "improve these bullet points", "make this sound senior", or "the Vireox section is weak".
---

# Resume Bullet Writer

Produce achievement-oriented resume bullets that read at a senior / architect altitude.

> **First:** load `resume-positioning` for this candidate's target framing, voice, and
> metric taxonomy. Pull facts only from the canonical sources listed there.

## When to use

- Rewriting a thin or generic experience section (the Vireox section is the prime target).
- Converting a list of tasks/responsibilities into impact bullets.
- "Make this sound more senior" / "add impact".

## The formula

```
<Strong past-tense verb> <the system/capability you built or owned>
  [using <key tech/architecture>] , <measurable impact or scope signal>.
```

- **Lead with the decision/system, not the activity.** "Migrated workflow session
  storage from MongoDB to PostgreSQL (AIP-78) with forward + rollback paths and SAST
  hardening, eliminating a class of session-loss failures" — not "worked on database
  migration".
- **One headline metric, bolded.** Two max. If none exists, use a scope/ownership signal.
- **No** "responsible for", no first-person, no adjective-stuffing.
- **Verb bank (senior/architect):** Architected, Owned, Led, Designed, Built, Migrated,
  Scaled, Optimized, Hardened, Instrumented, Pioneered, Consolidated, Productionized,
  Upstreamed, Standardized.

## Method

1. Load `resume-positioning`. Read the relevant source (work-activity.md / linear-activity.md)
   for the role being written.
2. Cluster raw activity into **themes** (e.g. report-generation platform, knowledge base,
   reliability, MCP gateway, agent runtime) — not one bullet per commit.
3. For each theme write **1 bullet**: verb + system + how + impact. Attach the real metric
   or ticket (AIP-1, AIP-78) when it strengthens credibility.
4. Order bullets **strongest-impact first**. 4–6 bullets per recent role; 2–3 for older.
5. Balance the set: across a role, show **both** AI-engineering and
   software/architecture bullets (see positioning).
6. Flag any metric you couldn't source as `[verify]`.

## Output format

Markdown bullets ready to paste, grouped under optional bold sub-headers
(`**Agent Platform & Reliability**`) only if the role has 5+ bullets. Otherwise flat.

## Quality bar (reject the draft if any fail)

- [ ] Every bullet starts with a strong verb, past tense.
- [ ] Every bullet names a concrete system or decision (not "various features").
- [ ] ≥ half the bullets carry a metric or hard scope signal.
- [ ] The role shows both AI and classical-engineering range.
- [ ] No unsourced numbers (else `[verify]`).
- [ ] No bullet exceeds ~2 lines.

## Example transform (Vireox)

> **Before:** "Lead the design and implementation of AI agents and the core product logic."

> **After:**
> - Architected the **report-generation platform** (V2→V5) behind OpenAI background mode,
>   eliminating the recurring 15-min timeout failures and adding full tracing, Slack
>   alerts, and per-draft agent isolation (AIP-1, AIP-13).
> - Migrated the Agno agent runtime's session storage from **MongoDB → PostgreSQL**
>   (AIP-78) with forward/rollback migrations and SAST hardening, removing a session-loss
>   failure class.
> - Built a unified **MCP tool gateway & catalog** (RFC 9728 OAuth, per-server PRM) and
>   contributed the MCP lifecycle-lock fix **upstream to the Agno framework**.
