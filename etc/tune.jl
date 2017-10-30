addprocs(1)

using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite

BaseBenchmarks.loadall!(tune = false)
warmup(BaseBenchmarks.SUITE)
tune!(BaseBenchmarks.SUITE; verbose = true)
BenchmarkTools.save(BaseBenchmarks.PARAMS_PATH, params(BaseBenchmarks.SUITE))
