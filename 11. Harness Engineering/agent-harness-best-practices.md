# Agent Harness: Setup Best Practices

> **Status: draft** — discovery notes + best practices, June 2026.
> Sources are listed at the bottom.

## 1. What is a harness?

**Agent = Model + Harness.**

The harness is everything around the model: prompts, tools, config,
permissions, hooks, sandboxes, subagents, and feedback loops.
The model thinks; the harness gives it state, tools, limits, and feedback.

Key idea from the field:

> "A decent model with a great harness beats a great model with a bad harness."

Most agent failures are **harness problems, not model problems**. Before you
blame the model, check the harness: missing instruction, missing tool, missing
feedback signal.

## 2. Core principles

1. **Smallest harness that works.** Start simple. Add a part only when the
   model fails without it. Every harness component encodes an assumption about
   what the model cannot do alone.
2. **Every rule is earned.** Every line in your instructions file should trace
   back to a real failure. Do not write rules "just in case" — noise makes all
   rules weaker.
3. **Feedback beats instructions.** An instruction says "do X". A sensor
   (linter, test, validator) *proves* X happened. Prefer sensors. Make them
   loud on failure and silent on success.
4. **Never let an agent grade its own work.** Agents praise their own output.
   Use a separate evaluator agent, or a deterministic check (tests, lint,
   validation script).
5. **Re-test the harness when models improve.** Each new model removes some
   old weaknesses. Remove harness parts that the model no longer needs —
   otherwise they become overhead.

## 3. Setup checklist — the seven layers

### 3.1 Instructions (AGENTS.md / CLAUDE.md)

- Keep it short (target under ~60 lines per file). Long files get ignored.
- Write conventions the agent cannot guess: package manager, test command,
  protected paths, naming rules.
- Capture the **why**, not only the what. Future sessions will not have the
  original reasoning in context.
- Apply the **ratchet**: when the agent makes the same mistake twice, turn it
  into a permanent rule. Remove rules when a new model makes them redundant.

### 3.2 Skills (progressive disclosure)

- Do not load everything at startup. Skills give the agent instructions,
  scripts, and references **only when needed**.
- One skill = one job, with a clear trigger description ("use when…").
- Put long how-to docs in `references/`, runnable helpers in `scripts/`.
  Keep `SKILL.md` itself short.

### 3.3 Tools

- **Few good tools beat many overlapping tools.** ~10 focused tools work
  better than 50 similar ones.
- If a CLI already exists and is well known (git, gh, psql, curl), prompt the
  agent to use the CLI instead of wrapping it in an MCP server. Models know
  these tools from training.
- Use MCP for things a CLI cannot do: private APIs, auth-gated services.
- **Security:** every MCP server description is trusted text the model reads.
  Vet servers for prompt-injection risk. Never commit auth headers or tokens.

### 3.4 Guardrails (permissions + hooks)

- Block destructive actions by default: force-push, mass delete, DROP TABLE,
  sending data to external services.
- Use lifecycle hooks for hard rules: pre-tool checks, post-edit lint,
  pre-commit validation. Hooks are enforced by the harness; instructions are
  not — if a rule must always hold, make it a hook, not a sentence.
- Run agents in a sandbox when possible: allow-listed commands, network
  isolation, pre-installed runtimes.

### 3.5 Feedback sensors (the most important layer)

- Fast checks pre-commit: lint, type check, unit tests, schema validators.
- Slow checks post-commit / in CI: full test suite, architecture checks,
  AI code review.
- Continuous background: dependency scanning, drift detection, runtime
  monitoring.
- Design rule: **"success is silent, failures are verbose."** A passing check
  prints nothing. A failing check injects the full error text back into the
  agent's loop so it can self-correct.

### 3.6 State and memory

- **Filesystem + git are the memory.** Commits give rollback and history;
  files give durable state across context windows.
- For multi-session work, keep a progress file (e.g. `claude-progress.txt`)
  that records what was done and what is next.
