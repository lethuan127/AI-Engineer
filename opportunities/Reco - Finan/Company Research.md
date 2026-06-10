# Finan (SoBanHang) — Company & Project Research

> Research for the **AI Agent Engineer** role. Recruiter **Reco** (Võ Thị Thúy Liễu, lieu.vo@reco-vn.com, 0967124482) is only the agency — the real employer is **Finan**.
> Compiled 2026-06-04.

---

## TL;DR
- **Company:** Finan — Vietnamese SME fintech, Singapore-HQ'd parent (Finan Pte Ltd).
- **Flagship product:** **SoBanHang** — sales/inventory/invoicing/cash-flow app for micro businesses. **800,000+ active users, $5B+ transaction volume.** Target: 1M users in 12 months.
- **The project you'd build:** **Finan One** — an *"AI-native business & finance operating system for SMEs, built on top of SoBanHang's transaction data infrastructure."* This is what the new funding scales.
- **Funding:** **$3.8M pre-Series A (May 2026)** — Hong Leong Bank $2M, OSK-SBI $1.5M, plus FEBE Ventures & Antler. Earlier $4M seed (2021).
- **Founders:** brothers **Bùi Hải Nam (CEO)** & **Bùi Hải Long**, founded mid-2021, both ex-regional-bank (15+ yrs).
- **Role fit:** Very strong vs the candidate's Vireox LLM-agent platform work (multi-tenant, tool use, prompt caching, outcome dashboards, full-stack).

---

## The Role (from JD)
- **Title:** AI Agent Engineer — level Middle / Senior.
- **Location:** Quận 2, HCMC (on-site). **Salary: up to 100,000,000 VND/month** (level decided after Round 1).
- **Work days:** Mon–Fri + Saturday morning (8:30–12:00).
- **Interview:** 2 rounds — (1) Technical with **General Manager**, (2) Culture fit with **CEO** (likely Bùi Hải Nam).

### What you'd do
- Own a capability **end-to-end**: business objective → spec → architecture → build → deploy → measure.
- Build **AI agents with tool use** on leading LLM APIs (tool schemas, conversation state, streaming, prompt caching, per-tenant token budgets).
- Build a **Copilot streaming chat** returning rich blocks (tables, charts, action buttons) via a BFF to a React frontend.
- **Workflow orchestration** for long-running agents (multi-step, retry/compensation, human approval gates).
- **Measure everything**: cost per outcome, p95 latency, success rate, hallucination rate, cache hit rate — every agent ships with a dashboard.
- **RAG pipelines** per tenant knowledge base.
- **Guardrails**: tenant isolation, PII redaction, capability gating, audit trails.
- Write specs **before** code: BRD, data model, API contract, ADR.

### Must-have
- 5+ yrs senior SWE on real production systems · 2+ yrs LLM APIs in production.
- Fluent **Python or Go** · **TypeScript + React** for the Copilot UI.
- Deep **tool use / function calling** · disciplined **prompt engineering** (versioning, evals, A/B).
- **Prompt caching** know-how (hit vs miss, structuring for high hit rate).
- Strong **SQL** (transactions, indexes, row-level security, OLTP vs OLAP).
- Service-level **architecture** design + clear trade-offs.
- External API integration quirks (idempotency, retry, reconciliation between sources of truth).
- **Multi-tenancy** (isolation, per-tenant quotas, capability gating at DB + app layer).
- Can write specs (500–2,000 lines) others implement.

### Not a fit if
- Only side projects/prototypes, no production ownership.
- Only the AI layer — can't do backend + frontend.
- "AI agent" = only prompt chaining, not architecture/orchestration/tool integration.
- No structured eval framework (judge models by gut feeling).
- Uncomfortable with long, detailed specs before coding.

### Benefits
13th-month salary (perf-based), full-salary insurance, lunch allowance 30k VND/day, laptop allowance 350k VND/month (own laptop), compensation by level (Senior/Staff) discussed after Round 1.

---

## Company Facts
| Item | Detail |
|---|---|
| Parent | Finan Pte Ltd (Singapore HQ) |
| Operating brand | SoBanHang |
| Founded | mid-2021 |
| Founders | Bùi Hải Nam (CEO), Bùi Hải Long — both 15+ yrs at regional banks/tech |
| Users | 800,000+ active business users |
| Transaction volume | $5B+ processed |
| Target | 1M customers within 12 months |
| Mission | "Elevate businesses through digital technology" — digitize VN micro/small businesses; focus on underserved (female entrepreneurs, rural shop owners) |
| Bank partners | Shinhan Bank Vietnam (Shinhan Store), Hong Leong Bank |

