addprocs(1)

using BaseBenchmarks
using BenchmarkTools
using Base.Test

BaseBenchmarks.loadall!()

@test begin
    run(BaseBenchmarks.SUITE, verbose = true, samples = 1,
        evals = 2, gctrial = false, gcsample = false);
    true
end
