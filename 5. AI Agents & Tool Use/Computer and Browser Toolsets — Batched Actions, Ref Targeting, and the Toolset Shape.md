# Computer and Browser Toolsets — Batched Actions, Ref Targeting, and the Toolset Shape

> Companion to [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md), which argued that pixels are the most expensive representation of a page you can hand a model. This note covers what the first-party tool did about it — and a change to tool *shape* that generalizes past browsers.

On 2026-08-20 Anthropic moved computer use, the Skills API, and the Files API to general availability and shipped a browser use tool alongside them. The GA label is the least interesting part. Three things changed underneath it: a single tool with an `action` enum became a **toolset** of named member tools; a turn can now carry **many actions instead of one**; and the browser toolset lets the model point at an element by **reference into an accessibility tree** rather than by pixel coordinate. Each of those removes a round-trip or a token class that agent harnesses have been paying for since the first screenshot loop.

---

## 1. What actually shipped

| Surface | Before | Now |
|---|---|---|
| Computer use | `{"type": "computer_20251124", "name": "computer"}`, beta header, one action per model call | `{"type": "computer_toolset_20260801"}`, GA, no beta header, 17 member tools, batched actions |
| Browser use | did not exist (Playwright/Puppeteer MCP or the pixel loop) | `{"type": "browser_toolset_20260801"}`, GA, 31 members (27 on by default) |
| Skills | filesystem-only, host-managed | `POST /v1/skills` + versions, attached via `container.skills`, runs in the code-execution sandbox |
| Files | re-send bytes each request | upload once, reference by `file_id`; 500 MB/file, 1 TB/org, optional expiry |

The older tool versions keep working. `computer_20251124` (beta header `computer-use-2025-11-24`) and `computer_20250124` still exist for models that predate the toolset, and a `computer_20251124` entry cannot coexist with the toolset entry in the same request.

## 2. From tool to toolset

The shape change is worth reading carefully, because it is the part that will show up in other tool families.

Old shape: one tool named `computer`, one `action` field, an enum of ~15 values, and a union input schema where half the fields are irrelevant to whichever action was chosen. New shape:

```json
{
  "tools": [
    {
      "type": "browser_toolset_20260801",
      "configs": {
        "javascript_exec": { "enabled": true },
        "read_network":    { "enabled": true }
      }
    }
  ]
}
```

The toolset entry has **no `name`** — sending one is an `invalid_request_error`. Each emitted `tool_use` block instead carries `name` = the member (`navigate`, `find`, `form_input`, …) plus `"toolset_name": "browser"`, and its `input` holds only that member's parameters. Every `tool_result` must echo `toolset_name`.

> Architectural takeaway — the `action`-enum pattern is a workaround for a schema system that couldn't express "one of N disjoint shapes." A toolset makes each action a first-class tool with its own tight schema, then gives the platform one handle to enable, disable, price, and cache the whole family. If you build your own tool surface, this is the shape to copy: narrow schemas, one grouping construct above them.

Per-member `configs` supports `enabled` (default `true`, except the four browser members that ship off: `javascript_exec`, `file_upload`, `read_console`, `read_network`) and `defer_loading`, which must be identical across all enabled members. `allowed_callers` is `["direct"]` for the computer toolset — it cannot be driven from inside code execution.

## 3. Batched actions and the fail-stop contract

A turn may now contain several member `tool_use` blocks. They run **sequentially in array order**, not concurrently. This is the round-trip saving: click, type, click, screenshot used to be four model calls.

The failure contract is the part to design around:

- Execution **stops at the first failing action**.
- Every skipped block still gets a `tool_result`, marked `is_error: true`, with an exact halt string — `Not executed: an earlier action in this turn failed.` for browser, `Not executed: an earlier computer action in this turn failed.` for computer.
- Omitting a `tool_result` for any emitted `tool_use` rejects the request.
- Opt out entirely with `tool_choice.disable_parallel_tool_use: true`.

> Why it matters: batching converts a sequence of independently-retryable steps into a partially-applied transaction. If actions 1–2 committed side effects and action 3 failed, the model resumes from a world state it did not observe. The idempotency and postcondition discipline in [Tool-Call Reliability](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md) is not optional once turns batch — a screenshot after the halt is the cheapest reconciliation you have.

## 4. Two ways to point at a thing

The browser toolset accepts either target shape; the computer toolset accepts only the first.

