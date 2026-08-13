using Pkg; Pkg.activate("inst/julia")
using Clade, InteractiveUtils

specs = Dict{String, Any}(
    "log_movement" => true, 
    "log_movement_freq" => 1,
    "_movement_log" => Dict{String, Vector}(
        "tick" => Int32[], "id" => Int64[], "x" => Int32[], "y" => Int32[],
        "age" => Int32[], "energy" => Float32[], "alive" => Bool[]
    )
)

mutable struct MockAgent
    id::Int64; x::Int32; y::Int32; age::Int32; energy::Float32; alive::Bool
end

mutable struct MockEnv
    specs::Dict{String, Any}
    t::Int
    agents::Vector{MockAgent}
end

dummy_env = MockEnv(specs, 1, [MockAgent(1, 10, 10, 5, 100.0f0, true)])

println("\n=== CODE WARNTYPE EVIDENCE ===")
@code_warntype Clade.log_movement!(dummy_env)
