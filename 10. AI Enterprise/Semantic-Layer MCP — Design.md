# Semantic-Layer MCP — Design (Claude-first)

> Design companion to *Operational Data for AI — Reach, Understand, Act* (this folder). Specifies the
> **semantic-layer MCP** — the highest-accuracy, highest-governance surface for letting an agent query
> operational data. Facts current as of mid-2026.

---

## 1. What it is — and why

A **read surface** where the agent answers business questions by **composing a structured query over
named, validated objects** (metrics, dimensions, filters), and a **semantic engine compiles it to
SQL**. The agent never writes SQL, never picks joins, never invents a metric definition.

That single constraint — *query validated concepts, not raw SQL* — is what removes the dominant
text-to-SQL failure modes (hallucinated columns/joins, inconsistent metric definitions) and lets
governance be enforced by the engine and warehouse rather than hoped for in a prompt.

---

## 2. Architecture

```
Claude (Cowork / Code)
   │  MCP tools  (structured query, NOT raw SQL)
   ▼
Semantic-layer MCP server   ← thin adapter: auth, audit, guardrails
   │  engine API (GraphQL / REST / JDBC)
   ▼
Semantic engine             ← dbt Semantic Layer (MetricFlow) / Cube / Cortex Analyst / LookML
   │  compiles to governed SQL (owns metric defs + joins)
   ▼
Warehouse / DB              ← Snowflake / BigQuery / Postgres (RBAC + RLS + masking apply)
```

The MCP server **does not reimplement** the semantic layer — it exposes an existing one and adds
identity, audit, and guardrails.

### Where the semantic knowledge lives

The semantic model is **version-controlled config files in git** — *not* in the warehouse, *not* in the
API. The warehouse holds the **data**; git holds the **meaning**; the API (and your MCP server) is just
the **bridge**. So a metric change is a PR, definitions can't silently drift, and there's a single
source of truth.

| Engine | Source of truth (git)                                                                                    | Compiled form                                                      | Query / introspect API                             |
| ---------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------- |
| **dbt Semantic Layer** | YAML in the dbt project — `semantic_models` (entities, dimensions, measures), `metrics`, `saved_queries` | **`semantic_manifest.json`** in `target/` (MetricFlow requires it) | **GraphQL** / JDBC |
| **Cube**               | YAML and/or JavaScript in the `model/` folder — cubes, views, measures, dimensions, joins, segments      | compiled in-memory at startup | **REST** / SQL / GraphQL; metadata via **`/meta`** |

```
YAML/JS in git  →  compile (semantic_manifest.json | Cube /meta)  →  query API  →  MCP server  →  Claude
   meaning             the compiled model                            the bridge
```

**This is where the discovery tools get their data.** `list_metrics` / `get_metric` /
`list_dimensions` are a **thin read over the compiled model** — dbt's `semantic_manifest.json` (or its
GraphQL metadata) and Cube's `/meta` endpoint. The MCP server invents nothing; it surfaces the
git-defined model. (And because the model is *files in git*, it's the same source-of-truth primitive as
documents and skills — versioned, reviewable, centralizable.)

---

## 3. The tool surface

Two tiers, following **progressive disclosure** (list cheap names → fetch one definition → query).
Discovery tools return *metadata*, not data.

**Discovery (orient):**

```
list_metrics(search?)          → [{ name, label, description, type }]            # names + 1-liners only
get_metric(name)               → { name, label, description, type,
                                   expr_in_business_terms, dimensions:[name],
                                   default_time_grain, format, filterable:[name] }
list_dimensions(metric?)       → [{ name, label, type, grains? }]
get_dimension_values(name,     → [value, ...]                                    # bounded distinct values
                     search?, limit?)                                            #   (for building filters)
list_entities() / get_entity   → models + relationships                          # the join graph (read-only)
list_saved_queries()           → [{ name, description, query }]                  # golden / few-shot queries
```

**Execution (act — structured, no raw SQL):**

```
compile(query)  → { compiled_sql, cost_estimate }        # dry-run / EXPLAIN, no execution
query(query)    → { columns, rows, compiled_sql,
                    row_count, truncated }                # always returns the compiled SQL
```

---

## 4. The query object (the contract)

