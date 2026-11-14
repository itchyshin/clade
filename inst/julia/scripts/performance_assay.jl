# Controlled population performance and common-garden foraging.
if !isdefined(@__MODULE__,:BehaviourAssay)
    include(joinpath(@__DIR__,"behaviour_assay.jl"))
end
module PerformanceAssay
import ..Clade, ..MatchedFounders, ..BehaviourAssay
using Random,Statistics,Serialization
const OFFSETS=((0,0),(-1,0),(0,1),(1,0),(0,-1))
energy(env)=sum(Float64[a.energy for a in env.agents if a.alive])
function trial(user_specs)
    horizon=Int(user_specs["max_ticks"])
    npre=zeros(Int,horizon);npost=zeros(Int,horizon);food=zeros(horizon);net=zeros(horizon)
    births=zeros(Int,horizon);deaths=zeros(Int,horizon);starvations=zeros(Int,horizon)
    g0=Ref(0.0);e0=Ref(0.0);environment=Ref{Any}();initial=Ref{Any}()
    known=Set{Int64}();cohorts=NamedTuple[];due=Dict{Int,Vector{Int}}()
    function initialize(specs)
        reference=copy(specs);reference["mutation_sd"]=.05
        env=Clade.create_environment(reference)
        initial[]=(fingerprint=MatchedFounders.initial_digest(env),diversity=MatchedFounders.exact_diversity(env.agents))
        union!(known,a.id for a in env.agents)
        env.specs=specs;environment[]=env;env
    end
    function observe(phase,env)
        t=Int(env.t)
        if phase==:before_agents
            npre[t]=count(a->a.alive,env.agents)
            g0[]=sum(Float64,env.grass);e0[]=energy(env)
        elseif phase==:after_agents
            food[t]=g0[]-sum(Float64,env.grass);net[t]=energy(env)-e0[]
            -1e-8<=food[t]<=2*npre[t]+1e-8 || error("grass intake bound failed")
        elseif phase==:after_tick
            npost[t]=length(env.agents);births[t]=env.n_births;deaths[t]=env.n_deaths;starvations[t]=env.n_starvations
            npost[t]==npre[t]+births[t]-deaths[t] || error("population balance failed")
            active=Set(a.id for a in env.agents)
            newborn=sort!(collect(setdiff(active,known)))
            length(newborn)==births[t] || error("birth-ID accounting failed")
            for id in newborn
                push!(cohorts,(id=id,birth_tick=t,followup_tick=t+100,survived_100=-1))
                push!(get!(due,t+100,Int[]),length(cohorts));push!(known,id)
            end
            for i in get(due,t,Int[])
                c=cohorts[i];cohorts[i]=merge(c,(survived_100=Int(c.id in active),))
            end
        end
    end
    result=Clade._run_clade(user_specs,initialize;observe=observe)
    env=environment[]
    for i in eachindex(cohorts)
        c=cohorts[i]
        if c.followup_tick<=horizon && c.survived_100<0
            isempty(env.agents) || error("missing cohort follow-up")
            cohorts[i]=merge(c,(survived_100=0,))
        end
    end
    (result=result,env=env,initial=initial[],npre=npre,npost=npost,food=food,net=net,
     births=births,deaths=deaths,starvations=starvations,cohorts=cohorts)
end

function one_step!(env,brain,location,amount,seed)
    a=env.agents[1];a.brain=brain
    a.x=Int32(3);a.y=Int32(3);a.age=Int32(49);a.energy=40f0;a.alive=true
    a.body_size=1f0;a.metabolic_rate=1f0
    empty!(brain.last_sample);brain.ticks_since_sample=typemax(Int32)
    fill!(env.grass,0f0);fill!(env.agent_map,0);env.agent_map[3,3]=1
    dx,dy=OFFSETS[location];env.grass[3+dx,3+dy]=Float32(amount)
    env.rng=Xoshiro(seed);env.t=Int32(1)
    before=energy(env);g=sum(Float64,env.grass)
    Clade.tick_agents!(env)
    eaten=g-sum(Float64,env.grass)
    0<=eaten<=min(amount,2) || error("one-step food bound failed")
    (food=eaten,net=energy(env)-before,action=Int(a.last_action))
end

function garden(brains,ploidy,seed;draws=64)
    isempty(brains) && throw(ArgumentError("brains required"))
    draws>0 || throw(ArgumentError("positive draws required"))
    before=MatchedFounders.digest(brains)
    specs=BehaviourAssay.specs(ploidy,.05,seed;max_ticks=1)
    specs["grid_rows"]=5;specs["grid_cols"]=5;specs["n_agents_init"]=1
    env=Clade.create_environment(Clade.normalize_specs(specs))
    rows=NamedTuple[]
    for (level,amount) in enumerate((.5,20.0)),location in 1:5
        food=0.0;net=0.0;success=0;idle=0;trials=length(brains)*draws
        for original in brains
            brain=deepcopy(original)
            for rep in 1:draws
                trial_seed=Int(90000000+1000000*seed+10000*(5*(level-1)+location)+rep)
                r=one_step!(env,brain,location,amount,trial_seed)
                food+=r.food;net+=r.net;success+=r.food>0;idle+=r.action==5
            end
        end
        push!(rows,(amount=amount,location=location,trials=trials,food=food,net=net,success=success,idle=idle))
    end
    MatchedFounders.digest(brains)==before || error("source brains changed")
    rows
end

