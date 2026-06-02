# Vireox (100x) — Linear Activity

> **User:** Thuan AI (`thuan@100xteam.ai`)  
> **Generated:** 2026-06-02  
> **Scope:** 51 issues assigned to the engineer across 5 teams  
> **Window:** 2026-05-12 → 2026-06-02  
> Issue descriptions are the actual body content (Linear list API caps each at 500 chars; longer ones note `get_issue` for the rest).

---

## Overview

- **Total issues:** 51  ·  **Created by me:** 33
- **By status:** ✅ completed 34 · 📋 backlog 6 · 🚫 canceled 4 · 🔵 started 4 · ⚪ unstarted 2 · ♻️ duplicate 1
- **By label:** Bug 17 · v2.16.0 8 · Feature 2 · Improvement 1

| Team | Issues | Completed |
|---|---|---|
| **AIP** — AIPlatform | 34 | 20 |
| **CENG** — Context Eng | 9 | 7 |
| **PENG** — Product Eng | 4 | 3 |
| **INF** — Infrastructure | 2 | 2 |
| **ORG** — Org Agentification | 2 | 2 |

---

## AIP — AIPlatform (34)

### AIP-1 — [LLM] Report Generation Reliability - Background Mode & Timeout Handling
✅ **Done** · Urgent priority · created 2026-05-13 · completed 2026-05-29

