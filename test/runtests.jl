addprocs(1)

using BaseBenchmarks
using BenchmarkTools
using Base.Test

@test begin @warmup BaseBenchmarks.SUITE end