```json
{"type": "coordinate", "x": 412, "y": 288}
{"type": "ref", "ref": "ref_2"}
```

Refs come from `read_page` (accessibility tree as text, each element tagged `[ref_N]`, `depth` default 15, output capped at 50,000 characters) or `find` (natural-language query, up to 20 matches, same tagged format). They are executor-assigned, scoped to the tab that produced them, and valid until navigation or material DOM change — **the API cannot detect staleness**, so a ref that silently now points at nothing is a live failure mode.

| Targeting mode | What the model consumes | Fails when |
|---|---|---|
| Pixel coordinate (computer toolset) | Screenshot images only — no tree at any depth | Layout shifts, scroll position drifts, resolution changes |
| Ref into accessibility tree (browser toolset) | `read_page`/`find` text, ~tagged elements | DOM mutates after the read; refs go stale invisibly |
| CDP selector (Playwright/Puppeteer MCP) | Caller-authored selectors | Selector brittleness — but the caller, not the model, owns it |
| Agent-native runtime (Kitesurf) | Structured DOM straight from the engine | Engine capability gaps (WebGL, video, long auth sessions) |

The browser toolset declares **no display dimensions** — Claude infers viewport size from the screenshots you return, so returning inconsistently sized images is a self-inflicted accuracy loss. The computer toolset likewise rejects `display_width_px` / `display_height_px` and does not downscale: an oversized image is a request error, not a resize.

## 5. `browser_state` — the out-of-band channel

Tab inventory does not travel as text the model wrote. It travels as a dedicated content block the client attaches to a `tool_result`:

```json
{
  "type": "browser_state",
  "tabs": [{"tab_id": "t1", "title": "Portal", "url": "https://…", "active": true}],
  "state_changes": [{"type": "download_completed", "download_id": "d1", "url": "https://…"}]
}
```

The model never sees this JSON. The API renders it into a `Tab Context:` text footer. `tabs` is the full inventory after the call, not a delta; exactly one entry is `active`. Limits: ≤ 100 tabs, ≤ 200 state changes, 4,096 chars per field. It is forbidden on `is_error: true` results, at most one per `tool_result`, and tab-management results (`new_tab`, `switch_tab`, `close_tab`, `list_tabs`) must contain **exactly one `browser_state` block and nothing else**. Download entries are validated but deliberately not rendered.

> Lesson: this is a clean pattern worth stealing — a typed side-channel for ambient environment state, normalized by the platform into one canonical rendering, instead of every client inventing its own "here are your tabs" prose. It also means the model's view of tab state cannot drift from the executor's, which is the usual source of "the agent kept acting on the wrong window."

## 6. The token bill

Toolsets are not free context. Approximate input-token overhead for the tool definitions alone:

| Toolset | Default members | With all optional members |
|---|---|---|
| `browser_toolset_20260801` | ~6,600 | ~7,480 |
| `computer_toolset_20260801` | ~4,500 | — (disabling `zoom` saves ~410) |

Roughly 11,000 tokens of standing overhead if you enable both, before a single screenshot. Screenshots then price at ⌈w/28⌉ × ⌈h/28⌉ visual tokens, capped at 4,784 on Opus 4.7 and later (2,576 px long edge); past 20 images in one request a stricter per-side limit kicks in. Both toolsets are ZDR-eligible; `defer_loading` exists precisely so you don't pay the definition cost on turns that will never touch a browser.

## 7. Skills and Files as platform objects

The same release turned two things the harness used to own into API resources.

**Skills API.** `POST /v1/skills` (multipart, or a zip), `POST /v1/skills/{skill_id}/versions`, `GET`/`DELETE` on both. Attachment is via `container`, not `tools`:

```json
{
  "container": {
    "skills": [
      {"type": "anthropic", "skill_id": "pptx", "version": "latest"},
      {"type": "custom", "skill_id": "skill_01AbCd…", "version": "skver_01AbCd…"}
    ]
  },
  "tools": [{"type": "code_execution_20250825", "name": "code_execution"}]
}
```