### Products
- **SoBanHang** — sales mgmt, orders, inventory, smart invoicing, cash flow, bank account opening, loan applications.
- **FinanBook** — accounting platform.
- **Smart debt collection**, cash-flow optimization, embedded "all-in-one banking".
- **Finan One** — the AI-native OS (see below).

### Funding
- **Pre-Series A — $3.8M (May 2026):** Hong Leong Bank (Malaysia) $2M; OSK-SBI Venture Partners $1.5M; existing backers FEBE Ventures & Antler.
- **Seed — $4M (2021, two tranches).**
- **Use of funds:** scale Finan One, expand embedded finance, more bank partnerships, SEA expansion. Also a research tie-up with Singapore Management University on AI fintech.

---

## Finan One — the project
> *"AI-native business and finance operating system built on top of SoBanHang's transaction data infrastructure."*

- Automates: **reconciliation, bookkeeping preparation, invoice matching, cash flow management**.
- CEO Bùi Hải Nam: "simplify operational and financial workflows for SMEs by automating repetitive tasks and supporting faster business decision-making."
- This is the company's forward bet (what the $3.8M funds) → high-ownership, build-the-agent-layer work, not maintenance.

---

## Insights / Reading between the lines
1. **Agents = finance automations.** The "AI agents measured by business outcomes" = reconciliation / invoice matching / cash-flow agents over real transaction data. The Copilot chat = the decision-support layer.
2. **Money is involved → correctness is load-bearing.** The SQL / OLTP-vs-OLAP, "reconciliation between sources of truth," and audit-trail must-haves are real, not boilerplate. Be ready to talk correctness, idempotency, and audit.
3. **Multi-tenancy at real scale (800k tenants).** Tenant isolation, per-tenant budgets, capability gating are genuine architecture problems here.
4. **Building from near-zero on top of existing data.** They want the agent layer over existing transaction infra — not greenfield toy, not maintenance. Fresh funding + AI bet = early, formative work.
5. **Singapore HQ + SEA expansion.** English, spec-heavy, regional standards (the JD itself is detailed English).
6. **Ex-banker founders.** Expect rigor, ownership, measurable outcomes; the CEO culture round will probe this.

---

## Fit assessment (candidate: Lê Văn Thuận)
**Strong matches** — Vireox LLM report-generation platform maps almost 1:1:
- LLM agents + tool use + prompt caching **in production** (98% delivery success; V4/V5 workflow generation).
- **Multi-tenant** platform experience.
- **Full-stack** (Python/Go + React).
- **Measurement / dashboards / evals** — matches outcome-driven framing.

**Gaps to prepare:**
- **Go** depth (if they push it over Python).
- A **formal eval / A-B testing framework** with hard numbers (not just manual checks).
- Concrete **finance-domain** correctness stories (reconciliation, audit).

---

## Contacts & Process
- **Recruiter:** Võ Thị Thúy Liễu (Reco) — lieu.vo@reco-vn.com — 0967124482.
- **Process:** Round 1 Technical (General Manager) → Round 2 Culture fit (CEO, likely Bùi Hải Nam). Compensation level discussed after Round 1.

---

## Sources
- [TNGlobal — Finan raises $3.8M](https://technode.global/2026/05/13/finan-raises-3-8m-to-expand-vietnam-sme-management-platform-across-southeast-asia/)
- [Fintech News SG — SoBanHang pre-Series A](https://fintechnews.sg/131334/vietnam/sobanhang-funding-pre-series-a/)
- [Founderland — SoBanHang raises $3.8M for AI fintech](https://www.founderland.ai/articles/sobanhang-raises-38m-to-power-vietnams-800k-smes-with-ai-fin-mp5ma5m9)
- [Fintech News Malaysia — Hong Leong backs SoBanHang](https://fintechnews.my/58415/funding/sobanhang-funding-pre-series-a/)
- [VIR — SoBanHang wraps up pre-Series A](https://vir.com.vn/sobanhang-wraps-up-pre-series-a-funding-round-152647.html)
- [LinkedIn — Bùi Hải Nam (CEO)](https://www.linkedin.com/in/hainam/)
- [Finan official site](https://finan.one/vn/ve-chung-toi/)
- Recruiter message + JD file (this folder).
