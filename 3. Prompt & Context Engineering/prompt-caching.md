# Prompt Caching

> **One idea to remember:** prompt caching is a **prefix match** over the exact bytes of your request. The provider saves the model's internal state (the KV cache) for the start of your prompt. If the next request starts with the *exact same bytes*, the provider skips re-computing that part. Any change early in the prompt invalidates everything after it.

## 1. Why caching exists

Every LLM request is stateless. The API re-reads your whole prompt — system prompt, tool definitions, documents, chat history — on every call. For an agent or chatbot, 90%+ of each request is identical to the previous one. Re-computing it wastes money and adds latency.

Prompt caching fixes this: the provider stores the computed attention state (key/value tensors) for a prompt prefix and reuses it. Results:

- **Cost:** cached tokens cost ~10% of normal input price (all three providers converge on ~90% off for reads).
- **Latency:** time-to-first-token drops a lot (OpenAI reports up to 80% faster on long prompts).

## 2. How to make work cacheable (provider-neutral rules)

These rules apply everywhere, because all three providers do prefix matching:

1. **Stable content first, volatile content last.** Order: tool definitions → system prompt → documents/examples → chat history → the new question. The request is rendered in this order, so the stable part forms the reusable prefix.
2. **Freeze the prefix byte-for-byte.** Common silent cache killers:
   - `datetime.now()` / `Date.now()` interpolated into the system prompt
   - UUIDs or request IDs early in the content
   - `json.dumps(d)` without `sort_keys=True` (key order changes between runs)
   - a tool list built per-user or per-request (tools render at position 0 — changing them kills the whole cache)
   - conditional system sections (`if flag: system += ...`) — every flag combination is a different prefix
3. **Append, never edit.** In multi-turn chat, only add new messages at the end. Editing the system prompt or an old message mid-conversation re-processes the whole history uncached. (Claude has a beta for mid-conversation `role: "system"` messages exactly so you can inject instructions *after* the cached history.)
4. **Don't switch model or tools mid-session.** Caches are scoped per model; tool changes invalidate position 0.
5. **Mind the minimum size.** Short prompts never cache (OpenAI ≥1024 tokens; Claude 1024–4096 depending on model; Gemini 1024–4096 depending on model). No error is raised — it just silently doesn't cache.
6. **Verify with the usage fields.** All three report cache hits in the response. If cache reads stay at zero across identical requests, a silent invalidator is at work — diff the rendered bytes of two requests.

## 3. The three strategies, compared

The big design difference is **who controls the cache**:

| | **OpenAI** | **Claude (Anthropic)** | **Gemini (Google)** |
|---|---|---|---|
| Mode | Automatic only | Explicit breakpoints (`cache_control`) | Both: implicit (auto) + explicit (`CachedContent` object) |
| You must do | Nothing (optionally `prompt_cache_key`) | Mark up to 4 blocks with `cache_control` | Implicit: nothing. Explicit: create/manage a cache resource with the API |
| Min tokens | 1,024 | 1,024–4,096 (per model; e.g. Opus 4.8 = 4,096, Sonnet 4.6 = 2,048) | 2,048 (Gemini 2.5) / 4,096 (Gemini 3.x) |
| Write cost | Free | **1.25×** input price (5-min TTL) or **2×** (1-hour TTL) | Free to write; you pay **storage** for explicit caches (~$1 / 1M tokens / hour) |
| Read cost | ~10% of input price (90% off) | ~10% of input price | ~10% of input price |
| Lifetime (TTL) | 5–10 min idle, max 1 h (up to 24 h on newer GPT-5.x models) | 5 min default, refreshed on every hit; optional 1 h | Implicit: short, not guaranteed. Explicit: you set TTL (default 1 h, any duration) |
| Guarantee | Best-effort (routing-dependent) | Deterministic — a breakpoint either hits or writes | Implicit: best-effort. Explicit: guaranteed while the cache lives |
| Routing control | `prompt_cache_key` to stick requests to the same cache node | Not needed (key is the prefix itself) | Explicit cache referenced by name (`cachedContents/xyz`) |
| Verify via | `usage.prompt_tokens_details.cached_tokens` | `usage.cache_read_input_tokens` / `cache_creation_input_tokens` | `usageMetadata.cachedContentTokenCount` |

### OpenAI — automatic, zero effort, best-effort

Nothing to configure. The API hashes the start of your prompt, routes the request to a machine that may hold that prefix, and discounts whatever matched.

- Free writes and a 90% read discount mean there is no downside — but also no guarantee. Hit rate depends on routing: if many machines serve your traffic, identical requests can land on a cold node.
- `prompt_cache_key` is the one knob: pass a stable key (e.g. per-tenant or per-prompt-template) so requests with the same long prefix route to the same node. Keep each key under ~15 requests/minute or the node overflows.
- Strategy in one line: *order your prompt correctly, pass a cache key, and check `cached_tokens`.*

