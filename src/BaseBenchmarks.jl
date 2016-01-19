module BaseBenchmarks

using BenchmarkTrackers

@tracker TRACKER

samerand(args...) = rand(MersenneTwister(1), args...)

include("arrays/ArrayBenchmarks.jl")
include("blas/BLASBenchmarks.jl")
include("lapack/LAPACKBenchmarks.jl")
include("micro/MicroBenchmarks.jl")
include("parallel/ParallelBenchmarks.jl")
include("problem/ProblemBenchmarks.jl")
include("simd/SIMDBenchmarks.jl")
include("shootout/ShootoutBenchmarks.jl")
include("sort/SortBenchmarks.jl")
include("sparse/SparseBenchmarks.jl")

macro execute(tagpred)
    return esc(quote
        run(BaseBenchmarks.TRACKER, BaseBenchmarks.BenchmarkTrackers.@tagged $tagpred)
    end)
end

end # module
