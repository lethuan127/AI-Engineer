# Connectors & MCP Server Categories — Anthropic's Knowledge-Work Plugins

> Lookup note. Start at §2: find your category, read across for the MCP servers that are candidates for it. §4 gives the endpoint once you have picked one.

Source: [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins), compiled from every `CONNECTORS.md` in the repo (17 files), every in-repo `.mcp.json` (21 files), and the root `marketplace.json`. Scanned at HEAD `e1f73c1`, 2026-08-13.

## 1. How to read this

The 15 first-party plugins are **tool-agnostic**. Skill files never name a vendor — they reference a `~~category` placeholder (`~~chat`, `~~CRM`, `~~data warehouse`) and the user's connected MCP server for that category fills the slot. Each plugin's `.mcp.json` pre-wires one or more real servers per category, and its `CONNECTORS.md` documents both those and the alternatives Anthropic considers valid substitutes.

That gives every category three tiers of candidate, which are the three middle columns of the index below:

| Tier | What it means | Confidence |
|---|---|---|
| **Pre-wired** | An entry in some plugin's `.mcp.json`. Endpoint is in §4. Works out of the box. | Verified — it's in the config |
| **Named alternative** | Listed under "Other options" in a `CONNECTORS.md`. Anthropic asserts the category fits; no endpoint shipped. | Anthropic's claim, unverified here |
| **Marketplace plugin** | A separate plugin in `marketplace.json` covering the same ground, usually the vendor's own full tool surface. | Exists; connector surface not readable from this repo |

Legend: `*` = declared in `.mcp.json` with an empty `url` (not wired yet). `‡` = `CONNECTORS.md` calls it included but no `.mcp.json` anywhere defines it — documentation only. `†` = my mapping, not a category the repo declares.

> Why the tiers matter: "pre-wired" and "named alternative" are not the same claim. Anthropic shipping a URL means the integration exists today; Anthropic listing "Redshift" under other options means the category is conceptually open, not that a Redshift MCP server is waiting for you.

## 2. Category → MCP server candidates

44 categories, merged across all 17 `CONNECTORS.md` files. "Plugins" counts how many first-party plugins declare the category.

