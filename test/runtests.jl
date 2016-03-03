addprocs(1)

using BaseBenchmarks
using Base.Test

@test begin execute(BaseBenchmarks.GROUPS, 1e-4, false; verbose = true); true end
