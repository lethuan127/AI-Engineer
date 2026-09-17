---
name: ats-optimizer
description: Optimize the resume to pass Applicant Tracking Systems (ATS) for a Senior AI/Software Engineer or AI Solution Architect role. Checks keyword coverage against a target job description, flags ATS-hostile formatting, and proposes safe fixes. Use when the user says "ATS check", "will this pass the bots", "optimize for keywords", or pastes a job description to match against.
---

# ATS Optimizer

Maximize machine-parseability and keyword match without keyword-stuffing.

> **First:** load `resume-positioning` for the keyword bank. If a target JD is provided,
> use `jd-tailor`'s analysis as the keyword source of truth.

## When to use

- Before submitting to a company with an online portal (Workday, Greenhouse, Lever…).
- User pastes a JD and asks "does my resume match".
- General "make it ATS-safe" pass.

## Two checks

### 1. Keyword coverage
- Extract the JD's hard requirements (languages, frameworks, cloud, AI/ML terms, years).
- Compare against the resume. Produce a **coverage table**: keyword → present? → where.
- For missing-but-true skills, suggest the **exact bullet or skills-line** to add them
  (must be honest — only add what the candidate actually has).
- Use the **canonical term + acronym** once each: "Model Context Protocol (MCP)",
  "Retrieval-Augmented Generation (RAG)" — ATS matches both forms.

### 2. ATS-hostile formatting (flag + fix)
- ❌ Tables/columns for layout, text boxes, headers/footers with content, images, icons,
  graphics-only skill bars. → ✅ single-column, plain text.
- ❌ Non-standard section titles. → ✅ "Work Experience", "Skills", "Education".
- ❌ Dates only in sidebars. → ✅ inline `Mon YYYY – Mon YYYY`.
- ❌ Special glyphs/emoji as bullets. → ✅ standard `-`/`•`.
- ✅ Standard fonts, `.docx`/`.pdf` (text-based, not scanned).

## Method

1. Get target role/JD (ask if not given; otherwise optimize against the positioning
   keyword bank for "Senior AI/Software Engineer / AI Solution Architect").
2. Run both checks against `CV/LÊ VĂN THUẬN.md`.
3. Output: (a) coverage table, (b) prioritized missing keywords with honest placement
   suggestions, (c) formatting fixes.
4. Compute a rough **match score** (% of JD hard requirements covered) and what would
   move it most.

## Output

```
Match: 78%  (14/18 hard requirements)
Missing (high value): Kubernetes operators, LangGraph, evaluation frameworks
Add to Skills/AI line: "agent evals (LLM-as-judge)" — supported by AIP auto-evals work
Formatting: 1 issue — skills currently render fine; no tables. ✅
```

## Quality bar

- [ ] No dishonest keyword insertion — every added term is real.
- [ ] Canonical + acronym form for key AI terms.
- [ ] Single-column, standard headings, text-based file.
- [ ] Match score + the 3 highest-leverage additions called out.
