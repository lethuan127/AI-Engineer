# Centralized Knowledge for AI — Rollout Plan

> Task-level detail for the *Enterprise Brief* §5 roadmap (and the *Solution Architecture* §11 build
> sequence). Phased, with **owner** and **done-when (acceptance)** for each task. Roles: **Lead**ership ·
> **IT**/Platform · **AI** Team · **Domain** expert/lead · **Sec**urity/Governance. Start with a pilot
> team; expand once each phase's "done" holds.

## Phase 0 — Decide & scope (prerequisite)

| Task | Owner | Done when |
|------|-------|-----------|
| Choose the **single source of truth** (Google Drive / SharePoint / git repo) | Lead + IT | one canonical location agreed and documented |
| Define the **permission model** — who/what may read vs write | Sec | read/write roles mapped to existing groups |
| Pick a **pilot team + 2–3 use cases** | Lead + AI | scoped pilot with success metrics written down |
| Choose **Claude surface(s)** (Cowork for staff, Code for devs) + IT guardrails | IT | surfaces approved; MDM/policy baseline set |

**Phase done:** source of truth, permissions, pilot, and surfaces are agreed in writing.

## Phase 1 — Stand up the shared filesystem

*One step centralizes documents + the AI's notes + playbooks.*

| Task | Owner | Done when |
|------|-------|-----------|
| Provision the shared folder / repo | IT | location exists with access controls |
| Install the **sync client** on pilot machines / connect the folder to Cowork | IT | folder appears locally / mounted into Cowork |
| Define **folder structure + naming conventions** (so agentic search works) | AI + Domain | documented structure; READMEs/index in place |
| Set **access permissions** (inherit from existing groups) | Sec | only authorized users/agents can read/write |
| Verify **read + write round-trip** | AI | agent edits a file → change syncs to everyone |

**Phase done:** a pilot user's AI can read *and* write the shared source of truth.

## Phase 2 — Capture procedural knowledge (playbooks / skills)

*Highest payoff, lowest risk. **Authored by domain experts themselves** — see the tooling note.*

| Task | Owner | Done when |
|------|-------|-----------|
| One-time: set up **Claude Code (desktop)** for domain experts — scoped to the skills repo, git auth pre-configured, permissions limited, a guided `/new-skill` command | IT | an expert can author + submit a skill **without typing git** |
| Identify the **top recurring tasks** | Domain | ranked shortlist of repeatable workflows |
| **Author 3–5 skills** in Claude Code (it does the file edit + commit + PR for them) | Domain | each runs end-to-end on a real task |
| Establish a **light review** — peer approval and/or CI lint/validate (no technical gatekeeper) | Domain + Sec | shared skills merge only after review |
| Verify each surface loads them | Domain + AI | the same skill works in **Cowork (use)** and **Claude Code (author)** |

**Phase done:** a domain expert authors a skill in Claude Code, it passes review, and the team uses it in Cowork.

> **Tooling — who authors vs who uses.** **Claude Code (desktop)** is the *authoring* tool: it writes
> `SKILL.md` and runs **git for** the expert, so non-technical people contribute **without git commands**.
> **Cowork** is the *daily* tool: it mounts skills **read-only** and just runs them — it *can't* author
> skills (read-only mount, no push), which is exactly why authoring uses Claude Code. IT does a one-time
> setup (scope + git auth + a guided command); after that, experts are **self-serve, no technical team in
> the loop**. Keep a light review (peer or CI) so one bad edit can't break everyone.

## Phase 3 — Agree shared facts & definitions

| Task | Owner | Done when |
|------|-------|-----------|
| Capture key **conventions/definitions** (e.g. "active customer", "MRR") | Domain | definitions written and agreed |
| Package them as a **`company-definitions` skill** — `SKILL.md` (router + trigger description) + `references/<topic>.md` | Domain (in Claude Code) | a sample question pulls the **right** definition **without** loading the whole glossary |
| Ship it in the **org plugin**; set a **review path** for changes | AI + Sec | every member gets it; edits merge only via review |

**Phase done:** agents give **consistent** answers using the shared definitions — pulled **on relevance**
(lean context) — across the team.

> **Why a skill, not flat notes.** A skill is **retrieved on relevance** (progressive disclosure: the
> one-line description loads always, the body when relevant, a specific `references/*.md` only when that
> term comes up) — so the glossary can grow huge without bloating context. For a *handful* of definitions,
> `CLAUDE.md` is simpler. **The `description` is the trigger** — keep it broad-but-precise so the model
> pulls definitions whenever a business term appears.

## Phase 4 — Connect operational data (READ)

| Task | Owner | Done when |
|------|-------|-----------|
| Inventory target systems (CRM / DB / BI) + pick the connector | AI + IT | connector chosen per system |
| Stand up connector(s) **read-only**, with **permission inheritance** | IT + Sec | agent reads only what the user may see |
| Add a **semantic layer** for the valuable metrics | AI + Domain | NL questions map to validated metrics, not raw SQL |
| Verify the **orient → ground → verify** flow on sample questions | AI | sampled answers match a trusted source |

**Phase done:** the AI answers business questions from **live** data, read-only and governed.

## Phase 5 — Enable operational writes (GATED)

| Task | Owner | Done when |
|------|-------|-----------|
| Define **which writes** are allowed + the approval policy | Sec + Lead | allow-list + draft→approve rule documented |
| Enable write **per-connector** with **per-action approval + audit** | IT + Sec | every write is approved and logged |
| Pilot one **low-risk write** end-to-end | AI | approved write succeeds with an audit trail |

