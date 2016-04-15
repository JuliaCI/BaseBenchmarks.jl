addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite
@warmup BaseBenchmarks.SUITE
tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)
JLD.save("evals.jld", "suite", evals(BaseBenchmarks.SUITE))
