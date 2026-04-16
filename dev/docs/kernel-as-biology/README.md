# clade kernel as biology

A side-by-side reading of the simulation kernel — Julia code on one side,
plain-English explanation and biological rationale on the other. The
goal is to make the rules of the simulation readable as biology so you
can spot bugs, theory mismatches, and unjustified simplifications
without being fluent in Julia.

## How to read this

Each chunk follows the same pattern:

> **The Julia code** (small, 3-10 lines, line numbers preserved).
>
> **What this says (plain English).** Translation of the code into
> ordinary language.
>
> **Biology.** What the corresponding biological process is in real
> organisms. Citations where they apply.
>
> **Audit findings.** What we learned from the fidelity audit (35
> scenarios, see `dev/audit/fidelity/STATUS.md`) about whether this
> rule produces the predicted behaviour. Skipped when the rule was
> never tested.
>
> **Variants worth considering.** Alternative biological rules that
> would also be defensible, with the trade-offs.

## Files in this directory

- [`tick.md`](tick.md) — Per-tick agent update: sense → decide → move
  → eat → age. **The hot path. Start here.**
- *(more files to come: `clade-main.md`, `sense.md`, `reproduce.md`,
  `death.md`, `genome.md`)*

## Julia-for-biologists primer

You only need a handful of Julia idioms to read these documents:

- `function name!(env)` — the trailing `!` is a Julia convention
  meaning "this function modifies its argument in place" (mutates
  rather than returning a new value). Same as Python's
  `list.append()` vs `sorted(list)`.
- `for ag in env.agents` — iterate over every agent. `ag` is the
  loop variable (one agent at a time).
- `ag.alive || continue` — read as "if not alive, skip this agent."
  The `||` is short-circuit OR; `continue` jumps to the next
  iteration. So this is shorthand for "skip dead agents."
- `ag.energy -= 1.0f0` — subtract 1.0 from the energy field.
  `f0` means "Float32" (single precision); just read it as `1.0`.
- `Int32(0)` — explicit type cast. Read as just `0`.
- `Float32(get(specs, "move_cost", 1.0))` — look up `"move_cost"`
  in the specs dictionary; if absent, use `1.0`. Then cast to
  Float32. Read it as "the move_cost parameter (default 1.0)."
- `inp = sense_agent(ag, env)` — call the function `sense_agent`
  with arguments `ag` and `env`, store the result in `inp`.
- `min(grass[x, y], max_bite)` — take whichever is smaller.
- `if ... elseif ... else ... end` — same as Python's
  `if/elif/else`.

That's enough to read 90% of the kernel. Ask if anything else is
opaque.