| Category | Placeholder | Pre-wired | Named alternatives | Marketplace plugin | Plugins |
|---|---|---|---|---|---|
| **AI research** | `~~AI research` | Owkin | — | — | 1 |
| **ATS** | `~~ATS` | — | Greenhouse, Lever, Ashby, Workable | — | 1 |
| **Analytics / BI** | `~~analytics` | — | Tableau, Looker, Power BI | Atlan†, Bigdata.com† | 1 |
| **CI/CD** | `~~CI/CD` | — | CircleCI, GitHub Actions, Jenkins, BuildKite | `buildkite`, `valtown` | 1 |
| **CLM** | `~~CLM` | — | Ironclad, Agiloft | — | 1 |
| **CRM** | `~~CRM` | HubSpot, Close, monday | Salesforce, Pipedrive, Copper | `monday-crm`, `carta-crm`, `common-room` | 4 |
| **Calendar** | `~~calendar` | Google Calendar*, Microsoft 365‡ | Outlook / Microsoft 365 Calendar | — | 7 |
| **Chat** | `~~chat` | Slack | Microsoft Teams, Discord | `slack-by-salesforce` | 12 |
| **Chemical database** | `~~chemical database` | ChEMBL | PubChem, DrugBank | — | 1 |
| **Clinical trials** | `~~clinical trials` | ClinicalTrials.gov | EU Clinical Trials Register | — | 1 |
| **Cloud storage** | `~~cloud storage` | Box, Egnyte, Microsoft 365‡ | Dropbox, SharePoint, Google Drive | `box`, `dropbox` | 3 |
| **Compensation data** | `~~compensation data` | — | Pave, Radford, Levels.fyi | — | 1 |
| **Competitive intelligence** | `~~competitive intelligence` | Similarweb | Crayon, Klue | `bigdata-com`† | 2 |
| **Data enrichment** | `~~data enrichment` | Clay, ZoomInfo, Apollo | Clearbit, Lusha | `zoominfo`, `lusha`, `apollo`, `vibe-prospecting`, `grasp` | 1 |
| **Data repository** | `~~data repository` | Synapse | Zenodo, Dryad, Figshare | — | 1 |
| **Data warehouse** | `~~data warehouse` | BigQuery, Definite, Snowflake*, Databricks* | Redshift, PostgreSQL, MySQL | `clickhouse`, `planetscale`, `cockroachdb`, `prisma`, `atlan`† | 2 |
| **Design / Design tool** | `~~design` `~~design tool` | Figma, Canva | Sketch, Adobe XD, Framer, Adobe Creative Cloud | `figma`, `canva`, `adobe-for-creativity`, `miro`, `b12-claude-plugin`, `cloudinary` | 3 |
| **Drug targets** | `~~drug targets` | Open Targets | UniProt, STRING | — | 1 |
| **E-signature** | `~~e-signature` | DocuSign | Adobe Sign | — | 1 |
| **ERP / Accounting** | `~~erp` | — | NetSuite, SAP, QuickBooks, Xero | `airwallex-agentos`, `carta-cap-table` | 1 |
| **Email** | `~~email` | Gmail*, Microsoft 365‡ | — | — | 9 |
| **Email marketing** | `~~email marketing` | Klaviyo | Mailchimp, Brevo, Customer.io | `postiz`† | 1 |
| **HRIS** | `~~HRIS` | — | Workday, BambooHR, Rippling, Gusto | — | 1 |
| **ITSM** | `~~ITSM` | ServiceNow‡ — nothing actually wired | Zendesk, Freshservice, Jira Service Management | `servicenow-sdk` | 1 |
| **Incident management** | `~~incident management` | PagerDuty | Opsgenie, Incident.io, FireHydrant | — | 1 |
| **Journal access** | `~~journal access` | Wiley Scholar Gateway | Elsevier, Springer Nature | — | 1 |
| **Knowledge base** | `~~knowledge base` | Notion, Guru, Atlassian (Confluence) | Help Scout, Coda, Slite | `sanity-plugin`, `mintlify` | 10 |
| **Lab platform** | `~~lab platform` | Benchling* | — | — | 1 |
| **Literature** | `~~literature` | PubMed, bioRxiv, Consensus | Google Scholar, Semantic Scholar | — | 1 |
| **Marketing analytics** | `~~marketing analytics` | Supermetrics | Google Analytics, Mailchimp, Semrush | `adspirer-ads-agent` | 1 |
| **Marketing automation** | `~~marketing automation` | HubSpot | Marketo, Pardot, Mailchimp | `postiz` | 1 |
| **Meeting transcription** | `~~meeting transcription` `~~conversation intelligence` | Fireflies | Gong, Dovetail, Otter.ai, Chorus | `zoom-plugin`, Gong + Granola (via `brand-voice`) | 2 |
| **Monitoring** | `~~monitoring` | Datadog | New Relic, Grafana, Splunk | `datadog`, `grafana-assistant`, `grafana-cloud-mcp`, `honeycomb`, `signoz`, `langfuse` | 1 |
| **Notebook** | `~~notebook` | Hex | Jupyter, Deepnote, Observable | — | 1 |
| **Office suite** | `~~office suite` | Microsoft 365‡ — nothing actually wired | Google Workspace | — | 5 |
| **Procurement** | `~~procurement` | — | Coupa, SAP Ariba, Zip | — | 1 |
| **Product analytics** | `~~product analytics` | Amplitude, Pendo | Mixpanel, Heap, FullStory, Google Analytics | `product-tracking-skills` | 4 |
| **Project tracker** | `~~project tracker` | Linear, Asana, Atlassian (Jira/Confluence), monday.com, ClickUp | Shortcut, Basecamp, Wrike | `monday-com`, `airtable` | 10 |
| **SEO** | `~~SEO` | Ahrefs, Similarweb | Semrush, Moz | `searchfit-seo` | 1 |
| **Sales engagement** | `~~sales engagement` | Outreach | Salesloft, Apollo | `apollo` | 1 |
| **Scientific illustration** | `~~scientific illustration` | BioRender | — | — | 1 |
| **Source control** | `~~source control` | GitHub | GitLab, Bitbucket | `gitkraken` | 1 |
| **Support platform** | `~~support platform` | Intercom | Zendesk, Freshdesk, HubSpot Service Hub | `intercom` | 1 |
| **User feedback** | `~~user feedback` | Intercom | Productboard, Canny, UserVoice, Dovetail | — | 2 |

