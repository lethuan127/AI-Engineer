# Consumer-Facing Agent Architecture — Skills Over Subagents, Presentation Tools, and Harness-Enforced Safety

> **Superseded, pending deletion.** This note and [7.5. Transactional Agents — A Reference Architecture for Agents That Move Money](../7.%20AI%20System%20Architecture/7.5.%20Transactional%20Agents%20—%20A%20Reference%20Architecture%20for%20Agents%20That%20Move%20Money.md) were produced by two runs of the daily-scan job against the same source (Anthropic's commerce-agent engineering deep-dive, 2026-09-02). 7.5 is the survivor: it is numbered, already cross-linked from tracks 5, 8, and 11, and frames the material correctly as *any agent whose output is a write against a system of record* rather than as a consumer-UI pattern.

All unique material from this draft has been folded into 7.5:

- the delegation / hand-off / bouncing distinction — when a subagent *does* earn its place (§1)
- prompt-vs-skill refinements: unconditional-residency instructions, harness pre-injection of predictable skills, and the missing-backend-endpoint tell (§1)
- presentation calls as the on-screen record for referential grounding, and the `eager_input_streaming` validation tradeoff (§4)
- memory keyed by person rather than account, and the extractor's tool-result exclusion as an injection boundary (§5)
- skills-as-tool-results and rolling breakpoints as cache corollaries, plus the Fable 5.1 cache-read repricing (§6)
- **the entire latency section** — the two budgets, the three levers, eager dispatch, progressive rendering, and why a smarter model often wins p99 (§7, new)
- clean-state bias, simulated-user evals as discovery-not-measurement, and the user-authored vs data-plane injection split (§8)
- the prompt-is-tuned-to-a-model caveat on sweeps (§9), and the no-module-boundary rationale for process isolation (§10)

Deleting this file needs Thuan's OK per `AGENTS.md` §4.

## References

- [Anthropic — A Guide to the Anatomy of Effective Commerce Agents](https://claude.com/blog/the-anatomy-of-effective-commerce-agents)
- [Anthropic — Building Commerce Agents with Claude](https://claude.com/blog/claude-for-commerce-agents)