```json
{
  "metrics":  ["total_revenue", "active_customers"],
  "group_by": [
    { "dimension": "region" },
    { "dimension": "order_date", "grain": "month" }
  ],
  "filters": [
    { "dimension": "order_date", "grain": "month", "op": "=",  "value": "2026-05" },
    { "dimension": "plan",       "op": "in", "value": ["pro", "enterprise"] }
  ],
  "order_by": [{ "field": "total_revenue", "dir": "desc" }],
  "limit": 50
}
```

Operators: `= != in not_in > >= < <= between contains is_null`.

**The five rules that make it safe and accurate:**

1. **Names only, validated server-side.** Every metric/dimension must exist in the model. Reject
  unknown names with an error that *lists the valid options* — this powers the **self-correction
   loop** (the agent retries correctly instead of hallucinating).
2. **No raw SQL on this surface.** If an escape hatch is needed, it is a *separate*, heavily-gated
  tool — never mixed in.
3. **The engine owns joins.** The agent groups by a dimension from another entity and it "just works"
  if a relationship exists. The agent never specifies joins → no hallucinated joins.
4. **Always return `compiled_sql`.** Transparency, citation, and human verifiability for every answer.
5. **Enforce `limit` (default + hard max) and return `truncated`.** Return aggregates, not 100k rows
  (context is finite and rivalrous).

---

## 5. Governance — baked in, not bolted on

- **Acts-as-user.** OAuth 2.1; the server maps the bearer token to a real user and passes identity
downstream so warehouse **RBAC + row-level security + column masking** apply. A hijacked instruction
still can't exceed that user's rights — injection is contained at the **authorization layer**, not
the prompt.
- **Read-only by construction.** A semantic-layer query is analytical. Writes to systems of record
live on a *different*, gated surface — keep them apart.
- **Cost guardrail.** Use `compile`'s `cost_estimate` to reject queries above a threshold before
running them.
- **Audit every call** — user, query object, compiled SQL, row count, latency.

---

## 6. The agent flow

```
list_metrics("revenue")            → finds total_revenue
get_metric("total_revenue")        → dims [region, plan, order_date], format USD, grain month
get_dimension_values("region")     → ["EMEA","NA",...]   (only if building a filter)
compile(query)                     → sees SQL + cost     (optional sanity check)
query(query)                       → rows + compiled_sql → answers, cites the SQL
```

No SQL is written by the model; "understanding" is **pre-encoded in the semantic model** and
*retrieved progressively* rather than pre-loaded.

---

## 7. Build vs. buy — the actual decision


| Situation                                                                               | Do this                                                                                                                                             |
| --------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| You already run **dbt**                                                                 | Use `**dbt-labs/dbt-mcp`** — its Semantic Layer tools already match this shape. Front it with your auth / audit / guardrails if needed.             |
| You run **Cube**                                                                        | Use the **Cube MCP server**.                                                                                                                        |
| You're on **Snowflake**                                                                 | **Cortex Analyst** semantic models (NL→SQL via REST) — note it is *NL-driven*, a slightly different shape from the structured-query contract above. |
| Bespoke semantic layer, or you need a tighter curated surface / org-specific governance | **Build a thin custom MCP** to the shape above — wrap your engine's API, don't reimplement it.                                                      |


The rule: **the design above is the target shape; the official servers already approximate it.**
Reinvent only for a bespoke engine or stricter governance.

---

## 8. Reference implementation sketch (custom, thin)

A custom server is a translator: MCP tool call → engine API call → shape the result. Pseudocode for the
two execution tools over a dbt-Semantic-Layer-style engine:

```python
# server.py — thin MCP adapter over a semantic engine
from mcp.server import Server
engine = SemanticEngine(...)   # dbt SL GraphQL / Cube REST / etc.
srv = Server("semantic-layer")

@srv.tool()
def list_metrics(search: str | None = None) -> list[dict]:
    # metadata only — names + 1-liners (progressive disclosure)
    return [{"name": m.name, "label": m.label, "description": m.description, "type": m.type}
            for m in engine.metrics(search)]

@srv.tool()
def compile(query: dict, user: User = CALLER) -> dict:
    q = validate(query, engine.model)        # reject unknown names -> list valid options
    sql = engine.compile(q, identity=user)   # engine owns joins + defs; identity -> RBAC/RLS
    return {"compiled_sql": sql, "cost_estimate": engine.estimate(sql)}

@srv.tool()
def query(query: dict, user: User = CALLER) -> dict:
    q = validate(query, engine.model)
    q.limit = min(query.get("limit", DEFAULT_LIMIT), MAX_LIMIT)   # rule 5
    if engine.estimate(engine.compile(q, identity=user)) > COST_CAP:   # guardrail
        raise ToolError("query too expensive; add filters or reduce grain")
    res = engine.run(q, identity=user)       # acts-as-user -> warehouse enforces perms
    audit.log(user, query, res.sql, res.row_count)                # rule + governance
    return {"columns": res.columns, "rows": res.rows,
            "compiled_sql": res.sql, "row_count": res.row_count,
            "truncated": res.row_count >= q.limit}
```