### 2.1 Categories only the marketplace covers

No first-party plugin declares these, so there is no `~~placeholder` and no pre-wired server — but the marketplace has candidates. Category names here are mine.

| Category† | Marketplace plugins |
|---|---|
| Web search / scraping | `tavily`, `exa`, `brightdata-plugin`, `nimble`, `browser-use`, `tinyfish` |
| Security & compliance | `vanta-mcp-plugin`, `auth0`, `stackhawk-api`, `stackhawk-hawkscan` |
| Vector / AI data platform | `qdrant-skills`, `pixeltable`, `datarobot-agent-skills` |
| Financial market data | `daloopa`, `lseg`, `sp-global`, `bigdata-com` |
| Cap table & investor ops | `carta-cap-table`, `carta-investors` |
| App / site builders | `base44`, `wix`, `b12-claude-plugin`, `valtown` |
| Workflow automation | `zapier`, `synthflow`, `desktop-commander` |
| Payments | Stripe, Square, PayPal, QuickBooks (all pre-wired in `small-business` only) |
| Experimentation | `growthbook` |
| Document generation | `carbone-skill` |
| Learning | `learn-with-coursera` |

## 3. Worked example

> "Show me MCP options for data warehouse."
>
> §2 row **Data warehouse**, placeholder `~~data warehouse`, used by `data` and `finance`.
> **Pre-wired and usable today:** BigQuery (`https://bigquery.googleapis.com/mcp`), Definite (`https://api.definite.app/v3/mcp/http`).
> **Declared but dead:** Snowflake and Databricks — both are in `.mcp.json` with `"url": ""`, so the plugins name them in workflows but ship nothing to connect to. If you need either, bring your own server.
> **Anthropic says these fit:** Redshift, PostgreSQL, MySQL — no MCP server shipped, you supply one.
> **Standalone plugins in the same space:** ClickHouse, PlanetScale, CockroachDB, Prisma (Postgres), plus Atlan for catalog/governance rather than query.
>
> The answer is BigQuery unless you are already on something else, and the trap is assuming Snowflake works because `data/.mcp.json` mentions it.

## 4. Endpoint reference — the 61 pre-wired servers

Deduped across all 21 in-repo `.mcp.json` files. "Plugins" counts how many wire that key.

