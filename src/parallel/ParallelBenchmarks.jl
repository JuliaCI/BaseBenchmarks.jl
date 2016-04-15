module ParallelBenchmarks

include(joinpath(Pkg.dir("BaseBenchmarks"), "src", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

#################################################
# Echoing data between processes (Issue #14467) #
#################################################

if nprocs() > 1
    function otherid(id)
        workers = procs()
        return workers[findfirst(w -> w != id, workers)]
    end
    g = addgroup!(SUITE, "remotecall", ["io", "remotecall_fetch"])
    for s in (2, 64, 512, 1024, 4096)
        z = zeros(UInt8, s)
        i = otherid(myid())
        g["identity", s] = @benchmarkable remotecall_fetch(identity, $i, $z)
    end
end

##################
# Multithreading #
##################

# Threading is broken for now, so we don't have tuned parameters for this yet
# if VERSION >= v"0.5.0-dev+923" && Base.Threads.nthreads() > 1
#     include("Laplace3D.jl")
#     include("ThreadedStockCorr.jl")
#     include("LatticeBoltzmann.jl")
#     g = addgroup!(SUITE, "multithread", ["thread", "laplace", "laplacian"])
#     g["laplace3d"] = @benchmarkable Laplace3D.perf_laplace3d()
#     g["pstockcorr"] = @benchmarkable ThreadedStockCorr.perf_pstockcorr(10^4)
#     g["lattice_boltzmann"] = @benchmarkable LatticeBoltzmann.perf_lattice_boltzmann(36)
# end

end # module