The load-bearing pieces are `validate()` (names-only, helpful errors → self-correction), `identity=user`
threaded into every engine call (acts-as-user), the limit clamp, the cost cap, and the audit line —
everything else is plumbing.

---

## 9. Why this beats text-to-SQL

No hallucinated columns/joins · one validated definition per metric · governance enforced by the engine

- warehouse · structured input is *validatable* (free SQL isn't) · transparent compiled SQL · a small,
**self-correcting** error surface (unknown-name errors guide the retry).

> The trade: it only answers what the model *defines*. A genuinely novel, un-modeled question needs a
> new metric/dimension first (a modeling task), or a separate gated raw-SQL surface. That boundary is a
> feature — it's the line between governed answers and free-form querying.

---

## 10. Letting the agent evolve the model (write to the semantic layer)

Everything above is **read** — the agent queries validated concepts. The advanced move is letting it
*adjust the semantic knowledge itself* (add/edit metrics, dimensions, entities, joins). This is the
resolution of §9's boundary — but it's the **highest-stakes write in the entire stack**, so it needs
the strongest gate.

### The reframe: this is a code change, not a live mutation

The semantic model is **files in git** (§2). So "adjust the semantic knowledge" = **write to those
files** = a *software change to a versioned artifact*. It must ride the **software-development lifecycle
(propose → PR → CI → review → merge → deploy)**, never a live in-place edit of the deployed model.

> **Cardinal rule: the agent proposes a change to the git source; it never hot-patches the live model.**
> A metric definition is *shared truth* — silently changing "revenue" changes every downstream answer,
> dashboard, and historical comparison at once. The write target is a **branch**, never the deployed
> manifest.

### The risk ladder — why this sits at the top

| Write target | Blast radius | Gate |
|--------------|--------------|------|
| Data row (warehouse / CRM) | one record / one query | runtime mutation: approval + transaction |
| **Semantic model (definitions)** | **everyone's numbers + history, retroactively** | **change-control: PR + CI + human review** |

A wrong row corrupts one record; a redefined metric corrupts *all* answers that use it, including past
ones. The model write gets a stronger gate than the data write, not the same one (P5).

### Two tiers, separated

**Tier 1 — Propose (the agent's surface):** drafts a diff, never applies live.

```
propose_metric(spec)      → { branch, pr_url, diff, impact, tests }   # writes YAML to a branch, opens PR
propose_dimension(spec)   → ...
propose_entity/join(spec) → ...
preview_change(spec)      → { compiled_diff, impact, sample_results }  # dry: compile + test-query on a SANDBOX, no PR
```

Every proposal auto-generates three things, not just the YAML:
- **Compiled diff** — what SQL actually changes.
- **Impact / blast-radius report** — which existing metrics, saved queries, and dashboards reference the
  touched objects; breaking vs non-breaking.
- **Tests** — assertions shipped with the change (non-null, sane row counts, declared additivity/grain
  hold).

**Tier 2 — Validate & merge (CI + human, *not* the agent in prod):**
- **CI** compiles the manifest, runs the engine's validations (dbt MetricFlow validations / Cube model
  compile), runs tests, scans for **breaking changes** (a renamed/removed object still referenced ⇒
  block), lints.
- **Human** reviews the *semantics* — "is this the right definition?" — then approves → merge → deploy.

### The flow (self-healing boundary)

```
1. agent can't find a metric for the question        (boundary hit)
2. propose_metric(...) drafts the YAML
3. preview_change → compile + test-query on a sandbox/dev branch → sanity-check the numbers
4. opens PR: diff + impact report + tests
5. human reviews semantics → merge → CI deploys
6. the metric now exists — for everyone, governed, tested
```

The agent **extends** the model, but through *propose-not-mutate*.

### Reference sketch — the propose tier

```python
@srv.tool()
def propose_metric(spec: dict, user: User = CALLER) -> dict:
    draft   = render_yaml(spec)                       # spec -> dbt/Cube model YAML
    branch  = repo.branch(f"agent/metric-{spec['name']}", author=user)
    repo.write(branch, path_for(spec), draft)
    impact  = analyze_impact(spec, engine.model)      # who references the touched objects
    tests   = generate_tests(spec)                    # non-null, additivity/grain, row sanity
    repo.write(branch, test_path(spec), tests)
    pr = repo.open_pr(branch, body=render(draft, impact, tests), author=user)  # provenance
    return {"branch": branch, "pr_url": pr.url, "diff": pr.diff,
            "impact": impact, "tests": tests}         # NOTHING is live yet
```

The load-bearing parts: it writes to a **branch** (never prod), attaches **impact + tests**, opens a
**PR** with the agent as author (provenance), and returns *nothing live* — deployment happens only
through CI + human merge.

### Guardrails specific to model edits

- **No live edits to prod** — the write tool targets a branch; only CI/merge deploys.
- **Human-in-the-loop on semantics.** Optionally auto-approve *purely additive, non-breaking* changes (a
  brand-new metric touching nothing existing) under policy; **hard-gate** any rename/remove/redefine.
- **Breaking-change detection is mandatory** — protect saved queries and dashboards from silent breakage.
- **Additivity & grain checks** — validate a new measure declares correct additivity/grain (prevents
  fan-out across all consumers).
- **Injection containment** — model edits are the prime attack target ("redefine revenue to hit my
  number"). The propose→PR→human path means a prompt-injected redefinition **can't land without
  review** — contain at the process layer, not the prompt (same principle as §5).
- **Provenance + audit** — PR author = the agent (co-authored); full git history; revertible.
- **Environment scoping** — the agent may freely edit a **dev/sandbox** model; **prod requires the full
  gate**.

> Principled: this is **P7** (agent-authored knowledge = files, governed by the software lifecycle) +
> **P2** (write to the git source via change-control) + **P5** (definition-of-truth is the top risk
> rung) + *draft, don't execute* (the agent drafts; CI + human deploy).

---

## Appendix — Glossary (term · definition · function · example)

Running domain: an e-commerce SaaS with `orders` and `customers`.

### The triad — dimension vs measure vs metric (read this first)

The three terms people conflate. One line each:

- **Dimension** = *by what* you slice (an axis). Qualitative. → `GROUP BY` / `WHERE`.
- **Measure** = *how much*, raw. A quantitative aggregation primitive. → the `SUM`/`COUNT`/`AVG`.
- **Metric** = *how much*, governed. A named, reusable KPI built on one+ measures (± filter/ratio). →
what the agent actually queries.


| Aspect           | Dimension                          | Measure                              | Metric                                   |
| ---------------- | ---------------------------------- | ------------------------------------ | ---------------------------------------- |
| **Answers**      | **"by what?"**                     | **"how much / how many?"** (raw)     | **"how much / how many?"** (exposed KPI) |
| **Nature**       | qualitative attribute (the axis)   | quantitative aggregation (primitive) | named business number                    |
| **In SQL**       | `GROUP BY` / `WHERE` column        | the aggregate expression             | aggregate ± filter/ratio, named          |
| **Pivot table**  | row & column headers               | cell values                          | the cell values you expose               |
| **Example**      | `region`, `plan`, `order_date`     | `SUM(amount)`, `COUNT(*)`            | `total_revenue`, `mrr`, `gross_margin`   |
| **Relationship** | **orthogonal** — slices any metric | the **building block**               | **built on** one+ measures               |


Two mental models: a **pivot table** — dimensions are the row/column headers, measures/metrics are the
cell values. Or by **question word** — a *dimension* answers "by what?", a *measure/metric* answers
"how much?".

**Measure vs metric** (the subtle pair): a measure is the raw aggregation (`revenue = SUM(amount)`); a
metric is that packaged as a governed, named KPI — sometimes 1:1 (`total_revenue` = the revenue
measure), sometimes derived (`gross_margin = revenue − cost`, `conversion_rate = signups / visits`).
Rule of thumb: **measures are primitives the modeler defines; metrics are the KPIs consumers query.**

> Tool note: the split is partly vendor-specific. **dbt / MetricFlow** separates *measures* (in
> semantic models) from *metrics* (built on them). **Cube** and **LookML** call the aggregations
> *measures* and expose no separate "metric" object. **Looker** just says "measures." The *concept* —
> raw aggregation vs exposed KPI — is universal even when the names aren't.

### Grain — what one row represents

**Grain** = the level of detail of a single row. Two senses, both about **correctness**:

- **Fact grain** (data-modeling sense): what one row of an entity *is*. `orders` = **one row per
order**; `order_items` = **one row per line item**. Knowing the grain tells you what you can safely
sum and join. Join `orders` (1/order) to `order_items` (N/order) and `SUM(orders.amount)`
**double-counts** — each order's amount repeats per line. This is **fan-out**. Additivity is
grain-relative.
- **Time grain** (query sense): the time bucket you roll up to — day / week / month / quarter / year.
`total_revenue` by `order_date` at grain **month** → 12 rows/year; at grain **day** → 365 rows.

Function: grain governs **safe aggregation**. Wrong fact grain → double-counting; wrong time grain →
wrong roll-up level. A good semantic layer **declares each entity's grain** so the engine aggregates at
the right level *before* joining — e.g. sum `revenue` at the order grain, *then* join `customers` to
group by `region`, avoiding fan-out.

### A. Semantic-model terms


| Term                     | Definition                                                                                  | Function (why it exists)                                         | Example                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Semantic layer**       | The governed model mapping business terms → SQL                                             | The single source of truth for "what the numbers mean"           | the whole `orders/customers` model below                                                         |
| **Entity** (model)       | A business object backed by a table/view                                                    | The *noun* you measure or group by                               | `orders`, `customers`                                                                            |
| **Primary key**          | Column uniquely identifying an entity's rows                                                | Anchors identity and joins                                       | `customers.id`                                                                                   |
| **Join / relationship**  | A declared link between entities                                                            | Lets the engine combine entities so the agent never writes joins | `orders.customer_id → customers.id` (many-to-one)                                                |
| **Measure**              | A raw aggregation over a column                                                             | The base number                                                  | `revenue = SUM(orders.amount)`                                                                   |
| **Metric**               | A named, exposed KPI built on a measure (± filters/ratios)                                  | The validated thing the agent actually queries                   | `total_revenue`, `mrr`, `gross_margin = revenue − cost`                                          |
| **Additivity**           | Whether a measure can be summed across dimensions (additive / semi-additive / non-additive) | Prevents wrong roll-ups                                          | `revenue` additive · `balance` semi-additive (not over time) · `distinct_customers` non-additive |
| **Dimension**            | An attribute to group or filter by                                                          | The "by what" axis                                               | `region`, `plan`, `order_date`                                                                   |
| **Time grain**           | Granularity of a time dimension                                                             | Controls the roll-up level                                       | `order_date` at grain `month`                                                                    |
| **Format**               | Display formatting of a metric                                                              | Correct presentation                                             | `total_revenue` → `$1,234,567` · `churn_rate` → `4.2%`                                           |
| **Segment**              | A reusable *named* filter                                                                   | DRY, governed filters                                            | `enterprise = plan IN ('enterprise','enterprise_plus')`                                          |
| **Saved / golden query** | A curated example query                                                                     | Few-shot guidance + house conventions                            | "revenue by region, this quarter"                                                                |


### B. Query terms


| Term                                | Definition                                   | Function                                            | Example                                                   |
| ----------------------------------- | -------------------------------------------- | --------------------------------------------------- | --------------------------------------------------------- |
| **Structured query** (query object) | JSON request of metrics + group_by + filters | The safe, *validatable* input that replaces raw SQL | the JSON in §4                                            |
| **Filter**                          | A `{dimension, op, value}` condition         | Narrows rows                                        | `{dimension:"plan", op:"in", value:["pro","enterprise"]}` |
| **Operator**                        | The comparison inside a filter               | How to compare                                      | `= · in · between · >=`                                   |
| **group_by**                        | Dimensions to aggregate over                 | Defines the result rows                             | `[{dimension:"region"}]`                                  |
| **order_by / limit**                | Sort + cap on results                        | Ranking + result-size control                       | `order_by: total_revenue desc · limit: 50`                |
| **compile()** (dry run)             | Produce SQL + cost without executing         | EXPLAIN / cost check before running                 | returns `cost_estimate: 2.1 GB scanned`                   |
| **Compiled SQL**                    | The SQL the engine generates                 | Transparency, citation, human verification          | `SELECT region, SUM(amount) … GROUP BY region`            |


### C. MCP & governance terms


| Term                         | Definition                               | Function                                  | Example                                                    |
| ---------------------------- | ---------------------------------------- | ----------------------------------------- | ---------------------------------------------------------- |
| **MCP tool**                 | A callable function exposed to the agent | The unit of capability                    | `query(...)`, `list_metrics(...)`                          |
| **Progressive disclosure**   | list → get → query tiering               | Keeps context lean (don't dump the model) | `list_metrics` (names) → `get_metric` (full def) → `query` |
| **Acts-as-user**             | Query runs under the caller's identity   | The agent never exceeds the user's rights | bearer token → user → warehouse role                       |
| **RBAC**                     | Role-based access control                | Who may see which objects                 | analyst role can't read `salaries`                         |
| **Row-level security (RLS)** | Per-row visibility rules                 | Users see only their rows                 | EMEA manager sees only EMEA rows                           |
| **Column masking**           | Obfuscate sensitive columns              | Protect PII                               | `email` → `j***@x.com`                                     |
| **Cost guardrail**           | Reject too-expensive queries             | Prevent runaway scans                     | reject `> 50 GB` scan                                      |
| **Audit log**                | Record of each call                      | Accountability + review                   | `{user, query, sql, rows, ms}`                             |


### D. Putting it together — one worked example

A slice of the semantic model (engine-agnostic sketch):

```yaml
entity: orders
  primary_key: id
  joins:
    - to: customers   on: orders.customer_id = customers.id   type: many_to_one
  dimensions:
    - { name: order_date, type: time, grains: [day, week, month, quarter, year] }
    - { name: region,     type: categorical }     # via customers.region
    - { name: plan,       type: categorical }     # via customers.plan
  measures:
    - { name: revenue, agg: sum, expr: amount, additivity: additive, format: usd }

metrics:
  - { name: total_revenue, measure: revenue }
  - { name: mrr, measure: revenue, filter: "order_type = 'subscription'", grain: month }

segments:
  - { name: enterprise, filter: "plan in ('enterprise','enterprise_plus')" }
```

Agent question → **"Top regions by revenue for enterprise customers, May 2026."**

The agent composes a **structured query** (names only — no SQL, no joins):

```json
{
  "metrics":  ["total_revenue"],
  "group_by": [{ "dimension": "region" }],
  "filters":  [
    { "dimension": "order_date", "grain": "month", "op": "=", "value": "2026-05" },
    { "segment": "enterprise" }
  ],
  "order_by": [{ "field": "total_revenue", "dir": "desc" }],
  "limit": 10
}
```

The engine resolves the **join** (`orders → customers`), the **segment**, and the **measure**, then
returns rows + the **compiled SQL** (acts-as-user, so RLS/masking apply):

```sql
SELECT c.region, SUM(o.amount) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE date_trunc('month', o.order_date) = '2026-05-01'
  AND c.plan IN ('enterprise', 'enterprise_plus')
GROUP BY c.region
ORDER BY total_revenue DESC
LIMIT 10;
```

Every term in the glossary appears exactly once in that flow: an **entity** with a **join**, a
**measure** rolled into a **metric**, grouped by a **dimension** at a **time grain**, narrowed by a
**filter** and a **segment**, capped by **limit**, executed **acts-as-user**, and returned with
**compiled SQL**.

---

## References

- [dbt — dbt MCP server](https://github.com/dbt-labs/dbt-mcp)
- [Cube — MCP server](https://docs.cube.dev/docs/integrations/mcp-server)
- [dbt — dbt Semantic Layer](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl)
- [dbt — Semantic models](https://docs.getdbt.com/docs/build/semantic-models)
- [dbt — Semantic manifest (semantic_manifest.json)](https://docs.getdbt.com/reference/artifacts/sl-manifest)
- [Cube — Data modeling overview](https://docs.cube.dev/docs/data-modeling/overview)
- [Snowflake — Cortex Agents MCP server](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake — Managed MCP servers for secure data agents](https://www.snowflake.com/en/blog/managed-mcp-servers-secure-data-agents/)
- [Anthropic — Tool use overview](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview)
- [Anthropic — MCP connector (Claude API)](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector)
- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic — Building agents for financial services](https://www.anthropic.com/news/finance-agents)
- [Model Context Protocol — Specification](https://modelcontextprotocol.io/specification)
- [Descope — MCP server security best practices](https://www.descope.com/blog/post/mcp-server-security-best-practices)