| Server key | Transport | Endpoint | Plugins |
|---|---|---|---|
| `slack` | http | `https://mcp.slack.com/mcp` (only entry carrying an `oauth` block: `clientId`, `callbackPort` 3118) | 14 |
| `gmail` | http | (empty) | 13 |
| `google calendar` | http | (empty) | 13 |
| `atlassian` | http | `https://mcp.atlassian.com/v1/mcp` | 12 |
| `notion` | http | `https://mcp.notion.com/mcp` | 11 |
| `asana` | http | `https://mcp.asana.com/v2/mcp` | 6 |
| `figma` | http | `https://mcp.figma.com/mcp` | 4 |
| `hubspot` | http | `https://mcp.hubspot.com/anthropic` | 4 |
| `linear` | http | `https://mcp.linear.app/mcp` | 4 |
| `amplitude` | http | `https://mcp.amplitude.com/mcp` | 3 |
| `amplitude-eu` | http | `https://mcp.eu.amplitude.com/mcp` | 3 |
| `intercom` | http | `https://mcp.intercom.com/mcp` | 3 |
| `monday` | http | `https://mcp.monday.com/mcp` | 3 |
| `similarweb` | http | `https://mcp.similarweb.com` | 3 |
| `apollo` | http | `https://mcp.apollo.io/mcp` | 2 |
| `bigquery` | http | `https://bigquery.googleapis.com/mcp` | 2 |
| `box` | http | `https://mcp.box.com` | 2 |
| `canva` | http | `https://mcp.canva.com/mcp` | 2 |
| `clickup` | http | `https://mcp.clickup.com/mcp` | 2 |
| `databricks` | http | (empty) | 2 |
| `docusign` | http | `https://mcp.docusign.com/mcp` | 2 |
| `fireflies` | http | `https://api.fireflies.ai/mcp` | 2 |
| `guru` | http | `https://mcp.api.getguru.com/mcp` | 2 |
| `snowflake` | http | (empty) | 2 |
| `ahrefs` | http | `https://api.ahrefs.com/mcp/mcp` | 1 |
| `benchling` | http | (empty) | 1 |
| `biorender` | http | `https://mcp.services.biorender.com/mcp` | 1 |
| `biorxiv` | http | `https://hcls.mcp.claude.com/biorxiv/mcp` | 1 |
| `c-trials` | http | `https://hcls.mcp.claude.com/clinical_trials/mcp` | 1 |
| `chembl` | http | `https://hcls.mcp.claude.com/chembl/mcp` | 1 |
| `clay` | http | `https://api.clay.com/v3/mcp` | 1 |
| `close` | http | `https://mcp.close.com/mcp` | 1 |
| `common-room` | http | `https://mcp.commonroom.io/mcp` | 1 |
| `consensus` | http | `https://mcp.consensus.app/mcp` | 1 |
| `datadog` | http | `https://mcp.datadoghq.com/api/unstable/mcp-server/mcp` | 1 |
| `definite` | http | `https://api.definite.app/v3/mcp/http` | 1 |
| `egnyte` | http | `https://mcp-server.egnyte.com/mcp` | 1 |
| `github` | http | `https://api.githubcopilot.com/mcp/` | 1 |
| `gong` | http | `https://mcp.gong.io/mcp` | 1 |
| `google drive` | http | (empty) | 1 |
| `granola` | http | `https://mcp.granola.ai/mcp` | 1 |
| `hex` | http | `https://app.hex.tech/mcp` | 1 |
| `klaviyo` | http | `https://mcp.klaviyo.com/mcp` | 1 |
| `ot` | http | `https://mcp.platform.opentargets.org/mcp` | 1 |
| `outreach` | http | `https://api.outreach.io/mcp/` | 1 |
| `owkin` | http | `https://mcp.k.owkin.com/mcp` | 1 |
| `pagerduty` | http | `https://mcp.pagerduty.com/mcp` | 1 |
| `paypal` | sse | `https://mcp.paypal.com/sse` | 1 |
| `pdf` | stdio | `npx -y @modelcontextprotocol/server-pdf --stdio` | 1 |
| `pendo` | http | `https://app.pendo.io/mcp/v0/shttp` | 1 |
| `pubmed` | http | `https://pubmed.mcp.claude.com/mcp` | 1 |
| `quickbooks` | http | `https://ai-inc.quickbooks.intuit.com/v1/mcp` | 1 |
| `square` | http | `https://mcp.squareup.com/sse` | 1 |
| `stripe` | http | `https://mcp.stripe.com` | 1 |
| `supermetrics` | http | `https://mcp.supermetrics.com/mcp` | 1 |
| `synapse` | http | `https://mcp.synapse.org/mcp` | 1 |
| `wiley` | http | `https://connector.scholargateway.ai/mcp` | 1 |
| `zoom-docs-mcp` | http | `https://mcp.zoom.us/mcp/docs/streamable` | 1 |
| `zoom-mcp` | http | `https://mcp-us.zoom.us/mcp/zoom/streamable` | 1 |
| `zoom-whiteboard-mcp` | http | `https://mcp-us.zoom.us/mcp/whiteboard/streamable` | 1 |
| `zoominfo` | http | `https://mcp.zoominfo.com/mcp` | 1 |

