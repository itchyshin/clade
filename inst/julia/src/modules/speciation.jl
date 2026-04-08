"""
    speciation.jl — Genome-distance-based species clustering.

Enabled when `specs["speciation"] == true`.

Species identity (`agent.species_id`) is assigned by clustering agents into
groups whose pairwise genome distance falls below `isolation_threshold`. Two
agents that are genomically close enough to exchange mates successfully are
considered conspecific; those above the threshold are reproductively isolated.

## Clustering algorithm

Every `speciation_cluster_interval` ticks (default 10):

1. Up to 200 agents are sampled uniformly at random to keep the O(n²) distance
   computation tractable. Using the full population on each tick would be
   prohibitively slow for large runs.

2. A genome-distance adjacency structure is built over the sample: agents i and j
   are adjacent iff `genome_distance(i, j) < isolation_threshold`.

3. BFS connected-component labelling assigns integer species IDs 1, 2, … to
   the sampled agents.

4. Non-sampled agents are assigned the species_id of their nearest sampled
   agent by genome distance (1-nearest-neighbour assignment into the labelled
   set).

Between clustering ticks all `species_id` values remain unchanged. Offspring
inherit the parent's `species_id` at birth (via the agent constructor) and
are re-labelled at the next clustering tick.

## Mate filtering

`speciation_filter_mates` is a utility for reproduce.jl: given a focal agent
and a candidate pool, it returns only same-species candidates. When no same-
species candidates exist (a population bottleneck or a genuinely isolated
individual), the full pool is returned so that reproduction is not blocked
entirely.

## References

Coyne, J.A. & Orr, H.A. (2004) Speciation. Sinauer Associates, Sunderland MA.
Nosil, P. (2012) Ecological Speciation. Oxford University Press.
Gavrilets, S. (2004) Fitness Landscapes and the Origin of Species. Princeton
    University Press.
"""

"""
    _bfs_components(adj::Dict{Int,Vector{Int}}, n::Int) -> Vector{Int}

BFS connected-component labelling on an undirected adjacency list over nodes
1..n. Returns a vector of length n where element i is the integer component
ID (1, 2, …) of node i. Nodes not present in `adj` (i.e. with no edges) each
form their own singleton component.
"""
function _bfs_components(adj::Dict{Int,Vector{Int}}, n::Int)::Vector{Int}
    comp   = zeros(Int, n)
    c_id   = 0
    queue  = Int[]

    for start in 1:n
        comp[start] != 0 && continue
        c_id += 1
        comp[start] = c_id
        empty!(queue)
        push!(queue, start)
        head = 1
        while head <= length(queue)
            v = queue[head]
            head += 1
            for nb in get(adj, v, Int[])
                comp[nb] != 0 && continue
                comp[nb] = c_id
                push!(queue, nb)
            end
        end
    end

    comp
end

"""
    assign_species!(env::Environment)

Cluster all agents by genome distance and update `agent.species_id`.

Runs every `speciation_cluster_interval` ticks. Is a no-op when
`specs["speciation"] == false` or when fewer than 2 agents are alive.

Algorithm
---------
1. Sample min(n_agents, 200) agents uniformly without replacement.
2. Compute pairwise genome distances within the sample. Build an adjacency
   list: edge (i,j) exists iff `genome_distance < isolation_threshold`.
3. Assign BFS-connected components as species IDs to the sampled agents.
4. Assign every non-sampled agent the species_id of the nearest sampled agent
   (by genome distance).

All randomness goes through `env.rng`.
"""
function assign_species!(env::Environment)
    specs = env.specs
    Bool(get(specs, "speciation", false)) || return

    interval = Int32(get(specs, "speciation_cluster_interval", 10))
    env.t % interval == Int32(0) || return

    ags = env.agents
    n   = length(ags)
    n < 2 && return

    thresh    = Float64(get(specs, "isolation_threshold", 0.5))
    sample_n  = min(n, 200)
    rng       = env.rng

    # ── 1. Sample agents ──────────────────────────────────────────────────────
    # Draw indices without replacement via partial Fisher-Yates shuffle
    idx_pool = collect(1:n)
    for i in 1:sample_n
        j = i + Int(floor(rand(rng) * (n - i + 1)))
        idx_pool[i], idx_pool[j] = idx_pool[j], idx_pool[i]
    end
    sample_idx = idx_pool[1:sample_n]

    # ── 2. Build adjacency over the sample ────────────────────────────────────
    adj = Dict{Int,Vector{Int}}()
    for ii in 1:sample_n
        i = sample_idx[ii]
        for jj in (ii + 1):sample_n
            j = sample_idx[jj]
            d = Float64(genome_distance(ags[i].genome, ags[j].genome))
            if d < thresh
                push!(get!(adj, ii, Int[]), jj)
                push!(get!(adj, jj, Int[]), ii)
            end
        end
    end

    # ── 3. BFS connected-component labelling ─────────────────────────────────
    comp = _bfs_components(adj, sample_n)

    # Assign species_id to sampled agents
    for ii in 1:sample_n
        ags[sample_idx[ii]].species_id = Int32(comp[ii])
    end

    # ── 4. Assign non-sampled agents to nearest sampled agent ─────────────────
    sampled_set = Set(sample_idx)
    for i in 1:n
        in(i, sampled_set) && continue
        best_d  = Inf
        best_sp = Int32(1)
        for ii in 1:sample_n
            j = sample_idx[ii]
            d = Float64(genome_distance(ags[i].genome, ags[j].genome))
            if d < best_d
                best_d  = d
                best_sp = ags[j].species_id
            end
        end
        ags[i].species_id = best_sp
    end

    return
end

"""
    speciation_filter_mates(focal::Agent, candidates::Vector{Agent},
                            specs::Dict{String,Any}) -> Vector{Agent}

Filter `candidates` to those sharing `focal.species_id`, implementing
assortative mating by species identity.

When `specs["speciation"] == false` the full candidate list is returned
unchanged. When no same-species candidate exists (e.g. a fully isolated
lineage), the full unfiltered list is also returned so that reproduction is
not blocked entirely.

Intended to be called from reproduce.jl before mate selection:

    pool = speciation_filter_mates(focal, nearby_agents, specs)
    # then pick mate from pool by signal preference
"""
function speciation_filter_mates(focal::Agent,
                                  candidates::Vector{Agent},
                                  specs::Dict{String,Any})::Vector{Agent}
    Bool(get(specs, "speciation", false)) || return candidates
    isempty(candidates) && return candidates

    same = filter(c -> c.species_id == focal.species_id, candidates)
    isempty(same) ? candidates : same
end
