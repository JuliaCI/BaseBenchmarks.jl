module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

include("array/benchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

export execute

end # module