- Hand off between agents with **structured artifacts** (spec files, task
  lists, JSON status), not by replaying conversation history.
- Use JSON for state the agent must not casually rewrite (e.g. a feature
  list). Models are less likely to "fix" a JSON file than a Markdown file.

### 3.7 Verification and evaluation

- Convert "good" into **gradable criteria** with weights, and calibrate the
  evaluator with few-shot examples so scores stay stable.
- The evaluator must **actively use the output** — run the app, click through
  it with a browser tool, take screenshots — not just read the code.
- Feedback must be actionable: point to the file and line, say what is wrong
  and what to change. Pass/fail alone does not help the generator.
- Watch the cost: heavy evaluator loops can cost 10–20x a single agent. Spend
  scaffolding budget on tasks at the edge of model ability, not easy ones.

## 4. Long-running work (many context windows)

Pattern from Anthropic's long-running harness work:

1. **Initializer agent** (first session): sets up the environment, writes
   `init.sh`, creates the progress file, writes a full feature list (all items
   start as "failing"), makes the first commit.
2. **Worker agent** (every later session) follows a startup checklist:
   - check working directory, read git log + progress file
   - run a basic end-to-end smoke test **first**
   - pick ONE highest-priority incomplete feature
   - implement, test, commit with a clear message, update the progress file.
3. **One feature at a time.** Never let the agent try to one-shot everything.
4. **Context resets over compaction** for very long work: a fresh agent
   reading a good handoff artifact beats a tired agent with a summarized
   history. (Newer models reduce this need — re-test per model.)

## 5. Anti-patterns

- ❌ Self-evaluation for long or important work.
- ❌ Instructions-only harness (no sensors) — the agent repeats mistakes.
- ❌ Sensors-only harness (no guides) — the agent rediscovers conventions
  every session.
- ❌ Guides and sensors that disagree (lint says X, AGENTS.md says Y).
- ❌ Over-specified rule files — every extra rule dilutes the rest.
- ❌ Trusting AI-generated tests without checking what they actually assert.
- ❌ Marking work "done" without running it.

## 6. Keep the harness alive (the steering loop)

The harness is a product. Iterate on it:

1. **Observe**: trace every run (what tools were called, what failed, cost,
   latency). Read real traces, not summaries.
2. **Ratchet**: each repeated failure becomes a rule, a hook, or a sensor.
3. **Prune**: on each model upgrade, stress-test old assumptions and delete
   harness parts the model no longer needs.
4. **Direct human input where it matters most**: approvals on irreversible
   actions, judgment on fuzzy quality — not on mechanical checks a sensor can
   do.

## 7. How this maps to our setup (100x / vireox)

| Best practice | Our implementation |
|---|---|
| Short, earned instructions | `CLAUDE.md` / `AGENTS.md` per repo and per team |
| Progressive disclosure | Skills (`skills/<name>/SKILL.md` + `references/` + `scripts/`) |
| Deterministic sensors | `scripts/validate_plugins.py` as the canonical gate |
| Hard enforcement, not prose | pre-commit hook (`.githooks`) running the validator |
| Tool scoping | coordinator access gate (`x-agent-hub.access`), subagent `skills:`/`mcpServers:` allow-lists |
| No secrets in tool config | `.mcp.json` carries only `type` + `url`; auth from the vault |
| Structured handoffs | SDD harness artifacts: spec.md → plan.md → tasks.md with approval gates |
| Observability + traces | observability plugin (SigNoz + Phoenix trace tools, playbooks) |

Gaps worth looking at next: a progress-file convention for multi-session
tasks, and a separate evaluator step for generated teams (today validation is
structural, not behavioral).

## Sources

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness design for long-running application development — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Harness engineering for coding agent users — Martin Fowler](https://martinfowler.com/articles/harness-engineering.html)
- [Agent Harness Engineering — Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)
- [Skill Issue: Harness Engineering for Coding Agents — HumanLayer](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
