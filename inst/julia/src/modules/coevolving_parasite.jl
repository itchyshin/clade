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
    sdims = Int(get(env.specs, "signal_dims", 0))
    sdims > 0 || return

    rate     = Float32(get(env.specs, "parasite_virulence_rate", 0.1))
    pressure = Float32(get(env.specs, "parasite_pressure",       0.5))
    scale    = Float32(get(env.specs, "parasite_distance_scale", 1.0))
    scale_sq = max(scale * scale, 1.0f-4)

    # Lazy-init the parasite optimum cached on env.specs (avoids
    # modifying the Environment struct). Length tracks signal_dims.
    opt = get!(env.specs, "_parasite_optimum",
               zeros(Float32, sdims))::Vector{Float32}
    if length(opt) != sdims
        resize!(opt, sdims)
        fill!(opt, 0.0f0)
    end

    # 1. Compute host signal centroid over live prey agents with
    #    signal vectors. Predators (empty signal) are excluded.
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

    # 2. Adapt parasite optimum toward centroid (exponential tracking).
    @inbounds for i in 1:sdims
        opt[i] = (1.0f0 - rate) * opt[i] + rate * centroid[i]
    end

    # 3–4. Apply Gaussian-falloff infection cost per host.
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
