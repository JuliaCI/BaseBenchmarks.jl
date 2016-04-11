addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

@warmup BaseBenchmarks.SUITE
tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)
JLD.save("evals.jld", "SUITE", evals(BaseBenchmarks.SUITE))
