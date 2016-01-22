module ParallelBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

#################################################
# Echoing data between processes (Issue #14467) #
#################################################

@track BaseBenchmarks.TRACKER "parallel io" begin
    @setup begin
        pid = first(addprocs(1))
        sizes = (2, 64, 512, 1024, 4096)
    end
    @benchmarks begin
        [(:identity, n) => remotecall_fetch(identity, pid, zeros(UInt8, n)) for n in sizes]
    end
    @teardown rmprocs(pid)
    @tags "parallel" "identity" "echo" "remotecall_fetch" "remotecall" "io"
end

##################
# Multithreading #
##################

include("Laplace3D.jl")
include("ThreadedStockCorr.jl")
include("LatticeBoltzmann.jl")

@track BaseBenchmarks.TRACKER "parallel multithread" begin
    @benchmarks begin
        (:laplace3d,) => Laplace3D.perf_laplace3d()
        (:pstockcorr,) => ThreadedStockCorr.perf_pstockcorr(10^4)
        (:lattice_boltzmann,) => LatticeBoltzmann.perf_lattice_boltzmann(36)
    end
    @tags "parallel" "thread" "multithread" "laplace" "laplacian"
end


end # module