```python
resp = client.chat.completions.create(
    model="gpt-5.2",
    messages=[{"role": "system", "content": BIG_STABLE_PROMPT},
              {"role": "user", "content": question}],
    prompt_cache_key="support-bot-v3",
)
print(resp.usage.prompt_tokens_details.cached_tokens)
```

### Claude — explicit, deterministic, you pay to write

You place `cache_control: {"type": "ephemeral"}` on content blocks (max 4 breakpoints per request). Each breakpoint says "cache everything up to here". Render order is `tools → system → messages`, so a breakpoint on the last system block caches tools + system together.

- **Writes cost extra** (1.25× for 5-min TTL, 2× for 1-h TTL), so caching a prefix you reuse only once *loses* money. Break-even: 2 requests (5-min TTL), 3 requests (1-h TTL).
- The 5-minute TTL refreshes on every cache hit, so steady traffic keeps the cache warm for free.
- Deterministic: same prefix + breakpoint → guaranteed read. This is why agent harnesses (Claude Code included) are built on it — the multi-turn pattern is "move the breakpoint to the last block of the newest turn; every request reuses the whole prior conversation."
- You can pre-warm with a `max_tokens: 0` request at startup so the first real user never pays the cold-write latency.
- Strategy in one line: *put breakpoints at stability boundaries (end of system prompt, end of last turn) and make sure each cached prefix is read at least twice.*

```python
resp = client.messages.create(
    model="claude-opus-4-8",
    max_tokens=16000,
    system=[{"type": "text", "text": BIG_STABLE_PROMPT,
             "cache_control": {"type": "ephemeral"}}],   # or "ttl": "1h"
    messages=[{"role": "user", "content": question}],
)
print(resp.usage.cache_read_input_tokens, resp.usage.cache_creation_input_tokens)
```

### Gemini — two layers: free implicit + managed explicit

- **Implicit caching** (Gemini 2.5+) works like OpenAI: automatic, no setup, savings passed on when a request happens to hit, no guarantee.
- **Explicit caching** is unique: you create a **`CachedContent` resource** — a server-side object holding the system instruction + contents (e.g. a long video, a code repo, a big PDF) with a TTL you choose. Later requests reference the cache by name instead of resending the tokens.
- Pricing model is different: reads are ~90% off like the others, but you pay **storage rent** (~$1 per 1M tokens per hour) for as long as the explicit cache lives. So an explicit cache is an *investment*: great for "1M-token video analyzed by 500 user questions over a day", wasteful for a prefix used twice.
- You can update a cache's TTL or delete it early to stop the rent.
- Strategy in one line: *rely on implicit caching by default; create an explicit cache when one big context will be queried many times over a known time window.*

```python
cache = client.caches.create(
    model="gemini-2.5-pro",
    config=types.CreateCachedContentConfig(
        system_instruction=BIG_STABLE_PROMPT,
        contents=[big_document],
        ttl="3600s",
    ),
)
resp = client.models.generate_content(
    model="gemini-2.5-pro",
    contents=question,
    config=types.GenerateContentConfig(cached_content=cache.name),
)
print(resp.usage_metadata.cached_content_token_count)
```

## 4. Which strategy fits which workload

| Workload | Best fit | Why |
|---|---|---|
| Simple chatbot / RAG with a shared system prompt | OpenAI auto or Gemini implicit | Zero effort, free writes, decent hit rate |
| Agent loop (many turns, tools, long history) | Claude explicit breakpoints | Deterministic incremental caching of the growing transcript; TTL refresh on every hit keeps it warm |
| One huge context (video, repo, book) queried many times over hours | Gemini explicit cache | Pay rent once, guaranteed hits, no need to resend tokens at all |
| Bursty traffic with long idle gaps | Claude 1-h TTL, or Gemini explicit with long TTL | Auto caches (OpenAI/implicit) evict in minutes |
| Fan-out: N parallel requests, same prefix | Any — but warm first | A cache entry is readable only after the first response starts. Send 1 request, wait for the first token, then fire the other N−1 |

## 5. Mental model summary

- **OpenAI:** "We cache for you, trust us." Convenience-first; tune only ordering + `prompt_cache_key`.
- **Claude:** "Tell us exactly what to cache; pay to write, save on reads." Control-first; the right primitive for agents, but a mis-placed breakpoint (or a one-shot prefix) costs money.
- **Gemini:** "Auto for free, or rent a named context object." The explicit cache is a different abstraction — a stored resource with a lifecycle, not a prefix marker.

All three are the same machine underneath (KV-cache reuse over a byte-identical prefix). The differences are about **who decides** (provider vs you), **what you pay** (write premium vs storage rent vs nothing), and **what is guaranteed** (deterministic vs best-effort).

## References

- [Anthropic — Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [OpenAI — Prompt caching guide](https://developers.openai.com/api/docs/guides/prompt-caching)
- [Google — Gemini context caching](https://ai.google.dev/gemini-api/docs/caching)
- [Gemini API pricing (cached token + storage rates)](https://ai.google.dev/gemini-api/docs/pricing)
