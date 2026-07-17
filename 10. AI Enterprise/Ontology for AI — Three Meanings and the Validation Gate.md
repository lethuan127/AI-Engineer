# Ontology for AI — Three Meanings and the Validation Gate

> Companion to [Semantic-Layer MCP — Design](./Semantic-Layer%20MCP%20—%20Design.md) (this folder). That note designs a metric-layer read surface; this one places it on the wider "ontology" map and argues the accuracy budget lives in validation, not generation. Facts current as of mid-2026.

---

## 1. Why the word broke

In roughly twelve months (2025 → early 2026), "ontology generation" went from research demo to a checkbox on every major data platform: Snowflake Semantic View Autopilot (GA Feb 2026), Databricks Unity Catalog business semantics (GA early 2026), Microsoft Fabric's "Ontology" item (preview), Google Looker's agent layer over an auto-generated knowledge catalog, Collibra semantic agents, Stardog Voicebox drafting ontologies from a multi-agent system.

The problem: these announcements do not describe the same artifact. They describe three. When you evaluate a vendor — or design your own layer — the first question is *which of the three they actually mean*.

## 2. The three meanings

| | 1. Formal ontology | 2. SQL-native virtual model | 3. Governed metric layer |
|---|---|---|---|
| **Artifact** | RDF/OWL classes, properties, axioms + reasoner | Concepts mapped onto warehouse tables, queryable as SQL | Facts, dimensions, measures defined once over tables |
| **Core promise** | **Inference** — derive facts nobody wrote down | Ontology-like modeling without leaving the relational world | **Consistency** — same number, same way, everywhere |
| **Query surface** | SPARQL / reasoner | SQL | Semantic query API → compiled SQL |
| **Skills required** | Ontology engineering, description logic | SQL only | SQL/YAML only |
| **Who ships it** | Semantic-web tools, document-to-graph builders | Middle-ground vendors | Snowflake, Databricks, dbt, Cube, Looker |
| **Failure mode** | Unadoptable ceremony; stale axioms | Borrowed vocabulary, unclear guarantees | Cannot reason — lookup only |

Meaning 3 is winning the volume war: when the large platforms say "semantics," they almost always mean governed metrics. The Open Semantic Interchange (Snowflake, Salesforce, dbt Labs, BlackRock et al., launched Sep 2025; spec v1.0 Jan 2026) standardizes exactly that — data sets, metrics, dimensions, relationships. It is a metric interchange, not an OWL interchange.

> Architectural takeaway: the [Semantic-Layer MCP — Design](./Semantic-Layer%20MCP%20—%20Design.md) in this folder is a meaning-3 system with meaning-2 traits. That is the right default for enterprise BI-style questions. But be precise about what it cannot do: it answers questions someone already framed; it does not infer.

## 3. Two distinctions that draw the real line

Marketing blurs the three meanings; two ideas from formal logic separate them cleanly.

**Closed world vs open world.** A warehouse assumes *not recorded = false* (no stock row → out of stock) — correct for a bounded system of record. A formal ontology assumes *not stated = unknown*, because the world it models is larger than any record of it. A metric layer is a closed-world instrument; treating it as an open-world knowledge model is a category error.

**Extensional vs intensional meaning.** A table *means its current rows* — change the rows, change the meaning. A class in an ontology *means its membership condition* — a rule (`VIP ≡ Customer with lifetime spend > X`) that stays fixed while individuals come and go. This is why an ontology can classify an entity nobody labeled, and a metric layer cannot.

The honest cut between the three meanings is therefore not RDF-vs-SQL (serialization is not inference — a bare triple dump entails nothing). It is: **has axioms that entail, versus does not.**

## 4. The evidence — where accuracy actually comes from

The strongest public numbers on LLM question-answering over enterprise data (Allemang & Sequeda, arXiv:2405.11706, on an enterprise SQL benchmark):

| Setup | Accuracy |
|---|---|
| LLM → raw SQL (text-to-SQL) | ~16% |
| LLM → knowledge-graph representation (text-to-SPARQL) | ~54% |
| + ontology-based query check (OBQC) + LLM repair loop | ~72% (incl. 8% honest "I don't know") |

