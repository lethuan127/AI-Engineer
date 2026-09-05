# Breaking the Lockstep Turn — Async Tool Calls, Mid-Turn Steering, and Configuration Updates

> **New 2026-09-03.** OpenAI shipped GPT-6 Astra and, in the same changelog entry,
> three Responses API controls that only make sense together: **async tool calling**
> (`async: true`), **mid-turn steering** (`response.steer` over WebSocket), and
> **configuration updates** (change reasoning effort between responses without
> touching the cached prefix). Read separately they look like three latency
> features. Read together they retire the assumption every agent harness has been
> built on since function calling shipped: that a turn is atomic — one request, one
> uninterrupted stretch of model work, one response, and nothing enters or leaves
> in between. Companion to
> [Background Agents](Background%20Agents%20—%20Asynchronous%20Execution,%20Lifecycle%20Events,%20and%20Handoff.md),
> which made the work *around* the loop asynchronous; this note is about the loop's
> interior. Also companion to
> [Speculative Execution in the Agent Loop](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md)
> and [Tool-Call Reliability](Tool-Call%20Reliability%20—%20Idempotency,%20Postcondition%20Verification,%20and%20Replay-Safe%20Authorization.md).

---

## 1. What the lockstep turn assumed

The standard tool-calling loop is a coroutine with exactly one suspension point:

```text
harness → model            (request: history + tools)
model   → harness          (tool_call)          ← model suspends here, and only here
harness → tool → harness   (execute)
harness → model            (tool_result)        ← model resumes
...repeat until the model emits a final message
```

Four properties fall out of that shape, and essentially every harness depends on
all four:

| Property | What it lets the harness assume |
|---|---|
| One outstanding tool call per suspension | A single `pending_call` variable is sufficient state |
| The model is idle while a tool runs | Tool latency and model latency never overlap; the critical path is their sum |
| Input arrives only between turns | The user cannot race the model; history is append-only at turn boundaries |
| Settings are fixed per request | Reasoning effort, tools, and instructions are properties of a request, not of a conversation |

The 2026-09-03 release breaks the first three outright and puts a crack in the
fourth. None of the breaks is opt-out-by-default in a meaningful sense: they are
opt-in per feature, but a harness that wants the latency wins has to give up the
invariants that made it simple.

> **Why it matters:** the parts of a harness that are cheap to write — the pending
> call slot, the turn-boundary queue, the "wait for tool, then resume" driver — are
> exactly the parts these features invalidate. The model didn't get harder to
> prompt. The *scheduler* got harder to write.

---

## 2. Async tool calls — the model stops blocking on its own tool

Mark a function or custom tool `async: true` and the model may continue generating
after emitting the call, before your application returns the output. The docs are
blunt about the division of labour: *"Your application still executes the tool.
Async tools don't move execution to OpenAI or manage your background jobs."*

```json
{
  "type": "function",
  "name": "lookup_price",
  "async": true,
  "strict": true,
  "parameters": {
    "type": "object",
    "properties": { "sku": { "type": "string" } },
    "required": ["sku"],
    "additionalProperties": false
  }
}
```

The result comes back later, on a subsequent request, matched by the original
`call_id` (`function_call` → `function_call_output`, `custom_tool_call` →
`custom_tool_call_output`), with `previous_response_id` pointing at the *latest*
response in the chain rather than the one that issued the call. So a single
response can contain both an outstanding async call and a finished answer to the
independent part of the request.

This is distinct from Background mode, which makes *response generation*
asynchronous. Here the response is synchronous; the **tool** is not.

Constraints stated: GPT-6 Astra and later; function and custom tools only, not
hosted built-ins; not to be combined with programmatic tool calling; and in
multi-agent mode, not to be combined with parallel tool calls.

> **Architectural takeaway:** the pending-call slot becomes a registry keyed by
> `call_id`, with a lifetime longer than the response that created it. That
> registry is now conversation-scoped mutable state your harness owns — which is
> the same category of thing [durable execution](../7.%20AI%20System%20Architecture/7.3.%20Durable%20Execution%20for%20Agents%20—%20Surviving%20Crashes%20Mid-Loop.md)
> exists to protect. A crash between dispatch and delivery orphans a job the model
> is still expecting.

### 2.1 The wait tool — and the fact that it isn't one

