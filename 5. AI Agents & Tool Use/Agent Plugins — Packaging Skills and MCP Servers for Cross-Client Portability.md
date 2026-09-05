# Agent Plugins — Packaging Skills and MCP Servers for Cross-Client Portability

> Source: [Agent Plugins Specification](https://agent-plugins.org/specification), [Enchanter — Agent Plugins: An Open Standard for Skills and MCP](https://enchanter.gg/en/blog/agent-plugins-open-standard-skills-mcp)
> Companion to [The Agent Protocol Stack — MCP, A2A, AGENTS.md](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md) and [11.4. Skills](../11.%20Harness%20Engineering/11.4.%20Skills.md)

Agent Plugins 1.0, announced 2026-08-06 and co-authored by OpenAI with AWS, Microsoft (GitHub + VS Code), Cursor (Anysphere), and Vercel — Google joined as a Core Maintainer 2026-08-13 — is not a new protocol. It is a **container format**. It takes two primitives that already had their own specs (Agent Skills for procedures, MCP for tool/data access) and defines the single directory-plus-manifest shape a client downloads, verifies, and loads without re-packaging. The problem it targets is distribution, not capability: "the problem is no longer creating capabilities, it's distributing them." Before this standard, a developer who built one capability — say, a code-review procedure that also needs a GitHub MCP server — packaged it once for ChatGPT, again for Cursor, again for VS Code, again for GitHub, each with its own manifest shape, naming rules, and install path.

---

## 1. Where this sits relative to the protocol stack

This repo's [Agent Protocol Stack](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md) note frames three "↔" relationships: MCP (agent↔tools), A2A (agent↔agent), AGENTS.md (human↔agent). Agent Plugins does not add a fourth relationship — it doesn't move bytes between an agent and anything at runtime. It sits **above** the MCP layer and the Skills primitive, standardizing how the artifacts that configure those two things travel between machines.

```text
   Distribution layer:   Agent Plugins  (plugin.json + skills/ + mcp.json)
                                 │  packages
             ┌───────────────────┴───────────────────┐
             ▼                                        ▼
   Skills (procedure, "how")              MCP server config (tools, "what")
   SKILL.md — loaded contextually          agent ↔ tools, per protocol stack
```

> Architectural takeaway: MCP solved "agent → tool" interop. Agent Skills solved "how does an agent load a capability's instructions." Neither solved "how do I ship one artifact that works unmodified across five different agent clients that each have their own plugin system." Agent Plugins is the missing packaging layer — it doesn't compete with MCP or Skills, it makes both of them portable as a single unit.

Put differently: MCP and Skills are the *what* (a tool call, a procedure). Agent Plugins is the *how it travels* — the same distinction as a language runtime versus the package manager that ships code written in it.

---

## 2. The manifest: `plugin.json`

Every plugin is a directory with a manifest at the root:

```text
my-plugin/
├── plugin.json
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
└── mcp.json          (optional)
```

`plugin.json` fields:

| Field | Required | Notes |
|---|---|---|
| `$schema` | yes | Must equal `https://agent-plugins.org/schemas/1.0.0/plugin.schema.json` — pins the spec version |
| `name` | yes | 1–64 chars, lowercase alphanumeric + `-`/`.`, first/last char alphanumeric, no consecutive `-`/`.` |
| `version` | no | SemVer recommended — the plugin's own version, distinct from the spec version |
| `description` | no | Free text |
| `author` | no | `name` / `email` / `url` |
| `homepage`, `repository` | no | URLs |
| `license` | no | SPDX identifier recommended |
| `keywords` | no | Array, for discovery/search |
| `extensions` | no | Client-specific data under reverse-domain namespaces |

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "acme.tools",
  "version": "1.2.0",
  "description": "Code review skill + GitHub MCP server",
  "license": "MIT",
  "extensions": {
    "com.cursor.autoActivate": true
  }
}
```

The `name` constraint (`acme.tools`, `my-plugin`) is a lowest-common-denominator identifier: it has to be a valid path segment, a valid npm-adjacent package name, and a valid URL component simultaneously, because a plugin name ends up embedded in filesystem paths, registry URLs, and client-side lookup keys across five-plus independently-built clients. That's a narrower charset than any single client would have needed on its own — the cost of designing for the intersection, not the union, of five ecosystems.

---

## 3. Two version numbers, not one

The spec separates **specification version** from **plugin version**, and conflating them is the most common mistake when reading a `plugin.json` for the first time.

| | What it versions | Where it lives | Who bumps it |
|---|---|---|---|
| Specification version | The manifest schema + validation rules themselves | `$schema` URL (`.../1.0.0/plugin.schema.json`) | The standards body (OpenAI + co-maintainers) |
| Plugin version | This specific plugin's own releases | `version` field (SemVer) | The plugin author |

A client reads `$schema` first to decide *how* to parse the rest of the file — which fields are legal, which are required — then reads `version` to decide *whether this copy is stale* relative to a registry. Confusing the two means asking "is this plugin new enough?" against the wrong number, or worse, trying to validate a 1.0.0-shaped manifest against 2.0.0 rules because a client assumed the URL was decorative.

> Why it matters: pinning validation rules to a versioned schema URL, not to a bare `"apiVersion": "1.0"` string, means the schema itself is machine-fetchable and diffable. A client that has never seen spec 1.1 can still detect "this manifest declares a schema I don't recognize" and fail closed instead of silently misparsing new fields.

---

## 4. The `extensions` escape hatch

`extensions` is a namespaced bag for client-specific data: `com.cursor.foo`, `com.microsoft.vscode.bar`. A client reads its own namespace and ignores everyone else's. This is the same reverse-domain pattern used across the protocol stack to let vendors extend a shared format without forking it.

| Format | Escape hatch | Namespace shape |
|---|---|---|
| Agent Plugins `plugin.json` | `extensions` object | Reverse-domain key (`com.cursor.foo`) |
| MCP tool/resource metadata | `_meta` field | Reverse-domain key, same convention (see [MCP App Lifecycle](./MCP%20App%20Lifecycle%20—%20Protocol%20Phases%20from%20Discovery%20to%20Teardown.md) on `_meta.ui.*`) |
| Kubernetes objects | `annotations` | Reverse-domain key by convention |

> Architectural takeaway: a portable core plus a namespaced escape hatch is the standard move for any format five-plus independent vendors co-author. It lets Cursor ship a `com.cursor.autoActivate` field next quarter without asking Microsoft's permission, and it lets a client that has never heard of that field skip it safely — unknown keys under `extensions` are never validated against the core schema, so they can't break portability for everyone else.

---

## 5. What v1.0 deliberately leaves out

The spec packages exactly two things: Agent Skills and MCP server configs. Hooks, slash commands, and other client-specific extension points are explicitly **not** part of the portable core in v1.0 — they're reachable only by stuffing client-specific data into `extensions`, which means they don't travel to a client that doesn't already know that namespace.

This is a scope decision, not a gap the authors missed:

- Skills and MCP configs are the two things that are *already* independently specified and *already* implemented by multiple clients — packaging them costs little design risk.
- Hooks and slash commands vary enormously across clients (see [11.5. Hooks, Permissions, and Side Effects](../11.%20Harness%20Engineering/11.5.%20Hooks%2C%20Permissions%2C%20and%20Side%20Effects.md) and [11.6. Slash Commands and Subagents](../11.%20Harness%20Engineering/11.6.%20Slash%20Commands%20and%20Subagents.md) for how much client-specific plumbing sits behind what looks like the same feature name) — standardizing them now would mean either picking one client's model as canonical or shipping a lowest-common-denominator abstraction nobody's happy with.
- A narrow, shippable v1.0 with a defined extension mechanism for everything else beats a comprehensive v1.0 that takes another year to get five vendors to agree on.

> Lesson: this is the same playbook MCP itself followed. MCP shipped narrow (tools, resources, prompts) and grew scope later through SEPs — see [MCP Goes Stateless](./MCP%20Goes%20Stateless%20—%20The%202026-07-28%20Release%20Candidate.md) and [The Post-Stateless MCP Roadmap](./The%20Post-Stateless%20MCP%20Roadmap%20—%20Agent%20Identity%2C%20Progressive%20Discovery%2C%20and%20One%20Transport.md) for what got added later and how. A standards body that ships a small interoperable core now, with an explicit escape hatch for what's still contested, has a track record of expanding scope in an orderly way rather than never expanding at all.

---

## 6. What actually changes for a plugin author

Before Agent Plugins, shipping "a code-review skill backed by a GitHub MCP server" to N clients meant N manifests, N naming schemes, N install flows. After it:

```text
Before:  1 capability × N clients = N packages, N manifest formats
After:   1 capability × 1 plugin.json = N clients read the same directory
```

The unit of shipping becomes the plugin directory itself. A client that implements the spec can discover, validate (`$schema` match), and install any conforming plugin without client-specific glue — the same value proposition MCP delivered for tool calls, applied one layer up, to the packaging problem.

> Why it matters: this only pays off if clients actually converge on reading `plugin.json` as the install unit instead of maintaining their own marketplace format alongside it. The co-maintainer list (OpenAI, AWS, Microsoft, Cursor, Vercel, Google) is the signal that the convergence is real rather than aspirational — five-plus companies that each already had a competing plugin system chose to standardize the packaging layer instead of the systems underneath it.

---

## 7. Practical checklist

When packaging a capability as an Agent Plugin:

1. Put `SKILL.md` under `skills/<name>/`, one directory per skill, matching the Agent Skills shape from [11.4. Skills](../11.%20Harness%20Engineering/11.4.%20Skills.md).
2. Put any MCP server config the skill depends on in `mcp.json` at the plugin root — don't bury tool wiring inside the skill's own files.
3. Set `$schema` explicitly and pin it to the spec version you validated against; don't hand-roll a manifest without it.
4. Reserve `extensions` for genuinely client-specific behavior (auto-activation, UI hints). If a field is useful to every client, argue for it in the core schema instead of hiding it in a namespace.
5. Treat `version` (your plugin) and the spec version pinned in `$schema` as two independent numbers when writing release notes or a changelog — don't bump one when you meant the other.

---

## References

- [Agent Plugins Specification](https://agent-plugins.org/specification)
- [Enchanter — Agent Plugins: An Open Standard for Skills and MCP](https://enchanter.gg/en/blog/agent-plugins-open-standard-skills-mcp)
