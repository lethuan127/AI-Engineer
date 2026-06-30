# Rocky Mountain — Shared Org Memory (Skills-Based) Design

> Applies *System Memory for AI — Capture, Store, Recall, Forget* to the
> `rocky-mountain-analytics` plugin. Focus: **shared org memory implemented as skills.**
> The core idea (research §5 tip + §8): a Claude Code **plugin** *is* shared org memory —
> **procedural** knowledge (skills) plus **shared semantic** knowledge (the `references/*.md`
> definitions, conventions, and the *why*), shipped via git → marketplace → every analyst,
> **read-only**, with all writes gated by **PR review**.

---

## 1. The four memory types, mapped to Rocky Mountain

Where each type lives, and what is **shared** vs **local**. Only the plugin (green) is org-shared;
everything else stays on each analyst's machine.

```mermaid
flowchart TB
    subgraph SHARED["🟢 SHARED ORG MEMORY — git + marketplace (read-only to analysts)"]
        direction TB
        PROC["Procedural — skills<br/>exec-intel · askmarketing · askinventory<br/>askhoodie · loyalty-report · report-builder…<br/><i>SKILL.md = how-to</i>"]
        SEM["Shared semantic — references/*.md<br/>metrics-definitions · membership-classification<br/>conversion-calendar · sql-reference · guardrails<br/><i>definitions, conventions, the why</i>"]
    end

    subgraph LOCAL["🟡 LOCAL / PER-ANALYST — never centralized raw"]
        direction TB
        EPI["Episodic — transcripts<br/>~/.claude/projects/&lt;id&gt;/*.jsonl<br/><i>what happened, this analyst</i>"]
        PERS["Personal semantic — user CLAUDE.md<br/>~/.claude/CLAUDE.md<br/><i>my style, my preferences</i>"]
        AUTO["Auto-memory<br/>~/.claude/projects/&lt;id&gt;/memory/<br/><i>facts this agent distilled</i>"]
    end

    subgraph SCOPED["🔵 SCOPED — travels with the repo"]
        PROJ["Project CLAUDE.md<br/><i>marketplace conventions, this project only</i>"]
    end

    PROC -->|"progressive disclosure"| CTX["Analyst's Claude Code context window"]
    SEM  -->|"loaded on demand"| CTX
    EPI -.->|"distill → promote a lesson"| PROC
    PERS -.-> CTX
    AUTO -.->|"durable + reusable? promote via PR"| SEM
    PROJ --> CTX

    classDef shared fill:#d4edda,stroke:#28a745,color:#155724
    classDef local fill:#fff3cd,stroke:#ffc107,color:#856404
    classDef scoped fill:#cce5ff,stroke:#007bff,color:#004085
    class PROC,SEM shared
    class EPI,PERS,AUTO local
    class PROJ scoped
```

**Read it as:** procedural + shared semantic are the only things worth sharing org-wide
(durable, reusable, impersonal — research §8). Episodic and personal stay local; their *value*
graduates upward by becoming a skill or a documented definition (dotted arrows = the promotion path).

---

## 2. Skills-based shared org memory — the distribution architecture

How one author's knowledge reaches every analyst. Git is the single source of truth; the
marketplace is the delivery channel; each install is a read-only copy.

```mermaid
flowchart LR
    AUTHOR["📝 Author / analyst<br/>writes or edits a skill"]

    subgraph REPO["📦 100x-managed-plugins (git)"]
        direction TB
        PR["Pull Request<br/>validate_plugins.py + review agents"]
        MAIN["main branch<br/>plugins/rocky-mountain-analytics/"]
        PR -->|"merge = approved write"| MAIN
    end

    MKT["🏪 Marketplace catalog<br/>marketplace.json"]

    subgraph FLEET["👥 Every analyst's Claude Code"]
        A1["Analyst A"]
        A2["Analyst B"]
        A3["Analyst C"]
    end

    AUTHOR -->|"open PR"| PR
    MAIN --> MKT
    MKT -->|"/plugin marketplace update<br/>(dereferenced copy)"| A1
    MKT --> A2
    MKT --> A3

    note["One author levels up everyone.<br/>Writes are reviewed (governance §9).<br/>Analysts only READ the installed copy."]
    MAIN -.-> note

    classDef repo fill:#d4edda,stroke:#28a745,color:#155724
    classDef fleet fill:#e7f1ff,stroke:#007bff,color:#004085
    classDef noteStyle fill:#f8f9fa,stroke:#adb5bd,color:#495057
    class PR,MAIN repo
    class A1,A2,A3 fleet
    class note noteStyle
```

