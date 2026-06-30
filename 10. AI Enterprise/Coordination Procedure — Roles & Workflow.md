# Coordination Procedure — AI Knowledge System

> How **end users**, **domain experts**, and the **AI/IT team** coordinate to build, ship, and use
> shared AI skills & knowledge.

**The shape:** end users surface needs → domain experts build (no technical team in the loop) → AI/IT +
CI ship org-wide → everyone benefits automatically. Peer/CI review keeps quality; AI/IT owns only setup,
governance, and harder escalations.

## Roles at a glance

| Role | Who | Primary tool | Owns |
|------|-----|--------------|------|
| **End User** | every employee | **Cowork** | *using* skills for daily work; reporting gaps |
| **Domain Expert** | process owner per function | **Claude Code (desktop)** | *authoring & fixing* skills; content correctness |
| **AI / IT Team** | platform / enablement | full stack | setup, publishing, governance, connectors, security |

## The core loop

```
End User ──report gap / bug──▶  Intake queue  ──▶  Domain Expert
                                                     │  author / fix in Claude Code (git via PR)
                                                     ▼
                                             Peer review + CI checks
                                                     │  merge
                                                     ▼
                                  AI/IT + CI: publish org plugin (versioned)
                                                     │  auto-install
                                                     ▼
End User ◀── new / updated skill, no action needed ── everyone's Cowork
```

## Workflows

**A — Use & report (End User)**
1. Run a skill in Cowork to do the work.
2. If a skill is **missing or wrong**, file a request: *what you tried* + *what happened*.
3. The request lands in the intake queue. No git, no authoring — just report.

**B — Author / adjust a skill (Domain Expert)**
1. Pick up a request from the queue.
2. Author/edit the skill **in Claude Code** — it handles git (commit + PR) for you.
3. **Test** it on a real case.
4. Open the PR → **peer review** (another expert) + **CI checks** (lint/validate).
5. On merge, the plugin re-publishes automatically.

**C — Ship to everyone (AI/IT + automation)**
1. CI **packages + version-bumps** the org plugin on merge.
2. The **org plugin auto-installs/updates** for all members.
3. End users get the new/updated skill — **no action**.

**D — Setup & govern (AI/IT)**
- *One-time:* provision the `ai-knowledge` repo + plugin, set up Claude Code for experts (scoped, git
  auth, `/new-skill`), wire connectors, set permissions.
- *Ongoing:* security review, connector/auth management, breaking-change gate, plugin releases.

## Responsibilities (RACI)

*R = does it · A = accountable · C = consulted · I = informed*

| Activity | End User | Domain Expert | AI/IT |
|----------|:--:|:--:|:--:|
| Use skills daily | **R** | – | – |
| Report gaps / bugs | **R** | I | I |
| Author / adjust a skill | I | **R/A** | C |
| Peer-review a skill | – | **R** | C |
| Define shared facts (`company-definitions`) | C | **R/A** | C |
| Publish the org plugin | – | I | **R/A** |
| Connectors / auth / security | – | I | **R/A** |
| Breaking-change approval | – | C | **R/A** |

## Escalation

| Situation | Goes to |
|-----------|---------|
| Need a new data source (CRM/DB/BI) | **AI/IT** (connectors) |
| Auth / permission / security question | **AI/IT + Security** |
| Rename/remove a skill others depend on (breaking) | **AI/IT** (hard gate) |
| A skill keeps failing | **Domain Expert** (content) → **AI/IT** if infra |

## Cadence

- **Continuous:** users report; experts pick up.
- **Weekly:** triage the request queue · review & merge PRs · release the plugin.
- **As needed:** AI/IT for connectors and escalations.

## One line per role

- **End user:** use skills, report gaps. *(Cowork)*
- **Domain expert:** author & fix skills, review peers. *(Claude Code)*
- **AI/IT:** set up once, publish, govern, connect data. *(full stack)*

## References

- [Centralized Knowledge for AI — Rollout Plan](Centralized%20Knowledge%20for%20AI%20—%20Rollout%20Plan.md)
- [Centralized Knowledge for AI — Solution Architecture](Centralized%20Knowledge%20for%20AI%20—%20Solution%20Architecture.md)
