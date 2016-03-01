addprocs(1)

using BaseBenchmarks
using Base.Test

@test begin warmup(BaseBenchmarks.GROUPS; verbose = true); true end
