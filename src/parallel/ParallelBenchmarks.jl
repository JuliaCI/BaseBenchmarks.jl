module ParallelBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

#################################################
# Echoing data between processes (Issue #14467) #
#################################################

@track BaseBenchmarks.TRACKER begin
    @setup begin
        pid = first(addprocs(1))
        sizes = (2, 64, 512, 1024, 4096)
    end
    @benchmarks "parallel" begin
        [(:identity, n) => remotecall_fetch(identity, pid, zeros(UInt8, n)) for n in sizes]
    end
    @teardown rmprocs(pid)
    @tags "parallel" "identity" "echo" "remotecall_fetch" "remotecall" "io"
end

end # module
