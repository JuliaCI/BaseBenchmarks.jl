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

#################################
# serialization (#18633, #7893) #
#################################

g = addgroup!(SUITE, "serialization", ["buffer", "string"])

function serialized_buf(x)
    io = IOBuffer()
    serialize(io, x)
    return io
end

teststrings = [randstring(32) for i=1:10^3]
teststrings_buf = serialized_buf(teststrings)

g["serialize", "Vector{String}"] = @benchmarkable serialize(io, $teststrings) setup=(io=IOBuffer())
g["deserialize", "Vector{String}"] = @benchmarkable deserialize($teststrings_buf) setup=(seek($teststrings_buf, 0))

testdata = rand(1000,1000)
testdata_buf = serialized_buf(testdata)

g["serialize", "Matrix{Float64}"] = @benchmarkable serialize(io, $testdata) setup=(io=IOBuffer())
g["deserialize", "Matrix{Float64}"] = @benchmarkable deserialize($testdata_buf) setup=(seek($testdata_buf, 0))

end # module