**Why this is the high-leverage pattern (research §8, table row 1):** procedural memory shared via
git is *free to centralize, already code-reviewed, and impersonal* — lowest risk, highest leverage.
Packaging the shared **semantic** memory (definitions) inside the same skill bundle gives it the
same safe, reviewed, versioned distribution path.

---

## 3. Recall — progressive disclosure (the 3 tiers)

This is *why* skills scale as shared memory: the context window never holds the whole knowledge base.
Only the thin description layer is always present; bodies and reference files load on demand.

```mermaid
flowchart TB
    Q["Analyst asks:<br/>'How do EDW memberships break down — bought vs gifted?'"]

    subgraph T1["TIER 1 — always in context (cheap)"]
        DESC["All skill <b>descriptions</b><br/>exec-intel, askmarketing, askinventory, askhoodie…<br/><i>name + one-line trigger only</i>"]
    end

    subgraph T2["TIER 2 — loads on trigger match"]
        BODY["rocky-mountain-exec-intel / SKILL.md<br/><i>workflow, rules, scope, pointers</i>"]
    end

    subgraph T3["TIER 3 — loads only when the task needs it"]
        REF1["references/membership-classification.md ✅"]
        REF2["references/metrics-definitions.md"]
        REF3["references/conversion-calendar.md"]
        REF4["references/sql-reference.md"]
    end

    Q --> DESC
    DESC -->|"trigger words: EDW, membership"| BODY
    BODY -->|"question = bought vs gifted →<br/>read the ONE matching file"| REF1
    BODY -.->|"not loaded"| REF2
    BODY -.->|"not loaded"| REF3
    BODY -.->|"not loaded"| REF4

    classDef t1 fill:#d4edda,stroke:#28a745,color:#155724
    classDef t2 fill:#fff3cd,stroke:#ffc107,color:#856404
    classDef t3 fill:#cce5ff,stroke:#007bff,color:#004085
    classDef off fill:#f1f3f5,stroke:#ced4da,color:#868e96
    class DESC t1
    class BODY t2
    class REF1 t3
    class REF2,REF3,REF4 off
```

**Read it as (research §5):** the description is the *index* (always loaded, like `MEMORY.md`); the
SKILL.md body is the *chapter*; the `references/*.md` are *detail pages* pulled only when the question
matches. Lean context + scales with the glossary = the procedural recall pattern applied to semantic
knowledge. Adding a 20th definition file costs **zero** extra context until it's actually needed.

---

## 4. The memory lifecycle for a shared skill

Capture → Store → Recall → Forget, the way it actually runs for Rocky Mountain. The key move:
a lesson from one analyst's session is **promoted** into the shared skill through a reviewed PR.

```mermaid
flowchart LR
    subgraph CAP["CAPTURE"]
        C1["Analyst hits a recurring need<br/>or a hard-won lesson<br/>(e.g. 'Commerce City price-only-test trap')"]
    end

    subgraph STORE["STORE (git)"]
        S1["Add/edit reference file<br/>or skill body"]
        S2["PR → validate + review<br/>(poisoning defense §9)"]
        S3["Merge to main"]
        S1 --> S2 --> S3
    end

    subgraph REC["RECALL"]
        R1["Progressive disclosure<br/>(diagram §3)<br/>loads it only when relevant"]
    end

    subgraph FORG["FORGET = deprecate, not decay"]
        F1["Stale definition / wrong rule<br/>= a bug to fix"]
        F2["Edit or remove via PR<br/>git history = audit trail"]
        F1 --> F2
    end

    C1 --> S1
    S3 --> R1
    R1 -.->|"found stale in use"| F1
    F2 -.->|"new version ships"| S3

    classDef cap fill:#e2d4f0,stroke:#6f42c1,color:#3d1a78
    classDef store fill:#d4edda,stroke:#28a745,color:#155724
    classDef rec fill:#cce5ff,stroke:#007bff,color:#004085
    classDef forg fill:#f8d7da,stroke:#dc3545,color:#721c24
    class C1 cap
    class S1,S2,S3 store
    class R1 rec
    class F1,F2 forg
```

**Two things the research stresses (§6):** procedural/shared-semantic memory is **never forgotten
passively** — no time-decay. A wrong rule is a *bug fixed via git*, not clutter that ages out.
And because it's file-based + git, every change is **diffable, reviewable, revertible** — staleness
shows up in review.

---

## 5. Personal vs shared — who can write where (governance)

