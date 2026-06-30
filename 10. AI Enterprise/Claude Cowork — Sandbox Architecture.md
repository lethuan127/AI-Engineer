# Claude Cowork — Sandbox Architecture

> **One idea to remember:** Cowork is **the Claude Code harness running inside a real hardware VM**, not a
> "dual-layer sandbox." Anthropic describes **six isolation mechanisms** — *two enforced outside the
> guest kernel* (the VM boundary + a host egress proxy, which hold even if the agent gets root) and *four
> inside* (unprivileged user, scoped mounts, gVisor networking, an in-VM MITM proxy). The **agent loop
> runs on the host; only code/shell execution runs in the VM.**

> Sourcing: claims below are marked **[official]** (Anthropic engineering posts), **[local]** (verified
> from VM bundles + logs on a live macOS install), or **[3p]** (third-party analysis — treat as likely).

## 1. "Dual-layer" is a simplification

"Dual-layer sandbox" is **not** Anthropic's term. The "two" framing comes from **Claude Code**, whose
sandbox Anthropic describes as *two isolation types* — **filesystem + network**. **Cowork is a heavier,
different design**: a full VM with **six** isolation mechanisms. **[official]**

The honest two-bucket model is **outside-guest vs in-guest** — not "two layers of sandbox":

- **Outside the guest** (survive the agent gaining root inside the VM): the **hypervisor/VM boundary**
  and the **host-side egress proxy**.
- **Inside the guest**: unprivileged per-session Linux user · scoped virtiofs mounts · gVisor
  user-mode networking · an in-VM MITM proxy.

## 2. The architecture

```
HOST (your macOS)
 ├─ Claude desktop app (UI) + AGENT LOOP (reasoning)            ← runs on the host
 ├─ cowork_vm_swift (VM controller) · node host process
 ├─ host egress proxy — domain allowlist + session token       ← OUTSIDE-guest mechanism #1
 └─ Computer Use (your real Chrome + cookies)                  ← on host, OUTSIDE the sandbox [3p]
        │  Apple Virtualization.framework (macOS) / HCS (Win)   ← OUTSIDE-guest mechanism #2 = VM boundary
        ▼
   GUEST VM — Ubuntu 22.04 LTS, ARM64
     ├─ coworkd (root daemon): mounts + in-VM proxy
     ├─ Claude Code CLI harness (staged) — EXECUTES shell/code here
     ├─ unprivileged per-session Linux user                    ← in-guest #1
     ├─ virtiofs: /mnt/.virtiofs-root (ro) + per-folder bind-mounts (rw / ro / rw-no-delete)  ← in-guest #2
     ├─ gVisor user-mode networking (blocks socket syscalls)   ← in-guest #3
     └─ in-VM MITM proxy (ephemeral CA, key in memory only)    ← in-guest #4
```

- **Outer boundary = a real hardware VM** — Apple **Virtualization.framework** on macOS, **HCS (Host
  Compute System)** on Windows; guest **Ubuntu 22.04**. Not the macOS app sandbox. **[official] [local]**
- **Cowork = Claude Code harness *inside* the VM.** Standalone Claude Code, by contrast, uses *OS-level*
  sandboxes — **Seatbelt** (macOS) / **bubblewrap** (Linux), no VM. Don't conflate the two. **[official]**
- **Agent loop on host, code execution in VM** — a deliberate split so a VM crash doesn't kill Cowork,
  while executed code still gets full filesystem + network containment. **[official]**

## 3. The six isolation mechanisms

| # | Mechanism | Where enforced | What it does |
|---|-----------|----------------|--------------|
| 1 | **VM / hypervisor boundary** | outside guest | code runs in a separate kernel + filesystem; host OS not reachable |
| 2 | **Host egress proxy** | outside guest | only allow-listed domains leave the machine; forwards only requests bearing the session token; host credentials never enter the guest |
| 3 | **Unprivileged per-session user** | in guest | the agent isn't root for its own work; least privilege |
| 4 | **Scoped virtiofs mounts** | in guest | only user-approved folders are visible, each with a mode (ro / rw / rw-no-delete) |
| 5 | **gVisor user-mode networking** | in guest | blocks raw socket syscalls — no arbitrary outbound connections |
| 6 | **In-VM MITM proxy** | in guest | terminates/inspects egress with an ephemeral CA (private key in memory only) |

The design intent: even if the agent **gets root inside the guest**, #1 and #2 still hold — it can't
escape the VM or reach non-allowlisted hosts. **[official]**

## 4. Filesystem model

The VM never sees your whole disk. **[official] [local]**

- The host shares a root over **VirtioFS**, mounted **read-only** in the guest at `/mnt/.virtiofs-root`.
- Per session, `coworkd` **bind-mounts only the user-approved subpaths** into
  `/sessions/<session>/mnt/<name>`, each with an explicit mode. Observed on a live install: the connected
  repo `rw`; `outputs` `rw`; `uploads`, `.auto-memory`, `.claude/projects`, `.claude/skills` all `ro`.
- Documented modes: **read-only · read-write · read-write-no-delete**, plus **mount-path allowlists via
  MDM** for enterprise.

## 5. Network model — three controls

Egress is locked down by three independent controls (corroborated by local logs): **[official] [local] [3p]**

1. **gVisor user-mode networking** — blocks socket syscalls in the guest (`networkMode=gvisor`); no
   direct internet from executed code. **[local]**
2. **In-VM MITM proxy** — `coworkd` generates an **ephemeral CA** (key in memory only) and runs a proxy
   on a unix socket; `api.anthropic.com` is terminated/re-signed, other allow-listed hosts are
   CONNECT-tunneled. **[local]** (selective-intercept detail **[3p]**)
