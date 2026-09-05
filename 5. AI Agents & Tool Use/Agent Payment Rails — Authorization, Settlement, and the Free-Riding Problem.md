# Agent Payment Rails — Authorization, Settlement, and the Free-Riding Problem

> Companion to [8.5. The Tool-Authorization Plane](../8.%20AI%20Safety%20%26%20Ethics/8.5.%20The%20Tool-Authorization%20Plane%20%E2%80%94%20Write%20Scope%2C%20Attribution%2C%20and%20Audit.md)
> and [Tool-Call Reliability — Idempotency, Postcondition Verification, and Replay-Safe Authorization](./Tool-Call%20Reliability%20%E2%80%94%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md).
> Those notes cover an agent that writes to a system. This one covers an agent that
> *spends* — the one write whose blast radius is denominated in money and whose
> reversal path is a chargeback, not a `git revert`.

Four protocols shipped between September 2025 and August 2026 to let an agent pay for
something without a human at the keyboard. They are routinely described as competitors.
They are not: three of them occupy different layers, one is a hosted product built on
another, and the layer that is actually load-bearing for an agent engineer — spend
authorization — is the one with the least settled answer.

---

## 1. Why the existing tool-authorization plane does not cover this

An agent buying an API call is, mechanically, a tool call with a side effect. The
mechanisms in [8.5](../8.%20AI%20Safety%20%26%20Ethics/8.5.%20The%20Tool-Authorization%20Plane%20%E2%80%94%20Write%20Scope%2C%20Attribution%2C%20and%20Audit.md)
— risk tiers, write scope, attribution — apply unchanged. Three properties break them:

| Property | Ordinary write | Payment |
|---|---|---|
| Reversal | Idempotent retry, or an undo endpoint | Chargeback or dispute — days, and a counterparty who must agree |
| Blast radius unit | Rows, files, messages | Currency, unbounded until a cap exists |
| Counterparty | Usually a system the deployer controls | An arbitrary merchant the agent discovered mid-task |
| Rate | Bounded by the API's own limits | Bounded only by the balance |

The last row is why per-call approval prompts fail here specifically. The whole point of
micropayment rails is an agent making hundreds of sub-cent calls to evaluate options.
A human approving each one destroys the use case; a human approving none of them destroys
the budget. The design problem is a **standing, attenuated grant** — not a confirmation
dialog.

---

## 2. The four protocols, by layer

| Protocol | Author | Layer it actually occupies | Core primitive |
|---|---|---|---|
| **AP2** (Agent Payments Protocol) | Google, 60+ partners; donated to the FIDO Alliance | Authorization / trust | Cryptographically signed **mandates** (verifiable credentials) |
| **ACP** (Agentic Commerce Protocol) | OpenAI + Stripe, Apache-2.0 | Merchant checkout flow | Agent-ready checkout config + delegated payment tokens |
| **x402** | Coinbase; now under a Linux Foundation body | Settlement transport | HTTP `402 Payment Required` + stablecoin settlement |
| **Cloudflare Wallets** | Cloudflare (announced 2026-08-04) | Hosted custody + spend policy | Account wallet → virtual wallet delegation, built on x402 |

They compose rather than compete: AP2 says *the human authorized this*, ACP says *here is
how the merchant takes it*, x402 says *the money moved*, and Cloudflare Wallets is a
managed implementation of custody and limits sitting on x402.

### AP2 — authorization as a signed artifact

AP2's contribution is the **mandate**: a tamper-proof, cryptographically signed statement
of what the agent may do. It defines two, and the split matters:

- **Intent Mandate** — the user's goal, signed. *"Find me white running shoes."* In the
  human-not-present flow it carries the rules of engagement: price ceiling, timing,
  conditions.
- **Cart Mandate** — the exact items and price, signed. In the human-present flow the
  *user* signs it after seeing the cart ("what you see is what you pay for"). In the
  human-not-present flow the *agent* generates it once the Intent Mandate's conditions
  are met.

