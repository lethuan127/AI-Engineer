# Background Agents — Asynchronous Execution, Lifecycle Events, and Handoff

> **New 2026-07-03.** Two independent surfaces converged on the same shape in the
> first days of July 2026. Claude Code `2.1.198` (2026-07-01) made subagents run in
> the background by default, and made a finished background agent **commit, push,
> and open a draft PR** instead of stopping to ask. The Claude developer platform's
> managed-agents / Deployments API landed the same primitives on the server side:
> cron **scheduled deployments**, a two-tier run record, and **lifecycle webhooks**
> so you react to events instead of polling. The interactive loop is no longer the
> default execution model for capable agents — the default is fire-and-forget with
> a callback. This note is about the three primitives that make that safe to
> operate: **lifecycle events**, **structured handoff**, and **mid-flight steering**.
> This note makes the work *around* the loop asynchronous; for the same move applied
> to the loop's interior — a turn that is no longer atomic — see
> [Breaking the Lockstep Turn](Breaking%20the%20Lockstep%20Turn%20—%20Async%20Tool%20Calls,%20Mid-Turn%20Steering,%20and%20Configuration%20Updates.md).
> Companion to [Multi-Agent Orchestration in Production](Multi-Agent%20Orchestration%20in%20Production%20—%20Topologies,%20Token%20Economics,%20and%20Coordination%20Failure.md),
> [Speculative Execution in the Agent Loop](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md),
> and [Durable Execution for Agents](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md).

---

## 1. Why blocking is the wrong default for a long-running agent

The classic agent loop is **synchronous**: the human sends a turn, the agent works,
the agent blocks on a prompt, the human answers. That is fine for a chat and wrong
for anything that runs for minutes or hours. A synchronous loop pins two scarce
resources for the whole duration — a foreground terminal *and* the human's
attention — even though the agent needs the human for only a few seconds of it.

The [speculative-execution note](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md)
attacked latency *inside* one loop. Background agents attack it *around* the loop:
if the work is long, don't make anyone watch it. Detach the run, let the human do
something else, and interrupt them only on the two events that actually need a
person — the agent is **stuck** or the agent is **done**.

> **Why it matters:** the bottleneck in a long agent task is not the model, it is
> the human sitting in the loop. Async execution removes the human from the *wait*
> and returns them only for the *decision*. That is the same move that turned
> synchronous RPC into message queues twenty years ago.

---

## 2. The control plane is lifecycle events, not polling

An async agent you cannot observe is just a process you have lost. The unit of
observability is the **lifecycle event** — the runtime emits a typed signal at
each state transition, and you attach behaviour to it. Two forms shipped, one per
surface:

| Surface | Mechanism | Events you get |
|---|---|---|
| Claude Code (local) | `Notification` hook | `agent_needs_input` (stuck, wants a decision), `agent_completed` (done) |
| Managed agents (API) | Webhooks | agent-version, deployment, and **deployment-run** lifecycle; session events via the event stream |

The Claude Code hook is the important design detail: "notification" is **not** a
terminal bubble. Because the two events plug into the ordinary hook system, the
sink is your code. `agent_completed` can post to Slack; `agent_needs_input` can
fire a desktop alert or page whoever owns the run; either can feed a CI pipeline.
The runtime's job is to *emit the transition*; deciding what a transition means is
yours.

On the API side the same idea is a **webhook**. Each deployment lifecycle change
(paused, unpaused, archived) and each scheduled run outcome is delivered as an
event, "so you can react … without polling." That matters because the failure you
most need to hear about — a run that never produced a session — is invisible to
anyone watching session output.

For streaming UIs there is a third, finer event: **event deltas**
(`event_start` / `event_delta`) preview an agent message's text as it is generated,
before the complete `agent.message` event arrives. Same principle, sub-second
granularity.

> **Architectural takeaway:** design the event sink *before* you detach the agent.
> A background agent with no wired-up `agent_needs_input` sink does not fail loudly
> — it waits forever, silently, and you find out when the deadline passes.

---

## 3. Structured handoff — the draft PR as the unit of output

A synchronous agent hands off by *speaking*: it prints an answer and waits. A
background agent has no one listening at the moment it finishes, so it must hand
off by **producing a reviewable artifact**. In `2.1.198` that artifact is a
**draft pull request**: a background agent that finishes code work in a worktree
now commits, pushes, and opens a draft PR on its own.