The safety model: analysts **write only to their own local memory** and **read** the curated shared
skill. Writes to shared memory take the stricter PR path. This is the defense against **memory
poisoning** (research §9 / OWASP ASI06).

```mermaid
flowchart TB
    subgraph ANALYST["🧑 Each analyst (local, read-write to self)"]
        direction TB
        W1["✍️ writes freely → personal CLAUDE.md, auto-memory, transcripts"]
        R1["👁️ reads → installed rocky-mountain skills"]
    end

    subgraph SHARED["🟢 Shared org memory — rocky-mountain plugin (read-only)"]
        SK["skills + references<br/><i>conventions, definitions, the why</i>"]
    end

    GATE{"PR review gate<br/>validate_plugins.py<br/>+ plugin-reviewer"}

    W1 -->|"durable, reusable, impersonal lesson?"| GATE
    GATE -->|"approved write only"| SK
    SK -->|"install / update"| R1
    GATE -.->|"rejected: noise, personal, or unverified"| W1

    classDef analyst fill:#fff3cd,stroke:#ffc107,color:#856404
    classDef shared fill:#d4edda,stroke:#28a745,color:#155724
    classDef gate fill:#f8d7da,stroke:#dc3545,color:#721c24
    class W1,R1 analyst
    class SK shared
    class GATE gate
```

**Read it as (research §8 + §9):** *per-user writable stores + a shared read-only store.* The only
way into shared memory is the reviewed PR — which gives you provenance, validation-on-write, and a
revertible audit trail by construction. A poisoned or stale fact can't silently enter the org's memory.

---

## 6. Maintaining shared knowledge

The hard question is not *how* to store shared knowledge, but *how the author knows what to update*.
Several feedback channels feed the author's decision — the diagram below shows them grouped by nature,
and the ranked table that follows scores each by effectiveness. They all converge on the same reviewed
PR gate from §5 — they only change **what** gets queued, never **how** it lands.

```mermaid
flowchart TB
    subgraph OFF["🟢 1 · Offline feedback — human + world, batch"]
        direction TB
        BE["Business events<br/>30K/Pacing PDFs · ops Slack · Linear<br/><i>conversions · rename · new stores · price shifts</i>"]
        UR["Direct user reports<br/><i>'this definition is wrong / missing'</i>"]
    end

    SRV["🔵 2 · Scheduled re-verification — cron vs live VireoX<br/>fact values <i>(metric thresholds · member SKU)</i> + schema drift <i>(tables/fields)</i>"]
    MCP["🟣 3 · Agent feedback via MCP<br/>self-contradiction · in-chat correction"]
    EVAL["🔴 4 · Eval / regression gate<br/>golden questions on every PR"]
    USAGE["⚪ 5 · Skill-usage metrics<br/>load freq · hit/miss · failures"]

    TRIAGE{"Author triage<br/>add · fix · deprecate"}
    GATE{"PR review gate (§5)<br/>validate + review"}
    SHARED["🟢 Shared org memory<br/>skills + references"]

    BE --> TRIAGE
    UR --> TRIAGE
    SRV --> TRIAGE
    MCP --> TRIAGE
    USAGE --> TRIAGE
    EVAL --> GATE
    TRIAGE --> GATE
    GATE -->|"approved"| SHARED
    SHARED -.->|"new version ships, loop repeats"| SRV

    classDef off fill:#d4edda,stroke:#28a745,color:#155724
    classDef rv fill:#cce5ff,stroke:#007bff,color:#004085
    classDef online fill:#e2d4f0,stroke:#6f42c1,color:#3d1a78
    classDef gatecls fill:#f8d7da,stroke:#dc3545,color:#721c24
    class BE,UR off
    class SRV rv
    class MCP,USAGE online
    class TRIAGE,GATE gatecls
    class SHARED off
```

**The channels, ranked by effectiveness** for Rocky Mountain — how much real staleness each one
actually catches. Effort is shown separately so a cheap-but-effective channel is easy to spot (the
rollout note after the table balances the two).