When the model's next step genuinely depends on a pending result, it needs a way
to block on purpose. OpenAI's answer is notable for what it *isn't*: there is no
built-in wait primitive. The guide says plainly that `wait_for_tasks`
*"isn't a built-in Responses tool"* — you define it yourself as an ordinary
synchronous function, and you give each async tool an extra `task_handle`
argument that the model chooses and your harness binds to the real `call_id`.

The delivery ordering is a hard requirement, not a suggestion: resolve the
requested handles, return each newly-completed result **on its original
`call_id`**, and only then return status on the wait call's own `call_id`.
The wait tool returns status; it never carries the payload.

| Concern | Who owns it |
|---|---|
| Choosing a handle, and when to wait | Model |
| Handle → `call_id` → job binding | Your harness |
| Handle uniqueness across the whole conversation, including completed tasks | Your harness (enforced in the tool description, honoured by the model) |
| Result delivery order | Your harness |

> **Lesson:** the protocol gave the model a scheduling *verb* and left the
> scheduler in userland. Handle collision with a completed task is a correctness
> bug the API cannot detect for you, and the only stated defence is a sentence in
> a tool description. That is a prompt-enforced invariant guarding application
> state — the pattern
> [Tool-Call Reliability](Tool-Call%20Reliability%20—%20Idempotency,%20Postcondition%20Verification,%20and%20Replay-Safe%20Authorization.md)
> argues you should never rely on. Key the registry so reuse is rejected, rather
> than trusting the handle to be fresh.

### 2.2 What the guide does not define

No cancellation or abort for a dispatched async call. No timeout, TTL, or expiry
for a pending call or handle. No cap on concurrent async calls. No statement on
how carried reasoning state crosses the async gap beyond `previous_response_id`
chaining. Error delivery is by convention only — the sample catches the exception
and returns it as the tool output.

A pending async call is therefore a resource with no defined end of life. If your
job never finishes, nothing in the protocol notices.

---

## 3. Mid-turn steering — input arrives inside the turn

Steering runs over a WebSocket to `wss://api.openai.com/v1/responses`. After
`response.created` for the response you want to redirect, send:

```json
{
  "type": "response.steer",
  "previous_response_id": "resp_1",
  "input": "Keep the scope small enough for one developer to finish in two weeks."
}
```

The event accepts only those three fields. The server replies
`response.steer.accepted` with a `steer.id`, and *acceptance means the input is
queued, not that the model has acted on it*. The API then creates a continuation
response automatically — but only after finishing the current output item and any
hosted tool work already running. The interrupted original ends with
`response.incomplete` and `incomplete_details.reason: "steered"`; if it happened
to finish first it keeps `completed` and still gets a continuation. Do not send
another `response.create` while waiting for that continuation.

The non-guarantees are stated up front and are the important part: steering
*"does not rewrite output already sent to your application, undo earlier actions,
or cancel tools that have already started."*

When the response needs a client tool result or an approval, the steer stays
queued and the API emits `response.steer.pending` with `reason:
"waiting_for_required_input"` and a `required_input[]` array naming the
outstanding `function_call_output`s. You return them with an ordinary
`response.create` on the same connection — and the server **implicitly prepends
the accepted steer** to that request's input. You never re-send the steer text.

| Failure code | Meaning |
|---|---|
| `invalid_input` | Unsupported event fields or non-user-message input |
| `steering_not_supported` | Model or request parameters incompatible |
| `response_not_found` | Target response not available on this connection |
| `too_many_pending_steers` | Too much steering queued; drain it before adding more |

Queued steering lives on the connection only. It is not stored with the response,
so a disconnect may have silently dropped it: *"Do not assume pending steering
survived the disconnect."* That makes the client responsible for recording what it
sent and reconciling against history before any replay — a de-duplication problem
in a channel that offers no idempotency key.

Availability is narrow: `gpt-6-astra` only, WebSocket only. GPT-5.6 and earlier
do not support it. No HTTP/SSE path, no first-party SDK helper — all four sample
languages drive a raw socket and hand-roll the JSON.

> **Why it matters:** the "interrupt the agent when it goes off track" behaviour
> that experienced Claude Code users already exhibit — supervise on drift instead
> of gating each step — now has a protocol-level primitive on the API rail rather
> than only inside a vendor CLI. The cost is that your client becomes a state
> machine over an unordered-ish event stream, and "did my correction land?" becomes
> a question with three answers (`accepted`, `pending`, `failed`) plus a fourth
> unnamed one: the socket dropped and nobody knows.

