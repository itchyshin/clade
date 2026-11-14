include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Random,Serialization,Statistics
function physical(env)
 names=filter(x->!(x in (:brain,:genome)),fieldnames(Clade.Agent))
 MixtureAssay.MatchedFounders.digest((env.grass,env.agent_map,env.rng,[Tuple(getfield(a,n) for n in names) for a in env.agents]))
end
# Select disjoint unlike-policy pairs; both arms change exactly these individuals.
# The treatment accepts only pairs that strictly reduce sum(counts.^2).
function assignments_matched(old, seed)
 rng=Xoshiro(2100000+seed); n=length(old); remaining=collect(1:n)
 shuffle!(rng,remaining); counts=[count(==(k),old) for k in 1:8]
 sham=copy(old); treated=copy(old); pairs=0
 while true
  groups=[[i for i in remaining if old[i]==k] for k in 1:8]
  order=sort(collect(1:8),by=k->(-counts[k],-length(groups[k]),k))
  choices=[k for k in order if !isempty(groups[k])]
  length(choices)<2 && break
  x,y=choices[1:2]; i,j=groups[x][1],groups[y][1]
  best=sum(abs2,counts); bestpair=nothing
  for u in 1:8, v in 1:8
   (u==x || v==y) && continue
   z=copy(counts);z[x]-=1;z[y]-=1;z[u]+=1;z[v]+=1
   score=sum(abs2,z)
   if score<best;best=score;bestpair=(u,v);end
  end
  bestpair===nothing && break
  u,v=bestpair;sham[i]=y;sham[j]=x;treated[i]=u;treated[j]=v
  counts[x]-=1;counts[y]-=1;counts[u]+=1;counts[v]+=1
  filter!(h->h!=i && h!=j,remaining);pairs+=1
 end
 @assert count(i->old[i]!=sham[i],1:n)==2pairs==count(i->old[i]!=treated[i],1:n)
 @assert findall(old.!=sham)==findall(old.!=treated)
 @assert [count(==(k),sham) for k in 1:8]==[count(==(k),old) for k in 1:8]
 return sham,treated,2pairs
end
ageband(age)=age<50 ? 1 : age<100 ? 2 : age<150 ? 3 : 4
function run(brains,seed,mode,io;horizon=1000,at=600)
 ids=MixtureAssay.assignments(8,48,seed); labels=Dict{Int64,Int}();known=Set{Int64}();history=NamedTuple[];pre=Ref("");post=Ref("");swaps=Ref(-1);counts0=Ref{Any}();counts1=Ref{Any}();envref=Ref{Any}()
 function init(s)
  e=MixtureAssay.initialize(s,brains,ids,seed);envref[]=e
  for (i,a) in enumerate(e.agents);labels[a.id]=ids[i];push!(known,a.id);end;e
 end
 before=Dict{Int64,Int}(); births=zeros(Int,4); deaths=zeros(Int,4); exposure=zeros(Int,4); nprev=Ref(48)
 function observe(phase,e)
  if phase==:after_agents
   empty!(before)
   for a in e.agents
    before[a.id]=Int(a.age);exposure[ageband(Int(a.age))]+=1
   end
  elseif phase==:after_tick
   alive=Set(a.id for a in e.agents)
   dead=setdiff(Set(keys(before)),alive)
   born=[a for a in e.agents if !haskey(before,a.id)]
   @assert length(born)==e.n_births && length(dead)==e.n_deaths
   @assert length(e.agents)==nprev[]+length(born)-length(dead)
   for id in dead;deaths[ageband(before[id])]+=1;end
   for a in born
    @assert haskey(before,a.parent_id)
    births[ageband(before[a.parent_id])]+=1
   end
   nprev[]=length(e.agents)
   for a in e.agents
    if !(a.id in known)
     haskey(labels,a.parent_id) || error("unknown parent")
     k=labels[a.parent_id];a.brain.mu==brains[k].mu || error("non-clonal policy")
     labels[a.id]=k;push!(known,a.id)
    end
   end
   if e.t%50==0
    v=zeros(Int,8);for a in e.agents;v[labels[a.id]]+=1;end
    ages=[Int(a.age) for a in e.agents]; bins=[count(x->lo<=x<hi,ages) for (lo,hi) in ((0,50),(50,100),(100,150),(150,typemax(Int)))];
    push!(history,(tick=Int(e.t),n=length(e.agents),freq=copy(v),grass=sum(Float64,e.grass),ages=join(bins,':'),age_sum=sum(ages),births=join(births,':'),deaths=join(deaths,':'),exposure=join(exposure,':')))
    fill!(births,0);fill!(deaths,0);fill!(exposure,0)
   end
  end
 end
 function intervene(e)
  Int(e.t)==at || return
  pre[]=physical(e); old=[labels[a.id] for a in e.agents];n=length(old);n>=8 || error("too few survivors for intervention")
  counts0[]=[count(==(k),old) for k in 1:8]
  if mode=="natural"
   swaps[]=0;counts1[]=copy(counts0[]);post[]=physical(e);return
  end
  sham,treated,k=assignments_matched(old,seed)
  modes=mode=="shuffle" ? sham : mode=="balanced" ? treated : error("invalid mode")
  swaps[]=k
  for (i,a) in enumerate(e.agents)
   k=modes[i];b=deepcopy(brains[k]);empty!(b.last_sample);b.ticks_since_sample=typemax(Int32)
   g=a.genome;a.genome=Clade.DiploidGenome(copy(b.mu),Float32[],copy(g.maternal_traits),Float32[],copy(b.arch),g.n_chromosomes);a.brain=b;labels[a.id]=k
  end
  counts1[]=[count(==(k),modes) for k in 1:8];post[]=physical(e)
  pre[]==post[] || error("physical state changed")
  mode=="shuffle" && counts0[]!=counts1[] && error("sham frequencies changed")
  mode=="balanced" && sum(abs2,counts1[])>sum(abs2,counts0[]) && error("balance worsened")
 end
 s=MixtureAssay.specs(1,seed,"demography";horizon=horizon)
 result=Clade._run_clade(s,init;observe=observe,intervene=intervene)
 pre[]!="" || error("intervention missing")
 if Int(envref[].t)<horizon
  for t in (50*cld(Int(envref[].t)+1,50)):50:horizon
   push!(history,(tick=t,n=0,freq=zeros(Int,8),grass=sum(Float64,envref[].grass),ages="0:0:0:0",age_sum=0,births="0:0:0:0",deaths="0:0:0:0",exposure="0:0:0:0"))
  end
 end
 for h in history
  println(io,join((seed,mode,h.tick,h.n,h.grass,pre[],post[],swaps[],join(counts0[],':'),join(counts1[],':'),join(h.freq,':'),h.ages,h.age_sum,h.births,h.deaths,h.exposure),','))
 end
 result
end
function study(n,firstseed,out,states)
 mkpath(out)
 open(joinpath(out,"runs.csv"),"w") do io
  println(io,"seed,mode,tick,n,grass,pre_hash,post_hash,swaps,counts_before,counts_after,policy_counts,age_bins,age_sum,births_parent_age,deaths_age,exposure_age")
  for seed in firstseed:firstseed+n-1
   src=deserialize(joinpath(states,"p1-m0.2-s$(seed).jls"));brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
   for mode in ("natural","shuffle","balanced");run(brains,seed,mode,io);end
   println("completed seed ",seed);flush(stdout)
  end
 end
end
length(ARGS)==4 || error("usage N FIRST OUT STATES")
study(parse(Int,ARGS[1]),parse(Int,ARGS[2]),ARGS[3],ARGS[4])
