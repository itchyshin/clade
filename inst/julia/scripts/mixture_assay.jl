# Private, balanced policy-transplant experiment; canonical kernel is unchanged.
if !isdefined(@__MODULE__,:PerformanceAssay)
 include(joinpath(@__DIR__,"performance_assay.jl"))
end
module MixtureAssay
import ..Clade,..BehaviourAssay,..MatchedFounders,..PerformanceAssay
using Random,Statistics,Serialization,SHA

function assignments(k,n,seed)
 k>0 && n>0 && n%k==0 || throw(ArgumentError("positive equal policy copies required"))
 shuffle(Xoshiro(110000+seed),repeat(1:k,inner=n÷k))
end
function panel(brains,k,seed)
 length(brains)>=k>0 || throw(ArgumentError("not enough source policies"))
 randperm(Xoshiro(120000+seed),length(brains))[1:k]
end
function specs(p,seed,mode;horizon=nothing)
 mode in ("forage","demography") || throw(ArgumentError("unknown phase"))
 h=horizon===nothing ? (mode=="forage" ? 50 : 300) : horizon
 s=BehaviourAssay.specs(p,0.0,300000+seed;max_ticks=h)
 s["n_agents_init"]=48
 mode=="forage" && (s["min_repro_age"]=10000)
 s
end
function initialize(s,brains,ids,seed)
 length(ids)==48 && all(1 .<= ids .<= length(brains)) || throw(ArgumentError("invalid policy assignment"))
 env=Clade.create_environment(s)
 cells=randperm(Xoshiro(130000+seed),900)[1:48]
 fill!(env.agent_map,0)
 for (i,a) in enumerate(env.agents)
  b=deepcopy(brains[ids[i]])
  all(==(.5f0),b.sigma) || error("source exploration drift")
  empty!(b.last_sample);b.ticks_since_sample=typemax(Int32)
  t=copy(a.genome.maternal_traits);p=Int(s["ploidy"])
  a.genome=Clade.DiploidGenome(copy(b.mu),p==2 ? copy(b.mu) : Float32[],
      t,p==2 ? copy(t) : Float32[],copy(b.arch),a.genome.n_chromosomes)
  a.brain=b;a.age=Int32(50);a.energy=70f0;a.energy_last_tick=70f0
  a.x=Int32(mod1(cells[i],30));a.y=Int32(cld(cells[i],30))
  env.agent_map[a.x,a.y]=i
  a.brain.mu==Clade.express_weights(a.genome,"additive") || error("policy/genome mismatch")
 end
 env.rng=Xoshiro(140000+seed)
 env
end
physical_digest(env)=MatchedFounders.digest((env.grass,[(a.id,a.x,a.y,a.age,a.energy,a.genome.maternal_traits,a.genome.paternal_traits) for a in env.agents],env.rng))

