# Realtime Voice Agents — Reasoning Inside the Speech-to-Speech Loop

> **Source:** OpenAI's `gpt-realtime-2.1` / `gpt-realtime-2.1-mini` release
> (2026-07-06) is the triggering event; the pattern is vendor-neutral.
> **Updated 2026-09-10** — §7 covers GPT-Live-1, which partly reverses the thesis
> below: the voice layer stops reasoning and starts *delegating*, and full duplex
> retires the spoken-preamble pattern as a requirement. Read §1–§6 as the
> half-duplex design that GPT-Live-1 is a reaction to. For the
> latency-hiding trick this note's "spoken preamble" resembles, see
> [Speculative Execution in the Agent Loop](./Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md);
> for the reasoning-vs-latency tradeoff on the text side see
> [Small Language Models for Agents](./Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md).

---

## 1. The assumption that just broke

Voice agents have lived under one hard constraint: a human expects the machine to
start talking back in roughly **300–800 ms**, or the turn feels broken. That
budget ruled out deep reasoning. So the field split into two camps — fast but
shallow speech-to-speech models, or a chained **STT → LLM → TTS** pipeline where
you could bolt a reasoning model in the middle but paid for it in latency and
lost prosody at every hop.

The July 2026 realtime models collapse that split: reasoning becomes a **dial
inside the realtime loop**, not a separate stage. You keep one unified
speech-to-speech pipeline *and* get configurable reasoning effort per turn. That
changes what a voice agent can be asked to do — multi-step tool use, disambiguation,
policy-checked answers — without dropping to a slower architecture.

> **Why it matters:** "voice" stops being a capability tier below "text agent."
> The same reasoning/tool-use/instruction-following you design for a text harness
> now runs in the audio loop, gated by a latency budget you set per turn.

## 2. Chained pipeline vs unified speech-to-speech

| Axis | Chained STT → LLM → TTS | Unified speech-to-speech |
|---|---|---|
| Hops per turn | 3 models, 3 network legs | 1 model, 1 leg |
| Prosody / tone | Lost at STT, re-synthesized by TTS | Preserved end-to-end |
| Interruables (barge-in) | Hard — each stage buffers | Native — model hears you mid-answer |
| Reasoning | Any text model, but adds a full LLM round-trip | In-loop, effort-configurable |
| Failure surface | 3 independent services to trace | 1 session, 1 trace |
| When it still wins | You need a specific text model / on-prem LLM | Default for latency-sensitive agents |

The unified path is now the default for latency-sensitive work. The chained path
survives only when you must route to a specific text model the realtime endpoint
does not offer, or when transcripts are a first-class product artifact.

## 3. The reasoning-effort dial

`gpt-realtime-2.1` exposes five reasoning-effort levels; **`low` is the default**
specifically to protect the latency budget on ordinary turns.

| Effort | Use it for | Cost |
|---|---|---|
| `minimal` / `low` | Greetings, confirmations, single-slot lookups | Cheapest, fastest — the common case |
| `medium` | Two-step tool use, mild disambiguation | Noticeable added latency + output tokens |
| `high` / `xhigh` | Multi-step planning, policy reasoning, math | Latency spikes; reserve for turns that earn it |

The engineering discipline is **per-turn effort budgeting**: classify the turn
(or let the model self-select) and spend reasoning only where the user will
tolerate the pause. Higher effort raises both wall-clock latency and output-token
cost, so treating effort as a global constant wastes money on "yes" and starves
the hard turns.

The `-mini` variant ships as a **distilled reasoning model** at the same price as
the prior non-reasoning mini — reasoning at the low tier, which is the bigger
practical story than the flagship: the cheap model can now think a little.

## 4. The silence problem — and the spoken-preamble pattern

The sharpest production insight in this release is behavioral, not architectural.
When a voice model reasons or calls a tool, it **goes silent**. Users read silence
as "it's broken" and interrupt (barge-in), which cancels the in-flight work. Text
agents never had this problem — a spinner is fine; dead air on a phone call is not.

