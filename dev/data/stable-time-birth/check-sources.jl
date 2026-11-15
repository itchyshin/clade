include(joinpath(@__DIR__,"inst/julia/scripts/mixture_assay.jl"))
using .MixtureAssay, Serialization, Statistics
BA=MixtureAssay.BehaviourAssay; MF=MixtureAssay.MatchedFounders
root=ARGS[1]
println("seed,distinct,mean_disagreement,panel_hash")
for seed in parse(Int,ARGS[2]):parse(Int,ARGS[3])
 data=deserialize(joinpath(root,string(seed),"source.jls")); @assert data.seed==seed
 panel=data.brains[MixtureAssay.panel(data.brains,8,seed)]
 distinct=length(unique(MF.digest(b.mu) for b in panel)); assay=BA.assay(panel;draws=64,seed=150000+seed)
 disagreement=mean(r.deterministic_disagreement for r in assay)
 @assert distinct==8 && disagreement>0
 println(join((seed,distinct,disagreement,MF.digest(panel)),','))
end
