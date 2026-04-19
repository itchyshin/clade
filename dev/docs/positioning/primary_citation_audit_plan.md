# Primary-citation audit — scope document

*Plan for verifying that every clade scenario's primary-paper citation
is **correct** (right paper, right claim, right prediction direction).
Not started yet; this doc is scope only. Multi-session work.*

---

## Why this matters

The landing page's trust signal is *"32 of 32 scenarios audited
against primary literature"*. That claim rests on two things:

1. **The fidelity audit runs the simulation and confirms a
   quantitative result matching the predicted direction** — this is
   what `dev/audit/fidelity/` already does systematically.

2. **The cited "primary literature" actually says what we attribute
   to it** — this is NOT systematically verified. We have citations
   like "Hamilton 1980 Red Queen" and "Williams 1966 predation" in
   scenario prose, but nobody has gone back and confirmed that the
   cited paper actually predicts what clade reproduces.

The second is where a behavioural-ecology reviewer would look first.
If any citation is loose — wrong paper, misattributed claim,
prediction the paper doesn't actually make — the whole "audited"
trust signal leaks. We can't take the 32/32 claim to a landing page
without (2) being solid.

---

## Current state — what exists and what doesn't

### What exists

- `dev/audit/fidelity/STATUS.md` — per-scenario ledger with verdict
  and brief "theory" cell per scenario.
- `dev/audit/fidelity/DASHBOARD.md` — summary of promotions /
  demotions / verdicts.
- Each `s-*.Rmd` scenario prose — typically cites the primary paper
  inline (e.g., "Hamilton 1964", "DeWitt & Scheiner 2004").

### What doesn't exist

- A canonical **citation → scenario** mapping with full bibliographic
  entries.
- A record of **which page / figure / specific claim** the citation
  refers to. "Hamilton 1980" is ambiguous — does the scenario
  reproduce Hamilton's *diversity* claim, *population-size* claim,
  or *sex-asex* differential?
- A sanity-check that the simulation's outcome direction matches the
  paper's actual prediction direction (not a paraphrase).

---

## Audit scope — 32 scenarios

Per scenario, produce a row like:

```
| Scenario | Primary paper | Full citation (BibTeX) | Specific claim | Prediction direction | clade's result | Matches? |
```

Example (hypothetical filled in for `s-kin`):

```
| s-kin | Hamilton 1964 | @article{hamilton1964...} | Genetic relatedness ≥ c/b → altruism evolves | More altruistic acts with higher r | Altruistic acts increase with r across 5-value sweep | ✅ |
```

Out of scope: the 4 discovery experiments (`s-module-comparison`,
`s-kitchen-sink`, `s-cross-module`, `s-bad-science`) — they're
explicitly ⚪ N/A (no primary claim to verify).

32 rows at maybe 15–30 min each = **8–16 hours of focused work**.
Sessioned across 3–4 work sessions.

---

## Session plan (when we start)

**Session 1 — low-hanging fruit (6 scenarios, ~2 hours).**
Classical behavioural-ecology citations that are clean and well-
known: `s-kin` (Hamilton 1964), `s-cooperation` (Emlen 1982),
`s-signals` (Fisher / Kirkpatrick-Ryan), `s-mating-systems`
(Hamilton 1980), `s-parental-care` (Trivers 1972 or Clutton-Brock),
`s-life-history` (Stearns 1992).

**Session 2 — cognitive-evolution scenarios (~2 hours).**
`s-brain-size` (Isler & van Schaik 2009), `s-social-learning`
(Boyd & Richerson), `s-baldwin` (Hinton & Nowlan 1987), `s-rl`
(Williams 1992 REINFORCE), `s-cephalopod` (Liedtke & Fromhage 2019),
`s-plasticity` (DeWitt & Scheiner 2004), `s-brain-comparison` (no
single citation — brain-architecture comparison is clade's own
contribution; flag honestly).

**Session 3 — ecology and species-interaction scenarios (~2 hours).**
`s-predator-prey`, `s-predation-neural`, `s-mimicry`, `s-disease`,
`s-group-defense`, `s-speciation`, `s-niche`, `s-complex-landscape`,
`s-seasonal`, `s-scavenging`, `s-dispersal-ifd`.

**Session 4 — trait-evolution + life-history remainder (~2 hours).**
`s-baseline`, `s-pop-genetics`, `s-body-size`, `s-clutch-size`,
`s-parental-investment`, `s-pace-of-life`, `s-stress-hypermutation`.

---

## Output format

A single file `citation_audit.md` under this directory with a
table, plus (for each row) a short paragraph of notes on:

- Did the paper actually predict what we reproduce?
- Any caveats the paper raised that we should acknowledge?
- Anything the paper claimed that clade *doesn't* reproduce (= an
  honest limitation to document)?

Resulting deliverables:

1. `citation_audit.md` — the table.
2. An updated set of `s-*.Rmd` files if any citations are wrong or
   incomplete (expected: 2–5 fixes out of 32, based on my rough
   sense of audit risk).
3. A `CITATION_AUDIT_SUMMARY.md` — one paragraph that the landing
   page can link to: "Every primary-literature citation in clade's
   32 auditable scenarios has been verified; see the full audit here."

---

## Why this is a research blocker for the landing page

Until the primary-citation audit is done:

- **We cannot say** "32/32 against primary literature" without a
  caveat. The claim is true at the level of "direction-correct
  quantitative result", but not necessarily at the level of "faithful
  to the cited paper's specific prediction".
- **We can say** "32/32 audited, direction-correct, citing primary
  literature" — which is weaker but defensible with the current
  ledger.

**Suggested wording for user-facing copy pending this audit**:

> *"Every scenario is tied to a specific primary-literature
> prediction and audited against that prediction via multi-seed
> simulation. All 32 auditable scenarios currently produce the
> direction-correct quantitative result at t > 2σ."*

That's honest and backed by `DASHBOARD.md`. The stronger claim
("faithful reproduction of each paper's specific prediction") waits
for this audit to be complete.

---

## Log

- **2026-04-19** — scope document written. Audit not yet started.
  Session 1 would begin with `s-kin` / Hamilton 1964 — a good warm-up
  because the claim ("r × benefit ≥ cost → altruism evolves") is
  crisp and the paper is well-understood.
