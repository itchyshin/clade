"""
    genome.jl — Meiosis, phenotype expression, and genome distance.

This module implements the genetic layer shared by all brain types. The genome
layer is strictly separated from the brain layer: genome.jl operates on raw
allele vectors; brain constructors in brains/*.jl interpret those vectors.

## Meiosis model

The model follows standard diploid genetics (Charlesworth & Charlesworth 2010,
Chapter 5). For each chromosome pair:

1. **Independent assortment** — the maternal or paternal chromosome is chosen
   with equal probability (Mendel's second law).
2. **Recombination** — a Poisson(crossover_rate) number of crossover points
   are sampled uniformly along the chosen haplotype. At each crossover,
   the template switches between maternal and paternal chromosomes.
3. **Mutation** — Gaussian noise N(0, mutation_sd) is added independently to
   each element of the resulting haplotype.

For haploid organisms (`ploidy == 1`) meiosis reduces to: choose one
(maternal) copy and mutate it. There is no recombination.

## Phenotype expression

The expressed phenotype (the brain weights and scalar traits used for
behaviour and life history) is computed once at birth by
`express_phenotype()` and stored in the Agent struct. It is not recomputed
within a lifetime.

Default dominance model: additive (midpoint of maternal and paternal alleles).
Other models: dominant (Bernoulli choice of allele), codominant (reported
separately in get_genome_data() but computed as additive for the phenotype).

## Genome distance

`genome_distance(g1, g2)` returns a normalised Euclidean distance in [0, ∞)
between two expressed genome phenotypes. This is used by:
- Speciation module (reproductive isolation when distance > isolation_threshold).
- get_genome_data() for diversity tracking.
- Social learning (copy from genetically distant agents).

References
----------
Charlesworth, B. & Charlesworth, D. (2010) Elements of Evolutionary Genetics.
    Roberts & Company, Greenwood Village CO. Chapter 5 (recombination and
    linkage), Chapter 6 (selection).
Orr, H.A. (2005) The genetic theory of adaptation: a brief history.
    Nature Reviews Genetics 6:119–127.
"""

using Random: AbstractRNG, rand, randn

# ── Constructors ───────────────────────────────────────────────────────────────

"""
    make_genome(specs, arch, rng) -> DiploidGenome

Create a new founder genome (no parents). Brain weights are sampled from
N(0, 0.1) and scalar traits are sampled from N(mean, mutation_sd) for each
trait, clamped to their allowed ranges.

Parameters are read from `specs`:
- `specs["ploidy"]` — 1 or 2.
- `specs["n_chromosomes"]` — chromosome count.
- `specs["mutation_sd"]` — initial weight distribution SD.
- Individual trait means and SDs from specs (body_size_init_mean, etc.).

`arch` is the brain architecture vector produced by the brain constructor
(e.g. [11, 8, 5] for a 2-layer ANN with input 11, hidden 8, output 5).
"""
function make_genome(specs::Dict{String,Any}, arch::Vector{Int32},
                     rng::AbstractRNG)::DiploidGenome
    n_weights  = arch_to_n_weights(arch)
    mutation_sd = Float32(get(specs, "mutation_sd", 0.1))

    mat_w = Float32.(randn(rng, n_weights) .* mutation_sd)
    pat_w = specs["ploidy"] == 2 ?
            Float32.(randn(rng, n_weights) .* mutation_sd) : Float32[]

    mat_t = _sample_traits(specs, rng)
    pat_t = specs["ploidy"] == 2 ? _sample_traits(specs, rng) : Float32[]

    DiploidGenome(mat_w, pat_w,
                  mat_t, pat_t,
                  Int32.(arch),
                  Int32(get(specs, "n_chromosomes", 1)))
end