---

## 4. Configuration updates — changing effort without paying for it

The third control is smaller and the most immediately practical. Insert a
`configuration_update` item into `input`, before the next user message:

```json
{
  "type": "configuration_update",
  "reasoning": { "effort": "high" }
}
```

It selects the effort for the next response and every subsequent one until
overridden, while the request-level `reasoning.effort` stays untouched — which,
per the guide, *"preserves the original prompt prefix for prompt caching."* That
is the entire point. Effort had previously been a request parameter, and a
conversation that dialled it up or down at the request level moved the prefix.

The constraints are unusually specific, and each one is a footgun:

- `gpt-6-astra` only, in standard single-agent mode. Changes reasoning effort and nothing else.
- Two adjacent `configuration_update` items are rejected.
- Cannot be combined with automatic compaction or automatic truncation; `/responses/compact` rejects histories containing them. After an explicit `compaction_trigger`, add a fresh update.
- The response's `reasoning.effort` **keeps reporting the request-level value**, not the effort actually selected. There is no field that reports the effective effort.

That last one deserves a callout. You now have a conversation-scoped setting with
no read-back path, whose only source of truth is your own replay of the history.

> **Architectural takeaway:** this is the cache economics from
> [prompt caching](../3.%20Prompt%20&%20Context%20Engineering/prompt-caching.md)
> asserting itself over API ergonomics. On GPT-6 Astra, cached input is $1.00
> against $10.00 uncached and cache *writes* are $12.50 — so a needless prefix
> change costs 12.5× a hit, twice over. The vendor would rather add an in-band
> conversation item with four rejection rules than let you invalidate a prefix by
> changing a parameter. Expect more settings to migrate from request parameters to
> history items for exactly this reason.

---

## 5. Supervision goes async because the loop did

The same release wires **misalignment monitoring** into Responses. It reviews
model reasoning and actions *asynchronously* in consequential contexts —
transferring or accessing sensitive data, destructive changes — and can stop a
conversation. Blocked requests return HTTP `403`, type `invalid_request_error`,
code `misalignment_policy_violation`; the guide says to match the code, not the
message, and to handle the error mid-stream as well as before streaming begins.

Coverage is not uniform, and the axis it varies on is *whether the platform can
tell that two requests are the same conversation*:

| Request shape | Monitored | Auto-stop |
|---|---|---|
| Responses with persisted reasoning, WebSockets, or OpenAI compaction | Yes | Yes |
| Responses with none of those | Yes | No — webhook alerts only |
| Chat Completions | No | No |

Project-level alerts arrive as a `safety.alert.created` webhook carrying only an
alert ID; you fetch the body from `GET /v1/safety/alerts/{id}` with the
`api.safety.alerts.read` scope, and get `request_id`, `response_id`,
`request_paused`, and a nullable `reason` (always null under ZDR). The guide is
careful about what a stop is worth: `request_paused: true` means a block was
*registered*, *"does not confirm that execution stopped or that earlier actions
were reversed,"* there is no documented way to resume, and *"a stopped request
does not undo earlier actions."*

> **Lesson:** an asynchronous monitor over an asynchronous loop can only ever
> arrive late. That is a containment argument, not a monitoring one — the same
> conclusion [8.1](../8.%20AI%20Safety%20&%20Ethics/8.1.%20Agent%20Containment%20&%20Control%20—%20Capping%20the%20Blast%20Radius.md)
> reaches from the other direction. Treat a `403` as an incident signal for a
> workflow you must reconcile by hand, not as a guardrail that held. And note the
> quiet coupling: the features that make you eligible for auto-stop — persisted
> reasoning, WebSockets, compaction — are the same ones this note is about. Opting
> into the async turn opts you into being supervisable.

---

## 6. What a harness has to change

| Harness component | Lockstep assumption | What the async turn requires |
|---|---|---|
| Pending-call state | One slot | `call_id`-keyed registry, conversation-lifetime, survives process restart |
| Handle namespace | n/a | Collision-rejecting store covering completed tasks |
| Result delivery | Return and resume | Ordered: results on original `call_id`s first, wait status last |
| Transport | HTTP request/response | WebSocket with reconnect and steer reconciliation |
| User input queue | Drains at turn boundary | Can be injected mid-response; may be silently dropped on disconnect |
| Effort control | Request parameter | History item, sticky, with no read-back |
| Cancellation | Abandon the request | **No primitive exists** for async calls or accepted steers |
| Safety response | Pre-flight check | Post-hoc `403` on a workflow that has already acted |

