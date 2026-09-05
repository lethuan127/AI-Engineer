# Model Hardware Standard — The Agent-to-Instrument Layer

> Source: [Anthropic — Previewing the Model Hardware Standard](https://www.anthropic.com/news/model-hardware-standard-research-preview) (2026-08-27, research preview).
> Companion to [The Agent Protocol Stack — MCP, A2A, AGENTS.md](./The%20Agent%20Protocol%20Stack%20—%20MCP%2C%20A2A%2C%20AGENTS.md.md) and [Tool-Call Reliability — Idempotency, Postcondition Verification, and Replay-Safe Authorization](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md).

Every agent protocol so far has moved bits. MCP connects a model to data and software tools; A2A connects agents to each other. The Model Hardware Standard (MHS) is the first serious attempt at the fourth edge: model to **actuator**. It is not a new transport and not an MCP competitor — it is a driver-and-description layer *underneath* MCP, so that a microscope, a liquid handler, or a robotic arm exposes itself to an agent the same way a filesystem does.

The architectural claim worth extracting is narrow and portable: **the hard part of an agent controlling a physical device is not the wire format, it is the description of what the device is and what it must never do.** MHS puts that description in the driver, not in the prompt. Everything else in the design follows from that choice.

---

## 1. The Problem MHS Names

Lab and factory instruments each ship their own control interface. A facility integrating new hardware writes a bespoke translator per device, and those translators encode the operating envelope — speed caps, weight limits, e-stop conditions — in whatever form the integrator chose. Reported integration effort before MHS: weeks to months per instrument. Reported effort with it: hours.

That number is the marketing line. The interesting part is *why* the work was weeks in the first place. It was not protocol plumbing. It was the tacit knowledge — the mass of the arm, the fluid that foams if aspirated too fast, the plate position that means "occupied" — that lives in PDFs and in a technician's head, and that has to be re-derived for every integration.

> Why it matters: an agent that can issue a command but cannot read the envelope around that command is not automatable, it is only remotely operable. The description is the product.

## 2. The Primitives

MHS keeps the command surface deliberately small and pushes all the richness into metadata.

| Layer | Content | Analogue |
|---|---|---|
| Commands | `read` (`get temperature`) and `write` (`set temperature`) | POSIX file ops; the reason Bash is agent-legible |
| States | Conditions the system can be in — *plate at position 3*, *sample at 25 °C*, *well filled* | Resource state in a REST model |
| Procedures | Operations the device performs — *aspirate*, *shake* | Tool definitions |
| Tags | Natural-language notes written into the driver during setup; compiled into a reference file listing what the device measures, what is adjustable, and which safety limits are enforced | A `SKILL.md` / `AGENTS.md` for a machine |
| Discovery | Devices publish themselves in a standard format so agents and devices find each other across a network with no bespoke translator | mDNS + a capability manifest |

The tag mechanism is the load-bearing invention. A human describes the instrument conversationally once; the driver emits a machine-readable card from that. This is the same move `AGENTS.md` made for repositories and `SKILL.md` made for procedures — capture tacit operator knowledge as a committed artifact next to the thing it describes, rather than re-injecting it into every prompt.

## 3. Three Control Mechanisms, Chosen by Task Shape

MHS is reachable three ways, and the choice is a latency/supervision tradeoff rather than a preference:

| Mechanism | Use when | Cost |
|---|---|---|
| MCP | The agent needs to observe and adjust mid-run — real-time monitoring, parameter tuning | One model turn per step; compute burns for the whole watch window |
| CLI | A human operator drives directly, or the agent shells out for a one-shot | No structured result schema |
| Code files (API) | Long-running sequences — the agent writes a program that chains driver commands across devices, and the devices execute it without the agent reasoning at each step | The agent is blind until the program returns or faults |

> Architectural takeaway: this is exactly the [code-execution-as-substrate](./Code%20Execution%20as%20the%20Tool-Calling%20Substrate%20—%20Programmatic%20Tool%20Calling.md) pattern, arriving in the physical world for the same reason it arrived in the software world. A per-step model round-trip is unaffordable when the loop is a 19-hour laser lock. The agent's job shifts from *issuing steps* to *writing the step sequence and supervising exceptions*.

The failure mode is also the same one code-execution has, but worse: a partially-executed physical program cannot be rolled back. See §6.

## 4. Safety Lives in the Driver, Not the Prompt

MHS enforces device-level safety limits — the driver refuses commands outside the declared envelope, independent of what the model asked for. The system also detects and blocks unsafe preconditions: missing plate, disconnected camera, engaged emergency stop.

This is the correct placement and worth stating as a general rule.

> Lesson: a guardrail expressed in a system prompt is a suggestion; a guardrail expressed in the tool implementation is a constraint. Physical-world agents make this distinction non-negotiable, but it was always the right design — see the permission and hook boundary in [11.5. Hooks, Permissions, and Side Effects](../11.%20Harness%20Engineering/11.5.%20Hooks%2C%20Permissions%2C%20and%20Side%20Effects.md).

What the enforcement layer does **not** cover is novel failure modes. In the Genentech pilot, bubble formation during liquid handling produced errors the model could not diagnose; researchers had to steer it toward gentler parameters because it did not understand the underlying physics. The envelope stops the machine from breaking itself. It does not give the agent physical intuition.

## 5. The Reported Numbers

Research-preview results, reported by Anthropic and its partners. Treat these as existence proofs of the integration claim, not as benchmarks — there is no shared task suite and each is a single site.

| Site | Task | Result |
|---|---|---|
| QuEra | Quantum laser relock | Success 96% → 99.3% over 700 trials; recovery 150 s (human script, 58% success) → 6 s, then 0.9–14 s; PID residual error 15.7 mV → 1.55 mV; 19 h locked vs ~1.6 unlocks/hour manual |
| Carnegie Mellon | Dose-response curve automation | Development several weeks → 8 hours; throughput ~3× |
| HHMI Janelia | Microscopy integration | New camera: multi-day → minutes; experiment start: 7 program launches → one dashboard click |
| U. Washington | qPCR + robotic-arm/liquid-handler coordination | Weeks of failed traditional automation → under one week; collision-free coordination |
| Genentech | BCA assay parameter optimization | Autonomous flow-rate tuning to expert spec (water ~140 µL/s, 0.016 RMSE; BSA 10 µL/s, 0.181 RMSE); recovered from tip-pickup and fluid-detection errors |
| Tetsuwan | qPCR dispense compiler | 9,143 dispenses across 300 transfer types; precision prediction 12% better than manufacturer spec on 31/45 runs |

The QuEra line is the one that generalizes. A tight, well-instrumented control loop with a cheap verifier and a fast reset is the ideal agent target — it is the physical-world equivalent of a task with a unit test. The Genentech line is the counterexample: an open-ended diagnosis with no verifier still needs a human.

## 6. Where This Design Is Thin

Four gaps, in descending order of how much they should worry an implementer.

**No rollback.** A software tool call can be retried; an aspirated well cannot be un-aspirated. The idempotency-key and postcondition-verification discipline from [Tool-Call Reliability](./Tool-Call%20Reliability%20—%20Idempotency%2C%20Postcondition%20Verification%2C%20and%20Replay-Safe%20Authorization.md) is not optional here, and MHS does not appear to specify it. A code-file program that dies halfway through leaves the bench in a partially-applied state that the next agent must be able to read out of device *states* — which is an argument for making state reporting exhaustive, not minimal.

**No concurrency primitive in evidence.** Multiple agents (or one agent's parallel branches) driving shared instruments needs exclusive locking. The competing academic proposal, LAP, makes reservation locks a first-class primitive precisely for this reason (§7). MHS's published description covers parallel *device orchestration by one agent*, which is a different problem.

**Programmable interface required.** MHS works with any device that has an API. Legacy equipment with front-panel-only control is out of scope, which is much of an existing facility.

**Compute cost of supervision.** QuEra noted that long monitoring windows cost real inference money that must be weighed against researcher time saved. Choosing MCP over a code file for a multi-hour run is a budget decision, not just a design one.

## 7. The Alternative Shape — LAP

An independent academic proposal, [LAP (Lab Agent Protocol)](https://arxiv.org/abs/2606.03755) (June 2026), solves the same problem from the A2A side and is worth reading against MHS because its primitive set is a superset on the risk axes:

| Concern | MHS | LAP |
|---|---|---|
| Base protocol | Driver layer reachable via MCP / CLI / code | Extends A2A's peer-to-peer, discovery-first task lifecycle |
| Capability description | Natural-language tags → reference file | `InstrumentCard` |
| Exclusive access | Not specified in the public description | Reservation mechanism for instrument locking |
| Hazardous operations | Device-level limit enforcement | Explicit safety-fence handshake |
| Result typing | Read values | `MeasurementResult` with physical typing and uncertainty |
| Existing device standards | Driver replaces the bespoke translator | Explicitly *encapsulates rather than replaces* |

> Architectural takeaway: LAP's `MeasurementResult` with uncertainty is the item MHS most visibly lacks. An agent that reads `25.0` and an agent that reads `25.0 ± 0.4 °C` make different decisions, and the second one can tell a drift from a fault. If you are designing an agent-to-instrument layer yourself, type your measurements.

## 8. Status and What It Means for Builders

MHS is a **research preview**, not an open standard. It is closed during the preview; Anthropic states an intent to open-source it after publishing safety evaluations and deployment guidance, with no date. Preview partners span sites (Genentech, UW Baker/Pinglay labs, Carnegie Mellon, HHMI Janelia, QuEra, Tetsuwan) and vendors (AWS, Automata, Danaher, Doosan Robotics, MBF Bioscience, QIAGEN, Tecan, Universal Robots).

| If you are… | Act now | Wait |
|---|---|---|
| Building agents for software-only domains | Steal the pattern: put the operating envelope in the tool, put tacit knowledge in a committed description file next to it | The protocol itself is irrelevant to you |
| Running a lab or line with programmable instruments | Apply to the preview if a vendor on the list is already in your stack | Otherwise wait for open-source; do not build on a closed preview spec |
| Designing an agent-to-instrument layer | Read LAP for the primitive set; MHS for the driver/tag ergonomics | Committing to either wire format |

The honest read: MHS is a vendor's driver framework with a standard's name, at the stage where the pilot numbers are real and the spec is not public. The idea it validates — that the description and the safety envelope belong in the driver — is the part that survives regardless of which format wins.

---

## References

- [Anthropic — Previewing the Model Hardware Standard](https://www.anthropic.com/news/model-hardware-standard-research-preview)
- [The Register — Anthropic Proposes Plumbing Spec to Link AI Agents to Lab Kit and Robots](https://www.theregister.com/ai-and-ml/2026/08/28/anthropic-proposes-plumbing-spec-to-link-ai-agents-to-lab-kit-and-robots/5293135)
- [arXiv — LAP: An Agent-to-Instrument Protocol for Autonomous Science](https://arxiv.org/abs/2606.03755)
