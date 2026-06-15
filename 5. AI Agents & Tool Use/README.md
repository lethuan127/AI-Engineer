# 5. AI Agents & Tool Use

## Notes
- [Agentic Context Engineering — Evolving Playbooks for Self-Improving Agents](Agentic%20Context%20Engineering%20—%20Evolving%20Playbooks%20for%20Self-Improving%20Agents.md) — ACE (Stanford/SambaNova, ICLR 2026): the agent self-improves by evolving a written playbook, not its weights; Generator/Reflector/Curator, delta updates that beat context collapse, and the numbers (matches a top proprietary agent on AppWorld).
- [Small Language Models for Agents — The Heterogeneous Architecture](Small%20Language%20Models%20for%20Agents%20—%20The%20Heterogeneous%20Architecture.md) — NVIDIA's SLM-first case: small specialists do the routine steps, a frontier LLM is the on-demand consultant; the economics, the router, and the LLM→SLM conversion recipe.
- [Speculative Execution in the Agent Loop — Hiding Latency with Predict-and-Verify](Speculative%20Execution%20in%20the%20Agent%20Loop%20—%20Hiding%20Latency%20with%20Predict-and-Verify.md) — borrow CPU speculation for agents: do likely-correct work during tool-call waits, verify before commit. The three shapes (IdleSpec speculative planning, safe/unsafe speculative tool calling, lossless speculator/target), the rollback discipline, and where it breaks on real input.
- [Agent Memory Architectures — Tiered, Vector, Temporal-Graph](Agent%20Memory%20Architectures%20—%20Tiered%2C%20Vector%2C%20Temporal-Graph.md) — the three 2026 memory designs (Letta tiered, Mem0 hybrid, Zep temporal graph), benchmarks, and production gaps.
- [The Agent Protocol Stack — MCP, A2A, AGENTS.md](The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md) — how 2026 agents connect to tools, to each other, and to humans (open-standard layer cake).
- [multi-agent.md](multi-agent.md) — single-system multi-agent patterns (graph, swarm, workflow).
- [MCP.md](MCP.md) — Model Context Protocol notes.

Roadmap: https://roadmap.sh/ai-agents
