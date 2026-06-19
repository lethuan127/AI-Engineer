# 3. Prompt & Context Engineering

## Notes
- [Prompting Best Practices — What Changed When Models Got Strong](Prompting%20Best%20Practices%20—%20What%20Changed%20When%20Models%20Got%20Strong.md) — the 2026 reset: strong/reasoning models killed the old trick bag (CoT-on-everything, heavy few-shot, "you MUST!!!", self-consistency, prefill). The durable core — specify intent not reasoning paths, the clarity floor (specific + the *why* + positive framing), XML/structure, long-data-top, sharper-fewer examples, let-it-think, prompting→context engineering (right altitude, high-signal tokens, context rot), agent guardrails on eagerness, and treating prompts as code (start minimal, re-tune per model). Ends with a one-screen checklist.
- [Prompting Techniques Catalog — What Each One Is, and Whether It Still Earns Its Keep](Prompting%20Techniques%20Catalog%20—%20What%20Each%20One%20Is%20and%20Whether%20It%20Still%20Earns%20Its%20Keep.md) — the 18 named techniques from promptingguide.ai, each re-graded for 2026 reasoning models (✅ core / ⚠️ situational / ⛔ redundant / 🏗️ now architecture). The pattern: reasoning-elicitation tricks (CoT, self-consistency, ToT, graph) moved *into the model*; tooling/grounding tricks (RAG, ReAct, PAL, ART) moved *into the system*. Master table + four families + a which-technique-for-which-task decision table. Companion to the best-practices note.
- [Prompt Caching](prompt-caching.md) — the mechanics: prefix-match over exact bytes, KV-cache reuse, why early edits invalidate everything after, and how to order a prompt for cache hits.
- [Skill.md](Skill.md) — skills vs commands (internal text layering vs external context manipulation).

Roadmap: https://roadmap.sh/prompt-engineering


Ref: https://www.promptingguide.ai/
https://docs.langchain.com/oss/python/concepts/context