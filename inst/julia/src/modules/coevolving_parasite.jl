"""
    coevolving_parasite.jl — Hamilton 1980 Red Queen parasite module.

Enabled when `specs["coevolving_parasites"] == true` AND `signal_dims > 0`.

Biological model
----------------

Implements the canonical Hamilton (1980) Red Queen mechanism: parasites
track the most-common host genotype, so hosts that are *genetically
novel* (far from the population mean) escape parasitism. Sexual
reproduction with recombination creates more such novel combinations
than asexual cloning → the classic Red Queen advantage of sex.

The parasite "population" is represented collectively as a single
virulence-genotype vector `parasite_optimum::Vector{Float32}` of length
`signal_dims`, cached in `env.specs["_parasite_optimum"]`. Per tick:

1. Compute the host signal centroid (mean over live prey agents).
2. Adapt the parasite optimum toward the centroid with rate
   `parasite_virulence_rate`. This models parasite evolution lagging
   the host population mean by roughly `1 / rate` ticks.
3. For each live prey agent, compute the genotype distance
   `d = |agent.signal - parasite_optimum|`. The infection penalty is
   `parasite_pressure * exp(-d^2 / scale^2)` — a Gaussian falloff with
   width `parasite_distance_scale`. Hosts close to the optimum pay the
   full penalty; hosts far from it escape almost entirely.
4. The penalty is applied as an energy drain (infection cost), not
   instant death. Starving hosts can still die to starvation via the
   normal mortality path.

The signal vector is *reused* as the genotype-matching channel here.
Scenarios that want both mimicry AND parasites will have the signal
serving both purposes; the honest-signal convention (aposematic
`signal_toxicity_coupling`) then interacts with parasite pressure in a
biologically reasonable way — warning-coloured toxic prey sit in a
shared signal region, so they share parasite pressure (an empirically
attested phenomenon; see Ruxton et al. 2004 §8.4).

Default parameters preserve legacy behaviour: `coevolving_parasites =
FALSE` makes the module a no-op.

References
----------

Hamilton, W.D. (1980) Sex versus non-sex versus parasite. *Oikos*
    35:282–290. The original Red Queen formulation.
Van Valen, L. (1973) A new evolutionary law. *Evol. Theory* 1:1–30.
    The Red Queen hypothesis as a coevolutionary phenomenon.
Ebert, D. & Hamilton, W.D. (1996) Sex against virulence: the
    coevolution of parasitic diseases. *Trends Ecol. Evol.*
    11(2):79–82.
"""

"""
    apply_coevolving_parasites!(env::Environment)

Update the collective parasite optimum and apply infection costs to
all live prey agents. Called once per tick from the main loop.
No-op when `coevolving_parasites = false` or `signal_dims == 0`.
"""
function apply_coevolving_parasites!(env::Environment)
    Bool(get(env.specs, "coevolving_parasites", false)) || return

    # 0.5.1: choose matching mode. "discrete" uses Hamming distance over
    # a discrete-allele haplotype (Hamilton 1980 canonical Red Queen);
    # "continuous" uses Euclidean distance over the signal vector
    # (0.5.0 mean-tracking variant). Default "auto" picks discrete when
    # `n_parasite_loci > 0`, else continuous.
    mode = get(env.specs, "parasite_match_mode", "auto")::String
    n_loci = Int(get(env.specs, "n_parasite_loci", 0))
    if mode == "auto"
        mode = n_loci > 0 ? "discrete" : "continuous"
    end

    if mode == "discrete"
        _apply_parasites_discrete!(env, n_loci)
    else
        _apply_parasites_continuous!(env)
    end
    nothing
end

