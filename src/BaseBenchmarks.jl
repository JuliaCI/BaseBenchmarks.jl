module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

include("arrays/ArrayBenchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

end # module
