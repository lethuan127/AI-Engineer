---
name: resume-quantifier
description: Add or strengthen quantified impact (metrics) on resume bullets for a Senior AI/Software Engineer. Use when bullets feel vague, lack numbers, or the user says "add metrics", "quantify this", "where are the numbers", or "make the impact concrete". Sources real numbers from the work-tracking logs and flags anything unverifiable.
---

# Resume Quantifier

Turn qualitative bullets into quantified ones — and never fabricate a number.

> **First:** load `resume-positioning` for the metric taxonomy and the canonical source
> files. Numbers come from those logs or the candidate, not from imagination.

## When to use

- A bullet describes work but has no measurable outcome.
- The user wants stronger, number-driven impact.
- Auditing a resume for "show, don't tell".

## The 6 metric dimensions (pick the most credible one per bullet)

1. **Latency / performance** — % faster, ms saved, p95 improvement.
2. **Cost** — % spend reduction, $ saved, tokens/calls cut.
3. **Scale** — req/day, txns, users, tenants, data volume.
4. **Reliability** — incidents removed, uptime %, error-rate drop, MTTR.
5. **Velocity** — % faster delivery, build/CI time, coverage %.
6. **Adoption / breadth** — teams/services using it, repos, features shipped.

## Method

1. For each unquantified bullet, ask: *which dimension does this work move?*
2. Look for a real number in `work-activity.md` / `linear-activity.md` / weekly logs
   (commit counts, AIP ticket outcomes, the headline metrics already on the CV).
3. If found → bold it into the bullet. If a number plausibly exists but isn't in the
   logs → write `[verify: <what to measure>]` so the candidate can fill it.
4. **Never** invent precision (no "improved by 47.3%" unless sourced).
5. Prefer **one strong, defensible** number over three soft ones.

## Sourcing guide (where this candidate's numbers live)

- **Volume/breadth:** 583 backend + 765 total commits, 12 repos, 51 Linear tickets,
  34 completed — all in `work-activity.md`.
- **Reliability:** specific fixes (CPU leak AIP-26, MCP race AIP-35/upstream, Bedrock/Vertex
  timeouts AIP-57, report background-mode AIP-1) — count incidents removed.
- **Prior roles (already quantified on CV):** 90% latency, 60% LLM cost, 40% faster dev,
  100k+ daily txns, 99.9% uptime, 80% test coverage.
- **Cost/latency in AI work:** sampling-model swaps, batch APIs, background mode — frame as
  reliability + cost even when exact % is `[verify]`.

## Output

The rewritten bullets with metrics inlined and bolded, plus a short **`[verify]` list**
of numbers the candidate should confirm before sending.

## Quality bar

- [ ] No fabricated or false-precision numbers.
- [ ] Each metric maps to one of the 6 dimensions and to a real source.
- [ ] Unverifiable-but-likely metrics are flagged, not dropped or invented.
- [ ] At most two metrics per bullet.
