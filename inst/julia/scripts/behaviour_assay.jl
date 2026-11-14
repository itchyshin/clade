# Private research assay; public simulation defaults are unchanged.
if !isdefined(@__MODULE__, :MatchedFounders)
    include(joinpath(@__DIR__, "matched_founders.jl"))
end
module BehaviourAssay
import ..Clade, ..MatchedFounders
using Random, Statistics, Serialization

function contexts()
    grass = [zeros(Float32,4),ones(Float32,4)]
    append!(grass, [Float32.(collect(1:4).==i) for i in 1:4])
    [vcat(Float32[e,a],g,fill(Float32(o),4),Float32[1])
     for e in (.25,.75) for a in (.25,.75) for g in grass for o in (0,1)]
end

# Integer sufficient statistics independently reconstruct both estimators.
function stats(A::AbstractMatrix, B::AbstractMatrix, draws::Int)
    size(A)==size(B) || throw(ArgumentError("count shapes differ"))
    n=size(A,1); n>=2 || throw(ArgumentError("at least two agents required"))
    all(sum(A,dims=2).==draws) && all(sum(B,dims=2).==draws) ||
        throw(ArgumentError("counts must total draws"))
    sa=vec(sum(A,dims=1)); sb=vec(sum(B,dims=1))
    cross=sum(A.*B)
    between=(n*cross-sum(sa.*sb))/(n*(n-1)*draws^2)
    within=1-cross/(n*draws^2)
    (between=between,within=within,cross=cross,sa=sa,sb=sb)
end

function assay(brains; draws::Int=64, seed::Int=720001)
    draws>0 || throw(ArgumentError("draws must be positive"))
    n=length(brains); n>=2 || throw(ArgumentError("at least two brains required"))
    all(b.arch==first(brains).arch && length(b.mu)==length(first(brains).mu) for b in brains) ||
        throw(ArgumentError("all brains must share architecture"))
    first(brains).arch[1]==11 && first(brains).arch[end]==5 ||
        throw(ArgumentError("assay requires 11 inputs and five actions"))
    before=MatchedFounders.digest(brains)
    rng=Xoshiro(seed)
    rows=NamedTuple[]
    for (context,x) in enumerate(contexts())
        banks=[zeros(Int64,n,5),zeros(Int64,n,5)]
        for bank in banks, rep in 1:draws
            z=Float32.(randn(rng,length(first(brains).mu)))
            for (i,b) in enumerate(brains)
                weights=b.mu .+ b.sigma .* z
                action=argmax(Clade.forward(Clade.make_ann_brain(weights,b.arch),x))
                bank[i,action]+=1
            end
        end
        s=stats(banks[1],banks[2],draws)
        deterministic=zeros(Int,5)
        for b in brains
            action=argmax(Clade.forward(Clade.make_ann_brain(b.mu,b.arch),x))
            deterministic[action]+=1
        end
        disagreement=1-sum(deterministic.*(deterministic.-1))/(n*(n-1))
        push!(rows,(context=context,n=n,draws=draws,cross=s.cross,
            sa=s.sa,sb=s.sb,between=s.between,within=s.within,
            deterministic_disagreement=disagreement))
    end
    before==MatchedFounders.digest(brains) || error("assay changed brains")
    rows
end

function specs(ploidy,mutation,seed;max_ticks=1000)
    Dict{String,Any}("random_seed"=>seed,"max_ticks"=>max_ticks,
        "grid_rows"=>30,"grid_cols"=>30,"n_agents_init"=>50,
        "brain_type"=>"bnn","bnn_sigma_source"=>"fixed","bnn_sigma_init"=>.5,
        "bnn_action_noise_scale"=>1.0,"action_exploration_epsilon"=>0.0,
        "ploidy"=>ploidy,"self_fertilization_fallback"=>true,
        "move_cost"=>1.0,"grass_max"=>20.0,"min_repro_energy"=>120.0,
        "energy_init"=>70.0,"mutation_sd"=>mutation,
        "grass_growth_mode"=>"stochastic","sense_mode"=>"per_cell","input_radius"=>1)
end

function fixed_ploidy(agents,ploidy)
    all(Clade.is_haploid(a.genome)==(ploidy==1) for a in agents)
end

function write_context(io,ploidy,mutation,seed,rows)
    for r in rows
        MatchedFounders.row(io,(ploidy,mutation,seed,r.context,r.n,r.draws,r.cross,
            r.sa...,r.sb...,r.between,r.within,r.deterministic_disagreement))
    end
end

