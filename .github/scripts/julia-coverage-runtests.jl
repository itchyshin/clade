# CI-only entry for the julia-coverage job (.github/workflows/coverage.yaml).
# Runs inst/julia/test/runtests.jl under --code-coverage=user and refuses to
# succeed when zero tests passed (loading the module alone still writes .cov).

using Test

const RUNTESTS =
    joinpath(@__DIR__, "..", "..", "inst/julia", "test", "runtests.jl")

function tally(ts::Test.DefaultTestSet)
    passes = ts.n_passed
    fails = ts.n_failed + ts.n_error + ts.n_broken + ts.n_invalid
    for child in ts.sets
        cpass, cfail = tally(child)
        passes += cpass
        fails += cfail
    end
    return passes, fails
end

ts = @testset "CI Julia coverage (runtests.jl)" verbose = true begin
    include(RUNTESTS)
end

passes, fails = tally(ts)
count_path = joinpath(@__DIR__, "..", "..", "coverage-julia-test-count.txt")
open(count_path, "w") do io
    println(io, "julia_test_pass_count=$passes")
    println(io, "julia_test_fail_count=$fails")
end
@info "Julia coverage test tally" passes fails

if passes == 0
    error("julia-coverage: zero tests passed; refusing empty success.")
end
if fails > 0
    error("julia-coverage: $fails failing test(s).")
end
