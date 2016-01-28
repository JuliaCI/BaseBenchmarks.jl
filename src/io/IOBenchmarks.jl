module IOBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers

#################
# read (#12364) #
#################

function perf_read!(io)
    seekstart(io)
    x = 0
    while !(eof(io))
        x += read(io, UInt8)
    end
    return x
end

@track BaseBenchmarks.TRACKER "iobuffer read" begin
    @setup io = IOBuffer(randstring(10^4))
    @benchmarks begin
        (:read,) => perf_read!(io)
        (:readstring,) => BaseBenchmarks.readstring(io)
    end
    @tags "io" "buffer" "stream" "read" "string"
end

end # module