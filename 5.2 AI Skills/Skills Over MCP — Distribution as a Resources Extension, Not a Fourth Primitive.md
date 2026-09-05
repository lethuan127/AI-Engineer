# Skills Over MCP — Distribution as a Resources Extension, Not a Fourth Primitive

> Source: the [Skills Over MCP Working Group charter](https://modelcontextprotocol.io/community/working-groups/skills-over-mcp) and the WG's `experimental-ext-skills` design docs. Companion to [11.4. Skills](../11.%20Harness%20Engineering/11.4.%20Skills.md), [Agent Plugins](../5.%20AI%20Agents%20&%20Tool%20Use/Agent%20Plugins%20—%20Packaging%20Skills%20and%20MCP%20Servers%20for%20Cross-Client%20Portability.md), and [The Post-Stateless MCP Roadmap](../5.%20AI%20Agents%20&%20Tool%20Use/The%20Post-Stateless%20MCP%20Roadmap%20—%20Agent%20Identity%2C%20Progressive%20Discovery%2C%20and%20One%20Transport.md).

Agent Skills solved *authoring* — a directory with a `SKILL.md` and progressive disclosure. MCP solved *tool access*. Between them sat an unowned question: how does a skill get from a server to an agent at runtime?

The obvious answer was to make skills a fourth MCP primitive alongside Tools, Resources, and Prompts. That proposal was written, discussed for three months, and **closed**. The interesting content of this note is the reasoning that killed it, because it generalizes: the WG concluded that a skill is not a new *kind* of thing, it is context — and MCP already has a primitive for context.

---

## 1. Why distribution was the open question

A tool description tells an agent *what a tool does*. It does not tell the agent how to sequence five tools, when to branch, or which of three approaches fits the situation. That "how-to" knowledge is what a skill carries, and it routinely runs to hundreds of lines — far past what belongs in a tool description.

The motivating observation from the original proposal's author is the practical one:

> "My main motivation is: we have so many MCP servers already available, how can we leverage them to distribute Skills?" — Yu Yi (Google)

There is an installed base of MCP servers that users have already trusted, configured, and connected. If a skill can ride that connection, skill distribution inherits a solved trust and transport problem instead of needing its own.

---

## 2. Six approaches, one spectrum

The WG's `approaches.md` enumerates the option space. It is worth reading as a spectrum from *protocol change* to *pure convention*, not as six unrelated ideas:

| # | Approach | Mechanism | Status |
|---|---|---|---|
| 1 | Skills as a distinct primitive | `skills/list` + `skills/get`, a `skills` capability, `notifications/skills/list_changed` | **Closed** 2026-02-24 (SEP-2076) |
| 2 | Skills as registry metadata | Skill references in registry entries; a `skills.json` / `_meta` field pointing at `.skill` bundles | In progress, owned by Registry WG |
| 3 | Skills as tools and/or resources | `list_skills` / `read_skills` tools, or `skill://` resources | Multiple independent implementations |
| 4 | Gateway / composition | One server fronting several, supplying the instructions that make them cohere | Pattern, not standardized |
| 5 | Server instructions as pointer | "If you need X, fetch resource Y" — defers loading until needed | Limited: cannot modify third-party server instructions |
| 6 | Official convention | Documented URI scheme + metadata, no protocol change | **Graduated** into SEP-2640 |

A variant worth noting under #3: **skills via Sampling** (SEP-1577). The server issues a sampling request carrying skill-specific tools (`read_skill_md`, `execute_script`) that are visible *only during that request*, so the main agent never sees them. That directly attacks tool bloat — the server orchestrates, the agent sees only the result. It is blocked on thin client support for Sampling, but it is the most interesting unexplored branch here.

---

## 3. What killed the new primitive

SEP-2076 was a competent design: dedicated methods, its own capability, a change notification, and progressive disclosure built in (summaries at startup, full body on demand). It closed anyway, for three reasons that are all worth carrying elsewhere.

**Complexity fatigue is now an explicit design constraint.** From the WG's own principles: the ecosystem has "too many overlapping concepts (servers, skills, plugins, hooks, agents)" and further surface area "erodes credibility and adoption." The stated bar is that a new primitive must show existing primitives *cannot* serve the need — not merely that a new one would be tidier.

**"Everything an MCP server exposes is context."** This is the load-bearing argument:

> "I don't like creating dichotomy between first-class skills and skills as context, because pretty much everything an MCP server exposes is context. Skills-as-resources is much more accurate." — Peder Holdgaard Pedersen (Saxo Bank)

Framing skills as context-as-resources dissolves the hierarchy question rather than answering it. There is no "first-class skill vs. mere context" tier to adjudicate, because the distinction was an artifact of the proposed design.

**The primitive flattened the format.** A skill in the Agent Skills spec is a *directory* — `SKILL.md` plus references, scripts, templates. `skills/get` returns a name-addressed blob, which loses that structure. The new primitive was, ironically, a worse fit for the thing it was meant to model than resources were.

> Architectural takeaway: the strongest argument against a new primitive was not "it costs too much" but "it models the domain incorrectly." When a proposed abstraction forces you to flatten the thing it abstracts, that is the signal — not the implementation cost.

One dissent is preserved in the record and remains unresolved:

> "The only slight concern I have is the idea that there are still 'first class skills' (skills that agents recognize as skills, can be presented as skills through the user agent, can be bundled with subagents, etc) and these sort of 'skills as context' approaches where the agent can certainly discover and ingest the skills data, but possibly with some differences compared to how they would apply first class skills." — Bob Dickinson (TeamSpark.ai)

That is the real risk of the resources route: a skill delivered as a resource may be *read* but not *treated as a skill* by a host that has a native skills concept. The convention can standardize the wire; it cannot standardize the host's respect for it.

---

## 4. What was chosen: SEP-2640, the Skills Extension

Submitted to the spec **2026-04-23**, Extensions Track, extension identifier `io.modelcontextprotocol/skills`.

| Property | Value |
|---|---|
| Track | Extensions — not core protocol |
| Protocol changes | **Zero.** Uses `resources/list`, `resources/read`, resource templates, subscriptions |
| Backward compatible | Yes |
| Content format | Delegated to the Agent Skills spec, not defined by MCP |
| Declared via | `initialize` capabilities |

Two things about this shape are worth naming.

**The Extensions Track is doing exactly the job it was added for.** The [2026-07-28 spec](../5.%20AI%20Agents%20&%20Tool%20Use/MCP%20Goes%20Stateless%20—%20The%202026-07-28%20Release%20Candidate.md) introduced a formal extensions framework so that capability growth stops accreting onto a core that has to stay small and cacheable. Skills are the first substantial test of that: a feature with real ecosystem demand, shipped without touching the core.

**Format and transport are owned by different bodies.** MCP defines how a skill is *addressed and fetched*; the Agent Skills spec defines what is *inside* `SKILL.md` (frontmatter, the 1–64-character lowercase-hyphenated `name`, progressive disclosure). That split is the same one HTTP made with MIME types, and it is why neither spec has to move at the other's pace.

---

## 5. The `skill://` URI scheme

### The convergence signal

Before any standardization, **four independent implementations picked `skill://` without coordinating.** NimbleBrain, skilljack-mcp, keithagroves/skills-over-mcp, and FastMCP 3.0 all landed on the same scheme. That is the healthy version of this process: convention proves the pattern, then the SEP formalizes what already works.

They diverged on structure, which is what the survey had to resolve:

| Implementation | Pattern | Authority | Sub-resources | Discovery |
|---|---|---|---|---|
| NimbleBrain | `skill://ipinfo/usage` | Server name | None | `resources/list` |
| skilljack-mcp | `skill://code-style` | None | Trailing-slash collection | `resources/list` + templates |
| skills-over-mcp | `skill://code-review` | None | `/document/` subpath | `skill://index` + templates |
| FastMCP 3.0 | `skill://pdf/SKILL.md` | None | File paths + `_manifest` (SHA-256) | Configurable disclosure |
| Well-known RFC | `https://…` | Domain | File paths | `index.json` over HTTP |

### Four design decisions

1. **Keep the double slash, drop the semantics.** RFC 3986 says the segment after `://` is a host. A skill path is not a host. Rather than the awkward `skill:///`, the convention keeps `skill://` and states that the first segment carries no special meaning — and that **clients MUST NOT attempt DNS or network resolution of it.**
2. **`SKILL.md` is explicit in the URI.** `skill://<skill-path>/SKILL.md`, always. This keeps the URI aligned with the directory model instead of hiding the entry point behind an abstraction — the same mistake §3 faulted the primitive for.
3. **Sub-resources are path siblings.** No special `/document/` namespace, no trailing-slash collection; supporting files are addressed by their path relative to the skill directory.
4. **The path is a locator; the name is identity.** Early drafts required one segment equal to the frontmatter `name`. That breaks the moment an organization needs `acme/billing/refunds` and `acme/support/refunds` — you cannot satisfy "one segment" and "segment equals name" without renaming a skill to dodge a collision. So they decoupled: **the URI says where to find it, the frontmatter says what it is.**

```text
skill://git-workflow/SKILL.md                      # flat path
skill://acme/billing/refunds/SKILL.md              # nested; frontmatter name may be "refund-handling"
skill://code-review/references/SECURITY.md         # sub-resource
skill://docs/{product}/SKILL.md                    # resource template (user-facing browse + completion)
```

A `SKILL.md` must not appear in an ancestor directory of another `SKILL.md` — skills do not nest.

### The implementation trap

> **Enumeration is optional.** A `skill://` URI is directly readable via `resources/read` whether or not it ever appears in `resources/list`, and clients **MUST NOT** treat an empty or absent listing as proof that a server has no skills.

This is the detail most likely to produce a silent bug. A client that gates skill support on a non-empty `resources/list` will see nothing on a server that exposes skills only by template or by documented URI, and will report "no skills" rather than an error. Identify skills by scheme (`skill://`), by entry point (a URI ending `/SKILL.md`), by MIME type (`text/markdown`), or by `_meta` — not by presence in a list.

---

## 6. Distribution, trust, and what is deliberately not solved

| Concern | Position taken |
|---|---|
| Install model | **Ephemeral.** Skills are available while the server is connected and gone when it disconnects. Clients MAY offer to install one permanently; nothing requires a separate install step. |
| Provenance | The remote server URL SHOULD be carried in skill frontmatter, so a skill encodes its own origin "when things go wrong." |
| Trust | Skill trust **equals server trust**. No separate skill trust model. |
| Marketplace | Explicitly discouraged. MCP is not to become a distribution channel for arbitrary third-party skill content. |
| Packaging | No OS-level bundles. No `tar.gz`. Skills stay text — MCP has no notion of the receiving environment. |
| Versioning | **Deferred.** A skill's version is the server's version; update the server, the skill content changes with it. |
| Collisions | Same `skill://` path on two servers is possible; clients SHOULD let the model disambiguate by server name, and servers MAY put provenance in `_meta`. |

> Why it matters: "trust equals server trust, and no marketplace" is the most consequential line here, and it is a deliberate sidestep of the problem [8.8. The Skill Supply Chain](../8.%20AI%20Safety%20&%20Ethics/8.8.%20The%20Skill%20Supply%20Chain%20—%20Install-Time%20Scanning%20and%20Why%20It%20Collapses.md) documents. Install-time scanning of third-party skills collapses because the content is prose that can be rewritten after review. MCP's answer is to refuse the premise: there is no third-party skill to scan, only skills from a server you already decided to trust. That is defensible, and it leaves the marketplace problem to whoever builds one.

The versioning deferral is the weakest point. Pinning a skill independently of its server is a normal requirement — the same reason lockfiles exist — and "the server version is the skill version" only holds while one team owns both.

### The complementary layer

Cloudflare's Agent Skills Discovery RFC registers `agent-skills` under the RFC 8615 `.well-known` prefix, so an organization publishes at `https://example.com/.well-known/agent-skills/index.json` — a versioned schema listing each skill with a name, description, URL, and **SHA-256 digest**. That is domain-level discovery with content integrity; MCP is runtime consumption. They stack rather than compete, and the digest is precisely the integrity primitive the `skill://` scheme does not attempt.

> Note the WG's own URI-scheme doc cites this as `/.well-known/skills/`; the RFC itself uses `/.well-known/agent-skills/`. Read the RFC for the current path.

---

## 7. The boundaries, and the gap they leave

The charter's "Out of Scope" section is where the governance shape shows:

- **Registry schema** belongs to the Registry WG. This WG contributes requirements only.
- **Plugin/bundle packaging** — skills + servers + subagents + config as one installable artifact — is explicitly out, which is the space the [Agent Plugins](../5.%20AI%20Agents%20&%20Tool%20Use/Agent%20Plugins%20—%20Packaging%20Skills%20and%20MCP%20Servers%20for%20Cross-Client%20Portability.md) standard occupies.
- **Client implementation mandates** are out: the WG "can document patterns but not require specific client behavior."

That last one is the real gap. The stated goal is "uniform discovery and consumption **from the server author's perspective**, while leaving room for client-side innovation." So the spec can standardize how a skill is advertised and fetched. It cannot standardize **how a client decides which skill to activate** — the hard problem once a session has two hundred of them available.

> Architectural takeaway: this is the same shape as the progressive-discovery gap in the [Post-Stateless MCP Roadmap](../5.%20AI%20Agents%20&%20Tool%20Use/The%20Post-Stateless%20MCP%20Roadmap%20—%20Agent%20Identity%2C%20Progressive%20Discovery%2C%20and%20One%20Transport.md). Protocol work reliably standardizes *advertisement* and reliably declines to standardize *selection*, because selection is where clients compete. If you are building a harness, assume selection is your problem permanently and budget for it — see [SKILL-ORCHESTRATION-NOTES](./SKILL-ORCHESTRATION-NOTES.md).

---

## 8. Where this stands, by role

| If you are… | Act now | Wait |
|---|---|---|
| An MCP server author | Expose skills as `skill://<path>/SKILL.md` resources today — four implementations and a submitted SEP agree on the shape | Registry-level skill metadata (Registry WG owns the schema) |
| A client / harness author | Identify skills by scheme and `/SKILL.md` suffix, never by list membership. Assume enumeration is incomplete | Nothing — activation logic was never going to be specified for you |
| A skill author | Write to the Agent Skills spec; it is the format authority under both routes | Independent skill versioning |
| Publishing skills organizationally | `/.well-known/agent-skills/index.json` with SHA-256 digests, which is orthogonal to MCP | A bundled plugin story that spans skills + servers + config |

**Caveat on freshness:** the charter's changelog stops at 2026-04-25 and lists weekly Tuesday sessions, while WG meeting records show a bi-weekly cadence by mid-2026. The charter page is a slower-moving document than the work. For current state, read the SEP-2640 pull request and the experimental repo's issue tracker rather than the charter.

## References

- [Model Context Protocol — Skills Over MCP Working Group Charter](https://modelcontextprotocol.io/community/working-groups/skills-over-mcp)
- [SEP-2640 — Skills Extension (Extensions Track, Resources-based)](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2640)
- [SEP-2076 — Agent Skills as a First-Class MCP Primitive](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2076)
- [modelcontextprotocol/experimental-ext-skills — Working Group Experimental Repository](https://github.com/modelcontextprotocol/experimental-ext-skills)
- [Skills Over MCP WG — Approaches Being Explored](https://github.com/modelcontextprotocol/experimental-ext-skills/blob/main/docs/approaches.md)
- [Skills Over MCP WG — Skill URI Scheme Proposal](https://github.com/modelcontextprotocol/experimental-ext-skills/blob/main/docs/skill-uri-scheme.md)
- [Skills Over MCP WG — Draft Skills Extension SEP](https://github.com/modelcontextprotocol/experimental-ext-skills/blob/main/docs/sep-draft-skills-extension.md)
- [agentskills/agentskills — Agent Skills Specification](https://github.com/agentskills/agentskills)
- [Cloudflare — Agent Skills Discovery RFC](https://github.com/cloudflare/agent-skills-discovery-rfc)
