using BaseBenchmarks
using BenchmarkTools
if VERSION >= v"0.7.0-DEV.2954"
    using Distributed
end

addprocs(1)

# re-tune the entire suite

BaseBenchmarks.loadall!(tune = false)
warmup(BaseBenchmarks.SUITE)
tune!(BaseBenchmarks.SUITE; verbose = true)
BenchmarkTools.save(BaseBenchmarks.PARAMS_PATH, params(BaseBenchmarks.SUITE))