"""
    _sample_traits(specs, rng) -> Vector{Float32}

Sample the N_SCALAR_TRAITS heritable scalar traits for one haplotype.
Each trait is drawn from N(init_mean, mutation_sd) and clamped to [min, max].
"""
function _sample_traits(specs::Dict{String,Any}, rng::AbstractRNG)::Vector{Float32}
    t = Vector{Float32}(undef, N_SCALAR_TRAITS)

    # Helper: clamp(N(mean, sd), lo, hi)
    sample(mean, sd, lo, hi) = clamp(Float32(mean + sd * randn(rng)), Float32(lo), Float32(hi))

    t[TRAIT_BODY_SIZE]          = specs["body_size_evolution"] ?
        sample(specs["body_size_init_mean"],
               specs["body_size_mutation_sd"],
               specs["body_size_min"], specs["body_size_max"]) : 1.0f0

    t[TRAIT_IMMUNE_STRENGTH]    = specs["immune_evolution"] ?
        sample(specs["immune_strength_init_mean"],
               specs["immune_strength_mutation_sd"],
               specs["immune_strength_min"], specs["immune_strength_max"]) : 0.0f0

    t[TRAIT_COOPERATION_LEVEL]  = specs["cooperation_evolution"] ?
        sample(specs["cooperation_init_mean"],
               specs["cooperation_mutation_sd"], 0.0, 1.0) : 0.0f0

    t[TRAIT_DISPERSAL_TENDENCY] = specs["dispersal_evolution"] ?
        sample(specs["dispersal_init_mean"],
               specs["dispersal_mutation_sd"],
               specs["dispersal_min"], specs["dispersal_max"]) : 0.0f0

    t[TRAIT_METABOLIC_RATE]     = specs["metabolic_rate_evolution"] ?
        sample(specs["metabolic_rate_init_mean"],
               specs["metabolic_rate_mutation_sd"],
               specs["metabolic_rate_min"], specs["metabolic_rate_max"]) : 1.0f0

    t[TRAIT_AGING_RATE]         = specs["aging_rate_evolution"] ?
        sample(specs["aging_rate_init_mean"],
               specs["aging_rate_mutation_sd"],
               specs["aging_rate_min"], specs["aging_rate_max"]) : 1.0f0

    t[TRAIT_REPRO_THRESHOLD]    = Float32(get(specs, "min_repro_energy", 120.0))

    t[TRAIT_MUTATION_SD]        = specs["mutation_rate_evolution"] ?
        sample(specs["mutation_sd_init_mean"], 0.01f0,
               specs["mutation_sd_min"], specs["mutation_sd_max"]) :
        Float32(get(specs, "mutation_sd", 0.1))

    t[TRAIT_LEARNING_RATE]      = specs["learning_rate_evolution"] ?
        sample(specs["learning_rate_init_mean"],
               Float32(specs["learning_rate_init_mean"]) * 0.1f0,
               specs["learning_rate_min"], specs["learning_rate_max"]) :
        Float32(get(specs, "learning_rate", 0.01))

    t
end

# ── Meiosis ────────────────────────────────────────────────────────────────────

"""
    meiosis(parent::DiploidGenome, specs, rng) -> Vector{Float32}

Produce one haploid gamete from `parent` by meiosis. Returns a weight vector
of length `length(parent.maternal_weights)`.

## Algorithm

For each chromosome `c` in `1:n_chromosomes`:

1. Select the starting template: `rand(rng) < 0.5 ? maternal : paternal`
   (independent assortment; Mendel's second law).
2. Sample `k ~ Poisson(crossover_rate)` crossover positions uniformly on
   the chromosome segment.
3. At each crossover position, switch template between maternal and paternal.
4. Copy the resulting recombinant segment.

After assembling all chromosomes, add mutation: `+= N(0, mutation_sd)`.

For haploid parents (`is_haploid(parent)`): directly copy maternal_weights
and mutate. No recombination.
"""
function meiosis(parent::DiploidGenome, specs::Dict{String,Any},
                 rng::AbstractRNG)::Vector{Float32}
    if is_haploid(parent)
        return _mutate_weights(copy(parent.maternal_weights), specs, rng)
    end

    n       = length(parent.maternal_weights)
    gamete  = Vector{Float32}(undef, n)
    nc      = Int(parent.n_chromosomes)
    seg_len = div(n, nc)   # weights per chromosome (last gets remainder)

    λ = Float64(get(specs, "crossover_rate", 1.0))

    for c in 1:nc
        lo = (c - 1) * seg_len + 1
        hi = c == nc ? n : c * seg_len

        # Choose starting strand by independent assortment
        using_mat = rand(rng) < 0.5

        # Sample crossover positions (Poisson number)
        k = _rpois(rng, λ)
        xpts = sort!(rand(rng, lo:hi, k))

        pos = lo
        for xp in xpts
            src = using_mat ? parent.maternal_weights : parent.paternal_weights
            gamete[pos:xp] .= src[pos:xp]
            pos = xp + 1
            using_mat = !using_mat
        end
        # Fill remainder of segment
        src = using_mat ? parent.maternal_weights : parent.paternal_weights
        gamete[pos:hi] .= src[pos:hi]
    end

    _mutate_weights(gamete, specs, rng)
end