function trial(brains,p,seed,mode,mono;horizon=nothing,overrides=Dict{String,Any}())
 k=length(brains);ids=mono==0 ? assignments(k,48,seed) : fill(mono,48)
 s=specs(p,seed,mode;horizon=horizon);merge!(s,overrides);h=Int(s["max_ticks"])
 pre=zeros(Int,h);post=zeros(Int,h);food=zeros(h);net=zeros(h);idle=zeros(Int,h)
 births=zeros(Int,h);deaths=zeros(Int,h);starvations=zeros(Int,h)
 g0=Ref(0.0);e0=Ref(0.0);environment=Ref{Any}();physical=Ref("")
 cohorts=NamedTuple[];due=Dict{Int,Vector{Int}}();known=Set{Int64}()
 function init(s)
  env=initialize(s,brains,ids,seed);environment[]=env;physical[]=physical_digest(env)
  union!(known,a.id for a in env.agents);env
 end
 function observe(phase,env)
  t=Int(env.t)
  if phase==:before_agents
   pre[t]=length(env.agents);g0[]=sum(Float64,env.grass);e0[]=PerformanceAssay.energy(env)
  elseif phase==:after_agents
   food[t]=g0[]-sum(Float64,env.grass);net[t]=PerformanceAssay.energy(env)-e0[]
   idle[t]=count(a->a.alive && a.last_action==5,env.agents)
   -1e-8<=food[t]<=2pre[t]+1e-8 || error("food bound")
   # Fixed 282-weight BNN, body/metabolism1: default costs .382 +1 or .5.
   net[t]<=5food[t]-1.382pre[t]+.5idle[t]+2e-4*pre[t] || error("energy ledger")
  elseif phase==:after_tick
   post[t]=length(env.agents);births[t]=env.n_births;deaths[t]=env.n_deaths;starvations[t]=env.n_starvations
   post[t]==pre[t]+births[t]-deaths[t] || error("population ledger")
   active=Set(a.id for a in env.agents)
   newborn=[a for a in env.agents if !(a.id in known)]
   length(newborn)==births[t] || error("birth ledger")
   for a in newborn
    push!(cohorts,(id=a.id,parent=a.parent_id,mate=a.mate_id,birth=t,follow=t+100,survived=-1))
    push!(get!(due,t+100,Int[]),length(cohorts));push!(known,a.id)
   end
   for i in get(due,t,Int[])
    c=cohorts[i];cohorts[i]=merge(c,(survived=Int(c.id in active),))
   end
   BehaviourAssay.fixed_ploidy(env.agents,p) || error("ploidy drift")
   all(all(==(.5f0),a.brain.sigma) for a in env.agents) || error("exploration drift")
   if mode=="forage"
    pre[t]==post[t]==48 && births[t]==deaths[t]==0 || error("equal density violated")
   end
  end
 end
 result=Clade._run_clade(s,init;observe=observe);env=environment[]
 for i in eachindex(cohorts)
  c=cohorts[i]
  if c.follow<=h && c.survived<0
   isempty(env.agents) || error("missing followup")
   cohorts[i]=merge(c,(survived=0,))
  end
 end
 # Independent cohort truth from the canonical death ledger, not observer rows.
 deathmap=Dict(Int(id)=>Int(t) for (id,t) in zip(env.deaths["id"],env.deaths["t"]))
 survivors=Set(a.id for a in env.agents)
 length(deathmap)==length(env.deaths["id"]) || error("duplicate death ID")
 for c in cohorts
  haskey(deathmap,c.id) || c.id in survivors || error("unaccounted newborn")
  if c.follow<=h
   c.survived==Int(get(deathmap,c.id,typemax(Int))>c.follow) || error("cohort/death mismatch")
  else
   c.survived==-1 || error("censoring mismatch")
  end
 end
 reward=5sum(food)-1.382sum(pre)+.5sum(idle)
 windows=[(lo=lo,hi=min(lo+49,h),pre=sum(pre[lo:min(lo+49,h)]),post=sum(post[lo:min(lo+49,h)]),
    nstart=lo==1 ? 48 : post[lo-1],nend=post[min(lo+49,h)],
    food=sum(food[lo:min(lo+49,h)]),net=sum(net[lo:min(lo+49,h)]),idle=sum(idle[lo:min(lo+49,h)]),
    births=sum(births[lo:min(lo+49,h)]),deaths=sum(deaths[lo:min(lo+49,h)]),starvations=sum(starvations[lo:min(lo+49,h)])) for lo in 1:50:h]
 (result=result,env=env,physical=physical[],pre=pre,post=post,food=sum(food),net=sum(net),
  exposure=sum(pre),births=sum(births),deaths=sum(deaths),reward=reward,clipping=reward-sum(net),
  cohorts=cohorts,windows=windows)
end

