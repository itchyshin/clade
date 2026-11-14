using Test,Random
if !isdefined(@__MODULE__,:BehaviourAssay)
    include(joinpath(@__DIR__,"..","scripts","behaviour_assay.jl"))
end
@testset "Behavioural assay independent-bank arithmetic" begin
    A=[10 0;0 10]; B=copy(A)
    s=BehaviourAssay.stats(A,B,10)
    @test s.between==1
    @test s.within==0
    @test BehaviourAssay.stats(fill(5,2,2),fill(5,2,2),10).between==0
    @test BehaviourAssay.stats([10 0;0 10],[0 10;10 0],10).between == -1
    @test_throws ArgumentError BehaviourAssay.stats(A,B,9)
    @test length(BehaviourAssay.contexts())==48
    @test all(length(x)==11 && x[end]==1 for x in BehaviourAssay.contexts())
end
@testset "Canonical choice assay and ploidy controls" begin
    arch=Int32[11,5]; w=zeros(Float32,60)
    w[56]=20
    a=Clade.BNNBrain(copy(w),zeros(Float32,60),arch,Float32[],typemax(Int32))
    w[56]=0;w[57]=20
    b=Clade.BNNBrain(copy(w),zeros(Float32,60),arch,Float32[],typemax(Int32))
    state=MatchedFounders.digest([a,b])
    rows=BehaviourAssay.assay([a,b];draws=4,seed=3)
    @test all(r.between==1 && r.within==0 && r.deterministic_disagreement==1 for r in rows)
    @test MatchedFounders.digest([a,b])==state
    clones=BehaviourAssay.assay([a,deepcopy(a)];draws=4,seed=3)
    @test all(r.between==0 for r in clones)
    a.sigma.=.5
    @test all(r.between==0 for r in BehaviourAssay.assay([a,deepcopy(a)];draws=8,seed=2))
    for ploidy in (1,2)
        s=Clade.normalize_specs(BehaviourAssay.specs(ploidy,.05,31;max_ticks=2))
        env=Clade.create_environment(s)
        @test BehaviourAssay.fixed_ploidy(env.agents,ploidy)
        child=Clade.make_offspring_genome(env.agents[1].genome,nothing,s,Xoshiro(31))
        @test Clade.is_haploid(child)==(ploidy==1)
    end
    @test_throws ArgumentError BehaviourAssay.assay([a];draws=4)
    @test_throws ArgumentError BehaviourAssay.assay([a,b];draws=0)
end