The resulting `Intent → Cart → payment method` chain is a non-repudiable audit trail that
answers authorization ("did the user grant this authority?"), authenticity ("does the
request reflect real intent?"), and accountability ("who is liable when it is wrong?")
separately. That three-way split is the part worth stealing even if you never adopt AP2:
most homegrown agent-spend designs collapse all three into one API key.

### x402 — settlement as an HTTP status code

x402 revives HTTP `402`. A server that wants payment answers `402` instead of `401`; the
client pays and retries. No account, no signup, no API key — which is precisely the point
for an agent evaluating an API it has never used before. It is chain-agnostic (EVM chains,
Solana, others), settles in stablecoins, and charges no protocol fee.

> Why it matters: x402 removes the *onboarding* step, not just the payment step. An agent
> that must create an account to try an API cannot try fifty of them. That is a capability
> change, not a billing change — and it is the reason the security analysis below is not
> an edge case.

---

## 3. The security record is already bad, and it is structural

Two 2026 papers audited x402 in production. Neither found a bug in a single
implementation; both found **cross-layer** failures — the gap between an HTTP request and
an on-chain settlement, which neither web security nor blockchain security has a
convention for.

*Free-Riding the Agentic Web* (arXiv:2605.30998) audited official SDKs and live
deployments across a protocol carrying 130M+ transactions and integrated by Google Cloud,
Cloudflare, and Stripe. Four vulnerability classes:

| Class | What goes wrong |
|---|---|
| Cross-resource substitution | Payment authorized for resource A is redeemed against resource B |
| Duplicate-settlement race | The same authorization settles twice under concurrency |
| Allowance overdraft | Spend exceeds the approved allowance |
| Denial of settlement | Payer is charged, service is withheld |

Measured **resource-leakage ratios up to 100%** — an attacker obtaining the full service
without net payment. The paper also proves a negative result worth internalizing: **no
output-only pricing scheme can be both fair to honest users and bounded against
inflation.** If you bill an agent purely on tokens it consumed, you have to choose which
of those two you give up. Their mitigations cut per-call reasoning cost 47% and moved
attacker advantage from 8.7× to 0.9× at 2.8% overhead.

*Five Attacks on x402* (arXiv:2605.11781) reaches the same shape independently across
authorization, binding, replay protection, web-layer handling, and cross-layer surface,
validated on local chains, Base Sepolia, and live endpoints against three open-source
SDKs. Outcomes fall into two buckets: **unpaid service**, or **paid-but-denied**.

> Lesson: "replay protection" here is the same problem CapLease identified for tool calls
> (see [Tool-Call Reliability](./Tool-Call%20Reliability%20%E2%80%94%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md)):
> a single-use token is not the same thing as a single-use *authorization*. A lost
> acknowledgement makes an honest retry indistinguishable from an attack, and only durable
> state keyed on the `(action, confirmation)` pair tells them apart. Payment rails
> reproduced the bug at a layer where the loss is denominated in money.

---

## 4. Where spend policy actually lives — the two-tier wallet

Cloudflare Wallets (announced 2026-08-04; handle reservation live, funding and virtual
wallets "coming soon") is the clearest published example of spend policy as an
infrastructure primitive rather than a prompt instruction:

- **Account Wallet** — held by the human account owner. Funds it, delegates from it,
  withdraws from it.
- **Virtual Wallet** — held by an agent, operated by API key, capped by limits the human
  set on the Account Wallet.

The controls on a Virtual Wallet are the interesting part, because they are the four
knobs any agent-spend design needs regardless of vendor:

1. **Total spending cap** — the balance the agent can ever reach.
2. **Merchant allowlist** — where it may spend at all.
3. **Per-transaction maximum** — the single-call blast radius.
4. **Anomaly → human review** — unusual patterns drop out of the autonomous path.

Agents register by keypair through Web Bot Auth and resolve to a readable handle
(`research.example.cloudflare.pay`), so a merchant can see the agent's organizational
affiliation. That is the [8.5](../8.%20AI%20Safety%20%26%20Ethics/8.5.%20The%20Tool-Authorization%20Plane%20%E2%80%94%20Write%20Scope%2C%20Attribution%2C%20and%20Audit.md)
"keep the person, add the agent" attribution split showing up on the payment rail: the
human owns the money, the agent is a named, separately-revocable spender against it.

> Architectural takeaway: every one of those four controls is enforced *outside* the
> model. None of them is a sentence in a system prompt. This is the same conclusion the
> Model Hardware Standard reached for physical actuators — safety limits belong in the
> driver, not the prompt — arriving independently at the payment layer. Treat any design
> where the budget lives in the agent's instructions as having no budget.

---

## 5. What to do today

| If you are | Do this | Not this |
|---|---|---|
| Building an agent that buys anything | Put the cap, allowlist, and per-transaction max in infrastructure the model cannot edit | State a budget in the system prompt |
| Accepting agent payments as a merchant | Bind the authorization to a specific resource *and* a specific settlement, and key idempotency on both | Trust that a payment header maps to the request that carried it |
| Choosing a protocol | Pick by layer: AP2 for authorization, ACP for merchant checkout, x402 for settlement — you will likely need more than one | Treat them as alternatives and pick "the winner" |
| Pricing an API for agent consumers | Accept that output-only pricing cannot be both fair and inflation-bounded; decide which you sacrifice, explicitly | Bill per output token and assume it is neutral |
| Running any of this in production now | Assume the cross-layer attack surface is live; the leakage measurements were taken against official SDKs, not toy code | Wait for the protocol to mature before adding your own checks |

The honest summary of the state of play: settlement is solved, merchant checkout is
solved-enough, and **authorization is not**. AP2's mandates are the best published answer
and are still moving through the FIDO Alliance. Until that settles, the durable control is
the one Cloudflare's wallet model makes explicit — a hard, externally enforced ceiling
that does not depend on the agent behaving well.

## References

- [x402 — An open standard for internet-native payments](https://www.x402.org/)
- [Google Cloud — Powering AI commerce with the new Agent Payments Protocol (AP2)](https://cloud.google.com/blog/products/ai-machine-learning/announcing-agents-to-payments-ap2-protocol)
- [Agentic Commerce Protocol — Open standard for commerce flows between buyers, AI agents, and businesses](https://www.agenticcommerce.dev/)
- [Cloudflare — Announcing Cloudflare Wallets: The programmable wallet for the agentic Internet](https://blog.cloudflare.com/wallets/)
- [arXiv — Free-Riding the Agentic Web: A Systematic Security Analysis of x402 Payments](https://arxiv.org/abs/2605.30998)
- [arXiv — Five Attacks on x402 Agentic Payment Protocol](https://arxiv.org/abs/2605.11781)
