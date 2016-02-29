module BaseBenchmarks

using BenchmarkTrackers
using Compat

# This is a temporary patch until JuliaLang/Compat.jl#162 is merged.
if VERSION < v"0.5.0-dev+2228"
    const readstring = readall
end

@tracker TRACKER

include("utils/RandUtils.jl")
include("arrays/ArrayBenchmarks.jl")
include("io/IOBenchmarks.jl")
include("linalg/LinAlgBenchmarks.jl")
include("micro/MicroBenchmarks.jl")
include("parallel/ParallelBenchmarks.jl")
include("problem/ProblemBenchmarks.jl")
include("scalar/ScalarBenchmarks.jl")
include("simd/SIMDBenchmarks.jl")
include("shootout/ShootoutBenchmarks.jl")
include("sort/SortBenchmarks.jl")
include("sparse/SparseBenchmarks.jl")
include("string/StringBenchmarks.jl")
include("tuples/TupleBenchmarks.jl")

macro execute(tagpred)
    return esc(quote
        run(BaseBenchmarks.TRACKER, BaseBenchmarks.BenchmarkTrackers.@tagged($tagpred); verbose = true)
    end)
end

end # module
