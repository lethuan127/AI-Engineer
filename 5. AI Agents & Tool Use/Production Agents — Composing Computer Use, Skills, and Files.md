# Production Agents — Composing Computer Use, Skills, and Files

> Source: [Anthropic — Build production agents with computer use, the Skills API, and the Files API](https://claude.com/blog/computer-use-skills-api-files-api) (2026-08-20). Contrast with [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md), which solves a different problem (browser-engine cost/architecture) rather than primitive composition.

Anthropic shipped three previously separate primitives — UI automation, procedural knowledge injection, and persistent file state — as one composable loop and moved Computer Use to general availability. The interesting part isn't any single API; it's that the reference workflow in the announcement chains all three without a custom orchestration layer.

---

## 1. What actually changed at GA

| Primitive | What it does | What's new |
|---|---|---|
| **Computer Use** | Agent drives software via screenshots — click, type, scroll | **Multi-action turns**: several actions execute per turn instead of one action per API call, cutting round-trip latency and token cost |
| **Browser use tool** | Extends Computer Use to web apps | Reads page structure and targets specific DOM elements, instead of clicking pixel coordinates on a screenshot |
| **Skills API** | Upload a folder of instructions, scripts, and templates that Claude loads contextually mid-task | Runs inside Claude's own sandbox — no separate hosting required; API simplified at GA |
| **Files API** | Persistent document storage (PDFs, spreadsheets, etc.) across requests | Automatic file expiration, 5× higher rate limits, 1TB org storage, and now HIPAA-eligible under a BAA |

> Architectural takeaway: the browser use tool's DOM-targeting is the same reuse-vs-rebuild fork as [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md), but it stays on the *reuse* side — a real rendered browser, just read via structure instead of pixels. It buys targeting accuracy without touching the cost problem Kitesurf was built to solve (Chromium's per-tab memory/CPU footprint).

## 2. The composed pattern

The announcement's worked example is a claims-filing agent:

1. Reads the intake document from the **Files API**.
2. Follows a **Skill** encoding the team's filing procedure.
3. Completes the submission in an insurer's web portal with the **browser use tool**.
4. Saves the confirmation back as a file via the **Files API**.

Each primitive owns one concern — input state, procedural knowledge, UI action, output state — and none of them talk to each other directly. The agent loop is the only thing that sequences them. That's the same shape as [Code Execution as the Tool-Calling Substrate](./Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md) argues for tool orchestration generally: keep primitives narrow, let the model (or model-written code) do the composing, instead of building a bespoke pipeline per workflow.

> Why it matters: before this, "read a document, follow SOP, act on a web UI, persist the result" required stitching together a document-storage integration, a prompt-engineered procedure, and a bespoke browser-automation harness — three separate build-and-maintain surfaces. Collapsing them into three first-party APIs moves the integration cost from "per customer workflow" to "per Anthropic API."

## 3. Reported numbers

Asteroid (cited in the announcement) reported, on claims-processing workflows: task completion time dropped from 32 minutes to 13 minutes, a 30% cost reduction, and 100% success rate. Treat this as one vendor's result on one workflow class (structured, portal-driven, document-in/document-out) — it does not generalize to open-ended browsing or tasks without a clean document boundary.

## 4. When this composition fits

| Signal | Composed pattern fits | Prefer something else |
|---|---|---|
| Task has a clear document-in/document-out shape | Yes | — |
| The "how" is a stable, describable SOP | Skills API | Ad hoc prompting if the procedure changes every run |
| Target UI has no API but is a normal rendered web app | Browser use tool (DOM targeting) | Agent-native runtime if the bottleneck is Chromium fleet cost, not accuracy |
| Regulated data (PHI) in the loop | Files API's HIPAA eligibility under a BAA | — |
| High-volume, cost-sensitive browsing at fleet scale | — | [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md) |

## References

- [Anthropic — Build production agents with computer use, the Skills API, and the Files API](https://claude.com/blog/computer-use-skills-api-files-api)
