module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

include("arrays/ArrayBenchmarks.jl")
include("blas/BLASBenchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

end # module
