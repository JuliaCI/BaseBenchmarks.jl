module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

samerand(args...) = rand(MersenneTwister(1), args...)

include("arrays/ArrayBenchmarks.jl")
include("blas/BLASBenchmarks.jl")
include("lapack/LAPACKBenchmarks.jl")
include("parallel/ParallelBenchmarks.jl")
include("problem/ProblemBenchmarks.jl")
include("sort/SortBenchmarks.jl")

execute(istagged) = run(TRACKER, istagged)

export ArrayBenchmarks,
       BLASBenchmarks,
       LAPACKBenchmarks,
       ProblemBenchmarks,
       ParallelBenchmarks,
       SortBenchmarks

export @tagged # reexported from BenchmarkTrackers

end # module
