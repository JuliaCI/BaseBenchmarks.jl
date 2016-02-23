module BaseBenchmarks

using BenchmarkTools
using Compat

# This is a temporary patch until JuliaLang/Compat.jl#162 is merged.
if VERSION < v"0.5.0-dev+2228"
    const readstring = readall
    export readstring
end

const ENSEMBLE = BenchmarkEnsemble()
export ENSEMBLE

include("utils/RandUtils.jl")
include("arrays/ArrayBenchmarks.jl")
include("io/IOBenchmarks.jl")
include("linalg/LinAlgBenchmarks.jl")
include("micro/MicroBenchmarks.jl")
include("parallel/ParallelBenchmarks.jl")
include("problem/ProblemBenchmarks.jl")
include("scalar/ScalarBenchmarks.jl")
include("shootout/ShootoutBenchmarks.jl")
include("simd/SIMDBenchmarks.jl")
include("sort/SortBenchmarks.jl")
include("sparse/SparseBenchmarks.jl")
include("string/StringBenchmarks.jl")

end # module

using BenchmarkTools # re-export BenchmarkTools
