addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

# re-tune the entire suite
# @warmup BaseBenchmarks.SUITE
# tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)
# JLD.save("evals.jld", "SUITE", evals(BaseBenchmarks.SUITE))

# re-tune a specific group/benchmark
# result = tune!(BaseBenchmarks.SUITE[g][b]; seconds = 10)
# evalsgroup = JLD.load("evals.jld", "SUITE")
# evalsgroup[g][b] = evals(result)
# JLD.save("evals.jld", "SUITE", evalsgroup)
