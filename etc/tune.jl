using BaseBenchmarks
using BenchmarkTools
using Distributed

addprocs(1)

# re-tune the entire suite

BaseBenchmarks.loadall!(tune = false)
warmup(BaseBenchmarks.SUITE)
tune!(BaseBenchmarks.SUITE; verbose = true)
BenchmarkTools.save(BaseBenchmarks.PARAMS_PATH, params(BaseBenchmarks.SUITE))