Every connector is remote HTTP except `paypal` (SSE), `square` (declared `http` but the URL is an `/sse` path — likely a config bug), and `pdf` (the one local stdio server in the whole repo). Anthropic hosts four itself under `*.mcp.claude.com` — `pubmed`, `biorxiv`, `chembl`, `clinical_trials`, all in `bio-research`; the rest point at vendor-operated endpoints.

## 5. Inverse lookup — plugin → wired connectors

| Plugin | Path | Servers | `.mcp.json` server keys |
|---|---|---|---|
| `productivity` | ./productivity | 9 | slack, notion, asana, linear, atlassian, monday, clickup, google calendar*, gmail* |
| `enterprise-search` | ./enterprise-search | 7 | slack, notion, guru, atlassian, asana, google calendar*, gmail* |
| `cowork-plugin-management` | ./cowork-plugin-management | 0 | no `.mcp.json` — meta-plugin |
| `sales` | ./sales | 14 | slack, hubspot, close, monday, clay, zoominfo, notion, atlassian, fireflies, apollo, outreach, google calendar*, gmail*, similarweb |
| `finance` | ./finance | 6 | snowflake*, databricks*, bigquery, slack, google calendar*, gmail* |
| `data` | ./data | 8 | snowflake*, databricks*, bigquery, hex, amplitude, amplitude-eu, atlassian, definite |
| `legal` | ./legal | 7 | slack, box, egnyte, atlassian, docusign, google calendar*, gmail* |
| `marketing` | ./marketing | 13 | slack, canva, figma, hubspot, amplitude, amplitude-eu, notion, ahrefs, similarweb, klaviyo, supermetrics, google calendar*, gmail* |
| `customer-support` | ./customer-support | 8 | slack, intercom, hubspot, guru, atlassian, notion, google calendar*, gmail* |
| `product-management` | ./product-management | 16 | slack, linear, asana, monday, clickup, atlassian, notion, figma, amplitude, amplitude-eu, pendo, intercom, fireflies, google calendar*, gmail*, similarweb |
| `bio-research` | ./bio-research | 11 | pubmed, biorender, biorxiv, consensus, c-trials, chembl, synapse, wiley, owkin, ot, benchling* |
| `engineering` | ./engineering | 10 | slack, linear, asana, atlassian, notion, github, pagerduty, datadog, google calendar*, gmail* |
| `human-resources` | ./human-resources | 5 | slack, google calendar*, gmail*, notion, atlassian |
| `design` | ./design | 9 | slack, figma, linear, asana, atlassian, notion, intercom, google calendar*, gmail* |
| `operations` | ./operations | 6 | slack, google calendar*, gmail*, notion, atlassian, asana |
| `small-business` | ./small-business | 11 | quickbooks, paypal, hubspot, canva, docusign, slack, stripe, square, gmail*, google calendar*, google drive* |
| `pdf-viewer` | ./pdf-viewer | 1 | pdf (stdio) |
| `slack-by-salesforce` | ./partner-built/slack | 1 | slack |
| `apollo` | ./partner-built/apollo | 1 | apollo |
| `common-room` | ./partner-built/common-room | 1 | common-room |
| `brand-voice` | ./partner-built/brand-voice | 6 | notion, atlassian, box, figma, gong, granola |
| `zoom-plugin` | ./partner-built/zoom-plugin | 3 | zoom-mcp, zoom-docs-mcp, zoom-whiteboard-mcp |

Five partner plugins are vendored in-repo under `partner-built/` and are single-vendor rather than category-based: `common-room` (Common Room MCP is the required primary source; only one optional category, Calendar), `zoom-plugin` (bearer-token env auth, no category system at all), `slack-by-salesforce` and `apollo` (one server each), and `brand-voice` by Tribe AI — the exception, which wires six servers as evidence sources without using the `~~category` system. `cowork-plugin-management` (meta-plugin) and `small-business` skip the pattern too: `small-business` has a populated `.mcp.json` but no `CONNECTORS.md`.

