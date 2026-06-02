---
name: jd-tailor
description: Analyze a target job description and tailor the resume to it for a Senior AI/Software Engineer or AI Solution Architect role. Extracts requirements, does a gap analysis against the candidate's real experience, and produces a tailored resume variant + a short fit narrative. Use when the user pastes a job posting, says "tailor my resume to this job", "analyze this JD", or "am I a fit for this role".
---

# JD Tailor (analyze + tailor)

Read a job description, map it to the candidate's real experience, and produce a tailored
resume variant — without inventing experience.

> **First:** load `resume-positioning`. Facts come only from the canonical sources.

## When to use

- A specific job posting is in hand and the resume should be tuned to it.
- The user wants a fit / gap assessment before applying.

## Method

### 1. Analyze the JD
Extract into a structured list:
- **Must-haves** (years, languages, frameworks, cloud, AI/ML, domain).
- **Nice-to-haves.**
- **Signals of seniority/architecture** (own design, lead, mentor, scale, ambiguity).
- **Company/domain keywords** worth mirroring.

### 2. Gap analysis (honest)
For each must-have: **Strong / Partial / Gap**, with the evidence (which role/project/ticket).
- *Strong:* direct, demonstrable (e.g. "LLM agent orchestration" → Vireox agent platform).
- *Partial:* adjacent/transferable (e.g. JD wants GCP, candidate is AWS-deep + some Vertex).
- *Gap:* not present — state it plainly; suggest honest framing or whether to skip the role.

### 3. Tailor
- Reorder/reword bullets so the **JD's top must-haves surface in the top third**.
- Pull matching projects forward; trim irrelevant ones.
- Mirror the JD's terminology (canonical + acronym) where the candidate genuinely has it.
- Adjust the professional summary's first sentence to the target title.
- Hand off keyword/format finalization to `ats-optimizer`.

## Output

1. **Fit summary** — one paragraph: overall match, top 3 strengths for *this* role, any
   honest gaps.
2. **Requirement → evidence table** (Strong/Partial/Gap).
3. **Tailored resume** (or a diff of what to change) saved as a variant, e.g.
   `CV/variants/LÊ VĂN THUẬN — <company-role>.md` — never overwrite the master.

## Quality bar

- [ ] No fabricated experience to close a gap; gaps are stated honestly.
- [ ] Top must-haves appear in the resume's top third.
- [ ] Master resume untouched; tailored copy saved as a named variant.
- [ ] Fit summary is candid, not a sales pitch.