| Rank | Channel (id) | What it catches | Effort | Why it ranks here |
|------|--------------|-----------------|--------|-------------------|
| **1** | **Offline feedback** (#5 + #1) | Human + world signals the author collects *outside* the live agent loop: **(a) business events** — banner conversion, the Schwazze→Rocky Mountain rename, a new store, a price-strategy shift, from the weekly 30K/Pacing PDFs, ops Slack, Linear; **(b) direct user reports** — an analyst says a definition is wrong/missing. Protects `conversion-calendar.md`, `report-context-maps.md`, scope, + any reported fact. | Med *(reports: none)* | The **business-event half** is RM's single largest staleness source — *no other channel sees the world change*. The **user-report half** (old standalone #1) is high-trust but partial; folding it in keeps every offline human/world signal on one path. |
| **2** | **Scheduled re-verification** (#4 + #6) | A cron re-checks high-relevance fact *values* against live VireoX (metric thresholds, member SKU/discount logic) **and diffs the VireoX schema** (renamed table / dropped column) before a query collides. Protects `metrics-definitions.md`, `membership-classification.md`, `sql-reference.md`. | Med | The only true fix for the research §7 **hard case** — stale high-relevance facts that still "look right." Proactive, not reactive; one cron covers both the fact values and the SQL *contract*. |
| **3** | **Agent feedback via MCP** (#2) | Agent flags trouble at point-of-use: **self-contradiction** (live VireoX disagrees with a stored fact) or a **user correction** mid-conversation, emitted with provenance. | High | High-value (catches staleness *as it's used*) but **reactive** — only fires when a query happens to hit the bad fact — and needs an MCP write-back path. |
| **4** | **Eval / regression gate** (#10) | A golden-question set in CI; a regression blocks the merge. Protects all skills + references. | Low | Best **ROI** — rides the existing `validate_plugins.py` gate. Catches author-introduced regressions *before* they ship, but not real-world drift. |
| **5** | **Skill-usage metrics** (#3) | Load frequency, trigger hit/miss, failure/over-delegation → fill gaps, fix high-use+high-fail first, retire never-used. | Med–High | Indirect on **correctness** (measures usage, not truth) and needs telemetry that may not exist yet. A prioritization aid, not a staleness detector. |

**How to read the ranking:** effectiveness here = *how much real staleness the channel catches*, not how
cheap it is. **Offline feedback** tops the list on the strength of its **business-event half** — RM's
memory is dominated by time-sensitive business facts and nothing else sees the world change; its
user-report half is high-trust but partial. **Scheduled re-verification** (one cron covering both
fact values and schema drift) catches the VireoX-derived facts that go stale silently. The **eval gate**
ranks high for ROI despite a narrower problem (nearly free). **Skill-usage metrics** ranks last — it
measures usage, not truth, and only after the fact, leaving the research §7 hard case to the channels
above it.

> **Governance still holds (§5; research §9).** None of these channels write to shared memory directly. They
> only **propose** changes into the author's triage; every change still lands through the reviewed PR.
> Channel 2 in particular ingests agent/user content, so its signals must carry **provenance** and be
> treated as untrusted until reviewed — exactly the memory-poisoning defense (OWASP ASI06).

**Rollout order (effectiveness × effort).** The ranking above is pure effectiveness; for *what to build
first*, balance it against effort: start with the **eval gate (#10)** (nearly free — just tests on the
existing `validate_plugins.py` gate), then stand up the **business-event feed** (the #5 half of offline
feedback — reuses the weekly reports already in the pipeline), then **scheduled re-verification with its
schema-drift watcher (#4 + #6)** (both query live VireoX, so they share plumbing). Each one still feeds the same
triage → PR path — they widen *what* you catch, never *how* it lands.

---

## Summary — how the research maps to Rocky Mountain

| Research concept | Rocky Mountain implementation |
|---|---|
| **Procedural memory, shared aggressively** (§8) | The skills themselves (`exec-intel`, `askmarketing`, …) shipped via the marketplace |
| **Shared semantic packaged as a skill** (§5 tip) | The `references/*.md` — metric definitions, membership classification, conversion calendar |
| **Recall = progressive disclosure** (§5) | description (always) → SKILL.md (on trigger) → one reference file (on demand) |
| **Store = files in git** (§4) | `plugins/rocky-mountain-analytics/` version-controlled |
| **Forget = deprecate, not decay** (§6) | Wrong rule = bug fixed via PR; git history is the audit trail |
| **Per-user writable + shared read-only** (§8) | Analysts write local memory; shared writes go through PR |
| **Poisoning defense** (§9) | `validate_plugins.py` + review agents + revertible git history |
| **Episodic stays local, value graduates** (§8) | Transcripts never centralized; a lesson becomes a skill/definition via PR |
| **Maintenance = proactive, not reactive** (§7) | 5 feedback channels ranked by effectiveness — top: offline feedback (business events + user reports), scheduled re-verification (with schema-drift watcher), agent-via-MCP — all feed author triage → PR |
```