Read the deltas: grounding (giving the model a semantic representation instead of raw tables) bought ~38 points; the **validation layer** — check every generated query against the ontology, explain the violation, let the LLM repair it — bought another ~18 and converted silent errors into explicit unknowns.

On the generation side (Lippolis et al., arXiv:2503.05388): a reasoning model with competency-question prompting drafts OWL ontologies that beat *novice* ontology engineers in expert review — but not experts, with documented residual errors (wrong domain/range restrictions, wrong inverse axioms, redundant classes).

> Why it matters: generation is cheap and good-enough; nobody is automating validation at the same pace. The 2025 systematic review of LLMs in ontology engineering says exactly this — the field over-invests in the generative front of the lifecycle and under-invests in evaluation and maintenance.

## 5. The failure mode: unvalidated meaning at scale

Two properties make a *generated-but-unchecked* semantic layer worse than no layer:

1. **Fluency is not entailment.** An LLM produces plausible continuations; a reasoner derives guaranteed consequences — or derives nothing and says so. A fluent, well-written semantic model can be confidently wrong, and it *reads* trustworthy.
2. **Contradictions don't degrade gracefully.** In a reasoning system, from a contradiction everything follows (principle of explosion). One inconsistent pair of axioms doesn't damage a corner of the model — it voids the guarantee everywhere. A partially-correct ontology in the operating layer is not "80% good"; it is unbounded until something checks it.

This is the "Ontology Trap": a model can propose meaning far faster than any organization can validate it, and the result is confident, well-written error wired into every system that depends on the layer.

## 6. Design consequences

For any agent-facing semantic layer (including the one specified in [Semantic-Layer MCP — Design](./Semantic-Layer%20MCP%20—%20Design.md)):

1. **Budget for the gate, not the draft.** Let an LLM draft the semantic model, but treat the draft as untrusted input to a review pipeline (human + automated checks), not as a shippable artifact. The model proposes; something else must dispose.
2. **Put a query checker in the hot path.** The single highest-leverage component in the QA numbers was not the graph — it was validating each generated query against the model and repairing on failure. In a metric-layer system the analogue is: reject any query that references undefined metrics/dimensions, return the violation as a structured error, let the agent retry.
3. **Prefer "I don't know" to a fluent guess.** 8 of the 72 points above are honest refusals. Design the surface so *cannot answer from validated concepts* is a first-class response.
4. **Know which buyer you are.** Mass-market BI questions need meaning 3 (consistency). High-assurance domains — agents that must explain themselves, anywhere a confident wrong answer is expensive — need meaning 1's inference and provenance. Don't pay for axioms you won't check; don't ship lookup and call it reasoning.
5. **Track the interchange standard.** If your semantic model is YAML in git (dbt/Cube style), watch Open Semantic Interchange for portability — it is where the ecosystem's default definition of "semantics" is being settled by distribution, not by argument.

## 7. Glossary

| Term | Meaning |
|---|---|
| Ontology (formal) | Machine-readable model of a domain: classes, properties, relationships + axioms enabling inference |
| Axiom | A stated rule the reasoner may use (`every Order has exactly one Customer`) |
| Reasoner | Engine that derives entailed facts from axioms — or reports inconsistency |
| Entailment | A consequence that *must* be true given the axioms (vs. plausible continuation) |
| TBox / ABox | Terminology (classes, axioms) vs. assertions (individuals, facts) |
| Closed / open world | Not recorded = false vs. not stated = unknown |
| Metric layer | Governed facts/dimensions/measures over warehouse tables; lookup, not inference |
| OBQC | Ontology-Based Query Check — validate a generated query against the ontology before execution |

## References

- [Massimiliano Geraci — Everybody Ships an Ontology Now. Nobody Agrees What the Word Means. (LinkedIn, Jul 2026)](https://www.linkedin.com/pulse/everybody-ships-ontology-now-nobody-agrees-what-word-means-geraci-2lenf/)
- [Allemang & Sequeda — Increasing the LLM Accuracy for Question Answering: Ontologies to the Rescue! (arXiv:2405.11706)](https://arxiv.org/abs/2405.11706)
- [Lippolis et al. — Ontology Generation using Large Language Models (arXiv:2503.05388)](https://arxiv.org/abs/2503.05388)
