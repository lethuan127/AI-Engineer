# Centralized Knowledge for AI — Enterprise Brief

> **Who this is for:** team leads and decision-makers — *not* engineers. Plain-language summary of how to
> give AI one shared, trustworthy source of your company's knowledge. The deeper technical notes in this
> folder cover the "how"; this brief covers the "what, why, and what to decide."

## 1. The idea in one minute

Today, using AI at work usually means **copy-pasting documents into chat windows**, and every tool
**remembers things separately**. The result is stale copies, inconsistent answers, and knowledge trapped
in one person's chat history.

The fix: give AI **one shared source of your company's knowledge — kept in your own systems — that every
employee and every AI tool can both *read and update*.** Set it up once, and everyone's AI works from the
same current truth, and can *act* on it, not just answer questions.

## 2. The three kinds of company knowledge


| Kind                       | In plain terms                                                                   | Where it lives                                  |
| -------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------- |
| **Documents**              | files people write                                                               | Google Drive, SharePoint                        |
| **Business data**          | live operational systems                                                         | CRM (Salesforce/HubSpot), databases, dashboards |
| **The AI's own knowledge** | what it learns, your reusable "how we do it" playbooks, and the work it produces | a shared folder, or a memory service            |


## 3. How AI connects to it

Two main ways (plus a fallback):

- **A shared folder** — your company's **existing cloud drive** (Google Drive, OneDrive/SharePoint),
synced onto the computer where the AI works. The AI opens, edits, and saves files in it **just like a
person**, and changes sync back so everyone stays current. *Think of it as your team's shared Drive
folder, with the AI added as a member.* It holds **documents, the AI's notes, and reusable playbooks** —
no new system to buy, and the simplest place to start.
- **Connectors** — a secure plug that lets the AI use a **live system** (Salesforce, your database, a
dashboard) to look things up and, where allowed, make updates.
- **Fallback** — the AI can operate an app through its screen, like a person, when nothing else connects.

> **The golden rule:** keep the real information in *your* systems and let the AI reach in. Don't let
> copies pile up inside chat tools — that's how knowledge goes stale and leaks.

## 4. Which Claude product for which people


| Product                     | For                                                | What it does                                                                                        |
| --------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Claude Cowork**           | everyday employees (analysts, ops, finance, legal) | give it a goal; it works across your files and apps and returns finished work                       |
| **Claude Code**             | developers                                         | the same agentic power, for software work                                                           |
| **Claude chat (claude.ai)** | anyone, quick questions                            | fast Q&A — but its memory is **private to the chat** and does *not* become shared company knowledge |


> For the workforce, **Cowork** is the main surface. Its memory and files live on the employee's
> machine/your systems — so they can be shared and governed — unlike the chat app, whose memory stays
> locked inside the product.

## 5. What to set up first (the roadmap)

Do the cheap, high-impact steps first:

1. **Pick your source of truth and connect it** — a shared Drive/SharePoint folder or a repository. This
  one step covers documents, the AI's notes, *and* reusable playbooks at once.
2. **Capture "how we do things" as playbooks** — so the work an expert does once, every employee's AI can
  repeat. (Highest payoff, lowest risk.)
3. **Agree on shared facts and definitions** — e.g. what counts as an "active customer" — so every answer
  is consistent.
4. **Connect live business data** — start **read-only**; allow the AI to *make changes* only later, with
  approval.

> **Detailed tasks, owners, and "done-when" criteria for each step:** see the
> [Rollout Plan](Centralized%20Knowledge%20for%20AI%20—%20Rollout%20Plan.md).

## 6. Sharing knowledge across the team


| Share first                    | Why                                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------- |
| **Playbooks / how-to**         | one expert's method → everyone benefits; low risk (reviewed like documents)                   |
| **Agreed facts & definitions** | keeps every team consistent                                                                   |
| **Don't bulk-share**           | raw chat transcripts — noisy and possibly sensitive; capture the useful *conclusions* instead |


Personal preferences stay **personal** (and can follow an employee across their devices). Team knowledge
is **shared, with a review step** before it's trusted company-wide.

## 7. Keeping it safe (governance in plain terms)

- **The AI never exceeds the person** — it can only do what the signed-in employee is allowed to do.
- **Important changes need a human** — updating a CRM record or a financial system: the AI **drafts**, a
person **approves**. The AI doesn't execute high-stakes actions on its own by default.
- **Review what gets remembered** — so wrong or deliberately planted information can't quietly spread
through shared memory.
- **Everything is logged** for audit.

## 8. "Is it safe to run on our computers?" (Cowork)

Short answer: **yes, by design.** When Cowork does work on a computer, it runs in a **locked, isolated
workspace** (a "sandbox"). It can only see the **folders you explicitly connect**, it **can't freely
reach the internet**, and it **never gets your saved passwords**. For tighter environments, IT can set
company-wide rules about what it may touch.

> One practical thing your team *will* notice: inside that locked workspace the AI can prepare and save
> changes, but **publishing changes to shared systems (e.g. pushing to GitHub) needs a person or an
> approved connector.** That's intentional — nothing leaves under your name without a checkpoint.

## 9. The decisions you need to make

- **Where is our single source of truth?** (Drive / SharePoint / a repository)
- **What may the AI change directly, vs only read?** (start read-only; expand carefully)
- **Who reviews shared playbooks and facts** before they're trusted company-wide?
- **Which product for which team**, and what guardrails does IT set?

## 10. What good looks like

- Every employee's AI gives **consistent answers from current information**.
- **No more copy-pasting; no stale duplicates.**
- AI that **completes work**, not just chats.
- **Knowledge compounds** — solved once becomes reusable everywhere.

## Plain-language glossary

- **Source of truth** — the one official place a piece of information lives.
- **Connector** — a secure plug that lets the AI use a live system (your IT may call the standard "MCP").
- **Playbook / skill** — a saved, reusable set of steps for a recurring task.
- **Sandbox** — a locked, isolated workspace where the AI's actions can't affect the rest of the computer.
- **Permission inheritance** — the AI can only do what the signed-in person is allowed to do.

## Go deeper (for your technical team)

- *Centralized Knowledge for AI — Comprehensive* — the full architecture
- *Operational Data for AI — Reach, Understand, Act* — connecting CRM/databases/BI
- *Semantic-Layer MCP — Design* — trustworthy answers over business data
- *System Memory for AI — Capture, Store, Recall, Forget* — how the AI's memory works
- *Claude Cowork — Sandbox Architecture* — the security model in detail

## References

- [Anthropic — Claude Cowork](https://www.anthropic.com/product/claude-cowork)
- [Anthropic — Use connectors to extend Claude's capabilities](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)
- [Anthropic — How we contain Claude across products](https://www.anthropic.com/engineering/how-we-contain-claude)

