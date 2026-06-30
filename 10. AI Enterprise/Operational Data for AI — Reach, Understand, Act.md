# Operational Data for AI — Reach, Understand, Act (Claude-first)

> Deep-dive companion to *Centralized Knowledge for AI — Comprehensive* (this folder), expanding the
> **Operational data** pillar. Operational data = live, structured business data in systems of record:
> CRM, SQL databases, data warehouses, BI. Researched Claude-first; facts current as of mid-2026.

---

## 1. What operational data is — and why it's different

Documents are self-describing prose you can sync as files. Operational data is the opposite on every
axis, and three properties drive the entire design:

| Property | Consequence |
|----------|-------------|
| **Live** | No syncable snapshot — the truth changes by the second. The integration must read it *now*. |
| **Structured, not self-describing** | A column `cust_st` could be "state" or "status." Meaning (units, enums, joins, business terms) lives **outside** the rows — so the agent must *understand* before it queries. |
| **System of record** | Writes are high-stakes (a posted journal entry, a changed deal stage). Write ≠ "edit a doc"; it must be gated. |

So the work splits into three jobs, in order: **reach** it (§2), **understand** it (§3–4), then **act**
on it (§5), all under **governance** (§6).

> **First principle (connect, don't copy):** keep the canonical copy in the source system; the agent
> reaches in live. A nightly CSV/Parquet export into a synced folder can speed heavy offline analysis,
> but it is a **stale snapshot**, not the system of record.

---

## 2. The reach — MCP only (no filesystem path)

Operational data is the **mirror image of documents**: there is no sync/mount path. The **MCP server
*is* the integration** — it exposes tools to query and (sometimes) write, and nothing materializes
locally. Write is per-connector and inherits the source system's own permissions.

| Category | System | MCP server | Write capability | Notes |
|----------|--------|-----------|------------------|-------|
| **CRM** | HubSpot | official HubSpot connector | ✅ create/update records, log notes/tasks (**no delete**) | per-action approval + audit log; respects HubSpot permissions |
| **CRM** | Salesforce | `@salesforce/mcp` (60+ tools) | ✅ SOQL + CRUD + bulk, bi-directional | toolsets selectable; org auth via flags; some tools non-GA |
| **Database** | Postgres / SQL | Postgres MCP Pro (Crystal DBA) | ⚙️ `--access-mode=restricted` (read-only) vs unrestricted (DDL/INSERT/UPDATE) | also `EXPLAIN` analysis, index advice, health checks |
| **Warehouse** | Snowflake | **official managed MCP** (GA Nov 2025) | ⚙️ via role privileges | Cortex Analyst / Search / Agents + direct SQL; RBAC, masking & policies inherited; OAuth 2.0. *(Older `Snowflake-Labs/mcp` is deprecated — use the managed server.)* |
| **Warehouse** | Google BigQuery | managed remote MCP (Preview, early 2026) | ⚙️ via IAM | `execute_sql` + dataset/table metadata tools |
| **Warehouse** | Databricks | managed MCP: Genie / SQL / Unity Catalog / Vector Search | ⚙️ via Unity Catalog perms | Genie = NL→SQL over governed data |
| **BI** | Qlik | official Qlik MCP Server | ⚙️ query + load scripts/automation; create sheets/charts | generates a **business glossary**; acts **as the user** (Section Access enforced) |
| **Multi-DB** | many | Google **MCP Toolbox for Databases** (`googleapis/mcp-toolbox`) | ⚙️ prebuilt + custom tools | safe NL2SQL across BigQuery, AlloyDB, Cloud SQL, Postgres, MySQL, Spanner, … |

**Build your own** when no connector fits, or when you want a *curated* surface instead of raw SQL: a
small MCP server in front of the database exposing a few well-defined tools (`search_schema`,
`run_query`, `get_metric`) is often safer and more accurate than handing the model arbitrary SQL.

---

## 3. Understand before you act — the core discipline

Because structured data is **not self-describing**, schema alone isn't enough; the agent needs a
**semantic layer**. Run a **read-first, write-last** flow — five steps, each cheaper than guessing:

```
1. Orient   → schema + semantics   (what tables/columns exist, and what they MEAN)
2. Ground   → sample + profile      (what the data actually looks like)
3. Verify   → read-only query       (does my understanding produce sane results?)
4. Propose  → draft the write       (show what will change; dry run)
5. Execute  → gated mutation        (approval, transaction, audit)
```

### 3.1 Orient — schema introspection + the semantic layer

- **Schema introspection** (the floor): list tables, columns, types, primary/foreign keys, indexes.
  Necessary but insufficient — names are cryptic and relationships ambiguous.
- **The semantic layer** (what turns schema into *understanding*): business definitions that map terms
  like "active customer," "MRR," or "churn" to concrete columns and joins. Sources:
  - **Column/table comments & a data dictionary** in the DB itself.
  - **A metrics/semantic layer** — dbt Semantic Layer, Cube, LookML — defines metrics, dimensions, and
    joins in business terms, so the model queries *validated* concepts rather than inventing SQL.
  - **BI business logic** — Qlik's business glossary; Snowflake Cortex Analyst **semantic models/views**.

> **Keep the semantic layer in the source** (connect-don't-copy): column comments, dbt models, Qlik
> logic live *with* the data and the MCP server exposes them — not a separate schema doc that drifts.

### 3.2 Ground — sample + profile

Before trusting the schema, pull reality: a few sample rows, the **distinct values** of enum-like
columns, null rates, min/max, row counts. This catches wrong assumptions (e.g. `status` actually holds
`'A'/'I'`, not `'active'/'inactive'`) before they become wrong queries.

### 3.3 Verify — read-only first

Write a `SELECT`, run it, and sanity-check results against expectation. **The read is the comprehension
test.** Use `EXPLAIN` to check cost before running anything heavy. Only after a read confirms the model
understands the data should it consider a write.

### 3.4 Few-shot / golden queries

Curated example pairs ("revenue by region this quarter" → the canonical SQL) are *procedural memory*
for the data. A handful of golden queries dramatically improves NL→SQL accuracy and encodes house
conventions (which table is authoritative, how to compute a metric).

### 3.5 Progressive disclosure for big schemas

A 1,000-table warehouse won't fit in context (P6: context is finite). Same recursion as documents:
**search** the tables relevant to the question → fetch **their** columns + descriptions → sample →
query. Don't dump the whole catalog. A `search_schema(query)` tool that returns candidate tables with
descriptions is the operational-data analog of *progressive disclosure by filename*.

---

## 4. Querying well — text-to-SQL in practice

NL→SQL on real databases is **hard**: the BIRD benchmark (real-world, 95 large DBs, dirty data, 37+
domains) shows large gaps vs. clean academic sets. The techniques that close the gap (DIN-SQL and
related work) stack up as:

1. **Schema linking** — identify the *relevant* tables/columns first (this is §3.5's progressive
   disclosure doing double duty).
2. **Decomposition** — break a complex question into sub-queries the model can get right.
3. **Few-shot in-context examples** — the golden queries from §3.4.
4. **Self-correction loop** — run the query; on error, feed the **DB error message + failed SQL** back
   for a retry. This single loop is one of the largest accuracy levers in practice.
5. **Constrain to a semantic layer** — generating against validated metrics/joins (dbt, Cortex Analyst)
   removes whole classes of hallucinated SQL.

**Manage result size, not just correctness:**

- **Aggregate/limit in the query** — return summaries, not 100k rows. Don't dump a result set into
  context (P6).
- **Just-in-time analysis** — Anthropic's pattern: write a targeted query, **store the result**, then
  analyze it with code (Bash/pandas) instead of loading the full dataset into the prompt.
- **Paginate** large reads; return a row count + sample, fetch more on demand.

---

## 5. The act — writing to a system of record

Write is the feature that makes the agent a participant — but here it is the highest-stakes write in
the whole knowledge stack. Gate it in layers:

- **Draft, don't execute, by default** — Anthropic's *negative space* pattern: emit the report or
  recommendation, but leave the high-stakes write (post the entry, approve the record) to a human
  unless executing it is the explicit job. The draft→execute line is the guardrail.
- **Dry run first** — `SELECT` the rows a mutation *would* affect and show them before running the
  `UPDATE`/`DELETE`. Predict the blast radius.
- **Transactions + rollback** — wrap writes so they can be undone; never auto-commit destructive ops.
- **Idempotency** — design writes so a retry can't double-apply (external IDs, upserts).
- **Bulk with care** — batch APIs (Salesforce bulk) are powerful and dangerous; cap batch size,
  preview, approve.
- **Per-action approval + audit** — each write surfaced for confirmation; every action logged
  (attributed to both the user and the agent).

---

## 6. Governance & safety

Writing — and even reading — operational data is bounded by the source system's own security, plus
agent-specific risks.

- **Permission inheritance / acts-as-user** — the agent must never exceed the acting human's rights.
  Qlik MCP acts as the user (Section Access enforced); Snowflake inherits RBAC + masking; HubSpot
  respects user permissions. Enforce **row-level security** and mask **PII** columns at the source.
- **Read-only by default in production** — run the DB MCP server as a read-only DB user; open write
  only where needed (Postgres `--access-mode=restricted`). Differentiate toolsets by environment
  (broad in dev, narrow in prod).
- **Least privilege, narrow tools** — many small scoped tools beat one broad "admin" tool; scope to
  specific datasets/projects.
- **Prompt injection is transport-independent.** Untrusted data in a record can instruct the agent to
  chain benign tools (read → query → exfiltrate) and slip past per-tool rules. The reliable fix is
  **authorization at the infrastructure level**, not prompt-level pleading: the MCP server must verify
  the bearer token maps to a real authenticated user with the requested rights (OAuth 2.1 + PKCE,
  short-lived tokens), so a hijacked instruction still can't exceed that user's permissions.
- **Audit everything** — writes especially; this is also what makes draft-vs-execute reviewable after
  the fact.

---

## 7. Performance & cost

- **`EXPLAIN` before heavy reads** — avoid full table scans; warehouses bill by bytes scanned.
- **Push work to the database** — aggregate/filter in SQL, not in the model.
- **Use read replicas** for analytical reads so the agent never loads the primary.
- **Respect rate limits** — CRM/SaaS connectors throttle; batch and back off.
- **Cache** stable lookups (schema, glossary, slowly-changing dimensions) so repeated orientation is
  cheap.

---

## 8. Architecture patterns — pick the right MCP surface

| Pattern | What the agent gets | Safety / accuracy | Use when |
|---------|---------------------|-------------------|----------|
| **Raw-SQL MCP** | arbitrary `run_sql` | lowest — full power, full risk | trusted dev, ad-hoc analysis, read-only mode |
| **Curated-tool MCP** | a few defined tools (`get_customer`, `list_open_deals`) | high — no arbitrary SQL | production app surfaces with known questions |
| **Semantic-layer MCP** | NL → *validated metrics/joins* (dbt, Cortex Analyst, Qlik) | highest — generation constrained to vetted concepts | governed metrics, many users, "trust the numbers" |
| **API/CRM connector** | record CRUD via the SaaS API | inherits SaaS RBAC + audit | HubSpot/Salesforce-style systems |

Rule of thumb: **the more sensitive and shared the data, the more curated/semantic the surface.** Raw
SQL is fine for a developer in a read-only sandbox; a finance team querying revenue should go through a
semantic layer so every answer uses the same validated definition.

---

## 9. Failure modes to design against

- **Hallucinated columns / wrong joins** → schema linking + read-only verify catch most.
- **Semantic misunderstanding** (`cust_st`) → the semantic layer + sampling.
- **Unbounded result sets** flooding context → aggregate/limit + just-in-time analysis.
- **Destructive writes** → dry-run + transaction + approval.
- **Permission leakage** (returning rows the user can't see) → row-level security enforced at query
  time, acts-as-user.
- **Prompt-injection tool chains** → infrastructure-level authorization, not prompt guardrails.

---

## 10. Takeaways

1. **No filesystem path — MCP is the only way in.** The MCP server *is* the integration; nothing syncs.
2. **Understand before you act.** Structured data isn't self-describing; a **semantic layer** plus the
   orient → ground → verify flow is what turns rows into reliable answers. Understanding is *retrieval*
   (schema/glossary/sample on demand), not pre-loading.
3. **Querying is a discipline, not a one-shot.** Schema linking, few-shot golden queries, and a
   self-correction loop are the accuracy levers; manage *result size* with aggregation and just-in-time
   analysis.
4. **Writes are the highest-stakes act in the stack.** Draft before execute, dry-run, transaction +
   rollback, per-action approval, audit.
5. **Governance is derived from where the write lands.** Permission inheritance, read-only by default,
   least-privilege tools, and **infrastructure-level authorization** (not prompt guardrails) against
   injection.
6. **Match the MCP surface to the stakes.** Raw SQL for trusted read-only work; a curated or
   semantic-layer surface for governed, shared, system-of-record data.

---

## References

- [HubSpot — Claude connector write access to CRM](https://developers.hubspot.com/changelog/claude-write-access-to-crm)
- [HubSpot — Set up and use the HubSpot connector for Claude](https://knowledge.hubspot.com/integrations/set-up-and-use-the-hubspot-connector-for-claude)
- [Salesforce — DX MCP Server (@salesforce/mcp)](https://github.com/salesforcecli/mcp)
- [Crystal DBA — Postgres MCP Pro](https://github.com/crystaldba/postgres-mcp)
- [Snowflake — Cortex Agents MCP server](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake — Managed MCP servers for secure data agents](https://www.snowflake.com/en/blog/managed-mcp-servers-secure-data-agents/)
- [Google Cloud — Use the BigQuery MCP server](https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp)
- [Databricks — Model Context Protocol (MCP)](https://docs.databricks.com/aws/en/generative-ai/mcp/)
- [Google — MCP Toolbox for Databases](https://github.com/googleapis/mcp-toolbox)
- [Qlik — Connecting the Qlik MCP server](https://help.qlik.com/en-US/cloud-services/Subsystems/Hub/Content/Sense_Hub/QlikMCP/Connecting-Qlik-MCP-server.htm)
- [dbt — dbt Semantic Layer](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl)
- [Anthropic — Text to SQL with Claude (cookbook)](https://platform.claude.com/cookbook/capabilities-text-to-sql-guide)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Building agents for financial services](https://www.anthropic.com/news/finance-agents)
- [BIRD — A Big Bench for Large-Scale Database Grounded Text-to-SQL](https://bird-bench.github.io/)
- [DIN-SQL — Decomposed In-Context Learning of Text-to-SQL](https://openreview.net/pdf?id=p53QDxSIc5)
- [Supabase — Defense in depth for MCP](https://supabase.com/blog/defense-in-depth-mcp)
- [Descope — MCP server security best practices](https://www.descope.com/blog/post/mcp-server-security-best-practices)
