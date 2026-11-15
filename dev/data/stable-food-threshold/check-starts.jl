include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Serialization
MF=MixtureAssay.MatchedFounders;C=MixtureAssay.Clade
root=ARGS[1];life=parse(Int,ARGS[2]);first=parse(Int,ARGS[3]);last=parse(Int,ARGS[4])
println("seed,food,age_mode,normalized_hash")
for seed in first:last
 d=joinpath(root,string(life),string(seed));data=deserialize(joinpath(d,"source.jls"));panel=data.brains[MixtureAssay.panel(data.brains,8,seed)]
 raw=readlines(joinpath(d,"runs.csv"));head=split(raw[1],',');ix=Dict(x=>i for (i,x) in enumerate(head))
 records=[split(line,',') for line in raw[2:end]]
 for rate in (.05,.025),age in ("fixed","staggered")
  ENV["CLADE_FACTORIAL_AGE"]=age;normalized=String[]
  for threshold in (80,120)
   s=MixtureAssay.specs(1,seed,"demography";horizon=1000)
   merge!(s,Dict("n_agents_init"=>96,"max_age"=>life,"min_repro_energy"=>threshold,"max_agents"=>700,"grass_rate"=>rate,"grass_init_prob"=>(rate==.05 ? .5 : .25)))
   s=C.normalize_specs(s);s["_movement_log"]=nothing
   ids=MixtureAssay.assignments(8,96,seed);env=MixtureAssay.initialize(s,panel,ids,seed)
   all(a.repro_threshold==threshold for a in env.agents) || error("incorrect threshold")
   matches=[r for r in records if parse(Int,r[ix["threshold"]])==threshold && parse(Float64,r[ix["food"]])==rate && r[ix["age_mode"]]==age && parse(Int,r[ix["mono"]])==0]
   length(matches)==1 && MixtureAssay.physical_digest(env)==matches[1][ix["physical"]] || error("recorded fingerprint mismatch")
   clean(t)=begin v=copy(t);length(v)>=C.TRAIT_REPRO_THRESHOLD && (v[C.TRAIT_REPRO_THRESHOLD]=0f0);v end
   h=MF.digest((env.grass,[(a.id,a.x,a.y,a.age,a.energy,clean(a.genome.maternal_traits),clean(a.genome.paternal_traits)) for a in env.agents],env.rng))
   push!(normalized,h)
  end
  length(unique(normalized))==1 || error("unmatched non-threshold initial state")
  println(join((seed,rate,age,normalized[1]),','))
 end
end
