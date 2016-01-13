module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

include("arrays/ArrayBenchmarks.jl")
include("blas/BLASBenchmarks.jl")
include("lapack/LAPACKBenchmarks.jl")
include("problem/ProblemBenchmarks.jl")
include("parallel/ParallelBenchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

export ArrayBenchmarks,
       BLASBenchmarks,
       LAPACKBenchmarks,
       ProblemBenchmarks,
       ParallelBenchmarks

export @tagged # reexported from BenchmarkTrackers

end # module