"""
    _apply_parasites_continuous!(env)

0.5.0 mean-tracking variant. Kept for backward compatibility and for
scenarios exploring continuous-trait parasite pressure (which selects
against genetic convergence but does *not* reproduce Hamilton's
canonical Red Queen).
"""
function _apply_parasites_continuous!(env::Environment)
    sdims = Int(get(env.specs, "signal_dims", 0))
    sdims > 0 || return

    rate     = Float32(get(env.specs, "parasite_virulence_rate", 0.1))
    pressure = Float32(get(env.specs, "parasite_pressure",       0.5))
    scale    = Float32(get(env.specs, "parasite_distance_scale", 1.0))
    scale_sq = max(scale * scale, 1.0f-4)

    opt = get!(env.specs, "_parasite_optimum",
               zeros(Float32, sdims))::Vector{Float32}
    if length(opt) != sdims
        resize!(opt, sdims)
        fill!(opt, 0.0f0)
    end

    n_hosts  = 0
    centroid = zeros(Float32, sdims)
    @inbounds for ag in env.agents
        ag.alive || continue
        length(ag.signal) == sdims || continue
        for i in 1:sdims
            centroid[i] += ag.signal[i]
        end
        n_hosts += 1
    end
    n_hosts == 0 && return
    @inbounds for i in 1:sdims
        centroid[i] /= Float32(n_hosts)
    end

    @inbounds for i in 1:sdims
        opt[i] = (1.0f0 - rate) * opt[i] + rate * centroid[i]
    end

    @inbounds for ag in env.agents
        ag.alive || continue
        length(ag.signal) == sdims || continue
        d_sq = 0.0f0
        for i in 1:sdims
            diff  = ag.signal[i] - opt[i]
            d_sq += diff * diff
        end
        penalty = pressure * exp(-d_sq / scale_sq)
        ag.energy -= penalty
    end
    nothing
end

"""
    _apply_parasites_discrete!(env, n_loci)

0.5.1 Hamilton 1980 canonical Red Queen. Parasite carries a discrete
binary haplotype that tracks the most-common host allele at each locus
(majority vote with lag). Host infection penalty drops off with
Hamming distance between host and parasite haplotype:

    penalty = pressure * ((n_loci - hamming) / n_loci)^k

Hosts matching the parasite haplotype exactly pay `pressure`; hosts
entirely mismatched pay 0. Exponent `k = parasite_discrete_exponent`
(default 4.0) sharpens the falloff so rare haplotypes escape cleanly.

The key biological insight: under Mendelian inheritance with free
recombination, sexual offspring inherit each locus independently from
either parent. If parents differ at some loci, offspring haplotypes
are genuinely *novel combinations* that the parasite haven't tracked.
Asexual clones carry identical haplotypes generation after generation,
so parasites lock onto them.
"""
function _apply_parasites_discrete!(env::Environment, n_loci::Int)
    n_loci > 0 || return
    rate     = Float32(get(env.specs, "parasite_virulence_rate", 0.1))
    pressure = Float32(get(env.specs, "parasite_pressure",       0.5))
    k_exp    = Float32(get(env.specs, "parasite_discrete_exponent", 4.0))

    # Parasite haplotype cached on env.specs. Length tracks n_loci.
    par_hap = get!(env.specs, "_parasite_haplotype",
                   zeros(Int32, n_loci))::Vector{Int32}
    if length(par_hap) != n_loci
        resize!(par_hap, n_loci)
        fill!(par_hap, Int32(0))
    end

    # 1. Compute per-locus host allele frequency (proportion = 1).
    n_hosts = 0
    freq1   = zeros(Float32, n_loci)
    @inbounds for ag in env.agents
        ag.alive || continue
        length(ag.parasite_haplotype) == n_loci || continue
        for i in 1:n_loci
            ag.parasite_haplotype[i] == Int32(1) && (freq1[i] += 1.0f0)
        end
        n_hosts += 1
    end
    n_hosts == 0 && return
    @inbounds for i in 1:n_loci
        freq1[i] /= Float32(n_hosts)
    end

    # 2. Adapt parasite haplotype with lag: each locus shifts toward the
    #    majority allele with probability `rate`. Implemented as a soft
    #    Bernoulli update: draw a new allele from Bernoulli(freq1) and
    #    replace the parasite locus with probability `rate`.
    rng = env.rng
    @inbounds for i in 1:n_loci
        if rand(rng) < rate
            par_hap[i] = rand(rng) < freq1[i] ? Int32(1) : Int32(0)
        end
    end

    # 3. Apply Hamming-distance penalty per host.
    n_loci_f = Float32(n_loci)
    @inbounds for ag in env.agents
        ag.alive || continue
        length(ag.parasite_haplotype) == n_loci || continue
        hamming = 0
        for i in 1:n_loci
            ag.parasite_haplotype[i] != par_hap[i] && (hamming += 1)
        end
        match_frac = Float32(n_loci - hamming) / n_loci_f
        penalty    = pressure * match_frac ^ k_exp
        ag.energy -= penalty
    end
    nothing
end