**Phase done:** the AI performs an **approved** write to a system of record, fully audited.

## Phase 6 — Scale memory (only if needed)

| Task | Owner | Done when |
|------|-------|-----------|
| Decide if memory must span **sessions/platforms** or outgrows files | AI | trigger criteria met (else skip this phase) |
| Stand up an **MCP memory server** (single write authority) | IT + AI | cross-session/platform memory works, conflict-free |

**Phase done:** memory is portable and conflict-free where the business needs it.

## Cross-cutting (every phase)

| Concern | Task | Owner |
|---------|------|-------|
| **Governance** | Audit on every tool call + write; DLP/policy review | Sec |
| **Observability** | Tracing so issues are debuggable | AI + IT |
| **Security review** | Re-check permission inheritance + sandbox settings before widening access | Sec |
| **Change mgmt** | Train the pilot team; collect feedback before expanding | Lead |

## Sequencing & dependencies

```
Phase 0 ─▶ Phase 1 ─▶ Phase 2 ─▶ Phase 3
                          └─▶ Phase 4 ─▶ Phase 5
                                            (Phase 6 anytime memory outgrows files)
```

- Phases **1–3 ride the filesystem** (cheap, low-risk) — do them first.
- Phases **4–5 add operational data** (more setup + governance) — the second wave; **read before write**.
- **Don't** start Phase 5 until Phase 4 is trusted; **don't** build Phase 6 until files genuinely fall short.

## Worked example — a SharePoint / Microsoft 365 shop

A common starting point: **documents already live on SharePoint.** The key realization is that the AI's
own knowledge **doesn't all go in one place** — split it by type:

| Knowledge | Store (for this shop) | How the AI reaches it |
|-----------|-----------------------|-----------------------|
| **Documents** | **SharePoint** (already there) | sync the library to the desktop via **OneDrive** → read **and write** the synced folder |
| **AI outputs / artifacts** | **SharePoint** (they *are* documents) | the agent saves finished work into the library |
| **Skills / workflows / commands** | the **`ai-knowledge` git repo** (Azure DevOps Repos or GitHub) — **not SharePoint** | **domain experts author in Claude Code (desktop)** — it does git for them; **Cowork *uses* them** (read-only); changes via PR (peer/CI review) |
| **Shared facts & definitions** | a **`company-definitions` skill** in `ai-knowledge` (`SKILL.md` + `references/*.md`) | **progressive disclosure** — pulled only when a question needs them; shipped in the org plugin |
| **Personal memory** | the user's **own machine** (`~/.claude/`, OneDrive-synced if wanted) | per-user, not shared |
| **Operational data** (CRM/SQL/BI) | stays in those systems | **MCP connectors** (Phase 4) |
| **Large/shared queryable memory** (later) | **MCP memory server** + vector store (e.g. Azure AI Search) | only if files fall short (Phase 6) |

Two gotchas specific to Microsoft 365:

- **Write-back uses OneDrive sync, not the connector.** The M365 connector is **read-only**; to let the AI
  *edit* SharePoint files, reach them through the **OneDrive-synced folder**.
- **Skills don't belong in SharePoint.** They're code — they need PR review, branches, and diffs. Put them
  in the **`ai-knowledge` repo**, even though your documents are on SharePoint. (Documents → SharePoint;
  know-how → git.)

So in this shop: **Phase 1** = SharePoint (via OneDrive sync) **+** the **`ai-knowledge`** repo; **Phase 2–3** populate
the git repo; **Phase 4** adds MCP connectors; AI outputs flow back to SharePoint.

Suggested `ai-knowledge` layout (one repo, skills + facts together):

```
ai-knowledge/
├── README.md                         # what this is + how domain experts contribute
├── .claude/
│   ├── skills/
│   │   ├── <playbook-name>/SKILL.md   # workflows/playbooks (Claude Code authors, Cowork uses, read-only)
│   │   └── company-definitions/       # shared facts & definitions — progressive disclosure
│   │       ├── SKILL.md               # router + trigger description (always-cheap)
│   │       └── references/            # one file per topic, pulled only when needed
│   │           ├── customers.md       #   "active customer", "churn", segments
│   │           ├── revenue.md         #   "MRR", "ARR", "gross margin"
│   │           └── fiscal.md          #   fiscal calendar / periods
│   └── commands/                      # optional slash commands (e.g. /new-skill)
├── .claude-plugin/
│   └── plugin.json                    # plugin manifest — name + version (bump to release)
└── CLAUDE.md                          # house conventions
```

> **Note — versioning & updates are not zero-touch.** The plugin manifest's **`version`** field controls
> releases: **bump it** to ship an update (omit it and every git commit counts as a new version). Updates
> reach members automatically **only if** an admin sets **`autoUpdate: true`** + **`enabledPlugins`** (managed
> scope) in settings — and even then a one-time **`/reload-plugins`** (or next launch) applies it. Without
> that config, users run `/plugin marketplace update` + `/reload-plugins` themselves.

## References

- [Centralized Knowledge for AI — Enterprise Brief](Centralized%20Knowledge%20for%20AI%20—%20Enterprise%20Brief.md)
- [Centralized Knowledge for AI — Solution Architecture](Centralized%20Knowledge%20for%20AI%20—%20Solution%20Architecture.md)