## 6. Marketplace inventory

94 plugin entries at HEAD `e1f73c1`, owner `Anthropic`. Two classes:

- **22 vendored in-repo** — `source` is a local path. Their connectors are the §5 table.
- **72 externally sourced** — `source` is an object pointing at a third-party GitHub repo pinned by `sha`: 44 use `{"source": "url"}` (whole repo is the plugin), 28 use `{"source": "git-subdir"}` (plugin lives at `path` inside a larger repo). MCP wiring lives in the vendor's repo, not here.

`category` is declared on only 58 of 94: productivity 18, development 13, monitoring 6, design 4, security 4, automation 3, database 3, finance 3, deployment 2, learning 1, testing 1 — 36 have none. The field is optional and clearly retro-fitted; the 15 first-party plugins declare no `category` at all.

| Category | Plugin | Source repo | Kind |
|---|---|---|---|
| automation | Browser Use (`browser-use`) | `browser-use/plugins/browser-use` | git-subdir |
| automation | Synthflow (`synthflow`) | `SynthFlowAI/AnthropicPlugin/plugins/synthflow` | git-subdir |
| automation | TinyFish (`tinyfish`) | `tinyfish-io/tinyfish-web-agent-integrations/claude` | git-subdir |
| database | ClickHouse (`clickhouse`) | `ClickHouse/clickhouse-claude-code-plugin` | url |
| database | PlanetScale (`planetscale`) | `planetscale/claude-plugin` | url |
| database | Qdrant (`qdrant-skills`) | `qdrant/skills` | url |
| deployment | Buildkite (`buildkite`) | `buildkite/skills` | url |
| deployment | Val Town (`valtown`) | `val-town/plugins/plugin` | git-subdir |
| design | Adobe for Creativity (`adobe-for-creativity`) | `adobe/skills/plugins/creative-cloud/adobe-for-creativity` | git-subdir |
| design | B12 (`b12-claude-plugin`) | `b12io/b12-claude-plugin` | url |
| design | Canva (`canva`) | `canva-sdks/canva-skills/plugins/canva` | git-subdir |
| design | Figma (`figma`) | `figma/mcp-server-guide` | url |
| development | base44 (`base44`) | `base44/skills` | url |
| development | DataRobot (`datarobot-agent-skills`) | `datarobot-oss/datarobot-agent-skills` | url |
| development | GitKraken (`gitkraken`) | `gitkraken/claude-plugin` | url |
| development | Mintlify (`mintlify`) | `mintlify/mintlify-claude-plugin` | url |
| development | Modern Web Guidance (`modern-web-guidance`) | `GoogleChrome/modern-web-guidance` | url |
| development | Pixeltable (`pixeltable`) | `pixeltable/pixeltable-skill` | url |
| development | Qodo (`qodo-skills`) | `qodo-ai/qodo-skills` | url |
| development | Qt (`qt-development-skills`) | `TheQtCompanyRnD/agent-skills` | url |
| development | Sanity (`sanity-plugin`) | `sanity-io/agent-toolkit` | url |
| development | ServiceNow SDK (`servicenow-sdk`) | `ServiceNow/sdk/providers/claude/plugin` | git-subdir |
| development | Tavily (`tavily`) | `tavily-ai/skills` | url |
| development | Twilio (`twilio-developer-kit`) | `twilio/ai` | url |
| development | Wix (`wix`) | `wix/skills` | url |
| finance | Daloopa (`daloopa`) | `daloopa/plugin` | url |
| finance | LSEG (`lseg`) | `LSEG-API-Samples/lseg-claude-plugin` | url |
| finance | S&P Global (`sp-global`) | `kensho-technologies/spglobal-agent-skills/plugins/spglobal-plugin` | git-subdir |
| learning | Learn with Coursera (`learn-with-coursera`) | `coursera/skills/skills` | git-subdir |
| monitoring | Datadog (`datadog`) | `datadog-labs/claude-code-plugin` | url |
| monitoring | Grafana Assistant (`grafana-assistant`) | `grafana/ai-marketplace/plugins/grafana-assistant` | git-subdir |
| monitoring | Grafana Cloud MCP (`grafana-cloud-mcp`) | `grafana/ai-marketplace/plugins/grafana-cloud-mcp` | git-subdir |
| monitoring | Honeycomb (`honeycomb`) | `honeycombio/agent-skill/honeycomb` | git-subdir |
| monitoring | Langfuse (`langfuse`) | `langfuse/skills` | url |
| monitoring | SigNoz (`signoz`) | `SigNoz/agent-skills/plugins/signoz` | git-subdir |
| productivity | Adspirer (`adspirer-ads-agent`) | `amekala/adspirer-mcp-plugin` | url |
| productivity | Airtable (`airtable`) | `Airtable/skills/plugins/airtable` | git-subdir |
| productivity | Airwallex AgentOS (`airwallex-agentos`) | `airwallex/airwallex-marketplace/plugins/airwallex-agentos` | git-subdir |
| productivity | Box (`box`) | `box/box-for-ai` | url |
| productivity | Carbone (`carbone-skill`) | `carboneio/carbone-skill` | url |
| productivity | Carta Cap Table (`carta-cap-table`) | `carta/plugins/plugins/carta-cap-table` | git-subdir |
| productivity | Carta CRM (`carta-crm`) | `carta/plugins/plugins/carta-crm` | git-subdir |
| productivity | Carta Investors (`carta-investors`) | `carta/plugins/plugins/carta-investors` | git-subdir |
| productivity | Desktop Commander (`desktop-commander`) | `wonderwhy-er/DesktopCommanderMCP/plugins/claude` | git-subdir |
| productivity | Dropbox (`dropbox`) | `dropbox/dropbox-ai-plugins/claude` | git-subdir |
| productivity | Exa (`exa`) | `exa-labs/exa-mcp-server` | url |
| productivity | Grasp (`grasp`) | `grasp-ai/grasp-mcp-plugin` | url |
| productivity | Intercom (`intercom`) | `intercom/claude-plugin-external` | url |
| productivity | Lusha (`lusha`) | `lusha-oss/lusha-mcp-plugin` | url |
| productivity | monday.com (`monday-com`) | `mondaycom/monday-claude-cowork-plugin` | url |
| productivity | monday CRM (`monday-crm`) | `mondaycom/mcp/plugins/monday-crm` | git-subdir |
| productivity | Vibe Prospecting (`vibe-prospecting`) | `explorium-ai/vibeprospecting-plugin` | url |
| productivity | Zapier (`zapier`) | `zapier/zapier-mcp/plugins/zapier` | git-subdir |
| security | Auth0 (`auth0`) | `auth0/agent-skills/plugins/auth0` | git-subdir |
| security | StackHawk API (`stackhawk-api`) | `stackhawk/agent-skills/plugins/api` | git-subdir |
| security | StackHawk HawkScan (`stackhawk-hawkscan`) | `stackhawk/agent-skills/plugins/hawkscan` | git-subdir |
| security | Vanta (`vanta-mcp-plugin`) | `VantaInc/vanta-mcp-plugin` | url |
| testing | GrowthBook (`growthbook`) | `growthbook/skills` | url |
| — | AI-Firstify (`ai-firstify`) | `techwolf-ai/ai-first-toolkit/plugins/ai-firstify` | git-subdir |
| — | Atlan (`atlan`) | `atlanhq/agent-toolkit` | url |
| — | Bigdata.com (`bigdata-com`) | `Bigdata-com/bigdata-plugins-marketplace/plugins/bigdata-com` | git-subdir |
| — | Bright Data (`brightdata-plugin`) | `brightdata/skills` | url |
| — | Cloudinary (`cloudinary`) | `cloudinary-devs/cloudinary-plugin` | url |
| — | CockroachDB (`cockroachdb`) | `cockroachdb/claude-plugin` | url |
| — | Fastly (`fastly-agent-toolkit`) | `fastly/fastly-agent-toolkit` | url |
| — | Miro (`miro`) | `miroapp/miro-ai/claude-plugins/miro` | git-subdir |
| — | Nimble (`nimble`) | `Nimbleway/agent-skills` | url |
| — | Postiz (`postiz`) | `gitroomhq/postiz-agent` | url |
| — | Prisma (`prisma`) | `prisma/claude-plugin` | url |
| — | Product Tracking (`product-tracking-skills`) | `Accoil/product-tracking-skills` | url |
| — | SearchFit SEO (`searchfit-seo`) | `searchfit/searchfit-seo` | url |
| — | ZoomInfo (`zoominfo`) | `Zoominfo/zoominfo-mcp-plugin` | url |

