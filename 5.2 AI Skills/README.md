# 5.2 AI Skills

## Notes

- [Skills Over MCP — Distribution as a Resources Extension, Not a Fourth Primitive](Skills%20Over%20MCP%20—%20Distribution%20as%20a%20Resources%20Extension%2C%20Not%20a%20Fourth%20Primitive.md) — how skills get from a server to an agent, and why the obvious design lost. SEP-2076 would have made skills a fourth MCP primitive (`skills/list`, `skills/get`, capability, notification); it closed 2026-02-24 on three arguments worth reusing — explicit complexity-fatigue budget, "everything an MCP server exposes is context" (so skills-as-resources dissolves the hierarchy question rather than answering it), and the primitive flattening a *directory* into a name-addressed blob. What shipped instead is SEP-2640, an Extensions Track spec with **zero protocol changes** over existing Resources, with content format delegated to the Agent Skills spec. Covers the `skill://` scheme (four independent implementations converged on it before standardization) and its four design calls — no host semantics on the authority segment, explicit `SKILL.md`, path siblings for sub-resources, and path-as-locator decoupled from frontmatter-as-identity — plus the enumeration trap (`resources/list` is optional; an empty list is not proof of no skills). Then the trust posture: skill trust = server trust, no marketplace, no OS packaging, versioning deferred to the server version — a deliberate sidestep of the supply-chain problem in 8.8. Closes on the gap the charter admits: discovery is standardized, **activation never will be**.
- [SKILL-ORCHESTRATION-NOTES.md](SKILL-ORCHESTRATION-NOTES.md) — working notes on skill selection and orchestration.

## Scratch

Skills inject information internally via text prompt layering (progressive disclosure) and model routing changes.

Commands manipulate information externally by slicing, summarizing, or clearing the wrapper that holds your active memory

https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise

https://github.com/iOfficeAI/OfficeCLI/tree/main/skills
https://github.com/MiniMax-AI/skills


https://code.claude.com/docs/en/skills#frontmatter-reference

https://code.claude.com/docs/en/skills#available-string-substitutions