"""
    meiosis_traits(parent::DiploidGenome, specs, rng) -> Vector{Float32}

Produce one gamete haplotype for the scalar trait vector via meiosis.
For haploid: copy and mutate. For diploid: random allele per trait (each
trait is treated as a separate unlinked locus — they are not part of the
brain genome and are short vectors, so full recombination is overkill).
"""
function meiosis_traits(parent::DiploidGenome, specs::Dict{String,Any},
                         rng::AbstractRNG)::Vector{Float32}
    if is_haploid(parent)
        return _mutate_traits(copy(parent.maternal_traits), specs, rng)
    end

    # Each trait inherits from a randomly chosen parent allele
    gamete = Vector{Float32}(undef, N_SCALAR_TRAITS)
    for i in 1:N_SCALAR_TRAITS
        gamete[i] = rand(rng) < 0.5 ?
                    parent.maternal_traits[i] : parent.paternal_traits[i]
    end
    _mutate_traits(gamete, specs, rng)
end

"""
    make_offspring_genome(parent1, parent2, specs, rng) -> DiploidGenome

Create an offspring genome from two parents. For haploid offspring:
`parent2` is ignored (asexual); the gamete is produced from `parent1` alone.
For diploid offspring: one gamete from each parent becomes the maternal and
paternal haplotype of the offspring.
"""
function make_offspring_genome(parent1::DiploidGenome, parent2::Union{DiploidGenome, Nothing},
                                specs::Dict{String,Any},
                                rng::AbstractRNG)::DiploidGenome
    mat_w = meiosis(parent1, specs, rng)
    mat_t = meiosis_traits(parent1, specs, rng)

    if specs["ploidy"] == 2 && parent2 !== nothing
        pat_w = meiosis(parent2, specs, rng)
        pat_t = meiosis_traits(parent2, specs, rng)
    else
        pat_w = Float32[]
        pat_t = Float32[]
    end

    DiploidGenome(mat_w, pat_w,
                  mat_t, pat_t,
                  parent1.architecture,
                  parent1.n_chromosomes)
end

# ── Phenotype expression ───────────────────────────────────────────────────────

"""
    express_weights(g::DiploidGenome, dominance_model::String) -> Vector{Float32}

Compute the expressed weight phenotype from the diploid genome.

Dominance models:
- `"additive"` (default) — expressed weight = (maternal + paternal) / 2.
  When haploid, expressed = maternal (no division).
- `"dominant"` — for each weight, randomly select the maternal or paternal
  allele (50% each). Equivalent to full dominance under random allele
  expression. Note: this is stochastic at birth (fixed once expressed).
- `"codominant"` — identical to additive for the expressed weight; the
  distinction matters only in get_genome_data() reporting.

Reference: Charlesworth & Charlesworth (2010), Section 5.1.
"""
function express_weights(g::DiploidGenome, dominance_model::String)::Vector{Float32}
    if is_haploid(g) || dominance_model == "dominant"
        if is_haploid(g)
            return copy(g.maternal_weights)
        else
            # Random allele per locus (Bernoulli 0.5 per locus)
            # We use a fast bit-level selection trick: for each group of 64
            # weights, draw one UInt64 and use each bit to select allele.
            n = length(g.maternal_weights)
            out = Vector{Float32}(undef, n)
            for i in 1:n
                # Independent Bernoulli per locus — simple but correct.
                out[i] = rand() < 0.5 ? g.maternal_weights[i] : g.paternal_weights[i]
            end
            return out
        end
    else
        # Additive (and codominant — same computation, different reporting)
        return (g.maternal_weights .+ g.paternal_weights) .* 0.5f0
    end
end

"""
    express_trait(g::DiploidGenome, trait_idx::Int,
                  dominance_model::String, lo, hi) -> Float32

Express one scalar trait, clamped to [lo, hi].
"""
function express_trait(g::DiploidGenome, trait_idx::Int,
                        dominance_model::String,
                        lo::Float32, hi::Float32)::Float32
    mat = g.maternal_traits[trait_idx]
    if is_haploid(g)
        return clamp(mat, lo, hi)
    end
    pat = g.paternal_traits[trait_idx]
    expressed = dominance_model == "dominant" ?
                (rand() < 0.5 ? mat : pat) :
                (mat + pat) * 0.5f0          # additive / codominant
    clamp(expressed, lo, hi)
end

# ── Genome distance ────────────────────────────────────────────────────────────

"""
    genome_distance(g1::DiploidGenome, g2::DiploidGenome) -> Float32

Normalised Euclidean distance between the expressed weight phenotypes of two
genomes:

    d = ||w1 - w2|| / sqrt(n_weights)

Normalising by sqrt(n) keeps the value in a comparable range regardless of
genome size. Returns 0.0 when the genomes are identical.

Used by the speciation module and for genetic diversity logging.
"""
function genome_distance(g1::DiploidGenome, g2::DiploidGenome)::Float32
    # Use additive expression for distance (consistent, deterministic)
    w1 = express_weights(g1, "additive")
    w2 = express_weights(g2, "additive")
    n  = length(w1)
    n == 0 && return 0.0f0
    s = 0.0f0
    @inbounds for i in 1:n
        d = w1[i] - w2[i]
        s += d * d
    end
    sqrt(s / Float32(n))
