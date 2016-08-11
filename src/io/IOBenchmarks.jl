module IOBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup()

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

g = addgroup!(SUITE, "read", ["buffer", "stream", "string"])

testbuf = IOBuffer(randstring(10^4))

g["read"]       = @benchmarkable perf_read!($testbuf)
g["readstring"] = @benchmarkable readstring($testbuf)

end # module
