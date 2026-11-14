include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay,Random,Serialization
function physical(env)
 names=filter(x->!(x in (:brain,:genome)),fieldnames(Clade.Agent))
 MixtureAssay.MatchedFounders.digest((env.grass,env.agent_map,env.rng,[Tuple(getfield(a,n) for n in names) for a in env.agents]))
end
function run(brains,seed,mode,io;horizon=1000,at=600)
 ids=MixtureAssay.assignments(8,48,seed); labels=Dict{Int64,Int}();known=Set{Int64}();history=NamedTuple[];pre=Ref("");post=Ref("");swaps=Ref(-1);counts0=Ref{Any}();counts1=Ref{Any}();envref=Ref{Any}()
 function init(s)
  e=MixtureAssay.initialize(s,brains,ids,seed);envref[]=e
  for (i,a) in enumerate(e.agents);labels[a.id]=ids[i];push!(known,a.id);end;e
 end
 function observe(phase,e)
  if phase==:after_tick
   for a in e.agents
    if !(a.id in known)
     haskey(labels,a.parent_id) || error("unknown parent")
     k=labels[a.parent_id];a.brain.mu==brains[k].mu || error("non-clonal policy")
     labels[a.id]=k;push!(known,a.id)
    end
   end
   if e.t%50==0
    v=zeros(Int,8);for a in e.agents;v[labels[a.id]]+=1;end
    push!(history,(tick=Int(e.t),n=length(e.agents),freq=copy(v),grass=sum(Float64,e.grass)))
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
  modes=if mode=="shuffle"
   copy(old)
  elseif mode=="balanced"
   x=repeat(1:8,inner=div(n,8));extras=shuffle(Xoshiro(1900000+seed),collect(1:8))[1:rem(n,8)];append!(x,extras);x
  else error("invalid mode") end
  shuffle!(Xoshiro(2000000+seed),modes); swaps[]=count(i->old[i]!=modes[i],1:n)
  for (i,a) in enumerate(e.agents)
   k=modes[i];b=deepcopy(brains[k]);empty!(b.last_sample);b.ticks_since_sample=typemax(Int32)
   g=a.genome;a.genome=Clade.DiploidGenome(copy(b.mu),Float32[],copy(g.maternal_traits),Float32[],copy(b.arch),g.n_chromosomes);a.brain=b;labels[a.id]=k
  end
  counts1[]=[count(==(k),modes) for k in 1:8];post[]=physical(e)
  pre[]==post[] || error("physical state changed")
  mode=="shuffle" && counts0[]!=counts1[] && error("sham frequencies changed")
  mode=="balanced" && maximum(counts1[])-minimum(counts1[])>1 && error("balance failed")
 end
 s=MixtureAssay.specs(1,seed,"demography";horizon=horizon)
 result=Clade._run_clade(s,init;observe=observe,intervene=intervene)
 pre[]!="" || error("intervention missing")
 if Int(envref[].t)<horizon
  for t in (50*cld(Int(envref[].t)+1,50)):50:horizon
   push!(history,(tick=t,n=0,freq=zeros(Int,8),grass=sum(Float64,envref[].grass)))
  end
 end
 for h in history
  println(io,join((seed,mode,h.tick,h.n,h.grass,pre[],post[],swaps[],join(counts0[],':'),join(counts1[],':'),join(h.freq,':')),','))
 end
 result
end
function study(n,firstseed,out,states)
 mkpath(out)
 open(joinpath(out,"runs.csv"),"w") do io
  println(io,"seed,mode,tick,n,grass,pre_hash,post_hash,swaps,counts_before,counts_after,policy_counts")
  for seed in firstseed:firstseed+n-1
   src=deserialize(joinpath(states,"p1-m0.2-s$(seed).jls"));brains=src.brains[MixtureAssay.panel(src.brains,8,seed)]
   for mode in ("natural","shuffle","balanced");run(brains,seed,mode,io);end
   println("completed seed ",seed);flush(stdout)
  end
 end
end
length(ARGS)==4 || error("usage N FIRST OUT STATES")
study(parse(Int,ARGS[1]),parse(Int,ARGS[2]),ARGS[3],ARGS[4])