> ##  Problem
>
> OpenAI LLM requests are timing out after 15 minutes. This is a recurring issue that has been observed weekly.
>
> ## Impact
>
> * **Severity:** Urgent
> * **Frequency:** Weekly occurrence (increasing frequency recently)
> * Agent sessions fail due to extended request timeouts
> * Affects AI Platform reliability and user experience
>
> ## Reference
>
> * Observability Session: [Session Link](<https://agent-hub.vireox.ai/observability/sessions/24f22d52… (truncated, use `get_issue` for full description)

### AIP-2 — Support dynamic fan-out in workflows where downstream step count depends on upstream output
📋 **Backlog** · Medium priority · created 2026-05-13

> ## Problem
>
> We have a workflow shape where the **number of downstream steps depends on the output of an upstream step**.
>
> ### Concrete example
>
> * **Step 1 (list):** an LLM (or DB query) returns a list of N companies.
> * **Step 2 (analyze):** run an analyzer once per company.
>
> ### Context
>
> Related to: Workflow CAG (with complex loop) → Loop
>
> ## Constraint
>
> `Workflow(steps=[...])` is **fixed at construction time**. We cannot natively declare N sibl… (truncated, use `get_issue` for full description)

### AIP-10 — UI/UX - White Text on White Background - Charlie's Acccount
📋 **Backlog** · Low priority · created 2026-05-13

> `[image]`
>
> This … (truncated, use `get_issue` for full description)

### AIP-13 — [Infra] Isolate sampling runs on multiple agent instances
✅ **Done** · High priority · created 2026-05-14 · completed 2026-05-29

> ## Problem
>
> Currently, sampling runs execute on the same agent instance. When running 5 parallel samples, all 5 runs fail together if the agent instance encounters issues (timeout, network error, etc.).
>
> ## Solution
>
> Isolate sampling runs across multiple agent instances to:
>
> * Prevent single point of failure affecting all parallel runs
> * Improve fault tolerance and reliability
> * Enable independent retry/recovery for each sampling run
>
> ## Impleme… (truncated, use `get_issue` for full description)

### AIP-14 — Databrick timeout
✅ **Done** · Low priority · created 2026-05-12 · completed 2026-05-25 · `Bug`

> Databricks returned 503 error - the service is unavailable.
>
> * [LINK TO DEBUG](<https://staging-agent-hub.100xteam.ai/observability/sessions/f3ac667a-7b28-423d-ad70-503552f257f1>)
>
> 2 requests to handle this issue
>
> * Auto retry at least 2 times with around 1 minute cooldown between failure and retry
> * Increase databrick capacity so it can handle many concurrent query

### AIP-15 — Research: solution options for dynamic fan-out in workflows
📋 **Backlog** · Medium priority · created 2026-05-14

> ## Goal
>
> Research and document the available patterns in Agno for implementing a workflow where the number of downstream steps depends on an upstream step's output (e.g. Step 1 lists N companies, Step 2 runs an analyzer per company), and recommend a default for the team.
>
> ## Constraint that drives all options
>
> `Workflow(steps=[...])` is **fixed at construction time**. You cannot natively declare N sibling steps where N depends on what Step 1 ret… (truncated, use `get_issue` for full description)

### AIP-23 — Agent Hub: Add support for GPT 5.5
✅ **Done** · High priority · created 2026-05-18 · completed 2026-05-18

> ## Summary
>
> Add GPT 5.5 model support to Agent Hub.
>
> ## Context
>
> From Slack discussion: Agent Hub currently does not support GPT 5.5, which is blocking testing of the background mode feature for report generation reliability.
>
> ## Reference
>
> * Related to: [https://linear.app/100xteam/issue/AIP-1/llm-report-generation-reliability-background-mode-and-timeout-handling](<https://linear.app/100xteam/issue/AIP-1/llm-report-generation-reliability-backgr… (truncated, use `get_issue` for full description)

### AIP-24 — Investigate Claude routine - adaptable with report workflow
🚫 **Canceled** · High priority · created 2026-05-18

> Investigate how Claude routines can be made adaptable with the report workflow.
>
> **Context:**
>
> * Related to Claude routine/skills platform initiative
> * Explore integration possibilities and adaptability requirements

### AIP-25 — Sync agent skills to Claude skills platform
🚫 **Canceled** · Low priority · created 2026-05-18

> Sync agent skills to the Claude skills platform.
>
> **Context:**
>
> * Part of Claude routine/skills platform initiative
> * Ensure agent skills are properly integrated and synchronized with the Claude skills platform

### AIP-26 — Investigate agent hub API high/leak CPU
✅ **Done** · Medium priority · created 2026-05-18 · completed 2026-05-18

> Investigate CPU performance issues with the agent hub API.
>
> **Issues to investigate:**
>
> * High CPU usage
> * Potential CPU/memory leaks
>
> **Goals:**
>
> * Identify root cause of high CPU consumption
> * Fix any memory/resource leaks
> * Optimize API performance

### AIP-35 — Upstream agno: contribute lifecycle lock fix for MCPTools parallel connect race
✅ **Done** · Low priority · created 2026-05-19 · completed 2026-05-29 · `Bug`

> ## Summary
>
> Low-priority follow-up to PR <pull-request id="4375e482-b50b-434a-bdce-138acd67018e" href="https://linear.app/100xteam/review/fixagents-serialize-mcptools-connectclose-to-prevent-82d5e7198458">100xteam-ai/100x-agent-hub#406</pull-request>. We patched the `anyio.BrokenResourceError` race in our **vendored fork** of `MCPTools` (`packages/vireox-agents/src/vireox_agents/agent/mcp/mcp_tool.py`) by adding an `asyncio.Lock` around `connect… (truncated, use `get_issue` for full description)

### AIP-36 — [Bug] Fix "document too large" error when saving workflow sessions to database
✅ **Done** · High priority · created 2026-05-19 · completed 2026-05-29 · `v2.16.0`, `Bug`

> ## Problem
>
> When running Management Reports with large amounts of data (many data points across different time periods and multiple store locations), the workflow session becomes too large to save to the database, resulting in the error:
>
> ```
> "document too large"
> ```
>
> This issue was observed in the following report:
>
> * Failed report: [https://agent-hub.vireox.ai/reports/6a0ae48c83a7cad3abcb24c7](<https://agent-hub.vireox.ai/reports/6a0ae48c83a7c… (truncated, use `get_issue` for full description)

### AIP-39 — [Bug] Notification Session ID link is invalid on Report Information page
✅ **Done** · Medium priority · created 2026-05-19 · completed 2026-05-29 · `v2.16.0`, `Bug`

> ## Description
>
> The Notification Session ID link on the Report Information page is invalid/broken. The link does not navigate to the correct observability page.
>
> ## Current Behavior
>
> * Report Session ID link works correctly → navigates to Observability
> * Notification Session ID link is broken/invalid
>
> ## Expected Behavior
>
> The Notification Session ID link should navigate to the correct observability page, similar to the Report Session ID link.
>
> … (truncated, use `get_issue` for full description)

### AIP-46 — Enable pre-indexed KB testing in native Claude
✅ **Done** · High priority · created 2026-05-20 · completed 2026-05-29

> ## Issue
>
> A request was made to test the pre-indexed knowledge base in CAG native Claude after SharePoint access was enabled.
>
> ## Solution
>
> Enable or set up access for testing the pre-indexed KB in Claude CAG MCP.
>
> ## Acceptance criteria
>
> - [ ] Pre-indexed KB is available in CAG native Claude for testing
> - [ ] Testing access is enabled for the requester
> - [ ] The setup is confirmed working

### AIP-55 — Wire pre-indexed KB MCP into the gateway tenant via mcp_servers object form (X-Knowledge-Base-Id header)
✅ **Done** · Medium priority · created 2026-05-20 · completed 2026-05-29

> Subtask of <issue id="fa329487-5d5c-4dbd-bc85-75ab2e83861e" href="https://linear.app/100xteam/issue/AIP-46/enable-pre-indexed-kb-testing-in-native-claude">AIP-46</issue> — concrete step that unblocks the parent's first acceptance criterion ("Pre-indexed KB is available in CAG native Claude for testing").
>
> ## Context
>
> The Knowledge-Base MCP server lives at `apps/onehundredx-knowledge-base-api/src/onehundredx_kb_api/mcp_app.py` and requires every … (truncated, use `get_issue` for full description)

### AIP-56 — [Bug] Rocky Mountain Report Failed
✅ **Done** · Urgent priority · created 2026-05-20 · completed 2026-05-29 · `Bug`

> #### Conversation ID
>
> [https://agent-hub.vireox.ai/reports/6a0d4f60b884e23009ce07b5](<https://agent-hub.vireox.ai/reports/6a0d4f60b884e23009ce07b5>)
>
> #### Issue
>
> Workflow 6a0d4d84b7ac4d2ef9576597 failed after 3 attempts: output contains failed step status
>
> #### Acceptance Criteria
>
> The report should works as stated by the agent
>
> #### Screenshot

### AIP-57 — fix(agents): forward explicit httpx.Timeout to Bedrock Claude SDK
✅ **Done** · Urgent priority · created 2026-05-20 · completed 2026-05-29 · `Bug`

> ## Root cause
>
> The Rocky Mountain report run (workflow `6a0d4d84b7ac4d2ef9576597`) failed because the Bedrock Claude HTTP request hit an `httpcore.ReadTimeout` after \~60 seconds of inter-chunk silence.
>
> Why 60 seconds (not our intended 1500s budget):
>
> 1. `agno` injects its **shared** `httpx.AsyncClient` into every `AsyncAnthropicBedrock` it constructs.
> 2. That shared client is built with `httpx.Timeout(60.0)` — `agno`'s default.
> 3. The Anthropi… (truncated, use `get_issue` for full description)

### AIP-68 — Port CACO + CO3 Pipeline Copilots to Claude plugin marketplace
✅ **Done** · Medium priority · created 2026-05-21 · completed 2026-05-29

> ## Summary
>
> Ported the two most-used LibreChat-source pipeline copilots — **VERIDIAN** (CACO fund, cannabis private credit) and **PRISM** (CO3 fund, opportunistic private credit) — to the [`100xteam-research/100x-ai-plugins`](<https://github.com/100xteam-research/100x-ai-plugins>) Claude plugin marketplace, following Spec-Driven Development.
>
> This is a concrete proof-point for <issue id="af318adc-f712-405f-a82b-0d02c0d6783a" href="https://linear… (truncated, use `get_issue` for full description)

### AIP-69 — 100x-mcp-gateway: enable DCR or CIMD on the cag tenant so MCP plugins drop env.OAUTH_CLIENT_ID
🚫 **Canceled** · Low priority · created 2026-05-21

> ## Why this exists
>
> Today, every plugin in `100x-ai-plugins` that talks to a CAG MCP server has to carry a non-canonical `env.OAUTH_CLIENT_ID` block in its `.mcp.json`:
>
> ```json
> {
>   "caco-knowledge-base": {
>     "type": "http",
>     "url": "https://connector.100xteam.ai/cag/caco-knowledge-base/mcp",
>     "env": { "OAUTH_CLIENT_ID": "77jusa9onf57c8fdajdaj4ltas" }
>   }
> }
> ```
>
> Anthropic's official `claude-plugins-official` catalog does **not** use this… (truncated, use `get_issue` for full description)

### AIP-77 — Support Claude Plugins runtime on our platform
🔵 **In Progress** · High priority · created 2026-05-25

> The goal is for all plugins already built to work on the platform.
>
> Reference docs: [Managed agents](<https://www.anthropic.com/engineering/managed-agents>)
>
> ## Issue
>
> * The platform needs to support Claude Plugins runtime to enable existing plugins to work seamlessly.
> * Currently, there is no infrastructure to host and run Claude plugins on our platform.
> * Need a way to expose plugin functionality via an API endpoint (e.g., `/chat/completions`)… (truncated, use `get_issue` for full description)

### AIP-78 — Migrate workflow session storage from MongoDB to PostgreSQL
✅ **Done** · High priority · created 2026-05-25 · completed 2026-05-29 · `v2.16.0`

> ## Objective
>
> Migrate the workflow session storage from MongoDB to PostgreSQL to eliminate the "document too large" limitation and support saving large workflow sessions.
>
> ## Background
>
> Currently, MongoDB's 16MB BSON document limit causes failures when saving large workflow sessions, particularly for Management Reports with extensive data across multiple time periods and store locations.
>
> ## Tasks
>
> - [ ] Design PostgreSQL schema for workflow se… (truncated, use `get_issue` for full description)

### AIP-79 — Handle OpenAI invalid prompt error gracefully instead of crashing all agents
📋 **Backlog** · — priority · created 2026-05-25 · `Bug`

> ## Issue / Problem Statement
>
> * Agent router fails with error: `Something went wrong. Here's the specific error message we encountered: An error occurred while processing the request: TeamRunError - Schwazze All Agents stopped responding`.
> * Root cause: OpenAI provider returns invalid prompt error: `Invalid prompt: your prompt was flagged as potentially violating our usage policy. Please try again with a different prompt`.
> * This error is not gr… (truncated, use `get_issue` for full description)

### AIP-80 — chore(config): consolidate Python formatter & linter on Ruff
✅ **Done** · Medium priority · created 2026-05-25 · completed 2026-05-29 · `v2.16.0`, `Improvement`

> ## Summary
>
> The repo currently runs **three overlapping Python formatting/lint tools** with redundant configuration, which causes inconsistent local vs. CI behavior and noisy diffs depending on which tool a contributor happens to run:
>
> * `black` (via `psf/black-pre-commit-mirror` v26.3.1) — formatter
> * `isort` (via `pycqa/isort` v8.0.1) — import sorter
> * `ruff` (>=0.14.0, dev dep) — linter **and** also configured with `[tool.ruff.lint.isort]` (i… (truncated, use `get_issue` for full description)

### AIP-83 — Implement 100x Linear plugin (vertical plugin for Claude marketplace)
✅ **Done** · Medium priority · created 2026-05-26 · completed 2026-05-29

> ## Goal
>
> Build a new **vertical plugin** `plugins/vertical-plugins/linear-toolkit/` for the 100x AI plugin marketplace that wraps the Linear MCP and exposes opinionated skills + slash commands for the team's day-to-day Linear workflow.
>
> This is the canonical source for Linear-related skills; downstream agent plugins (e.g. an SDD harness variant) will bundle these skills via `scripts/sync-agent-skills.py`.
>
> ## SDD lifecycle (non-negotiable)
>
> This… (truncated, use `get_issue` for full description)

### AIP-84 — linear-toolkit v0.2: encode VireoX Linear operating guide
✅ **Done** · Medium priority · created 2026-05-26 · completed 2026-05-29

> ## Issue / Problem Statement
>
> `linear-toolkit` v0.1.0 (shipped via <issue id="3e637490-f9bd-449d-8d4b-53fd15fd466b" href="https://linear.app/100xteam/issue/AIP-83/implement-100x-linear-plugin-vertical-plugin-for-claude-marketplace">AIP-83</issue> / specs/0004-add-vertical-linear-toolkit) was written before the VireoX Linear operating guide was finalised. The plugin's skills encode a simpler mental model than the guide demands. Without updating t… (truncated, use `get_issue` for full description)

### AIP-85 — Build 100x-engineering-skills vertical plugin (skills counterpart to SDD harness)
📋 **Backlog** · Medium priority · created 2026-05-26 · `Feature`

> ## Summary
>
> Build a new **vertical plugin** `plugins/vertical-plugins/100x-engineering-skills/` that ships opinionated, always-on **agent skills** for craft-level discipline — verification before completion, systematic debugging, test-driven development, git worktree hygiene, and 100x-specific PR conventions. It's the **skills counterpart** to `100x-sdd-harness` (<issue id="b45719b3-e257-4f4f-9650-d5976c120080" href="https://linear.app/100xteam/… (truncated, use `get_issue` for full description)

### AIP-94 — Init agent runtime MVP implementation (Deep-first)
🔵 **Finish Development** · Medium priority · created 2026-05-28

> ## Issue / Problem Statement
>
> We need a concrete implementation-start ticket to initialize the new agent runtime on our platform with the approved Deep-first architecture.
>
> Design and discovery are in place, but engineering work needs one executable ticket that anchors MVP delivery for API ingress, Deep loop, sandbox execution, credential loading, plugin path mapping, persistence, and observability.
>
> ## Proposed Solution
>
> Start with an MVP runti… (truncated, use `get_issue` for full description)

### AIP-96 — RFC 9728: per-server PRM in 401 + protected_resources on AS (100x-mcp-gateway PR #8)
✅ **Done** · Medium priority · created 2026-05-28 · completed 2026-05-29

> ## Issue / Problem Statement
>
> Production MCP connector (`/cag/...`) advertised the **tenant aggregate** PRM URL in `WWW-Authenticate` `resource_metadata` on 401. Multi-server tenants then returned `resource` as an **array** on that PRM document. Strict MCP clients (Python SDK, agent runtimes) expect `resource` to be a **string** per RFC 9728 §3.1.
>
> ## Proposed Solution
>
> Ship <pull-request id="49ef2385-e417-4ef0-83fb-615cdbb1fc86" href="https://l… (truncated, use `get_issue` for full description)

### AIP-99 — Port VireoX AskData agent to 100x-ai-plugins marketplace
✅ **Done** · Medium priority · created 2026-05-29 · completed 2026-05-29

> ## Issue / Problem Statement
>
> [AIP-77](<https://linear.app/100xteam/issue/AIP-77/support-claude-plugins-runtime-on-our-platform>) requires existing Claude marketplace plugins to run on the platform. **VireoX AskData** (`agent_VRdpknFj90O4ygVpoLFLF` on [Agent Hub](<https://agent-hub.vireox.ai/ai-gateway/agents/agent_VRdpknFj90O4ygVpoLFLF>)) is a high-usage retail analytics agent that today only exists in the LibreChat / Agent Hub runtime.
>
> We nee… (truncated, use `get_issue` for full description)

### AIP-101 — Fix structured_retrieve runtime init error on knowledge base
✅ **Done** · — priority · created 2026-05-29 · completed 2026-06-01

> `structured_retrieve` is intermittently failing on the knowledge-base backend.
>
> Observed error:
> `internal_error: Error building agent runtime for agent 6e5bd1b8-2b96-4d0d-b6ef-d818d947dfdc: RuntimeDb not initialized -- call initialize_agno_runtime() first`
>
> This was seen while querying the workbook `May 2026 Holding Report Fund IV and IV (a).xlsx` with `cardId` `016CMDZWJTBKBEABQMLJALMNJAA7WJLGNK`.
>
> The issue appears to be backend-related on the… (truncated, use `get_issue` for full description)

### AIP-103 — Add components architecture diagram
🔵 **In Progress** · Medium priority · created 2026-06-02

> ## Issue / Problem Statement
>
> * The runtime planning docs in `docs/components/` describe harness abstractions H1–H11 but there is no single visual of how they connect.
> * Contributors cannot see request flow (HTTP → Agent SDK → plugins → sessions → models → observability) at a glance.
> * Slows design review and onboarding during Phase 0.
>
> ## Proposed Solution
>
> * Add a components architecture diagram covering H1–H11 from `docs/components/00-harness… (truncated, use `get_issue` for full description)

### AIP-104 — Add data schema
⚪ **Todo** · Medium priority · created 2026-06-02

> ## Issue / Problem Statement
>
> * Session persistence is proposed on `Postgres` (the `postgres_session_store.py` pattern from <issue id="f08e4867-6acd-409b-b5fb-19244f51520a" href="https://linear.app/100xteam/issue/AIP-77/support-claude-plugins-runtime-on-our-platform">AIP-77</issue>) but the data schema is undefined.
> * Without a schema, conversation-state and session storage cannot be implemented or reviewed.
>
> ## Proposed Solution
>
> * Define the d… (truncated, use `get_issue` for full description)

### AIP-107 — Brain (H2) abstraction layer — make the stateless brain swappable
📋 **Backlog** · Medium priority · created 2026-06-02

> ## Issue / Problem Statement
>
> Following spec `003-brain-terminology` (D-008), the **brain** is the stateless model-calling loop (H2), now living in `runtime/brain/`. Today the runtime is hard-wired to one concrete brain — `DeepRuntimeRunner` (wraps `create_deep_agent`) — instantiated directly in `runtime/main.py` and typed directly in `runtime/api/chat.py`.
>
> There is no seam that lets us **replace the brain implementation** (e.g. a different age… (truncated, use `get_issue` for full description)

### AIP-111 — Improve user experience for viewing report error details
⚪ **Todo** · — priority · created 2026-06-02

---

## CENG — Context Eng (9)

### CENG-5 — HTML Failure - Charlie's Report - May 13th
✅ **Done** · Urgent priority · created 2026-05-13 · completed 2026-05-29 · `Bug`

> [https://agent-hub.vireox.ai/reports/6a03c60e6895dc6dc5f73672](<https://agent-hub.vireox.ai/reports/6a03c60e6895dc6dc5f73672>)

### CENG-6 — Failure to send reports on yesterday report delivery status
✅ **Done** · Urgent priority · created 2026-05-13 · completed 2026-05-13 · `Bug`

> ## Overview
>
> Unknown issue. Need <user id="a8f740ea-60a4-4c89-8e7d-8c11bf4bbb85">thuan</user> to investigate and propose solution
>
> [Link to debug](<https://agent-hub.vireox.ai/reports/6a03efa83d2ffc83c15feaa8>)
>
> ---
>
> ## Root Cause Analysis
>
> **Issue:** Background job MCP returning 401 authentication error
>
> **Observability Link:** [https://agent-hub.vireox.ai/observability/sessions/efc25b61-3579-4a52-869f-4239137787a3](<https://agent-hub.vireox.ai… (truncated, use `get_issue` for full description)

### CENG-8 — Rocky Mountain - Report / Workflow Not Found on Agent Hub
✅ **Done** · Urgent priority · created 2026-05-13 · completed 2026-05-13 · `Bug`

> <user id="a8f740ea-60a4-4c89-8e7d-8c11bf4bbb85">thuan</user> need your help to investigate why this user has a conversation to generate a report but searching in the report/workflow tab shows he has created nothing. 
>
> Conversation: 
> [https://agent-hub.vireox.ai/librechat/conversations/015e181d-3110-425a-acb4-e5dbbd4a021f](<https://agent-hub.vireox.ai/librechat/conversations/015e181d-3110-425a-acb4-e5dbbd4a021f>)
>
> Report Tab: 
>
> `[image]`

### CENG-9 — Fix case-sensitive issue when searching workflow by email
✅ **Done** · Medium priority · created 2026-05-13 · completed 2026-05-13

> ## Problem
>
> When searching for workflows by email on Agent Hub, the search is case-sensitive. This causes workflows to not be found if the email case doesn't match exactly.
>
> ## Context
>
> Related to <issue id="6deb4eb7-093f-4871-84ef-f860cfaeb008" href="https://linear.app/100xteam/issue/CENG-8/rocky-mountain-report-workflow-not-found-on-agent-hub">CENG-8</issue> (Rocky Mountain - Report / Workflow Not Found on Agent Hub) where a workflow was not i… (truncated, use `get_issue` for full description)

### CENG-90 — [Bug] Unable to view session; session does not show router delegating to sub agents
♻️ **Duplicate** · Medium priority · created 2026-05-25 · `Bug`

> 1. [https://agent-hub.vireox.ai/librechat/conversations/522661ee-1487-4115-85d8-2d5cd46eb0e0](<https://agent-hub.vireox.ai/librechat/conversations/522661ee-1487-4115-85d8-2d5cd46eb0e0>)
> 2. [https://agent-hub.vireox.ai/librechat/conversations/52b13376-6fa3-4047-9129-314de4e65241](<https://agent-hub.vireox.ai/librechat/conversations/52b13376-6fa3-4047-9129-314de4e65241>)
>
> Current finding: there is not enough information yet to identify the root ca… (truncated, use `get_issue` for full description)

### CENG-98 — [BUG] Router unable to query data
✅ **Done** · High priority · created 2026-05-25 · completed 2026-05-29 · `v2.16.0`, `Bug`

> conversation on may 18th but the agent is not able to query data from may 10th to may 16th. 
>
> Conversation:
> [https://agent-hub.vireox.ai/observability/sessions/c3af4c3a-fd8e-4656-93d3-21e20b006962](<https://agent-hub.vireox.ai/observability/sessions/c3af4c3a-fd8e-4656-93d3-21e20b006962>)
>
> Impacted session ID: 
> c3af4c3a-fd8e-4656-93d3-21e20b006962
>
> `[image]`

### CENG-100 — Agent hallucinates current date instead of using actual system time
✅ **Done** · Medium priority · created 2026-05-25 · completed 2026-05-29 · `v2.16.0`, `Bug`

> ## Issue / Problem Statement
>
> * Agent incorrectly reports current date as `2026-04-13` when actual date is `2026-05-17`.
> * The `from_date` context variable shows the hallucinated date instead of the real system time.
> * This causes incorrect date-based queries and data retrieval failures.
> * Reported by thuan in Slack thread on parent ticket <issue id="74622247-dba1-49cc-b403-847aca8a320e" href="https://linear.app/100xteam/issue/CENG-98/bug-router… (truncated, use `get_issue` for full description)

### CENG-127 — VireoX is not converting data into tables
✅ **Done** · Urgent priority · created 2026-05-25 · completed 2026-05-29 · `Bug`

> VireoX is not converting data into tables
>
> ---
>
> ## Root cause (investigated 2026-05-26)
>
> **Not a data/query failure.** Production observability shows the backend completed successfully; the user-visible issue is **chat UI rendering** of the agent's table output.
>
> ### Evidence
>
> | Item | Value |
> | -- | -- |
> | **trace_id** | `42e9845e7ee6c2e391d9cd5b8019c8de` |
> | **conversation_id** | `ff67d165-f921-44ce-af0c-23102edb346b` |
> | **Started** | 2026-05… (truncated, use `get_issue` for full description)

### CENG-279 — [BUG] All Rocky Mountain Retail Report Failed
🔵 **Ready for Test** · Urgent priority · created 2026-06-01 · `Bug`

> [https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be61](<https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be61>)
> [https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be5f](<https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be5f>)
> [https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be60](<https://agent-hub.vireox.ai/reports/6a1d6d3c9cb4d43c8ce0be60>)

---

## PENG — Product Eng (4)

### PENG-86 — [LibreChatSync] feat: Add timezone to tool Placeholder
✅ **Done** · — priority · created 2026-05-12 · completed 2026-05-13

### PENG-103 — [Reports] Switch sampling agent model to Gemini
🚫 **Canceled** · — priority · created 2026-05-12

### PENG-219 — Release v2.15.0 — 100x-agent-hub
✅ **Done** · High priority · created 2026-05-25 · completed 2026-05-25

> ## Issue / Problem Statement
>
> * Production needs the latest `100x-agent-hub` changes bundled and deployed.
> * Two feature areas ready for release: Observability MCP and model timeout improvements.
> * Current agent timeouts use a hardcoded 1500s OpenAI constant, causing issues with Bedrock Claude and Vertex Gemini clients.
>
> ## Proposed Solution
>
> * Merge PR #418 into `main` and tag `v2.15.0`.
> * **Observability MCP**: new MCP integration for observab… (truncated, use `get_issue` for full description)

### PENG-238 — Implement Claude Opus 4.8 in Agent Hub
✅ **Done** · Medium priority · created 2026-05-29 · completed 2026-05-29 · `v2.16.0`, `Feature`

> ## Issue / Problem Statement
>
> * Librechat has enabled Claude Opus 4.8 (`us.anthropic.claude-opus-4-8`).
> * Agent Hub does not yet support this model.
> * Users cannot access the latest Opus model capabilities through Agent Hub.
> * Reported by <user id="d9f6cbf3-2d90-4a45-9b32-e36a7114fe92">vinh</user>.
>
> ## Proposed Solution
>
> * Add `us.anthropic.claude-opus-4-8` to the list of available models in Agent Hub.
> * Update model configuration/registry to in… (truncated, use `get_issue` for full description)

---

## INF — Infrastructure (2)

### INF-3 — [AgentHub] CVE-2026-42284 — GitPython
✅ **Done** · High priority · created 2026-05-18 · completed 2026-05-19

> ## Summary
>
> | Field | Value |
> | -- | -- |
> | **CVE ID** | `CVE-2026-42284` |
> | **Package** | `GitPython` |
> | **Installed Version** | `3.1.46` |
> | **Fixed Version** | `3.1.47` |
> | **CVSS Score** | 9.0 |
> | **Severity** | **CRITICAL** |
> | **Repository** | `100x-agent-hub` |
> | **Package Manager** | `python` |
> | **First Detected** | 2026-05-09 |
> | **Last Updated** | 2026-05-14 |
>
> ## Description
>
> GitPython is a python library used to interact with Git … (truncated, use `get_issue` for full description)

### INF-4 — [AgentHub] Health check
✅ **Done** · Low priority · created 2026-05-19 · completed 2026-05-19

> #### Ticket Kind
>
> Bug / Issue / Incident
>
> #### Context / Problem Statement / Request
>
> Agent Hub container health check show error `ERROR - MongoDB health check failed`:
>
> ```
>
> 2026-05-19 02:33:22,000 [prod|Vireox Agent Hub] - vireox_common_libs.db.postgres - INFO - Database health check passed
> 2026-05-19 02:33:22,001 [prod|Vireox Agent Hub] - vireox.api.v1.health - INFO - PostgreSQL health check result: True
> 2026-05-19 02:33:22,001 [prod|Vireox A… (truncated, use `get_issue` for full description)

---

## ORG — Org Agentification (2)

### ORG-3 — Fix HTML DOCTYPE extraction to support XHTML transitional
✅ **Done** · High priority · created 2026-05-25 · completed 2026-05-29 · `v2.16.0`, `Bug`

> ## Issue
>
> The system extracts HTML content by looking for the tag `<!DOCTYPE html>`, but some reports generate XHTML transitional DOCTYPE:
>
> ```
> <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
> ```
>
> This causes the system to fail to extract the report HTML content, resulting in emails not being sent.
>
> ## Acceptance Criteria
>
> * Update the HTML extraction logic to handle both … (truncated, use `get_issue` for full description)

### ORG-6 — [Question] Can Prolific AI with Claude based agents generate workflows/reports yet?
✅ **Done** · Medium priority · created 2026-05-27 · completed 2026-05-29 · `Bug`

> From a previous discussion, we discovered that directly interacting with Claude-based agents to generate report was not feasible but there was a bypass by using the Agent Router (running GPT) to get the workflow needed.
>
> Has there been any new developments on this front?
>
> ---
>
> ## Update (May 27, 2026)
>
> **Related Ticket:** [PENG-142](<https://linear.app/100xteam/issue/PENG-142/claude-bedrock-issues-on-staging-environment>) - Claude Bedrock issues… (truncated, use `get_issue` for full description)

---
