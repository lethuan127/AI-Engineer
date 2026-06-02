# CV Versions

The resume is versioned by time. Each snapshot is `LÊ VĂN THUẬN-YYYY-MM.md`, and
`LÊ VĂN THUẬN.md` is a **symlink to the latest** so tools and skills have a stable path.

| Version | Date | Status | Summary |
|---|---|---|---|
| [2026-06](./LÊ%20VĂN%20THUẬN-2026-06.md) | Jun 2026 | **current** ← symlink | Adds **Senior AI Engineer \| Vireox** (Oct 2025–present) as the lead role; adds **AWS Certified Solutions Architect – Associate**; reformatted to standard dash bullets and ATS-friendly headings. **Rev 2026-06-02:** rewrote the Vireox role from the work-tracking logs (`/activity-to-resume`). **Rev 2026-06-02b — structural redesign:** switched to an experience-led layout — removed the duplicate Notable Projects section (named products now folded into role bullets), tightened the 4-paragraph summary to one AI-forward paragraph, moved grouped AI-first Core Skills near the top, merged Education + Certifications, resolved the CQ "Present" date conflict (CQ folded into Rennlabs), and added a one-line contact header. **Rev 2026-06-02c — review pass:** replaced vanity activity counts (583+ commits, "9 incident tickets") with scope/impact framing, and polished the reliability bullet. **Rev 2026-06-02d:** added a problem-solver trait to the summary — solving technical + business problems by combining multiple techniques, with two technical→business proof points (background-mode pipeline ended outages; batch-processing cut LLM cost 60%). **Rev 2026-06-03:** split the dense summary into a tight 3-line summary + a front-loaded **Highlights** strip (4 achievement one-liners spanning platform ownership, technical→business impact, scale, and OSS/cert credibility). **Rev 2026-06-03b — ATS pass:** added canonical spell-outs and high-frequency synonyms to the AI/LLM skills line — Large Language Models (LLMs), Generative AI, Retrieval-Augmented Generation (RAG), embeddings, prompt engineering, fuller model-provider names + Vertex AI; formatting already ATS-clean. |
| [2025-09](./LÊ%20VĂN%20THUẬN-2025-09.md) | Sep 2025 | archived | Pre-Vireox baseline. Leads with Software Engineer \| Rennlabs; no Certifications section; asterisk-bullet formatting. |

## What changed: 2025-09 → 2026-06

- **+ New lead role** — Senior AI Engineer at Vireox (agent & product architecture, intelligent
  agent systems, agent-driven team automation).
- **+ Certifications** section — AWS Certified Solutions Architect – Associate.
- **Formatting** — `*` bullets → `-` bullets; consistent blank-line spacing; standard section
  headings (better ATS parsing).
- *Not yet reflected:* the detailed Vireox work in `vireox(100x) work tracking/` (report platform,
  KB platform, MCP gateway, runtime migration, Agno OSS) — the current Vireox bullets are still
  high-level. Run `/activity-to-resume` to cut the next version from those logs.

## Convention

- **Filename:** `LÊ VĂN THUẬN-YYYY-MM.md` (year-month of the snapshot).
- **Current pointer:** `LÊ VĂN THUẬN.md` → newest dated file (relative symlink).
- **Read** facts from the symlink; **never edit** an archived dated snapshot.

## Cutting a new version

```sh
cd "CV"
cp "LÊ VĂN THUẬN-2026-06.md" "LÊ VĂN THUẬN-2026-09.md"   # 1. copy latest → new date
# 2. edit ONLY the new dated file
ln -sf "LÊ VĂN THUẬN-2026-09.md" "LÊ VĂN THUẬN.md"        # 3. re-point the symlink
# 4. add a row to this file
```
