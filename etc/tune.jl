addprocs(1)

using JLD
using BaseBenchmarks
using BenchmarkTools

BaseBenchmarks.loadall!(tune = false)
jldpath = joinpath(Pkg.dir("BaseBenchmarks"), "etc", "evals.jld")

# re-tune the entire suite
@warmup BaseBenchmarks.SUITE
tune!(BaseBenchmarks.SUITE; seconds = 10, verbose = true)
JLD.save(jldpath, "suite", evals(BaseBenchmarks.SUITE))