end

# ── Utility ────────────────────────────────────────────────────────────────────

"""
    arch_to_n_weights(arch::Vector{Int32}) -> Int

Compute total number of weights + biases for a fully connected MLP with the
given layer widths (including input and output layers).

For a network with layers [n0, n1, n2, n3]:
  n_weights = n0*n1 + n1 + n1*n2 + n2 + n2*n3 + n3

This is used to allocate the genome weight vectors. BNN genomes store both
μ and σ, so their effective size is 2 * arch_to_n_weights(arch).
"""
function arch_to_n_weights(arch::Vector{Int32})::Int
    n = 0
    for i in 1:length(arch)-1
        n += arch[i] * arch[i+1] + arch[i+1]   # weights + biases
    end
    n
end

"""
    _mutate_weights(w::Vector{Float32}, specs, rng) -> Vector{Float32}

Add Gaussian noise N(0, mutation_sd) to each element of `w` in place.
Returns `w` (modified).
"""
function _mutate_weights(w::Vector{Float32}, specs::Dict{String,Any},
                          rng::AbstractRNG)::Vector{Float32}
    sd = Float32(get(specs, "mutation_sd", 0.1))
    sd == 0.0f0 && return w
    @inbounds for i in eachindex(w)
        w[i] += Float32(sd * randn(rng))
    end
    w
end

"""
    _mutate_traits(t::Vector{Float32}, specs, rng) -> Vector{Float32}

Mutate scalar trait vector by adding N(0, trait_mutation_sd) to each active
trait and clamping. Inactive traits (when evolution is disabled) are not
mutated. Returns `t` (modified in place).
"""
function _mutate_traits(t::Vector{Float32}, specs::Dict{String,Any},
                         rng::AbstractRNG)::Vector{Float32}
    function maybe_mutate!(i, sd, lo, hi)
        t[i] = clamp(t[i] + Float32(sd * randn(rng)), Float32(lo), Float32(hi))
    end

    specs["body_size_evolution"] &&
        maybe_mutate!(TRAIT_BODY_SIZE,
                      specs["body_size_mutation_sd"],
                      specs["body_size_min"], specs["body_size_max"])

    specs["immune_evolution"] &&
        maybe_mutate!(TRAIT_IMMUNE_STRENGTH,
                      specs["immune_strength_mutation_sd"],
                      specs["immune_strength_min"], specs["immune_strength_max"])

    specs["cooperation_evolution"] &&
        maybe_mutate!(TRAIT_COOPERATION_LEVEL,
                      specs["cooperation_mutation_sd"], 0.0, 1.0)

    specs["dispersal_evolution"] &&
        maybe_mutate!(TRAIT_DISPERSAL_TENDENCY,
                      specs["dispersal_mutation_sd"],
                      specs["dispersal_min"], specs["dispersal_max"])

    specs["metabolic_rate_evolution"] &&
        maybe_mutate!(TRAIT_METABOLIC_RATE,
                      specs["metabolic_rate_mutation_sd"],
                      specs["metabolic_rate_min"], specs["metabolic_rate_max"])

    specs["aging_rate_evolution"] &&
        maybe_mutate!(TRAIT_AGING_RATE,
                      specs["aging_rate_mutation_sd"],
                      specs["aging_rate_min"], specs["aging_rate_max"])

    specs["mutation_rate_evolution"] &&
        maybe_mutate!(TRAIT_MUTATION_SD, 0.01,
                      specs["mutation_sd_min"], specs["mutation_sd_max"])

    specs["learning_rate_evolution"] &&
        maybe_mutate!(TRAIT_LEARNING_RATE,
                      Float32(specs["learning_rate_init_mean"]) * 0.1f0,
                      specs["learning_rate_min"], specs["learning_rate_max"])

    t
end

"""
    _rpois(rng, λ) -> Int

Sample one draw from Poisson(λ) using the inversion method for small λ
(Knuth 1969). For λ > 30 uses a normal approximation.

Reference: Knuth, D.E. (1969) The Art of Computer Programming, Vol. 2,
    Addison-Wesley, Section 3.4.1.
"""
function _rpois(rng::AbstractRNG, λ::Float64)::Int
    λ <= 0.0 && return 0
    if λ > 30.0
        # Normal approximation (CLT): Poisson(λ) ≈ N(λ, sqrt(λ))
        return max(0, round(Int, λ + sqrt(λ) * randn(rng)))
    end
    # Inversion (Knuth)
    L = exp(-λ)
    k = 0
    p = 1.0
    while true
        p *= rand(rng)
        p < L && break
        k += 1
    end
    k
end
