# clade positioning research — program log

*Background research to evidence-base every claim that ends up on
`index.md`, `README.md`, or the `why-clade` vignette. Started
2026-04-19 after the Phase 1–5 docs cleanup surfaced that the
landing-page copy was written from memory rather than from sources.*

---

## Research principle

**Every positioning claim on a user-facing page must trace to a
source in this directory.** If we say "clade fits where SLiM doesn't",
we cite what SLiM's own docs say it does and doesn't do — verbatim,
not paraphrased. If we group clade's 32 modules under a three-pillar
frame, we either show that the frame is ours (editorial choice) or
cite a published typology that uses the same split.

The textbook-attribution mistake (see
[`textbook_attribution_postmortem.md`](#)) — saying clade's framing
"follows Davies/Krebs/West" when DKW is actually organised by topic —
came from writing positioning copy before doing the research. These
docs are the fix.

---

## Sub-documents

| File | Status | What it contains |
|---|---|---|
| [`competitive_landscape.md`](competitive_landscape.md) | **Draft 1** (2026-04-19) | Verbatim positioning quotes from SLiM, NetLogo, Mesa, msprime, and Railsback & Grimm. What each tool's own docs say it is for. What each explicitly does *not* claim. |
| [`methods_reviews.md`](methods_reviews.md) | **Draft 1** | Survey of existing reviews of ABM / IBM in ecology. Typologies we can position clade within — Grimm's POM framework, ODD protocol, pragmatic-vs-paradigmatic, Murphy 2025 (applied ecology), Stillman et al. 2015 (behavioural-ecology IBMs). |
| [`primary_citation_audit_plan.md`](primary_citation_audit_plan.md) | **Scope only** | Plan for per-scenario primary-citation verification. 32 auditable scenarios × read the cited paper × confirm clade's implementation matches the claim. Multi-session work; scope document only for now. |

---

## Open questions (need user input)

1. **Is Murphy et al. 2025 (`Ecosphere 10.1002/ecs2.70342`) an already-
   cited review in the field?** The abstract (we couldn't fetch it)
   could tell us whether clade fits their "applied ecology ABM"
   typology or whether it's better framed as a theoretical-evolution
   tool. If we have institutional access, pulling the full text would
   help.
2. **Stillman, Railsback, Giske, Berger & Grimm (2015),
   "Making predictions in a changing world: the benefits of
   individual-based ecology"** (*BioScience* 65:140–150) is the
   closest single-paper review of behavioural-ecology IBMs I've
   found in initial searches. Worth reading — does it describe a
   typology clade should fit?
3. **Is there a review specifically on neural-brain-evolution
   simulators?** Polyworld (Yaeger 1994), Framsticks (Komosinski &
   Ulatowski 1999), Avida (Ofria & Wilke 2004), Evosphere (Eiben et
   al. 2013) — collectively this is a real genre. clade's niche
   claim depends on what this genre looks like now.
4. **User evidence.** None yet (per user, 2026-04-19). Research plan
   doesn't assume users exist; positioning should avoid "researchers
   use clade to…" claims until one exists.

---

## What the user-facing copy is *allowed* to say, given current evidence

- ✅ "Modular R + Julia simulator" — self-evident from code.
- ✅ "32 of 32 auditable scenarios pass" — claim derives from
  `dev/audit/fidelity/DASHBOARD.md`; the ledger counts are the
  evidence. **Subject to the primary-citation audit** — the claim
  strengthens or weakens based on whether every cited paper actually
  says what clade reproduces.
- ✅ "For behavioural / cognitive / social-evolution modelling" —
  topic coverage is self-evident from the biology-modules table.
- ⚠️  "clade fits where SLiM doesn't" — needs the competitive-
  landscape evidence base (now in `competitive_landscape.md`) before
  it can appear on a user-facing page.
- ❌ "Follows the canonical structure of Davies/Krebs/West" —
  **retracted** in PR #78. DKW doesn't use the three-pillar frame.
- ❌ "Draws on Shettleworth" — **retracted** in PR #78. No
  traceable design influence.
- ❌ "Godfrey-Smith partly inspired s-cephalopod" — **retracted** in
  PR #78. No documented design input.
- ❌ "Researchers use clade to…" — no users yet; wait.

---

## Log

- **2026-04-19** — created scaffold. Collected verbatim positioning
  for SLiM, NetLogo, Mesa, msprime, Railsback & Grimm. Identified
  Murphy 2025 and Stillman et al. 2015 as probably-relevant review
  papers to read when we have access. User confirmed no clade users
  exist yet, so "user evidence" track is N/A until that changes.
