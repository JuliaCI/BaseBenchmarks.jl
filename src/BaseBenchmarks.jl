module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

include("arrays/benchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

end # module