Two of those rows have no vendor-side answer at all. Cancellation is absent from
both the async-tool and steering surfaces, and there is no expiry on a pending
call — so lifecycle management for in-flight work is entirely yours, and it is the
part most likely to be skipped by a harness that adopted `async: true` for the
latency win.

> **Architectural takeaway:** adopt these in the order the risk runs.
> `configuration_update` is nearly free and pays immediately on a cache-heavy
> agent. Mid-turn steering is worth it when a human watches the agent work and
> corrections are common. Async tool calls are worth it only when you have a real
> parallelism story *and* a place to keep durable per-call state — otherwise you
> have traded a clean sum-of-latencies for an orphaned-job problem you will find in
> production.

---

## 7. Where this leaves the vendor split

GPT-6 Astra is $10/$50 per MTok with a 1,050,000-token context, 128k max output,
an April 30 2026 cutoff, and `reasoning.effort` of `low` through `max` — `none` is
rejected with a 400. Requests over 272K input tokens are billed at 2× input and
cache rates and 1.5× output *for the whole request*. Tool calling with this model
requires the Responses API; Chat Completions does not support it.

Anthropic has been moving the same direction from a different corner: Opus 5's
mid-conversation tool changes (see
[11.7](../11.%20Harness%20Engineering/11.7.%20Tools%20and%20MCP.md)) mutate the
toolset across turns while holding the cache, and the managed-agents surface put
lifecycle events and steering around detached runs. The shared premise is that a
long agent conversation is a *session with mutable configuration*, not a sequence
of independent requests — and that the prompt cache is the constraint deciding
what mutation is allowed to look like.

There is a sharper way to read all three controls, and it reframes the vendor
comparison. A self-implemented harness has always had "mid-turn steering" — if you
own the driver loop, injecting between steps is just building the next request
differently, and it always succeeds. What OpenAI shipped is not a new capability;
it is **compensation for having moved the loop server-side**. Hosted tools mean
the trajectory runs inside one response, out of reach, and `response.steer` is the
back door into a process you no longer control. That explains every awkward
constraint at once: WebSocket-only (you need a channel into someone else's
process), `accepted` ≠ applied (you are asking, not doing), no cancellation (you
don't own the process), item-boundary granularity (you can't see where the loop
is), and connection-scoped state (you aren't the source of truth).

The granularity turns out to be roughly equivalent either way — an `output item`
boundary is about as fine as "between two model calls" in a client loop — so the
two converge on capability and diverge on *reliability*. Owning the loop is
strictly better. Steering is what you buy back when hosted tools are worth more
than that. See [7.6. The Responses API as a Hosted Agent Loop](../7.%20AI%20System%20Architecture/7.6.%20The%20Responses%20API%20as%20a%20Hosted%20Agent%20Loop.md)
for the full surface, and [7.1](../7.%20AI%20System%20Architecture/7.1.%20Claude%20Platform%20Managed%20Agent.md) /
[7.2](../7.%20AI%20System%20Architecture/7.2.%20Self-Implemented%20Agent%20Harness%20—%20Components.md)
for the axis it sits on.

The thing to watch is whether cancellation shows up. Every other primitive here
started a piece of work; none of them can stop one. A protocol that can dispatch
but not revoke is not finished.

---

## References

- [OpenAI — Async Tool Calling Guide](https://developers.openai.com/api/docs/guides/async-tool-calling)
- [OpenAI — Mid-Turn Steering Guide](https://developers.openai.com/api/docs/guides/steering)
- [OpenAI — Reasoning Models Guide](https://developers.openai.com/api/docs/guides/reasoning)
- [OpenAI — Misalignment Monitoring](https://developers.openai.com/api/docs/guides/safety-checks/misalignment-monitoring)
- [OpenAI — GPT-6 Astra Model Reference](https://developers.openai.com/api/docs/models/gpt-6-astra)
- [OpenAI — API Changelog](https://developers.openai.com/api/docs/changelog)
