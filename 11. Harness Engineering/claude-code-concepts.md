# Claude Code — core concepts (simple notes)

Plain-English notes on how Claude Code works: the harness, the recap
(context management), memory, and tools. Written to be easy to read.

---

## 1. Model vs. Harness

There are two parts working together.

- **The model (Claude)** = the brain. It only does text in → text out. It
  decides *what* to do.
- **The harness (Claude Code)** = the body and the room. It actually *does*
  the work — open files, run commands, show answers.

A model alone cannot touch your files or run a terminal. The harness gives it
hands.

```
You  ──▶  Harness (Claude Code)  ──▶  Model (Claude)
              │   ▲                        │
              │   └──── decisions ◀────────┘
              ▼
        files, shell, git, tools
```

### What the harness does
1. Takes your message and sends it to the model.
2. Gives the model **tools** (Read, Edit, Bash, Search, etc.).
3. Runs the tool calls and sends results back to the model.
4. Shows the model's answer to you.
5. Manages the **context / recap** (see §2).
6. Enforces **permissions, hooks, and settings**.

When notes say "the harness did X," it means Claude Code itself — not you and
not the model.

---

## 2. Recap (context management / compaction)

The model can only hold a limited amount of text at once — its **context
window**. A long chat (many messages, file reads, command outputs) slowly
fills it.

When the context gets close to full, the harness makes a **recap**: a summary
of the chat so far. The recap replaces the long old history, so the model can
keep working without running out of room.

### How it works
1. The chat grows; everything takes space.
2. The harness sees the context nearing the limit.
3. It writes a recap (summary of key facts, decisions, files changed, current
   task).
4. The next "window" starts with that recap + the most recent messages. Work
   continues — no need to stop or hand off.

### What it keeps
- What we are doing and why.
- Decisions already made (so it won't re-ask).
- Files changed and key findings.
- Open to-dos.

It can lose small early details. So exact things (line numbers, file content)
are safer to re-check than to trust from memory.

### You can control it
- It runs **automatically** when needed.
- `/compact` — trigger it yourself. `/compact <instructions>` tells it what to
  focus on keeping.
- `/clear` — wipe context fully and start fresh (no recap).

---

## 3. Recap vs. Memory (two different things)

| | Recap / compaction | Memory |
|---|---|---|
| Scope | Within one chat session | Across sessions |
| Purpose | Keep a long chat going | Remember durable facts |
| Lifetime | Temporary | Saved to files, survives after the chat ends |

**Memory** is a set of files Claude Code can write (one fact per file) about
you or the project. They are loaded back in later sessions so it remembers
things like your preferences or ongoing work.

Good memory examples: who you are, how you like to work, project goals/constraints.
Not memory: things already in the code or git history.

---

## 4. Tools, permissions, hooks

- **Tools** = the actions the model can take (read/edit files, run shell, search,
  call MCP servers, etc.). The harness runs them and returns the result.
- **Permissions** = rules for what runs without asking. Risky or hard-to-undo
  actions (delete data, force-push, send to external services) should ask first.
  You can allow specific commands so they stop prompting.
- **Hooks** = automatic actions the harness runs on certain events (for example
  "before/after a tool runs" or "when the chat stops"). Useful for "always do X
  when Y happens." These live in `settings.json`.
- **MCP servers** = extra tool providers Claude Code can connect to (e.g. Linear,
  observability, Google Drive). They add more tools on top of the built-in ones.

---

## 5. Quick glossary

- **Model** — the AI brain (Claude). Text in, text out.
- **Harness** — the program that runs the model and does real actions
  (Claude Code).
- **Context window** — how much text the model can hold at once.
- **Recap / compaction** — summarizing a long chat to keep going.
- **Memory** — durable facts saved to files across sessions.
- **Tool** — an action the harness can run for the model.
- **Permission** — rule for what runs without asking first.
- **Hook** — an automatic action on an event.
- **MCP** — a way to plug in extra tools/services.

---

*Note: these describe Claude Code (the harness) behavior, not any one project's
code. For exact, up-to-date details, check the official Claude Code docs.*