The code execution tool is **required** — skills materialize at `/skills/{skill-name}/` inside the sandbox, keyed on the SKILL.md `name`, not the `skill_01…` ID. Constraints that shape design: no network access, no runtime package installs, ≤ 20 skills per request, ≤ 30 MB uncompressed per upload, a new version is a **full snapshot rather than a delta** (omitted files are dropped), and skills are workspace-scoped so any key in the workspace can invoke or delete them. Changing the skills list — including its order — invalidates the prompt cache. Pinning `"latest"` in production means a colleague's upload changes behavior mid-flight; pin `skver_` IDs instead. See [11.4. Skills](../11.%20Harness%20Engineering/11.4.%20Skills.md) for the format itself.

**Files API.** `POST /v1/files`, then reference by `file_id` in a `document`, `image`, or `container_upload` block. Uploaded files are `downloadable: false` — only files a skill or the code execution tool *creates* can be downloaded. `expires_in_seconds` is set once at upload (3,600 to 7,776,000 seconds) and is immutable; after expiry a referencing Messages request fails **before inference**, which is the good failure. All Files operations are free; the bytes are billed as input tokens when they enter a request.

> Architectural takeaway — skills and files stop being harness-local filesystem concerns and become versioned, workspace-scoped platform objects. That is the same migration MCP servers made from stdio subprocess to addressable endpoint, and it carries the same governance question: workspace-wide read/invoke/delete means the skill registry now needs the access-control thinking you'd give a shared code repo.

## 8. The composed pattern, and where it fits

The announcement's worked example is a claims-filing agent: read the intake document from the Files API → follow a Skill encoding the team's filing procedure → complete the submission in an insurer's web portal with the browser toolset → save the confirmation back as a file. Each primitive owns exactly one concern — input state, procedural knowledge, UI action, output state — and none of them call each other. The agent loop is the only sequencer. That is the same argument [Code Execution as the Tool-Calling Substrate](./Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md) makes generally: keep primitives narrow, let the model do the composing, don't build a bespoke pipeline per workflow.

Asteroid, cited in the announcement, reported on claims-processing workflows: 32 minutes → 13 minutes per task, ~30% cost reduction, 100% completion, with no prompt changes. Read it as one vendor's result on one workflow class — structured, portal-driven, document-in/document-out. It does not transfer to open-ended browsing or tasks without a clean document boundary.

| Signal | This composition fits | Prefer something else |
|---|---|---|
| Clear document-in / document-out shape | Yes | — |
| The "how" is a stable, describable SOP | Skills API | Ad hoc prompting if the procedure changes every run |
| Target UI has no API but is a normal rendered web app | Browser toolset, ref targeting | An agent-native runtime if the bottleneck is fleet cost, not accuracy |
| Regulated data (PHI) in the loop | Computer use is now BAA-eligible for HIPAA workloads | — |
| High-volume, cost-sensitive browsing at fleet scale | — | [Agent-Native Browser Runtimes](./Agent-Native%20Browser%20Runtimes%20—%20Rebuilding%20the%20Browser%20for%20Machines%2C%20Not%20Humans.md) |

> Why it matters: before this, "read a document, follow an SOP, act on a web UI, persist the result" meant stitching a document store, a prompt-engineered procedure, and a bespoke browser harness — three build-and-maintain surfaces. The integration cost moves from per-workflow to per-platform. The tradeoff is that it also moves the governance surface there: workspace-scoped, mutable, shared.

## 9. What changes for a harness author

1. **Stop modeling the loop as one action per turn.** Batch the deterministic runs (navigate → find → form_input → screenshot) and keep the model call for the branch points.
2. **Return a screenshot after any halted batch.** It is the reconciliation primitive; the model cannot infer where the sequence stopped.
3. **Prefer refs to coordinates where the browser toolset is available**, and re-read after any navigation rather than reusing a ref across it.
4. **Budget the standing token cost.** ~11k tokens of definitions is a meaningful fraction of the context you were going to spend on the actual task; `defer_loading` and per-member `enabled` are the levers.
5. **Pin skill versions.** `"latest"` is a shared mutable pointer with organization-wide write access.

---

## References

- [Anthropic — Build Production Agents with Computer Use, the Skills API, and the Files API](https://claude.com/blog/computer-use-skills-api-files-api)
- [Claude Platform Docs — Browser Use Tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/browser-use-tool)
- [Claude Platform Docs — Computer Use Tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)
- [Claude Platform Docs — Agent Skills Overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Claude Platform Docs — Skills Guide](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
- [Claude Platform Docs — Files API](https://platform.claude.com/docs/en/build-with-claude/files)
