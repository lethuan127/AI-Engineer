# Tool-Call Reliability — Idempotency, Postcondition Verification, and Replay-Safe Authorization

> **Source:** three arXiv papers from August 2026. Two converge on the same
> non-atomic failure class from different angles — [Verified Tool Calls Improve
> LLM Agent Reliability Under Non-Atomic
> Failures](https://arxiv.org/abs/2608.02645) (submitted 2026-07-31) and [Beyond
> Single-Use Tokens: Durable Authorization State for Replay-Resistant LLM Agent
> Actions](https://arxiv.org/abs/2608.01710) (submitted 2026-08-03). A third
> adds the axis the other two hold fixed — the agent's own accumulated errors —
> in [Invocation-Level Reliability of Tool-Using
> Agents](https://arxiv.org/abs/2608.26189) (submitted 2026-08-23); see §5.

Every agent framework's tool-calling loop is built on an assumption: a tool
call is atomic, and it returns one of two things — success or failure. Real
tool calls are not atomic. A payment API can accept a request and then time
out before confirming it. A database write can commit while the response is
lost in transit. An agent that retries on "no response received" cannot tell
whether it is retrying a call that never ran or duplicating one that already
did. Both papers below attack this gap, at two different layers: one makes
the *action* safe to retry, the other makes the *authorization* behind the
action safe to retry. They are complementary, not competing.

---

## 1. The wrong mental model: tool call as atomic RPC

Agent harnesses model a tool call as a function call — dispatch, wait, get a
result, branch on it. Production tool calls exhibit three non-atomic failure
modes that this model has no vocabulary for:

| Failure mode | What actually happens |
|---|---|
| **Timeout after dispatch** | The call was accepted by the downstream system; the agent just never saw the response. |
| **Delayed visibility** | The side effect happened, but a subsequent read (a status check, a balance query) doesn't reflect it yet. |
| **Partial state update** | A multi-step operation committed some but not all of its effects before failing. |

An agent that treats "no response" as "call failed" and retries produces
duplicate actions — a second charge, a second email, a second database row.
An agent that treats "no response" as "call succeeded" and moves on silently
drops work. Both are wrong, and which one an unmodified harness picks is
arbitrary — it depends on which timeout fired first.

> **Why it matters:** this is not a corner case that better prompting fixes.
> It is a property of distributed systems that agent frameworks inherited the
> moment tools started calling real APIs instead of returning mock data.

---

## 2. Layer 1 — verification-aware tool wrapper (making the action retry-safe)

The first paper's fix does not touch the model. It wraps the tool call itself
in three mechanisms:

1. **Postcondition verification** — after a call returns (or times out), check
   the *actual state* the call was supposed to produce, rather than trusting
   the return value. Did the row exist? Did the balance change?
2. **Verify-before-retry** — before re-issuing a call, run the postcondition
   check first. If the effect already happened, skip the retry instead of
   duplicating it.
3. **Idempotency keys** — attach a stable, unique key to the call so that if a
   retry does reach the downstream system, the system itself can recognize
   and no-op the duplicate.

Tested against injected non-atomic failures across multiple task templates,
the wrapper "significantly reduces duplicate actions, while maintaining
comparable task success rates" — the fix is in the tool-calling substrate, not
in a bigger or better-prompted model.

> **Architectural takeaway:** idempotency keys only work if the downstream
> system honors them. Postcondition verification is the fallback for every
> API that doesn't — which in practice is most of them. Build the check, not
> just the key.

---

## 3. Layer 2 — durable authorization state (making the *permission* retry-safe)

The second paper shows that idempotency keys on the action are not sufficient
when the action requires a **user authorization** step first — "transfer
$500," "send this email," "delete this record." The failure mode here is
subtler and, on real trajectories, common: analyzing 10,152 agent
trajectories, the authors found **39.8%** contained semantically-equivalent
repeated calls under uncertain execution outcomes, and **58%** of lost
acknowledgments triggered the agent re-proposing the same authorization to the
user.

The mechanism, named **semantic replay**: the user confirms an action once.
The confirmation's acknowledgment is lost. The agent, unable to distinguish
"nothing happened" from "it happened but I didn't hear back," replans and asks
again — or worse, silently retries with a freshly issued single-use token.
Each token is honestly single-use. The *authorization instance* — the thing
the user actually agreed to — still gets exhausted twice, because the system
was tracking token identity, not the confirmation itself.

**CapLease**, their proposed fix, tracks the authorization by what it is
*about*, not by which token carries it:

- A durable, token-independent record binds `(action, confirmation)` to an
  execution budget.
- Transitions move through an explicit **Issued → Prepared → Committed**
  protocol, so a half-finished authorization has a recorded state instead of
  disappearing into ambiguity when a message is lost.
- A stable idempotency key on the eventual side effect closes the loop with
  Layer 1.

In fault injection across 12,000 scenarios, CapLease (and a server-side
"Server Ledger" variant) produced **zero** fresh-reissuance, concurrent-spend,
or confirmation-replay violations. Baselines built on single-use tokens alone
(Progent, PACT, AIRGuard) blocked the obvious replay case but still allowed
fresh reissuance and duplicate authorizations under the same lost-ack
conditions.

> **Lesson:** a single-use token answers "can this exact artifact be redeemed
> twice?" It does not answer "has the user already agreed to this?" Those are
> different questions, and an agent that replans on ambiguity will keep
> generating fresh, individually-valid tokens for an authorization that should
> have been exhausted once.

---

## 4. When idempotency keys alone are not enough

| Situation | Layer needed |
|---|---|
| A tool call may be silently duplicated by a retry, with no human approval step in the loop | Layer 1 (idempotency key + postcondition verification) is sufficient |
| A tool call is gated by a user's explicit confirmation ("yes, send it" / "yes, charge it") and the agent can replan, retry, or resume across turns | Layer 1 alone is not sufficient — the confirmation itself needs durable state (Layer 2), because a lost ack produces a *new, valid* token for an authorization the user already spent |
| The action is read-only or naturally idempotent (a query, a status check) | Neither layer is load-bearing — non-atomicity here just means "read again" |

> **Architectural takeaway:** the two papers are solving the same root problem
> — an agent cannot reliably tell "in flight" apart from "done" apart from
> "never happened" — at two different points in the stack. Idempotency keys
> protect the *side effect*. Durable authorization state protects the
> *permission* that gates it. A production agent that moves money, sends
> messages, or deletes data needs both, because the permission and the effect
> fail independently.

---

## 5. A third failure axis — the agent's own earlier mistakes

Sections 1–4 treat the *environment* as the unreliable party: the network drops, the API times out, the ack is lost. Noorain et al. hold the environment perfectly reliable and measure the other source of tool-call failure — **error the agent injected into its own context on an earlier step.**

The setup is a chained tool task where the correct next tool is a parity rule applied to the incoming value, not a pre-announced order. That matters: the model cannot pattern-match a script, it has to read the previous result. They run depths 1, 2, 4, 6, and 8 and compare two accuracies at each step:

| Symbol | Measurement | Meaning |
|---|---|---|
| `p_t` | **Teacher-forced** accuracy at step *t* | The step is fed a clean, correct prior state. Measures raw capability |
| `g_t` | **Free-running** accuracy at step *t* | The step is fed whatever the model actually produced. Measures deployed behavior |
| `L_t = 1 − g_t/p_t` | **Net propagation loss** | The fraction of the model's own capability destroyed by its own history |

The headline number: **by depth 6, roughly 70% of a model's clean-context capability is lost to its own earlier mistakes** (L₆ ≈ 0.686, 0.684 across the two conditions reported).

> Why it matters: this is the number that reframes the whole reliability budget. A per-call accuracy figure — the thing every tool-calling benchmark reports — is `p_t`. What you deploy is `g_t`. Buying reliability by raising per-call accuracy has sharply diminishing returns at depth, because the dominant term is not the call, it is the six calls of contaminated state in front of it. Truncating, verifying, or re-grounding the state between steps attacks the term that is actually large.

### 5.1 The measurement bug it exposes

The paper's more transferable contribution is a critique of how tool-calling evals score. The standard method compares each step against a **fixed gold trajectory**. Once an agent diverges from that trajectory, the comparison is no longer measuring anything meaningful:

```text
gold:    A ──► B ──► C ──► D
actual:  A ──► B ──► X ──► ?
                     │
                     └─ from here, gold's next value was produced by tool
                        constants the model never saw. Matching it is
                        information-theoretically impossible, not merely hard.
```

Two things break at once. Severity estimates are pinned to their boundary — the paper reports **0 of 869 poisoned steps scored correct**, which reads as "total collapse" but is partly an artifact of unreachability. And **recovery becomes unobservable**: an agent that notices its error and continues sensibly from the state it actually holds scores identically to one that flails.

The proposed fix is **conditional-on-state scoring** — credit a call when it correctly continues from the value the model actually holds, not when it matches gold. Applied retrospectively to the same cached completions at no extra compute, severity estimates move off the boundary to interior values (+0.149 to +0.316).

> **Architectural takeaway:** if your agent eval compares trajectories step-by-step against a golden path, it is measuring divergence, not competence, and it is blind to the recovery behavior you most want to select for. Score each step against the state the agent is actually in. This is a scoring-function change, not a data-collection change — you can rerun it over completions you already have.

### 5.2 Scope caveat

The study covers five open-weight models on a free inference tier, greedy decoding, on a synthetic parity-routing task. The absolute numbers should not be read as frontier-model behavior. The two structural claims — that free-running accuracy diverges hard from teacher-forced accuracy as depth grows, and that gold-trajectory matching makes recovery unmeasurable — are the parts that transfer.

---

## References

- [Verified Tool Calls Improve LLM Agent Reliability Under Non-Atomic Failures — arXiv abstract](https://arxiv.org/abs/2608.02645)
- [Beyond Single-Use Tokens: Durable Authorization State for Replay-Resistant LLM Agent Actions — arXiv abstract](https://arxiv.org/abs/2608.01710)
- [Invocation-Level Reliability of Tool-Using Agents — arXiv abstract](https://arxiv.org/abs/2608.26189)