The word *draft* is the whole design. The agent does the work and stages the
result; it does **not** merge. The commit is automatic, the merge decision stays
with a human. This is the same blast-radius logic as
[Agent Containment & Control](../8.%20AI%20Safety%20%26%20Ethics/8.1.%20Agent%20Containment%20%26%20Control%20—%20Capping%20the%20Blast%20Radius.md):
let the agent act freely inside a boundary (a branch, a worktree, a draft) whose
worst outcome is a PR you close unread.

A good async handoff artifact has three properties:

1. **Durable** — it outlives the agent process. A PR sits in the repo; a chat
   message scrolls away.
2. **Reviewable** — it is a diff, not a claim. You audit *what changed*, not the
   agent's summary of what changed.
3. **Non-destructive by default** — landing it is a separate, human, reversible
   act. Draft, not merged. Staged, not shipped.

> **Lesson:** the choice of handoff artifact *is* the safety model. A background
> agent that pushed to `main` would be the same feature with the containment
> deleted. "Open a draft PR" is not a UI nicety; it is where the human gate lives.

---

## 4. Two shapes of background agent

The two July surfaces are the same primitive at different lifetimes. Know which
one you are building.

| | Interactive-detached | Scheduled deployment |
|---|---|---|
| Trigger | A human kicks it off, then walks away | Cron `expression` + `timezone`, or a manual `run` |
| Example | `claude agents` background subagent | Managed-agents Deployment (`"0 20 * * 5"`) |
| Lifetime | One task, minutes–hours | Recurring, indefinite |
| "Done" means | Draft PR opened, `agent_completed` fires | A **deployment run** record + a session |
| Failure surface | Hook / terminal | `deployment_run` with `error.type`, plus a webhook |
| Who resumes it | The human who launched it | The next scheduled tick |

The scheduled shape adds a failure mode the interactive shape does not have: the
run can fail **before any agent exists**. The Deployments API models this with a
**two-tier record** — every trigger writes a `deployment_run`, and only a
*successful* run carries a `session_id`. A failed run instead carries an
`error.type` (`environment_archived_error`, `agent_archived_error`,
`session_rate_limited_error`). Some failures also **auto-pause** the deployment so
it stops firing into a broken config until you fix it. Watching session logs will
never show you these; only the run record and its webhook will.

---

## 5. Mid-flight steering and per-session overrides

Detached does not mean fixed. Two escape hatches keep a background agent
steerable:

- **Steer / interrupt.** Send an additional user event mid-execution to redirect,
  or interrupt to stop. Async is not fire-and-*forget*; it is fire-and-*callback*,
  and the channel stays open both ways.
- **Session-level overrides.** When starting a session you can pass an
  `agent_with_overrides` to swap the model, system prompt, tools, MCP servers, or
  skills **for that one session** without editing the reusable agent definition.
  This is how one agent definition fans out into many differently-configured runs
  — the analogue of per-invocation config in a job queue.

---

## 6. Design rules and where it breaks

- **No sink, no async.** Wire `agent_needs_input` / webhooks *first*. A detached
  agent whose stuck-signal goes nowhere is a hung job you will not notice.
- **The handoff artifact is the contract.** If there is no repo/worktree, "open a
  draft PR" has nothing to write to — pick another durable, reviewable artifact
  (a file, an issue, a report) before detaching.
- **Draft is the gate; keep it.** The moment a background agent can merge or push
  to a protected branch, you have removed the only human checkpoint. Enforce it in
  branch protection, not just in the agent's instructions.
- **Watch runs, not just sessions.** For scheduled agents the dangerous failures
  (archived env, rate-limited creation, auto-pause) live in the run record and its
  webhook, never in session output.
- **Mind cron edge cases.** Wall-clock schedules skip a spring-forward hour and
  fire twice on fall-back; missed triggers are not backfilled on unpause. Schedule
  outside the DST window or use UTC when a missed or duplicate run is unacceptable.
- **Idempotency is on you.** A recurring agent that is not idempotent will happily
  do the same side-effecting work every tick.

> **Architectural takeaway:** the shift from interactive to background agents is
> less a model capability than an **operations** change. The model was already
> good enough to run for an hour; what shipped in July 2026 is the plumbing that
> lets it run *unattended* — typed lifecycle events to observe it, a durable draft
> artifact to hand off through, and a run record to catch the failures that never
> reach a session. Build those three before you detach anything.

---

## References

- [Anthropic — Claude Code changelog](https://code.claude.com/docs/en/changelog)
- [Anthropic — Claude Managed Agents overview](https://platform.claude.com/docs/en/managed-agents/overview)
- [Anthropic — Managed Agents: scheduled deployments](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments)
- [Anthropic Engineering — How we contain Claude across products](https://www.anthropic.com/engineering)
