# 10. AI Enterprise

Application AI for the enterprise — how to give a company's AI **one shared, governed source of truth**
that every person and every AI tool can read and write, across platforms. Claude-first.

## Centralized Knowledge for AI

A connected body of work, written at three altitudes. **Pick your entry point by audience:**

| Read this | If you are… | What it is |
|-----------|-------------|------------|
| [Enterprise Brief](Centralized%20Knowledge%20for%20AI%20—%20Enterprise%20Brief.md) | a **leader / decision-maker** | non-technical: what it is, why it matters, what to decide |
| [Solution Architecture](Centralized%20Knowledge%20for%20AI%20—%20Solution%20Architecture.md) | an **architect** | the reference architecture — layers, flows, NFRs, decisions, rollout |
| [Comprehensive](Centralized%20Knowledge%20for%20AI%20—%20Comprehensive.md) | an **engineer wanting the full framework** | first principles, the two-axis model, every pillar end-to-end |
| [Rollout Plan](Centralized%20Knowledge%20for%20AI%20—%20Rollout%20Plan.md) | a **team executing it** | the roadmap as phased tasks — owner + done-when per step |

### Component deep-dives

- [Operational Data for AI — Reach, Understand, Act](Operational%20Data%20for%20AI%20—%20Reach%2C%20Understand%2C%20Act.md) — connecting CRM / SQL / BI via MCP; orient-before-act; gated writes.
- [Semantic-Layer MCP — Design](Semantic-Layer%20MCP%20—%20Design.md) — the highest-governance way to query business data: structured queries over validated metrics, not raw SQL. Includes a glossary (metric vs measure vs dimension, grain).
- [System Memory for AI — Capture, Store, Recall, Forget](System%20Memory%20for%20AI%20—%20Capture%2C%20Store%2C%20Recall%2C%20Forget.md) — the agent-authored memory tier; the lifecycle per memory type; sharing & multi-machine/platform; memory poisoning.
- [Claude Cowork — Sandbox Architecture](Claude%20Cowork%20—%20Sandbox%20Architecture.md) — the execution trust boundary (VM + six isolation mechanisms); the commit-works/push-doesn't gotcha and its fix.

### Companion (other tracks)

- [Context Window Management — Eviction, Compaction & Memory](../3.%20Prompt%20%26%20Context%20Engineering/Context%20Window%20Management%20—%20Eviction%2C%20Compaction%20%26%20Memory.md) — runtime context management (in *3. Prompt & Context Engineering*).

### Reading paths

- **Decide / pitch it:** Enterprise Brief → Solution Architecture.
- **Design / build it:** Solution Architecture → Comprehensive → the deep-dive for your component.
- **One topic fast:** jump straight to the relevant deep-dive.

---

## Scratch notes (unsorted)

> Rough ideas kept from the original README — not yet folded into the body of work above.

### MCP Gateway
- Authentication/Authorization · OAuth 2.1 Dynamic Client Registration · Resource protected metadata · Server Authorization metadata (OIDC configuration metadata)

### One Entry Endpoint
- MCP registry · Toolset · REST API to MCP

### Products / references seen
- **Mnemoverse Memory** — store and recall long-term memory for AI agents; persistent across Claude, Cursor, ChatGPT; semantic search across sessions/projects/tools.
- **Minutes — Meeting Memory for AI** — record, transcribe, search meetings/voice memos; privacy-first, local-only transcription with whisper.cpp.
- **Local Falcon** — AI-search visibility tracking across ChatGPT/Gemini/Grok/Google AI Overviews + local search.
- https://o-mega.ai/articles/claude-desktop-cowork-and-code-complete-guide