function study(nseeds,outdir,state_dir;seed_start=20001)
 nseeds>0 || throw(ArgumentError("positive seeds required"))
 isdir(outdir) && !isempty(readdir(outdir)) && error("output must be empty")
 mkpath(outdir)
 names=("runs","windows","cohorts","deaths","panels","policies")
 io=Dict(n=>open(joinpath(outdir,n*".csv"),"w") for n in names)
 try
  println(io["runs"],"ploidy,source_mutation,seed,mode,mono,physical_hash,panel_hash,final_tick,final_agents,min_population,tick_of_min,exposure,food,net_energy,uncapped_reward,clipping,births,deaths,cohort_exposure,cohort_births,recruits100,founder_births")
  println(io["windows"],"ploidy,source_mutation,seed,mode,mono,lo,hi,pre_exposure,post_exposure,nstart,nend,food,net_energy,idle,births,deaths,starvations")
  println(io["cohorts"],"ploidy,source_mutation,seed,mode,mono,id,parent,mate,birth,follow,observed,survived")
  println(io["deaths"],"ploidy,source_mutation,seed,mode,mono,id,tick")
  println(io["panels"],"ploidy,source_mutation,seed,source_sha256,panel_hash,between,within,source_n")
  println(io["policies"],"ploidy,source_mutation,seed,policy,source_index,mu_hash,brain_hash")
  completed=0
  for p in (1,2),seed in seed_start:(seed_start+nseeds-1),m in (0.0,.05,.2)
   path=joinpath(state_dir,"p$(p)-m$(m)-s$(seed).jls")
   source=deserialize(path)
   source.ploidy==p && source.mutation==m && source.seed==seed || error("archive metadata mismatch")
   before=MatchedFounders.digest(source.brains)
   indices=panel(source.brains,8,seed);brains=source.brains[indices];ph=MatchedFounders.digest(brains)
   rows=BehaviourAssay.assay(brains;draws=64,seed=150000+seed)
   MatchedFounders.row(io["panels"],(p,m,seed,bytes2hex(sha256(read(path))),ph,mean(r.between for r in rows),mean(r.within for r in rows),length(source.brains)))
   for (j,i) in enumerate(indices)
    MatchedFounders.row(io["policies"],(p,m,seed,j,i,MatchedFounders.digest(brains[j].mu),MatchedFounders.digest(brains[j])))
   end
   for mode in ("forage","demography"),mono in 0:8
    r=trial(brains,p,seed,mode,mono);h=length(r.pre);eligible=filter(c->c.follow<=h,r.cohorts)
    MatchedFounders.row(io["runs"],(p,m,seed,mode,mono,r.physical,ph,Int(r.env.t),length(r.env.agents),minimum(r.post),argmin(r.post),r.exposure,r.food,r.net,r.reward,r.clipping,r.births,r.deaths,sum(r.pre[1:max(0,h-100)]),length(eligible),sum(c.survived for c in eligible;init=0),count(c->c.parent<=48,r.cohorts)))
    for w in r.windows
     MatchedFounders.row(io["windows"],(p,m,seed,mode,mono,w.lo,w.hi,w.pre,w.post,w.nstart,w.nend,w.food,w.net,w.idle,w.births,w.deaths,w.starvations))
    end
    for c in r.cohorts
     MatchedFounders.row(io["cohorts"],(p,m,seed,mode,mono,c.id,c.parent,c.mate,c.birth,c.follow,c.follow<=h,c.survived))
    end
    for (id,t) in zip(r.env.deaths["id"],r.env.deaths["t"])
     MatchedFounders.row(io["deaths"],(p,m,seed,mode,mono,id,t))
    end
    completed+=1
    completed%18==0 && println("completed ",completed," / ",108nseeds)
   end
   MatchedFounders.digest(source.brains)==before || error("source brains mutated")
  end
 finally
  foreach(close,values(io))
 end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
 length(ARGS) in (3,4) || error("usage: mixture_assay.jl N_SEEDS OUTDIR STATE_DIR [SEED_START]")
 MixtureAssay.study(parse(Int,ARGS[1]),ARGS[2],ARGS[3];seed_start=length(ARGS)==4 ? parse(Int,ARGS[4]) : 20001)
end
