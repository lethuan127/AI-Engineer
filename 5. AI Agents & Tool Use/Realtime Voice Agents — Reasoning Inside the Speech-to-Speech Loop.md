# Realtime Voice Agents — Reasoning Inside the Speech-to-Speech Loop

> **Source:** OpenAI's `gpt-realtime-2.1` / `gpt-realtime-2.1-mini` release
> (2026-07-06) is the triggering event; the pattern is vendor-neutral. For the
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

## 7. Architectural takeaway

- Reasoning is now a **per-turn dial in the audio loop**, not a separate pipeline
  stage. Budget it like a scarce resource: `low` by default, escalate only on turns
  that earn the pause.
- **Never let a tool call be silent.** A spoken preamble is a required harness
  pattern for voice, the same way a streaming token is for text.
- Prefer **unified speech-to-speech** over chained STT→LLM→TTS unless you have a
  hard reason (specific text model, transcript-as-product).
- **Caching is the cost story.** Cached audio input is an order of magnitude
  cheaper; design prompts and session state so the reusable part is cacheable.
- Voice is no longer a downgraded agent tier — the reasoning, tool-use, and
  eval discipline from your text harness ports directly; only the latency budget
  and the silence problem are new.

## References

- [OpenAI — New Realtime models on the API: gpt-realtime-2.1 and gpt-realtime-2.1-mini](https://community.openai.com/t/new-realtime-models-on-the-api-gpt-realtime-2-1-and-gpt-realtime-2-1-mini/1385896)
- [OpenAI — Realtime and Audio Guide](https://developers.openai.com/api/docs/guides/realtime)
- [MarkTechPost — OpenAI Releases GPT-Realtime-2.1 and GPT-Realtime-2.1-mini for Low-Latency Voice Agents](https://www.marktechpost.com/2026/07/06/openai-gpt-realtime-2-1-mini-reasoning-realtime-api/)
