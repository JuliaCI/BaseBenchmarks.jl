module BaseBenchmarks

info("loading BaseBenchmarks.jl (this could take a few seconds)...")

using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

print("\tloading RandUtils.jl..."); tic();
include("utils/RandUtils.jl")
println("done (took $(toq()) seconds)")

print("\tloading ArrayBenchmarks.jl..."); tic();
include("array/ArrayBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading IOBenchmarks.jl..."); tic();
include("io/IOBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading LinAlgBenchmarks.jl..."); tic();
include("linalg/LinAlgBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading MicroBenchmarks.jl..."); tic();
include("micro/MicroBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading ParallelBenchmarks.jl..."); tic();
include("parallel/ParallelBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading ProblemBenchmarks.jl..."); tic();
include("problem/ProblemBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading ScalarBenchmarks.jl..."); tic();
include("scalar/ScalarBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading ShootoutBenchmarks.jl..."); tic();
include("shootout/ShootoutBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading SIMDBenchmarks.jl..."); tic();
include("simd/SIMDBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading SortBenchmarks.jl..."); tic();
include("sort/SortBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading SparseBenchmarks.jl..."); tic();
include("sparse/SparseBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading StringBenchmarks.jl..."); tic();
include("string/StringBenchmarks.jl")
println("done (took $(toq()) seconds)")

print("\tloading TupleBenchmarks.jl..."); tic();
include("tuple/TupleBenchmarks.jl")
println("done (took $(toq()) seconds)")

end # module
