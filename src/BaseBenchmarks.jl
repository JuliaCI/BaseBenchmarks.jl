module BaseBenchmarks

info("loading BaseBenchmarks.jl (this could take a few seconds)...")

using BenchmarkTools
using Compat

const GROUPS = BenchmarkTools.GroupCollection()

include("utils/RandUtils.jl")
include("array/ArrayBenchmarks.jl")
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
include("tuple/TupleBenchmarks.jl")

end # module

using BenchmarkTools # re-export BenchmarkTools