> Architectural takeaway: the marketplace is a **pinned-source index**, not a package registry. Every external entry carries a `sha`, so installs are reproducible and the vendor cannot silently change what ships — but it also means the connector surface of 72 of 94 plugins is invisible from this repo. A complete connector inventory including partner plugins requires resolving each `sha` and reading the vendor's own `.mcp.json`.

## 7. Traps when picking a candidate

**An empty `url` means two different things.** Six server keys are declared with `"url": ""`: Snowflake, Databricks (both `finance` and `data`), Benchling (`bio-research`), and the three Google connectors Gmail, Google Calendar, Google Drive. The first three read as genuine "not wired yet" placeholders. The Google three appear in 13, 13, and 1 plugins and are almost certainly resolved by the host rather than by URL. Same field, same value, opposite meaning — check which kind you are looking at before concluding a category is unusable.

**`CONNECTORS.md` overstates what is included.** Cross-checking every "Included servers" entry against the 61 real `.mcp.json` keys, two are documentation-only: **Microsoft 365** — claimed as included for Email, Office suite, Cloud storage, and Calendar across 8 plugins, but no `microsoft`/`office`/`outlook` key exists in any config — and **ServiceNow** for ITSM in `operations`. Everything else in an "Included" column resolves to a real key. This is the trap that bites hardest on lookup: `~~office suite` and `~~ITSM` read as covered and are not.

