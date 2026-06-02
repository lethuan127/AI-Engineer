# Resume & Career Toolkit (Claude Code skills)

A set of reusable Claude Code skills for resume, application, and interview work — tailored
to **Lê Văn Thuận** as a **Senior AI / Software Engineer** positioning toward **AI Solution
Architect**, with a **balanced full-stack + AI** framing. Modeled on
[Paramchoudhary/ResumeSkills](https://github.com/Paramchoudhary/ResumeSkills) but customized
to this candidate and wired into the verified work-tracking logs.

They live in `.claude/skills/` and auto-load when your request matches their description.
Invoke explicitly with the slash command (e.g. `/resume-bullet-writer`) or just describe the
task in natural language.

## The skills

| Skill | Use it to… |
|---|---|
| **resume-positioning** | Shared anchor — target role, voice, metric taxonomy, source files. The others load it; you rarely call it directly. |
| **activity-to-resume** | Turn the git + Linear work-tracking logs into experience bullets + a project entry. **Start here for the Vireox rewrite.** |
| **resume-bullet-writer** | Write/rewrite experience bullets (action + how + impact) at senior altitude. |
| **resume-quantifier** | Add or strengthen metrics on bullets; flags anything unverifiable. |
| **resume-skills-section** | Rebuild the SKILLS section — grouped, balanced AI + backend, honest levels. |
| **ats-optimizer** | Keyword + formatting check to pass ATS; match-score against a JD. |
| **jd-tailor** | Analyze a job posting, gap-analysis, produce a tailored resume variant. |
| **portfolio-case-study** | Write a STAR + architecture case study of a project. |
| **interview-prep** | Behavioral (STAR), AI/system-design, and project deep-dive prep. |
| **cover-letter** | Draft a tight, tailored cover letter for a specific role. |
| **linkedin-optimizer** | Headline, About, experience, skills tuned for recruiter search. |

## Recommended workflow

1. **`/activity-to-resume`** → draft the new Vireox experience + project from the logs.
2. **`/resume-bullet-writer`** + **`/resume-quantifier`** → tighten bullets, add metrics.
3. **`/resume-skills-section`** → modernize the skills taxonomy (add MCP, RAG, Agno, evals…).
4. Per application: **`/jd-tailor`** → **`/ats-optimizer`** → **`/cover-letter`**.
5. Before interviews: **`/portfolio-case-study`** + **`/interview-prep`**.
6. **`/linkedin-optimizer`** once the resume is settled.

## Design principles baked into every skill

- **Source of truth, never invent.** Facts come from `CV/LÊ VĂN THUẬN.md` and
  `CV/vireox(100x) work tracking/`. Unsourced numbers are flagged `[verify]`.
- **Balanced full-stack + AI**, oriented toward solution architecture.
- **The master resume is never overwritten** — tailored outputs are saved as variants
  (`CV/variants/`, `CV/cover-letters/`, `CV/portfolio/`, `CV/interview-prep/`, `CV/linkedin/`).
- **The resume is versioned by time** — `CV/LÊ VĂN THUẬN-YYYY-MM.md` dated snapshots, with
  `CV/LÊ VĂN THUẬN.md` a symlink to the latest. See `CV/VERSIONS.md` for the changelog and
  the "cut a new version" steps (also encoded in `resume-positioning`).

## Portability

These are personal career tools. To use them in any project, copy `.claude/skills/resume-*`,
`activity-to-resume`, `ats-optimizer`, `jd-tailor`, `interview-prep`, `cover-letter`,
`portfolio-case-study`, and `linkedin-optimizer` into `~/.claude/skills/` (global) — but note
they reference this repo's file paths, so update those if you move them.
