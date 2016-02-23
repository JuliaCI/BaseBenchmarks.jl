module ParallelBenchmarks

using ..BaseBenchmarks
using ..BenchmarkTools
using ..Compat

#################################################
# Echoing data between processes (Issue #14467) #
#################################################

if nprocs() > 1
    function otherid(id)
        workers = procs()
        return workers[findfirst(w -> w != id, workers)]
    end

    g = addgroup!(ENSEMBLE, "parallel io", ["parallel", "identity", "echo", "remotecall_fetch", "remotecall", "io"])
    for s in (2, 64, 512, 1024, 4096)
        g["identity", s] = @benchmarkable remotecall_fetch(identity, otherid(myid()), zeros(UInt8, $s))
    end
end

##################
# Multithreading #
##################

if VERSION >= v"0.5.0-dev+923" && Base.Threads.nthreads() > 1
    include("Laplace3D.jl")
    include("ThreadedStockCorr.jl")
    include("LatticeBoltzmann.jl")

    g = addgroup!(ENSEMBLE, "parallel multithread", ["parallel", "thread", "multithread", "laplace", "laplacian"])
    g["laplace3d"] = @benchmarkable Laplace3D.perf_laplace3d()
    g["pstockcorr"] = @benchmarkable ThreadedStockCorr.perf_pstockcorr(10^4)
    g["lattice_boltzmann"] = @benchmarkable LatticeBoltzmann.perf_lattice_boltzmann(36)
end

end # module