**Eight categories ship with zero pre-wired server by design** — Analytics/BI, ATS, CI/CD, CLM, Compensation data, ERP/Accounting, HRIS, Procurement — and the two above bring the real total to **ten** categories with nothing you can connect out of the box. The plugin describes the workflow and leaves the connector entirely to you. These are the categories where §2's "marketplace plugin" column matters most.

**Six vendors appear on both sides of the split.** Intercom, Box, Canva, Figma, Datadog, ZoomInfo are wired as category connectors inside first-party plugins *and* published as standalone partner plugins. The first-party wiring is a swappable category slot; the partner plugin is the vendor's own full tool surface. Prefer the partner plugin when you want depth in that one tool, the category slot when you want the plugin's workflows.

**Some vendors split across multiple plugins** rather than shipping one: Carta (cap-table / CRM / investors), Grafana (Assistant / Cloud MCP), StackHawk (API / HawkScan), monday.com (monday.com / monday CRM). Searching for one name can miss the plugin you actually want.

**Concentration.** Four connectors carry most of the suite: Slack (14 plugins), Gmail and Google Calendar (13 each), Atlassian (12), Notion (11). `bio-research` is the outlier — none of its nine categories (Literature, Scientific illustration, Clinical trials, Chemical database, Drug targets, Data repository, Journal access, AI research, Lab platform) is shared with any other plugin.

**Staleness.** The marketplace grew from ~50 to 94 entries between the 2026-08-11 and 2026-08-13 scans, almost entirely in externally-sourced partner plugins. Regenerate from a fresh `git clone https://github.com/anthropics/knowledge-work-plugins.git` rather than fetching individual raw GitHub URLs — fetches through a summarizing model risk light hallucination on file contents, so cross-check anything load-bearing against the clone.

## References

- [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins)
- [Anthropic — Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Anthropic — Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/specification)