The fix is a **spoken preamble**: before executing a function, the model emits a
short filler utterance —

```text
User:  "What's the status of order 4471?"
Agent: "Let me check that order for you now."   ← spoken preamble (audio starts immediately)
        └─ [tool call: get_order_status(4471)]   ← runs during the preamble
Agent: "It shipped yesterday and arrives Thursday."
```

The preamble buys cover for the tool round-trip and the reasoning pause, keeping
the channel alive so the user does not talk over the agent. This is the audio-loop
cousin of speculative execution: **do the slow thing behind a cheap thing the user
perceives as progress.** Design your tool-calling turns to always front a preamble;
treat a silent tool call as a bug.

## 5. Transport and session shape

Realtime voice runs over three transports, chosen by where the client lives:

| Transport | Client | Notes |
|---|---|---|
| WebRTC | Browsers | Direct browser ↔ API audio; lowest jitter |
| WebSocket | Server-side pipelines | You proxy audio through your backend |
| SIP | Telephony / PSTN | Phone-tree and call-center integration |

Credential handling is the one security gate that is easy to get wrong: the API
key stays server-side, and the server **mints a short-lived ephemeral client
secret** that the browser uses to open its direct connection. Never ship the
long-lived key to the client. The 2.1 models also improved interruption behavior,
alphanumeric recognition (order IDs, confirmation codes), and silence/noise
handling — the unglamorous parts that decide whether a phone agent survives a real
call.

## 6. What moved on the numbers

- **p95 latency down ≥25%** across the realtime voice models, credited to improved
  caching (which also lowers cost, not just delay). p95 is the number that matters
  for voice — the tail is what users feel as "laggy."
- Reasoning effort trades directly against that budget: `low` preserves it, `high`
  spends it.

Indicative pricing (per 1M tokens) — the shape matters more than the exact figures:

| | `-mini` | full `2.1` |
|---|---|---|
| Audio input (fresh / cached) | $10.00 / $0.30 | $10.00 / $0.30 |
| Audio output | $20.00 | $64.00 |
| Text input | $0.60 | $4.00 |

Cached audio input at ~3% of fresh makes **prompt/audio caching the primary cost
lever** for high-volume voice — the same lesson text agents already learned, now
load-bearing for phone traffic.

## 7. The full-duplex correction — GPT-Live-1 (2026-09-10)

Two months later OpenAI shipped `gpt-live-1` in the API, and it moves the
boundary back. §1–§6 described a model that reasons *inside* the audio loop.
GPT-Live-1 does the opposite: it is a **front-end voice layer** priced
separately at **$0.05/minute**, and it *"can delegate reasoning and tool calls
to a backend text model."* The architecture is no longer one model — it is two,
split along a seam the previous release had deliberately erased.

The justification for re-splitting is the one thing a unified model still could
not do: **full duplex**. GPT-Live-1 listens and speaks *simultaneously*,
reasoning over incoming and outgoing audio together rather than alternating. It
is explicitly *"not a turn-based model"* while still supporting turn detection
for applications that want explicit boundaries. Reported gains: **+30 percentage
points on Full Duplex Bench** over `gpt-realtime-2.1`, and #1 on Tau3 when paired
with a GPT-6 Astra backend at medium effort.

### 7.1 What full duplex retires

| §4's problem | The half-duplex fix (§4) | Under full duplex |
|---|---|---|
| Model goes silent during tool calls | Spoken preamble before every call | Conversation continues *while work happens in the background* — the channel never goes dead |
| User interrupts and cancels in-flight work | Design turns to front a preamble | Model hears and reasons over the interruption without losing the pending work |
| Thinking pauses read as "it's broken" | Filler utterance | Reported ~80% fewer interruptions during thinking pauses vs turn-based systems (Speak, early evaluation) |

The spoken preamble drops from **required harness pattern** to **stylistic
choice**. That is a rare thing to see: a production pattern invalidated by a
capability change two months after it was worth writing down.

### 7.2 The delegation seam

