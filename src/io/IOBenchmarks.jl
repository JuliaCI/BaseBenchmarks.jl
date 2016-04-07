module IOBenchmarks

using ..BaseBenchmarks: SUITE
using BenchmarkTools
using Compat

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

g = newgroup!(SUITE, "iobuffer read", ["io", "buffer", "stream", "read", "string"])

testbuf = IOBuffer(randstring(10^4))

g["read"] = @benchmarkable perf_read!($testbuf)
g["readstring"] = @benchmarkable readstring($testbuf)

end # module
