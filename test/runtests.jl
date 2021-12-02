using BaseBenchmarks
using BenchmarkTools
using Test
using Distributed

addprocs(1)

BaseBenchmarks.loadall!()

@test begin
    run(BaseBenchmarks.SUITE, verbose = true, samples = 1,
        evals = 1, gctrial = false, gcsample = false);
    true
end
