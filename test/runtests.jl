using BaseBenchmarks
using BenchmarkTools
using Compat
using Compat.Test

if VERSION >= v"0.7.0-DEV.2954"
    using Distributed
end

addprocs(1)

BaseBenchmarks.loadall!()
for group in BaseBenchmarks.NOT_INCLUDED_IN_ALL
    BaseBenchmarks.load!(group)
end

@test begin
    run(BaseBenchmarks.SUITE, verbose = true, samples = 1,
        evals = 2, gctrial = false, gcsample = false);
    true
end