The backend is a parameter, not a given. The pattern OpenAI describes is
**routing by turn difficulty** — a cheap model for scheduling and order status,
a reasoning model for the hard cases — which is
[Model Routing in the Agent Loop](./Model%20Routing%20in%20the%20Agent%20Loop%20—%20Per-Step%20Model%20Selection.md)
applied to the voice front-end, with the twist that the router is now the thing
holding the microphone. The delegation is asynchronous and explicitly addressed:

```json
{ "type": "session.commentary.append",
  "delegation_id": "<id of the in-flight delegation>",
  "content": "<what the backend came back with>" }
```

A `delegation_id` is the tell. The voice layer tracks multiple outstanding
delegations while still talking — which makes this the audio-loop analogue of
the async tool calls in
[Breaking the Lockstep Turn](./Breaking%20the%20Lockstep%20Turn%20—%20Async%20Tool%20Calls,%20Mid-Turn%20Steering,%20and%20Configuration%20Updates.md),
with the same unanswered questions about what happens to a delegation that never
returns.

> **Architectural takeaway:** the July release collapsed the voice/reasoning
> split to buy latency. The September release re-opens it to buy **duplex**, and
> pays for the seam with an explicit delegation protocol rather than a chained
> pipeline. Read the two together and the real axis is not unified-vs-chained —
> it is *what the fast layer is allowed to do while the slow layer thinks.*

### 7.3 What to re-check in your own build

- **Your latency architecture may be obsolete.** If the design is organized around covering dead air, the covering is now the model's job.
- **Cost model changes shape.** A per-minute voice layer plus backend tokens is not comparable to the per-token table in §6. Price the two legs separately.
- **The eval target moves.** Full Duplex Bench and interruption/backchannel behavior measure things turn-based evals cannot see. A voice suite built on turn-level pass rates will score a full-duplex agent blind.
- **Transcripts stop being a reason to chain.** GPT-Live-1 natively emits ASR transcripts and response text, removing §2's "transcript-as-product" exception.
- **Vendor-lock check.** The delegation seam is the interesting primitive and it is one vendor's proprietary protocol. Nothing standard sits underneath it yet.

## 8. Architectural takeaway

- Reasoning is a **dial you place**, not a fixed layer: in-loop effort (§3) and
  delegation to a backend model (§7) are the two positions, and full duplex is
  what makes the second one pay.
- **Never let a tool call be silent** — a spoken preamble was a required harness
  pattern on half-duplex models. On a full-duplex model the channel stays alive
  by construction; keep the preamble only where it reads as courtesy.
- Prefer **unified speech-to-speech** over chained STT→LLM→TTS unless you have a
  hard reason (specific text model, on-prem constraint). "Delegating to a backend"
  is not the chained pipeline coming back: the audio never leaves the voice model.
- **Caching is the cost story** on per-token voice models; on a per-minute voice
  layer, the lever moves to *how long the call lasts* and *which backend answers
  which turn*.
- Voice is no longer a downgraded agent tier — the reasoning, tool-use, and
  eval discipline from your text harness ports directly; only the latency budget,
  the silence problem, and now duplex behavior are new.

## References

- [OpenAI — New Realtime models on the API: gpt-realtime-2.1 and gpt-realtime-2.1-mini](https://community.openai.com/t/new-realtime-models-on-the-api-gpt-realtime-2-1-and-gpt-realtime-2-1-mini/1385896)
- [OpenAI — Realtime and Audio Guide](https://developers.openai.com/api/docs/guides/realtime)
- [MarkTechPost — OpenAI Releases GPT-Realtime-2.1 and GPT-Realtime-2.1-mini for Low-Latency Voice Agents](https://www.marktechpost.com/2026/07/06/openai-gpt-realtime-2-1-mini-reasoning-realtime-api/)
- [OpenAI — Build More Natural Voice Experiences with GPT-Live-1 in the API](https://openai.com/index/introducing-gpt-live-1-in-the-api/)
- [OpenAI — Getting Started with GPT-Live](https://developers.openai.com/api/docs/guides/live)
