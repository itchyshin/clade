"""
    plasticity.jl — Phenotypic plasticity in reproductive timing.

Enabled when `specs["phenotypic_plasticity"] == true`.

Phenotypic plasticity allows an agent to express different phenotypes from the
same genotype in response to local environmental cues. Here, plasticity modifies
the agent's effective reproductive threshold — the minimum energy required before
the agent will attempt to reproduce — based on the richness of local grass
resources.

The heritable `plasticity` trait (0–1) scales the magnitude of this adjustment.
Agents with `plasticity == 0` are canalized: they always reproduce at their
genetically fixed threshold regardless of local conditions. Agents with
`plasticity == 1` show maximal condition-dependent reproductive timing: they
delay reproduction strongly in poor patches and accelerate it in rich ones.

The adaptive logic follows condition-dependent life history theory (West-Eberhard
2003): reproduction in rich conditions trades future survival for immediate
offspring output, whereas reproductive restraint in poor conditions preserves
somatic condition for future opportunities. The plasticity trait enables
individual-level tracking of local resource state without requiring the agent to
carry explicit resource memory.

Note: `plasticity` itself is logged through the standard trait logging path in
logging.jl (e.g., `mean(ag.plasticity for ag in env.agents)`). No separate
logging function is required in this module.

References
----------
West-Eberhard, M.J. (2003) Developmental Plasticity and Evolution. Oxford
    University Press.
DeWitt, T.J. & Scheiner, S.M. (2004) Phenotypic variation from single
    genotypes: a primer. In T.J. DeWitt & S.M. Scheiner (eds.), Phenotypic
    Plasticity: Functional and Conceptual Approaches. Oxford University Press.
    pp. 1–9.
Roff, D.A. (2002) Life History Evolution. Sinauer Associates.
"""

"""
    effective_repro_threshold(ag::Agent, env::Environment) -> Float32

Return the agent's effective reproductive threshold adjusted for local resource
richness. Called from the reproduction decision in reproduce.jl in place of the
raw `ag.repro_threshold`.

When `phenotypic_plasticity == false`, returns `ag.repro_threshold` unchanged.

When enabled, the function:

1. Surveys a square neighbourhood of radius `plasticity_sense_radius` (toroidal
   wrap) around the agent's current position and computes mean grass density
   normalised to `[0, 1]` relative to `grass_max`.

2. Computes deviation from neutral density (0.5):

       deviation = local_density − 0.5

   Positive deviation (rich patch) → threshold decreases → agent reproduces
   sooner. Negative deviation (poor patch) → threshold increases → agent waits.

3. Scales the adjustment by the agent's heritable `plasticity` trait and by the
   baseline threshold itself (so proportional sensitivity is constant across
   genotypes with different thresholds):

       adjustment = plasticity × deviation × repro_threshold × 0.5

   The 0.5 factor limits the maximum adjustment to ±25 % of the baseline
   threshold at full plasticity in the most extreme environments.

4. Returns the adjusted threshold clamped to `[10, 1000]` to prevent
   biologically implausible values.

All sensing is done through `env.grass` and the toroidal grid dimensions in
`env.specs`. All reads are bounds-safe via `mod1`.
"""
function effective_repro_threshold(ag::Agent, env::Environment)::Float32
    Bool(get(env.specs, "phenotypic_plasticity", false)) || return ag.repro_threshold

    radius   = Int(get(env.specs, "plasticity_sense_radius", 3))
    toroidal = Bool(get(env.specs, "toroidal", true))
    rows, cols = size(env.grass)

    total_grass = 0.0f0
    n_cells     = 0

    @inbounds for dx in -radius:radius, dy in -radius:radius
        nx = wrap_or_clamp(Int(ag.x) + dx, rows, toroidal)
        ny = wrap_or_clamp(Int(ag.y) + dy, cols, toroidal)
        total_grass += env.grass[nx, ny]
        n_cells     += 1
    end

    grass_max     = Float32(get(env.specs, "grass_max", 5.0))
    local_density = total_grass / (Float32(n_cells) * grass_max)

    # Deviation from neutral: positive = rich, negative = poor
    deviation  = local_density - 0.5f0
    adjustment = ag.plasticity * deviation * ag.repro_threshold * 0.5f0

    clamp(ag.repro_threshold - adjustment, 10.0f0, 1000.0f0)
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/plasticity.jl")
# reproduce.jl: replace bare `ag.repro_threshold` comparisons with:
#   effective_repro_threshold(ag, env)
# No tick-loop additions required — effective_repro_threshold is a pure query
# called only from the reproduction gate.
# Note: effective_repro_threshold is a no-op (identity) when
#   phenotypic_plasticity == false, so it is safe to call unconditionally.
# plasticity trait logging: no dedicated function needed.
#   Use mean(ag.plasticity for ag in env.agents if ag.alive) in logging.jl
#   alongside other heritable trait means (body_size, toxicity, etc.).
# === END CLADE.JL ADDITIONS ===
