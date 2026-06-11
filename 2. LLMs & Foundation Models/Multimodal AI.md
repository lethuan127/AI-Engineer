# Multimodal AI — How LLMs Take In and Produce More Than Text

> **Multimodal** = the model works with more than one type of data ("modality"):
> text, images, audio, video. Examples: GPT-4o, Gemini, Claude (vision input).

---

## 1. The core idea: everything becomes tokens

A Transformer LLM only understands one thing: **a sequence of vectors**
(lists of numbers, called *embeddings*). Text, images, and audio are all
converted into this same format before the model sees them.

```
Text   ──► tokenizer       ──► text tokens   ─┐
Image  ──► vision encoder  ──► image tokens ──┼──► one shared sequence ──► Transformer
Audio  ──► audio encoder   ──► audio tokens ──┘
```

Once everything is in the same "token space," the Transformer does not care
where a token came from. Attention works the same way over an image token as
over a word token. **That is the whole trick.**

---

## 2. Input side — how each modality gets in

### Text
- A **tokenizer** (BPE / SentencePiece) splits text into sub-word pieces:
  `"understanding"` → `"under" + "stand" + "ing"`.
- Each piece maps to an embedding vector via a lookup table.
- Rule of thumb: 1 token ≈ 4 characters of English. Vietnamese and code are
  usually more tokens per character.

### Images
1. The image is cut into a grid of small squares called **patches**
   (often 14×14 or 16×16 pixels).
2. A **vision encoder** — usually a Vision Transformer (ViT), e.g. CLIP or
   SigLIP — turns each patch into a vector.
3. A small **projector** (1–2 linear layers; also called an "adapter" or
   "MLP connector") maps those vectors into the same embedding space as text
   tokens.

Result: a 1024×1024 image becomes ~1,000–1,500 tokens sitting **inside your
prompt**. More resolution → more patches → more tokens → more cost and latency.

### Audio
- Sound is first turned into a **spectrogram** (a picture of frequencies over
  time).
- An audio encoder converts chunks of it (e.g. every ~80 ms) into tokens.
- Same projector idea as images. Whisper-style encoders are common.

### Video
- Just **sampled frames** (images) plus optionally the audio track, with
  timestamps. So video = "many images + audio."
- This is why video is very token-expensive, and why APIs sample only a few
  frames per second.

---

## 3. Documents and files — PDF, Office, CSV, …

Files are not a new modality. They are **combinations** of the two modalities
above (text + images), unpacked before the model sees them.

### PDF — the "dual view" trick
When you send a PDF to Claude, the system does two things to **every page**:

1. **Renders the page as an image** → goes through the vision path (patches).
2. **Extracts the text layer** → goes through the text path (tokenizer).

The model gets both, side by side. That is why it can read the words *and*
understand charts, tables, stamps, signatures, and layout on the same page.

```
PDF page ──► page image  ──► vision encoder ──► image tokens ─┐
        └──► text layer  ──► tokenizer      ──► text tokens  ─┴─► model
```

**Cost:** you pay for both views. Roughly **1,500–3,000 text tokens per page**
(depends on density) **plus** the image tokens for the rendered page. So a
3-page PDF ≈ ~7,000 tokens, while plain text extraction of the same pages
would be ~1,000. The dual view is ~7× more expensive but actually *sees* the
document.

**Limits (Claude API):** max 32 MB per request, max 600 pages
(100 pages for 200K-context models), no password-protected PDFs.

**Scanned PDFs:** there is no separate OCR engine. A scan has no text layer,
so the model reads it purely through the **image** path (vision). This works
well for clear scans, and badly for blurry or rotated ones — rotate pages
upright and keep text legible.

**Three ways to send a PDF** (Claude API, `document` content block):
- `source: {type: "url", url: ...}` — simplest.
- `source: {type: "base64", media_type: "application/pdf", data: ...}` — local files.
- `source: {type: "file", file_id: ...}` — upload once via the **Files API**
  (max 500 MB per file, 100 GB per org), then reference it in many requests.
  Best for documents you query repeatedly.

**Useful extras:**
- **Citations** — pass `citations: {enabled: true}` on the document block and
  the answer carries references back to the exact source passage.
- **Prompt caching** — put `cache_control` on the document block; repeated
  questions over the same PDF then cost ~10% of the input price.
- **Order** — put the PDF *before* your question in the content array.

### Other file types
| File | How it gets in |
|---|---|
| `.txt`, `.md`, `.csv`, `.json`, code | Just text — tokenized directly, no vision cost |
| `.docx`, `.xlsx`, `.pptx` | Converted/parsed to text (or handled by code-execution / document skills that read and write them programmatically) |
| Standalone images in docs | Vision path, same as any image |
| Huge documents (1000s of pages) | Don't stuff into context — chunk + embed + retrieve (RAG, see track 4) |

The mental model: **a "file" is a container.** The platform unpacks it into
text tokens and/or image tokens; the model itself only ever sees tokens.

