# 1. AI & ML Fundamentals

This section gives you **working literacy** in AI and Machine Learning — enough to read papers, talk to data scientists, evaluate model output, and recognize when ML is the right tool. It is **not** a research-grade textbook.

## Why This Matters for AI Engineers

As an AI Engineer, you mostly use pre-trained models (LLMs, embeddings, vision models) rather than train your own. But to use them well, you need to understand:

- **What's happening under the hood** — so you can debug weird behavior
- **When ML / LLM is the right tool** — vs. plain code, rules, or human-in-the-loop
- **How models are evaluated** — to measure quality of your AI features
- **Why models fail** — overfitting, bias, drift, leakage all apply to LLM systems too

The goal: **read it, don't derive it.** Conceptual depth, not mathematical mastery.

## When to Use ML / LLM / Plain Code

| Problem | Best Tool |
|---|---|
| Deterministic logic, clear rules | Plain code |
| Pattern in structured data, lots of labeled examples | Classic ML |
| Open-ended language, reasoning, summarization | LLM |
| Image / video understanding | Vision model (often LLM-based now) |
| Personalization at scale | ML + recommendation system |
| One-off task with no training data | Prompt an LLM |

## Index

1. [What is AI & ML](./1.%20What%20is%20AI%20%26%20ML.md) — definitions, history, AI/ML/DL/GenAI nesting
2. [ML Paradigms](./2.%20ML%20Paradigms.md) — supervised, unsupervised, self-supervised, RL
3. [ML Workflow](./3.%20ML%20Workflow.md) — problem → data → train → eval → deploy → monitor
4. [Key Concepts](./4.%20Key%20Concepts.md) — features, loss, gradient descent, overfitting, leakage
5. [Model Families](./5.%20Model%20Families.md) — linear, trees, neural nets, CNN, RNN, transformers
6. [Evaluation Basics](./6.%20Evaluation%20Basics.md) — metrics, confusion matrix, splits
7. [Data Fundamentals](./7.%20Data%20Fundamentals.md) — quality, labeling, drift, bias
8. [Math Essentials](./8.%20Math%20Essentials.md) — linear algebra, probability, calculus, statistics (light)

## How This Connects to AI Engineering

- **LLMs are transformers** — a type of self-supervised neural network (see section 2 of the main path)
- **RAG combines** retrieval + ML embeddings + LLM (see section 4 of the main path)
- **Evaluation discipline transfers** directly to LLM eval (see section 6 of the main path)
- **Bias, drift, monitoring** apply to LLM systems just like classical ML

## Recommended Learning Path (Light Touch)

1. **One short course**: [fast.ai Practical Deep Learning](https://course.fast.ai/) **or** [Andrew Ng's ML Specialization](https://www.coursera.org/specializations/machine-learning-introduction)
2. **One book skim**: [Hands-On Machine Learning](https://www.oreilly.com/library/view/hands-on-machine-learning/9781098125967/) by Aurélien Géron — read chapter intros, skip exercises
3. **Visual intuition**: [3Blue1Brown's Neural Network series](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi)
4. **Skip**: graduate-level textbooks, paper reproductions, Kaggle grinding (unless you specialize)

## References

- [Google's ML Crash Course](https://developers.google.com/machine-learning/crash-course)
- [Distill.pub](https://distill.pub/) — visual ML explainers
- [Papers With Code](https://paperswithcode.com/) — track SOTA across ML tasks
- [The Hundred-Page Machine Learning Book](https://themlbook.com/) — Andriy Burkov (concise overview)
- [roadmap.sh — AI/ML Roadmap](https://roadmap.sh/ai/ai-engineer)
