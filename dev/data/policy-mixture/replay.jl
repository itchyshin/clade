include(joinpath(@__DIR__,"..","..","..","inst","julia","scripts","mixture_assay.jl"))
length(ARGS)==2 || error("usage replay.jl NEW_OUTDIR STATE_DIR")
MixtureAssay.study(1,ARGS[1],ARGS[2])
for p in (1,2),m in (0.0,.05,.2),mode in ("forage","demography"),mono in (0,1)
 seed=20001;source=MixtureAssay.deserialize(joinpath(ARGS[2],"p$(p)-m$(m)-s$(seed).jls"))
 brains=source.brains[MixtureAssay.panel(source.brains,8,seed)]
 r=MixtureAssay.trial(brains,p,seed,mode,mono)
 ids=mono==0 ? MixtureAssay.assignments(8,48,seed) : fill(mono,48)
 init(s)=MixtureAssay.initialize(s,brains,ids,seed)
 isequal(r.result,Clade._run_clade(MixtureAssay.specs(p,seed,mode),init)) || error("observer changed canonical result")
end
println("All24 mixture/monoculture phase and ploidy observer controls pass")