3. **Host-side egress proxy** — a domain **allowlist**; forwards only requests carrying the VM's
   provisioned session token. **[official]**

"Web fetch" therefore runs through controlled egress, not arbitrary outbound sockets.

## 6. What runs where — and why it matters

| Component | Runs on | Implication |
|-----------|---------|-------------|
| UI + **agent loop** (reasoning) | **host** | survives VM restarts; not itself sandboxed |
| **Shell / code execution** | **guest VM** | full FS + network containment applies here |
| **Computer Use** (Chrome control, screenshots) | **host**, your real browser/cookies **[3p]** | this path is **outside** the VM sandbox — the agent acts as *you* in a real browser, so it's governed by approval prompts, not the VM |

> The security takeaway: the VM contains **what the agent executes**; it does **not** contain **Computer
> Use**, which drives your real browser on the host. Different trust model — gate it with per-action
> approval, not the sandbox.

## 7. On-disk artifacts (verified on a live macOS install)

Under `~/Library/Application Support/Claude/` and `~/Library/Logs/Claude/`: **[local]**

- `vm_bundles/claudevm.bundle/` — `rootfs.img` (+ `.zst`), `sessiondata.img` (persistent `/sessions`),
  `efivars.fd` (UEFI), `machineIdentifier`, `vmIP`, **`gvisorMacAddress`** → a persistent Apple-VZ VM
  with gVisor networking.
- `claude-code-vm/<version>/claude` (+ `.sdk-version`) — the **Claude Code CLI staged to run inside the
  VM** as the harness → confirms "Claude Code inside a VM."
- Logs: `cowork_vm_swift.log` (host VM controller — `startVM … memoryGB=4 … networkMode=gvisor`,
  `Process spawned: command=bash`), `coworkd.log` (guest root daemon — kernel boot, virtiofs root `ro`,
  per-session mounts with modes, `MITM proxy started`), `vzgvisor.log` (gVisor usernet), `cowork_vm_node.log`.

> Note: directory name is `Claude` on the **consumer** build; the **enterprise / 3P** build uses
> `Claude-3p`. (See the *System Memory* note's Cowork locations.)

## 8. Gotcha: `git commit` works, `git push` / PR doesn't

A direct, practical consequence of the network (§5) + credential (§2) isolation: inside Cowork's VM,
**you can commit but you can't push or open a PR.**

| Step | Needs | In the VM? |
|------|-------|-----------|
| `git commit` | local fs + git config | ✅ writes to the rw-mounted folder's `.git` |
| `git push` | network to `github.com` + **your credentials** | ❌ egress allowlist + host creds never enter the guest |
| `gh pr create` | API call + token | ❌ same |

This is the guardrail, not a bug — pushing under *your* identity is an outward action the sandbox is
meant to prevent (and it enforces the §10-style draft→human-merge discipline). Two ways to handle it:

**A. Push from the host (default, simplest).** Cowork's commit lands in the **host's** `.git` (the folder
is bind-mounted), so on the host: `git log` → `git push` → `gh pr create`. The agent drafts + commits;
**you** push + open the PR.

**B. GitHub MCP connector (let the agent open the PR).** A **GitHub MCP server operates on the *remote*
repo via the API — not your local folder** — so it skips `git push` entirely. It bypasses both blockers
because it holds its **own OAuth/PAT** (not credentials in the VM) and runs **host-side / hosted**
(`api.githubcopilot.com/mcp/`), outside the code-VM's egress.

```
agent edits files in the mounted folder        (local, to iterate/test)
  → create_branch(repo, "agent/update-plugin")
  → push_files(repo, branch, [{path, content}…])   # sends file CONTENTS as a commit ON GitHub (not a local push)
  → create_pull_request(repo, base, head, …)       # PR appears on github.com
```

- **Don't confuse** with a *git MCP server* (operates on the **local folder** via the `git` CLI) — its
  push still hits the same wall. It's the *GitHub* MCP server (remote API) that gets around it.
- **Caveat:** `push_files` makes **one fresh API commit** from file contents, not a replay of your local
  commit history. For "land my changes on a PR" it's fine; to preserve granular history, push from host.

**Recommendation:** default to **(A)**; use **(B)** when the agent should open the PR autonomously,
scoped to one repo (fine-grained PAT: `contents` + `pull_requests`, or OAuth scopes you approve).

## 9. Takeaways

1. **Not "dual-layer."** It's a **hardware VM + a host egress proxy** (the two outside-guest controls)
   wrapping **four in-guest controls** — six mechanisms, designed so guest-root still can't escape.
2. **Cowork = Claude Code in a VM**; standalone Claude Code = OS sandbox (Seatbelt/bubblewrap). Same
   harness, very different containment.
3. **Agent loop on host, execution in the VM** — resilience + containment, split deliberately.
4. **The sandbox covers executed code, not Computer Use** — browser control runs on the host as you;
   gate it with approvals.
5. **Files are exposed per-folder, per-mode** (virtiofs bind-mounts of approved paths only); **network is
   allowlist-only** through a three-control egress path.

## References

- [Anthropic — How we contain Claude across products](https://www.anthropic.com/engineering/how-we-contain-claude)
- [Anthropic — Making Claude Code more secure and autonomous with sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
- [Claude Code — Choose a sandbox environment](https://code.claude.com/docs/en/sandbox-environments)
- [GitHub — github/github-mcp-server](https://github.com/github/github-mcp-server)
- [GitHub Docs — Set up the GitHub MCP Server (remote, OAuth)](https://docs.github.com/en/copilot/how-tos/provide-context/use-mcp/set-up-the-github-mcp-server)
