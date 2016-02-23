addprocs(1)

using BaseBenchmarks
using Base.Test

@test begin execute(ENSEMBLE, 1e-6; verbose = true); true end
