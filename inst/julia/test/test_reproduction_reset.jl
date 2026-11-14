using Test,Random
if !isdefined(@__MODULE__,:Clade)
 using Clade
end
function _reproduction_reset_specs(;ticks=3,history="iteroparous",clutch=1)
 Dict{String,Any}("random_seed"=>31,"max_ticks"=>ticks,"n_agents_init"=>1,
 "grid_rows"=>10,"grid_cols"=>10,"max_agents"=>20,"ploidy"=>1,
 "brain_type"=>"bnn","bnn_sigma_source"=>"fixed","bnn_sigma_init"=>.5,
 "grass_init_prob"=>1.0,"grass_max"=>20.0,"grass_rate"=>0.0,
 "energy_init"=>200.0,"min_repro_energy"=>50.0,"max_age"=>200,
 "repro_cost_mode"=>"fixed","repro_cost"=>0.0,
 "offspring_energy_mode"=>"fixed","offspring_energy"=>.1,
 "max_clutch_size"=>clutch,"life_history"=>history)
end
function _reproduction_reset_run(s)
 captured=Ref{Any}()
 Clade._run_clade(s,specs->(captured[]=Clade.create_environment(specs)))
 captured[]
end
@testset "Focal reproductive episodes reset between ticks" begin
 env=_reproduction_reset_run(_reproduction_reset_specs())
 founder=only(filter(a->a.id==1,env.agents))
 @test founder.num_offspring==3
 @test sum(env.progress["n_births"])==3
 s=Clade.normalize_specs(_reproduction_reset_specs())
 env=Clade.create_environment(s);founder=env.agents[1]
 Clade.create_offspring!(env)
 Clade.create_offspring!(env)
 @test founder.num_offspring==1
 @test env.n_births==1
 env=Clade.create_environment(s);founder=env.agents[1];founder.energy=0f0
 Clade.create_offspring!(env)
 @test !founder.reproduced
 founder.energy=200f0;Clade.create_offspring!(env)
 @test founder.num_offspring==1
end
@testset "Semelparous flag survives until next mortality phase" begin
 env=_reproduction_reset_run(_reproduction_reset_specs(ticks=1,history="semelparous",clutch=3))
 founder=only(filter(a->a.id==1,env.agents))
 @test founder.alive && founder.reproduced
 @test founder.num_offspring==3
 env=_reproduction_reset_run(_reproduction_reset_specs(ticks=2,history="semelparous",clutch=3))
 @test all(a.id!=1 for a in env.agents)
 i=only(findall(==(1),env.deaths["id"]))
 @test env.deaths["t"][i]==2
 @test env.deaths["cause"][i]=="semelparous"
 @test env.deaths["num_offspring"][i]==3
 @test sum(env.progress["n_births"])==3
end