function write_garden(io,p,m,seed,rows,draws)
    for r in rows
        MatchedFounders.row(io,(p,m,seed,r.amount,r.location,r.trials,draws,r.food,r.net,r.success,r.idle))
    end
end

function study(nseeds,outdir,state_dir;draws=64,max_ticks=1000)
    nseeds>0 && draws>0 && max_ticks>0 || throw(ArgumentError("positive counts required"))
    isdir(outdir) && !isempty(readdir(outdir)) && throw(ArgumentError("output must be empty"))
    mkpath(outdir)
    open(joinpath(outdir,"runs.csv"),"w") do runs
     open(joinpath(outdir,"windows.csv"),"w") do windows
      open(joinpath(outdir,"cohorts.csv"),"w") do cohorts
       open(joinpath(outdir,"garden.csv"),"w") do gardens
        println(runs,"ploidy,mutation_sd,seed,initial_fingerprint,endpoint_brain_fingerprint,initial_diversity,final_tick,final_agents,final_diversity,min_population,tick_of_min,total_births,total_deaths,mean_population,final_haploid_fraction")
        println(windows,"ploidy,mutation_sd,seed,window,start_tick,end_tick,agent_ticks,post_agent_ticks,n_at_start,n_at_end,food,net_energy,births,deaths,starvations,cohort_end_tick,cohort_agent_ticks,cohort_births,recruits_100")
        println(cohorts,"ploidy,mutation_sd,seed,id,birth_tick,followup_tick,followup_observed,survived_100")
        println(gardens,"ploidy,mutation_sd,seed,amount,location,trials,draws,food,net_energy,successes,idle_choices")
        completed=0
        for p in (1,2),seed in 20001:(20000+nseeds)
            expected=nothing
            for m in (0.0,.05,.2)
                r=trial(BehaviourAssay.specs(p,m,seed;max_ticks=max_ticks));env=r.env
                expected===nothing && (expected=r.initial.fingerprint)
                r.initial.fingerprint==expected || error("founders differ")
                BehaviourAssay.fixed_ploidy(env.agents,p) || error("ploidy changed")
                old=deserialize(joinpath(state_dir,"p$(p)-m$(m)-s$(seed).jls"))
                fingerprint=MatchedFounders.digest([a.brain for a in env.agents])
                # Full-horizon replay must recover the actual prior endpoint brains.
                if max_ticks==1000
                    fingerprint==MatchedFounders.digest(old.brains) || error("prior endpoint mismatch")
                end
                n=length(env.agents);t=Int(env.t)
                MatchedFounders.row(runs,(p,m,seed,expected,fingerprint,r.initial.diversity,t,n,
                    MatchedFounders.exact_diversity(env.agents),minimum(r.npost[1:t]),argmin(r.npost[1:t]),
                    sum(r.births),sum(r.deaths),sum(r.npost)/max_ticks,n==0 ? NaN : mean(Clade.is_haploid(a.genome) for a in env.agents)))
                for (name,lo,hi) in (("full",1,max_ticks),("late",div(max_ticks,2)+1,max_ticks))
                    cohort_hi=min(hi,max_ticks-100)
                    selected=[c for c in r.cohorts if lo<=c.birth_tick<=cohort_hi]
                    exposure=cohort_hi>=lo ? sum(r.npre[lo:cohort_hi]) : 0
                    MatchedFounders.row(windows,(p,m,seed,name,lo,hi,sum(r.npre[lo:hi]),sum(r.npost[lo:hi]),r.npre[lo],r.npost[hi],sum(r.food[lo:hi]),sum(r.net[lo:hi]),
                        sum(r.births[lo:hi]),sum(r.deaths[lo:hi]),sum(r.starvations[lo:hi]),cohort_hi,exposure,length(selected),sum(c.survived_100 for c in selected;init=0)))
                end
                for c in r.cohorts
                    observed=c.followup_tick<=max_ticks
                    MatchedFounders.row(cohorts,(p,m,seed,c.id,c.birth_tick,c.followup_tick,observed,observed ? c.survived_100 : NaN))
                end
                rows=garden(old.brains,p,seed;draws=draws)
                write_garden(gardens,p,m,seed,rows,draws)
                for io in (runs,windows,cohorts,gardens);flush(io);end
                completed+=1;println("completed $completed / $(6*nseeds)");flush(stdout)
            end
        end
       end
      end
     end
    end
end

function reassay(state_dir,outfile;nseeds=10,draws=256)
    open(outfile,"w") do io
        println(io,"ploidy,mutation_sd,seed,amount,location,trials,draws,food,net_energy,successes,idle_choices")
        for p in (1,2),seed in 20001:(20000+nseeds),m in (0.0,.05,.2)
            old=deserialize(joinpath(state_dir,"p$(p)-m$(m)-s$(seed).jls"))
            write_garden(io,p,m,seed,garden(old.brains,p,seed;draws=draws),draws);flush(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    if length(ARGS)==5 && ARGS[1]=="reassay"
        PerformanceAssay.reassay(ARGS[2],ARGS[3];nseeds=parse(Int,ARGS[4]),draws=parse(Int,ARGS[5]))
    else
        length(ARGS) in (3,4,5) || error("usage: performance_assay.jl N_SEEDS OUTDIR STATE_DIR [DRAWS] [MAX_TICKS]")
        PerformanceAssay.study(parse(Int,ARGS[1]),ARGS[2],ARGS[3];draws=length(ARGS)>=4 ? parse(Int,ARGS[4]) : 64,max_ticks=length(ARGS)==5 ? parse(Int,ARGS[5]) : 1000)
    end
end