---

## 4. Output side — how the model produces non-text

This is the harder part. Three common designs:

### Design A: Text-only output (most common today)
- Claude and most production LLMs accept multimodal **input** but generate
  only **text** tokens.
- The output head is a softmax over the text vocabulary — nothing else.
- Simple, safe, cheap. "Multimodal" here really means *multimodal-in,
  text-out*.

### Design B: Tool / pipeline output
- The LLM writes text, and that text drives a **separate** generator model.
- Example: LLM writes an image prompt → a **diffusion model** paints the image
  (how DALL·E 3 worked). Same for classic text-to-speech: LLM writes text → a
  TTS model speaks it.
- The LLM never touches pixels or audio waves itself.
- Weakness: the generator only sees the short prompt, not the full
  conversation, so instruction-following on details is weaker.

### Design C: Native multimodal output
- The model's vocabulary is **extended with image/audio tokens**, made by a
  "codec" model (e.g. VQ-VAE / RVQ) that compresses images or audio into a
  discrete token alphabet.
- The LLM then autoregressively generates those tokens; a decoder turns them
  back into pixels or sound waves.
- GPT-4o's voice mode and native image generation, and Gemini's native image
  output, work this way.
- Big win: the **same attention** that read your prompt also shapes the
  output, so it follows instructions (text in image, exact layout, speaker
  emotion) much better than a separate diffusion model.

---

## 5. Two architecture styles worth knowing

| Style | How | Examples | Trade-off |
|---|---|---|---|
| **Late fusion (adapter)** | Frozen pre-trained LLM + frozen vision encoder; train only a small projector between them | LLaVA, MiniGPT-4, Qwen-VL (partly) | Cheap to train, fast to ship; quality ceiling is lower — the LLM was never *born* multimodal |
| **Early fusion (native)** | One Transformer trained from the start on mixed text/image/audio token streams | GPT-4o, Gemini, Chameleon | Very expensive to train; modalities blend deeply, best quality |

Most open-source multimodal models you can fine-tune yourself (LLaVA family)
are late fusion: you can often train just the projector on a single GPU.

---

## 6. Practical points for an AI engineer

- **Images are input tokens like any other.** They consume context window and
  you pay for them. In the Claude API you pass them as base64 or a URL inside
  the `content` array, mixed with text blocks; you can interleave many.
- **Resolution matters.** Most APIs downscale large images. Tiny text in a
  screenshot may become unreadable after downscaling — crop the region you
  care about instead of sending the full screen.
- **The model "sees" semantics, not pixels.** It cannot count pixels, measure
  exact distances, or reliably count many small objects — patches are an
  abstraction, not a ruler.
- **Order matters.** Image-before-question usually works better than
  question-before-image, because attention is causal (later tokens can attend
  to earlier ones, not the reverse).
- **OCR-ish tasks work; structured extraction works better with a schema.**
  Give the model a JSON schema / tool definition when extracting from
  documents and screenshots.
- **Prompt caching applies to images too** — a big image you re-send every
  turn is a great cache candidate.
- **Latency:** vision encoding adds time before the first output token; audio
  output (Design C) streams chunk-by-chunk like text.

---

## 7. Quick glossary

| Term | Simple meaning |
|---|---|
| Modality | A type of data: text, image, audio, video |
| Embedding | A vector (list of numbers) representing a token |
| Patch | A small square cut from an image; the "word" of vision |
| Vision encoder (ViT) | A Transformer that turns patches into vectors |
| Projector / adapter | Small layers that map encoder vectors into the LLM's token space |
| Spectrogram | A picture of sound: frequency vs time |
| VQ-VAE / codec | A model that compresses images/audio into a discrete token alphabet, and back |
| Diffusion model | A separate image generator that denoises random noise into a picture |
| Early vs late fusion | Trained multimodal from birth vs glued together with an adapter |
| Text layer | The selectable text stored inside a PDF (scans don't have one) |
| Files API | Upload a file once, reference it by `file_id` in many requests |

---

## References

- [CLIP — Learning Transferable Visual Models From Natural Language Supervision (OpenAI, 2021)](https://arxiv.org/abs/2103.00020)
- [ViT — An Image is Worth 16x16 Words (Google, 2020)](https://arxiv.org/abs/2010.11929)
- [LLaVA — Visual Instruction Tuning (2023)](https://arxiv.org/abs/2304.08485)
- [Chameleon — Mixed-Modal Early-Fusion Foundation Models (Meta, 2024)](https://arxiv.org/abs/2405.09818)
- [Whisper — Robust Speech Recognition via Large-Scale Weak Supervision (OpenAI, 2022)](https://arxiv.org/abs/2212.04356)
- [Claude API — Vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision)
- [Claude API — PDF support](https://platform.claude.com/docs/en/build-with-claude/pdf-support)
- [Claude API — Files API](https://platform.claude.com/docs/en/build-with-claude/files)