function study(nseeds,outdir;draws=64,max_ticks=1000)
    nseeds>0 && max_ticks>0 && draws>0 || throw(ArgumentError("counts must be positive"))
    isdir(outdir) && !isempty(readdir(outdir)) && throw(ArgumentError("output must be empty"))
    mkpath(joinpath(outdir,"states"))
    open(joinpath(outdir,"contexts.csv"),"w") do table
        println(table,"context,"*join(["input$i" for i in 1:11],','))
        for (i,x) in enumerate(contexts()); MatchedFounders.row(table,(i,x...)); end
    end
    open(joinpath(outdir,"runs.csv"),"w") do runs
      open(joinpath(outdir,"assay.csv"),"w") do profiles
        println(runs,"ploidy,mutation_sd,seed,initial_fingerprint,initial_diversity,final_tick,final_agents,final_diversity,min_population,tick_of_min,total_births,mean_population,behavioral_entropy_last100,between,within,deterministic_disagreement,assay_draws,assay_seed,final_haploid_fraction")
        println(profiles,"ploidy,mutation_sd,seed,context,n,draws,cross,"*join(["a$i" for i in 1:5],',')*","*join(["b$i" for i in 1:5],',')*",between,within,deterministic_disagreement")
        completed=0
        for ploidy in (1,2), seed in 20001:(20000+nseeds)
            matched=nothing
            for mutation in (0.0,.05,.20)
                run=MatchedFounders.trial(specs(ploidy,mutation,seed;max_ticks=max_ticks),.05)
                env=run.env; n=length(env.agents); t=Int(env.t)
                fixed_ploidy(env.agents,ploidy) || error("endpoint ploidy changed")
                matched===nothing && (matched=run.initial.fingerprint)
                matched==run.initial.fingerprint || error("initial state mismatch")
                all(all(==(.5f0),a.brain.sigma) for a in env.agents) || error("sigma changed")
                rng_before=MatchedFounders.digest(env.rng)
                assay_seed=700000+seed
                rows=n>=2 ? assay([a.brain for a in env.agents];draws=draws,seed=assay_seed) : NamedTuple[]
                rng_before==MatchedFounders.digest(env.rng) || error("assay changed simulation RNG")
                write_context(profiles,ploidy,mutation,seed,rows)
                avg(field)=isempty(rows) ? NaN : mean(getproperty(r,field) for r in rows)
                ns=env.progress["n_agents"][1:t]
                entropy=env.progress["behavioral_diversity"][max(1,t-99):t]
                entropy=filter(isfinite,entropy)
                hap=n==0 ? NaN : mean(Clade.is_haploid(a.genome) for a in env.agents)
                MatchedFounders.row(runs,(ploidy,mutation,seed,matched,run.initial.diversity,t,n,
                    MatchedFounders.exact_diversity(env.agents),minimum(ns),argmin(ns),
                    sum(env.progress["n_births"][1:t]),sum(ns)/max_ticks,
                    isempty(entropy) ? NaN : mean(entropy),avg(:between),avg(:within),
                    avg(:deterministic_disagreement),draws,assay_seed,hap))
                serialize(joinpath(outdir,"states","p$(ploidy)-m$(mutation)-s$(seed).jls"),
                    (ploidy=ploidy,mutation=mutation,seed=seed,brains=[a.brain for a in env.agents]))
                flush(runs);flush(profiles);completed+=1
                println("completed $completed / $(6*nseeds)");flush(stdout)
            end
        end
      end
    end
end

function reassay(state_dir,outfile;draws=256,nseeds=10)
    open(outfile,"w") do io
        println(io,"ploidy,mutation_sd,seed,between,within,deterministic_disagreement,draws")
        for ploidy in (1,2), seed in 20001:(20000+nseeds), mutation in (0.0,.05,.2)
            state=deserialize(joinpath(state_dir,"p$(ploidy)-m$(mutation)-s$(seed).jls"))
            length(state.brains)>=2 || continue
            rows=assay(state.brains;draws=draws,seed=700000+seed)
            MatchedFounders.row(io,(ploidy,mutation,seed,
                mean(r.between for r in rows),mean(r.within for r in rows),
                mean(r.deterministic_disagreement for r in rows),draws))
            flush(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    if length(ARGS)==5 && ARGS[1]=="reassay"
        BehaviourAssay.reassay(ARGS[2],ARGS[3];draws=parse(Int,ARGS[4]),nseeds=parse(Int,ARGS[5]))
    else
        length(ARGS) in (2,3,4) || error("usage: behaviour_assay.jl N_SEEDS OUTDIR [DRAWS] [MAX_TICKS]")
        BehaviourAssay.study(parse(Int,ARGS[1]),ARGS[2];draws=length(ARGS)>=3 ? parse(Int,ARGS[3]) : 64,max_ticks=length(ARGS)==4 ? parse(Int,ARGS[4]) : 1000)
    end
end
