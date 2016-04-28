addprocs(1)

using BaseBenchmarks
using BenchmarkTools
using Base.Test

BaseBenchmarks.loadall!()

@test begin warmup(BaseBenchmarks.SUITE); true end
