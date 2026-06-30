# Problem-Solving Frameworks for Better Decisions

A framework is not magic. It is a checklist for your thinking. Under pressure, your brain takes shortcuts and skips steps. A framework forces the steps back in: name the real problem, see the whole system, break it down, test your assumptions, and decide on purpose instead of by reflex.

The single most important idea on this page: **match the tool to the problem.** Most bad decisions come from using the wrong approach for the situation — applying a rigid checklist to a problem nobody understands yet, or endlessly analyzing a choice you could just reverse tomorrow. So we start with the five thinking tools, then give you one repeatable process that ties them together, then go deep on how this applies to AI solution architecture.

---

## The Decision-Quality Idea

Good decisions are not the same as good outcomes. A good outcome can come from luck; a bad outcome can come from a sound decision that hit bad luck. You cannot control outcomes, so judge yourself on the **process**: did you frame the problem well, gather enough information, consider real alternatives, and account for being wrong?

The Heath brothers make this point sharply — for important decisions, a good *process* beats raw analysis. Two practical anchors run through everything below:

- **The 70% rule (Bezos):** most decisions should be made with ~70% of the information you wish you had. Waiting for 90% means you are too slow. ([Amazon 2016 shareholder letter, summarized](https://blueprints.guide/posts/one-way-vs-two-way-doors))
- **Reversible vs. irreversible (one-way vs. two-way doors):** if a decision is easy to undo (a *two-way door*), decide fast and learn from doing. If it is hard or impossible to undo (a *one-way door*), slow down, consult, and deliberate. Most decisions are two-way doors that we wrongly treat as one-way. ([fs.blog](https://fs.blog/reversible-irreversible-decisions/))

Speed is a feature for reversible decisions and a danger for irreversible ones. Knowing which you are facing is half the battle.
    
---

## The Top 5 Frameworks

These five cover the large majority of real situations. Learn them well rather than collecting twenty you never use.

### 1. First Principles Thinking — strip away assumptions

Break a problem down to the facts you *know* are true, separate from the assumptions you have inherited, then rebuild the solution from those facts. This is how you escape "we've always done it this way" and find genuinely new options.

**How to run it:**
1. State the problem and write down every assumption you are making about it.
2. For each assumption ask: *is this a law of physics/economics, or just a convention?* Keep only what is truly fundamental.
3. Rebuild a solution from those fundamentals, ignoring how it is "normally" done.

The classic example is Musk costing a battery pack by its raw materials (nickel, aluminum, carbon) instead of accepting the market price — and finding it could be far cheaper. Use it when you suspect the conventional answer is expensive, slow, or simply assumed. ([fs.blog](https://fs.blog/first-principles/), [Untools](https://untools.co/first-principles/))

### 2. Systems Thinking — see the whole, not the part

Most hard problems are not single events; they are produced by a *system* of connected parts, feedback loops, and delays. Fixing the visible symptom often makes the system worse later. Systems thinking looks for *structure* and *leverage points* — the small change that produces an outsized, lasting effect.

**Core vocabulary:**
- **Stocks and flows** — stocks accumulate (cash, trust, technical debt, user base); flows fill or drain them (hiring vs. attrition, signups vs. churn).
- **Feedback loops** — *reinforcing* loops amplify (word-of-mouth growth, debt snowball); *balancing* loops resist and seek a goal (budgets, capacity limits).
- **Delays** — consequences often show up much later than the action, which is why cause and effect are hard to connect.

**How to run it:** map the key players, flows, incentives, and loops on one page; find where a delay or loop is driving the behavior; then look for the leverage point rather than pushing harder on the symptom. Beware **second-order effects** — "and then what happens?" asked two or three times. ([Donella Meadows, *Thinking in Systems* summary](https://curatella.com/notes/thinking-in-systems-book-summary/), [Res Extensa](https://www.resextensa.co/p/res-extensa-6-systems-thinking-stocks))

### 3. Issue Trees + MECE — break a big problem into solvable pieces

When a problem is too big to attack directly ("revenue is down", "the system is slow"), decompose it into a tree of sub-problems. **MECE** (Mutually Exclusive, Collectively Exhaustive) is the quality bar for the branches: no overlaps, no gaps. This is the core tool consultants use to make a fuzzy problem tractable.

**Two flavors:**
- **Issue / logic tree** — broad, neutral decomposition of *all* possible drivers. Use when you do not yet have a guess.
- **Hypothesis tree** — start from a testable hypothesis ("latency is dominated by the retrieval step") and only branch into what would prove or disprove it. Faster, because you skip branches you do not need. Use when you already have a strong hunch.

Decompose, then **prioritize**: spend effort on the branch with the biggest expected impact, not the easiest one. ([Crafting Cases](https://www.craftingcases.com/issue-tree-guide/), [MBA Crystal Ball: MECE](https://www.mbacrystalball.com/blog/strategy/mece-framework/))

### 4. Cynefin — diagnose the problem before you pick a method

Pronounced "kuh-NEV-in". Created by Dave Snowden, it is a *sense-making* framework: figure out what **kind** of problem you have, because each kind needs a different response. This is the meta-framework that tells you which of the others to use.

| Domain | Cause & effect | Right response |
|---|---|---|
| **Clear** | Obvious to everyone | *Sense → Categorize → Respond.* Apply the known best practice. |
| **Complicated** | Knowable with expertise | *Sense → Analyze → Respond.* Bring in experts; there are several good answers. (First principles, issue trees live here.) |
| **Complex** | Only clear in hindsight | *Probe → Sense → Respond.* Run safe-to-fail experiments and let patterns emerge. (Systems thinking lives here.) |
| **Chaotic** | No usable relationship | *Act → Sense → Respond.* Do something now to create stability, then assess. |
| **Disorder** | You don't know which domain | Get more information until you can place it. |

The common, expensive mistake is treating a **complex** problem (most novel product, org, and AI problems) as if it were **complicated** — demanding an upfront analysis and a guaranteed plan, when you should be experimenting. ([Untools](https://untools.co/cynefin-framework/), [Wikipedia](https://en.wikipedia.org/wiki/Cynefin_framework))

### 5. Inversion + Premortem — debias by starting from failure

Our defaults sabotage decisions: **confirmation bias** (we seek evidence that we are right), **sunk-cost fallacy** (we keep going because we already spent), and **overconfidence**. The cheapest fix is to invert.

- **Inversion:** instead of "how do I succeed?", ask "what would *guarantee* failure?" — then avoid those things.
- **Premortem (Gary Klein):** before committing, imagine it is a year later and the project failed badly. Have the team write down *why*. This surfaces risks that optimism hides, and it gives quiet skeptics permission to speak. ([Klein/Kahneman premortem](https://kathrynwelds.com/2015/09/16/debiasing-decisions-combat-confirmation-bias-and-overconfidence-bias/), [sunk cost](https://en.wikipedia.org/wiki/Sunk_cost))

Treat sunk costs as gone: decide only on future costs and benefits.

**Bias checklist — run this before any consequential call.** You cannot remove biases, but naming them out loud weakens their grip:
- **Confirmation bias** — am I only collecting evidence that I'm right? *Fix: go look for what would prove me wrong.*
- **Anchoring** — is the first number/idea I heard dragging my estimate toward it? *Fix: estimate independently before seeing others' numbers.*
- **Availability** — am I overweighting the recent, vivid, or easy-to-recall example? *Fix: ask for base rates, not anecdotes.*
- **Recency** — am I overreacting to the latest event (a single outage, one bad demo)? *Fix: look at the trend, not the last point.*
- **Authority / HiPPO** — am I deferring to the highest-paid person's opinion instead of the evidence? *Fix: gather views before the senior person speaks.*
- **Sunk cost** — am I continuing because of what I already spent? *Fix: decide as if starting fresh today.*
- **Overconfidence** — is my confidence backed by a track record, or by a feeling? *Fix: give a range, not a point; run the premortem.* ([debiasing](https://kathrynwelds.com/2015/09/16/debiasing-decisions-combat-confirmation-bias-and-overconfidence-bias/), [list of cognitive biases](https://en.wikipedia.org/wiki/List_of_cognitive_biases))

---

## Multidimensional Thinking — decide across dimensions, not down one line

The five tools above sharpen *how* you reason. Multidimensional thinking sharpens *how widely* you look before you reason. A **linear thinker** evaluates a choice on one axis — usually cost or speed — in a straight line. A **multidimensional thinker** holds several axes at once: cost *and* customer trust *and* team morale *and* long-term flexibility *and* risk. The same decision often flips depending on which dimensions you let into the room. ([All To Buzz](https://www.alltobuzz.com/multidimensional-thinking/), [Improve decision-making with multi-dimensional thinking](https://medium.com/illumination/improve-your-decision-making-with-multi-dimensional-thinking-33d73712b775))

This is not vague "think bigger" advice. It is a concrete scan: before deciding, deliberately rotate the problem through a fixed set of dimensions so you stop optimizing one number at the expense of everything else.

**Dimensions to scan (pick the ones that apply):**
- **Time horizon** — what looks good this quarter but bad in three years? (ties to systems thinking's *delays*)
- **Stakeholders** — user, team, business, ops, security, legal: who wins and who pays?
- **Metrics** — never just one. Cost, latency, quality, reliability, maintainability, risk.
- **Scale / zoom** — does this hold at 10× the load, the data, the users? Zoom in to the detail and out to the whole system.
- **Perspective / discipline** — how would an engineer, a finance person, a customer, an attacker each see this?
- **Probability** — best case, expected case, worst case — not just the one you hope for.

**How to run it:** list the live dimensions, score each option roughly on every one (a simple table is enough), and watch for the option that is *only* winning because you were staring at a single axis. The trap to avoid is the opposite: *analysis paralysis*. Multidimensional thinking widens the view to **find** the few dimensions that actually decide the call — then you commit. It feeds directly into WRAP's "Widen your options" and "Attain distance" steps below.

> **Linear vs. multidimensional, concretely:** "Which model is cheapest per token?" is linear. "Which model gives us acceptable quality, at a latency users tolerate, at a cost we can sustain, without locking us to one vendor, and that we can swap in six months?" is multidimensional — and it is the question that actually matters.

---

## The Repeatable Process: WRAP + the Door Test

The frameworks above are *tools*; this is the *process* that decides when to use them. It is built on the Heath brothers' **WRAP** model, with the reversible/irreversible test wired in so you spend effort in proportion to the stakes.

> **Step 0 — Classify the door.** Is this reversible (two-way) or irreversible (one-way)? Reversible → bias to speed, run a light version of the steps below, decide at 70%. Irreversible → run the full process slowly and consult widely. Also place the problem in **Cynefin** so you know whether to analyze or experiment.

**W — Widen your options.** Avoid "whether or not" framing; it hides choices. Force at least one more real alternative. Ask "what would we do if this option disappeared?" Learn from people who have solved it before.

**R — Reality-test your assumptions.** Fight confirmation bias on purpose: actively look for disconfirming evidence, ask experts the hard questions, and where possible **run a small experiment** instead of debating. Small, cheap tests beat big arguments.

**A — Attain distance before deciding.** Step back from the emotion of the moment. Useful prompts: *"What would I tell my best friend to do here?"* and the 10/10/10 test — *how will I feel about this in 10 minutes, 10 months, 10 years?* Anchor on your core priorities, not the loudest short-term feeling.

**P — Prepare to be wrong.** Run a **premortem**. Set a **tripwire** — a specific signal that tells you to stop and re-decide ("if churn crosses 5%, we revisit"). Bound the downside so a wrong call is survivable.

Then **decide, write down why, and set a review date.** Writing the reasoning down (see ADRs below) is what lets you learn whether your *process* was good, separate from luck. ([WRAP summary](https://www.shortform.com/blog/wrap-decision-making/), [Heath Brothers one-page summary](https://heathbrothers.com/member-content/1-page-summary-of-the-wrap-model/))

---

## Supporting Tools

Smaller, sharp tools that plug into the process above. Each does one job well.

- **Expected value — score uncertainty, don't feel it.** Rank options by `probability × impact` instead of gut comfort. A 30% shot at a huge win can beat a safe small one. Its partner, the **expected value of information**, asks: *is it worth paying (time, a spike, a prototype) to reduce the uncertainty before I commit?* This is the math behind the 70% rule — buy more information only when it would actually change the decision. ([expected value](https://en.wikipedia.org/wiki/Expected_value))

- **OODA loop — the fast loop for reversible, live situations.** *Observe → Orient → Decide → Act,* then repeat. Where WRAP is the careful process for one big choice, OODA is for fast-moving situations where you decide, act, watch what happens, and adjust — incident response, debugging a flaky agent, a fast-changing market. Whoever loops faster (and *orients* better on new information) wins. Maps to Cynefin's complex/chaotic domains. ([Wikipedia](https://en.wikipedia.org/wiki/OODA_loop))

- **Pareto / 80-20 — find the vital few.** Roughly 80% of effects come from 20% of causes. Before fixing everything, find the small set of causes driving most of the pain and start there. Pairs with issue trees: decompose, then attack the heaviest branch. ([Wikipedia](https://en.wikipedia.org/wiki/Pareto_principle))

- **Second-order thinking — "and then what?"** First-order thinking stops at the immediate result; second-order asks what the result *causes*, two and three steps out. Cheap fixes with bad second-order effects (a discount that trains customers to wait for sales; a quick hack that becomes load-bearing) are the classic trap. Ask "and then what?" at least twice. ([fs.blog](https://fs.blog/second-order-thinking/))

- **Opportunity cost — every yes is a no.** The real cost of a choice is the best thing you gave up to do it. Saying yes to a feature is saying no to whatever that team could have built instead. A useful prioritization filter: if it isn't a clear "hell yes," it's a no — because a lukewarm yes spends the capacity a great option will need later. ([opportunity cost](https://en.wikipedia.org/wiki/Opportunity_cost))

---

## Deep Dive: Applying This to AI Solution Architecture

AI architecture decisions are unusually hard because the technology, the models, and the costs all change fast, and because the systems are **probabilistic** — the same input can give different outputs. That puts most AI work squarely in Cynefin's **complex** domain: you cannot fully analyze your way to the answer, you have to experiment. Here is how the frameworks map to the decisions you actually face.

### Classify the door first

| Decision | Door type | Implication |
|---|---|---|
| Prompt design, top-k, chunking strategy, which model behind an API | **Two-way** | Cheap to change. Decide fast, A/B test in production, iterate. |
| RAG vs. fine-tuning for a capability | Mostly two-way | Start with RAG/prompting; fine-tune later only if evals demand it. |
| Vector DB / core data store, agent framework, cloud provider | **Closer to one-way** | Migration is costly. Deliberate, prototype, check lock-in. |
| Sending regulated/PII data to a third-party model; an irreversible data-deletion or training-on-customer-data choice | **One-way** | Slow down. Involve security, legal, and stakeholders. |

The frequent error: teams agonize over reversible choices (which prompt, which top-k) and rush the irreversible ones (data governance, vendor lock-in). Flip that.

### First principles for the build-vs-buy and "do we even need AI" question

Strip the assumption that the answer is a large model or an agent. The fundamental question is: *what is the actual task, what accuracy does it truly need, and what is the cheapest reliable way to get there?* Often a smaller model, a deterministic rule, retrieval, or classic software beats a heavyweight agent on cost, latency, and reliability. Cost the solution from the task up, not from the trendy tool down.

### Issue trees for diagnosis ("the AI app is bad")

"Quality is low" is too big. Decompose MECE-style:
- **Retrieval** — are we fetching the right context? (recall, chunking, embeddings)
- **Generation** — given good context, is the model reasoning well? (model choice, prompt, temperature)
- **Orchestration** — tool calls, routing, state, error handling
- **Evaluation** — are we even measuring the right thing?

Then test the most likely branch first (a hypothesis tree). This stops the team from randomly swapping models when the real problem is retrieval.

### Systems thinking for the second-order effects

AI systems are full of feedback loops and delayed costs:
- **Cost flows** — token usage is a flow that drains a budget stock; an agent that loops can blow it up non-linearly.
- **Latency stacks** — each retrieval/tool/model hop adds delay; the user feels the *sum*.
- **Quality feedback loops** — bad outputs that get cached or fed back as training data create reinforcing decay. Logging and eval are the balancing loop that keeps quality from drifting.
- **Human trust** — a stock that fills slowly and drains fast; one bad hallucination in a demo can cost more trust than ten good answers built.

Map these before scaling, not after the bill arrives.

### Premortem for AI-specific failure modes

Before shipping, imagine it failed in production and ask why. The usual culprits: **hallucination** on edge cases, **prompt injection / security**, **cost blow-up** from runaway loops, **eval gaps** (you measured the wrong thing), **latency** under real load, and **silent quality drift** as the model or data changes. For each, set a **tripwire**: an eval threshold, a cost ceiling per request, a guardrail, an alert.

### Write it down: Architecture Decision Records (ADRs)

The artifact that makes all of this stick is the **ADR** — a short, dated markdown file that captures *one* decision: the context, the options considered with pros/cons, the choice, and its consequences/trade-offs. ADRs (popularized by Michael Nygard; see the MADR template) are the AI architect's version of "decide, write down why, set a review date." Months later, when the landscape shifts, you can see *what you knew and why you chose* — and re-decide on evidence instead of memory. ([adr.github.io](https://adr.github.io/), [MADR templates](https://adr.github.io/adr-templates/))

---

## Quick Reference — which tool, when

- **I don't know what kind of problem this is** → Cynefin (diagnose first).
- **The conventional answer feels too expensive or just assumed** → First principles.
- **Fixing the symptom keeps backfiring; effects are delayed** → Systems thinking.
- **The problem is too big to attack directly** → Issue tree + MECE.
- **I'm about to commit and I'm feeling confident** → Inversion + premortem.
- **I'm optimizing one number and ignoring the rest** → Multidimensional thinking (rotate the dimensions).
- **The situation is fast-moving and I must act and adjust** → OODA loop.
- **I'm choosing under real uncertainty** → Expected value (probability × impact).
- **I can't fix everything at once** → Pareto / 80-20 (start with the vital few).
- **I have a real decision to make** → WRAP + the door test (+ bias checklist), then an ADR.

A framework's job is to slow you down at the few moments that matter and speed you up everywhere else. Start with the door test and Cynefin; reach for the others as the problem demands.

---

## References

- Snowden, D. — Cynefin framework: [Untools](https://untools.co/cynefin-framework/), [Wikipedia](https://en.wikipedia.org/wiki/Cynefin_framework), [The Cynefin Co](https://thecynefin.co/effective-decision-making-support-tool/)
- First principles thinking: [fs.blog](https://fs.blog/first-principles/), [Untools](https://untools.co/first-principles/)
- Systems thinking (Meadows, *Thinking in Systems*): [book summary](https://curatella.com/notes/thinking-in-systems-book-summary/), [stocks/flows/loops](https://www.resextensa.co/p/res-extensa-6-systems-thinking-stocks)
- Issue trees & MECE (Minto): [Crafting Cases](https://www.craftingcases.com/issue-tree-guide/), [MECE](https://www.mbacrystalball.com/blog/strategy/mece-framework/)
- Heath, C. & D. — *Decisive* / WRAP: [Shortform summary](https://www.shortform.com/blog/wrap-decision-making/), [Heath Brothers one-pager](https://heathbrothers.com/member-content/1-page-summary-of-the-wrap-model/), [Stanford GSB](https://www.gsb.stanford.edu/faculty-research/books/decisive-how-make-better-choices-life-work)
- Reversible vs. irreversible / one-way vs. two-way doors (Bezos): [fs.blog](https://fs.blog/reversible-irreversible-decisions/), [Blueprints](https://blueprints.guide/posts/one-way-vs-two-way-doors)
- Debiasing — premortem (Klein), confirmation bias, sunk cost: [Kathryn Welds](https://kathrynwelds.com/2015/09/16/debiasing-decisions-combat-confirmation-bias-and-overconfidence-bias/), [sunk cost](https://en.wikipedia.org/wiki/Sunk_cost)
- Architecture Decision Records (Nygard / MADR): [adr.github.io](https://adr.github.io/), [ADR templates](https://adr.github.io/adr-templates/)
- Multidimensional / non-linear thinking: [All To Buzz](https://www.alltobuzz.com/multidimensional-thinking/), [multi-dimensional decision-making](https://medium.com/illumination/improve-your-decision-making-with-multi-dimensional-thinking-33d73712b775), [Groves et al., *Linear and Nonlinear Thinking* (2015)](https://onlinelibrary.wiley.com/doi/abs/10.1002/jocb.60)
- Supporting tools: [expected value](https://en.wikipedia.org/wiki/Expected_value), [OODA loop](https://en.wikipedia.org/wiki/OODA_loop), [Pareto principle](https://en.wikipedia.org/wiki/Pareto_principle), [second-order thinking](https://fs.blog/second-order-thinking/), [opportunity cost](https://en.wikipedia.org/wiki/Opportunity_cost)
- Cognitive biases: [List of cognitive biases (Wikipedia)](https://en.wikipedia.org/wiki/List_of_cognitive_biases)
