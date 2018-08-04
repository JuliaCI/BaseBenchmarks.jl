module IOBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

if VERSION >= v"0.7.0-DEV.3406"
    using Random
end
if VERSION >= v"0.7.0-DEV.3476"
    using Serialization
end

const SUITE = BenchmarkGroup()

#################
# read (#12364) #
#################

function perf_read!(io, ::Type{T}) where T
    seekstart(io)
    x = zero(T)
    while !(eof(io))
        x += read(io, T)
    end
    return x
end

g = addgroup!(SUITE, "read", ["buffer", "stream", "string"])

g["read"] = @benchmarkable perf_read!(testbuf, UInt8) setup = testbuf = IOBuffer(randstring(RandUtils.SEED, 10^4))
g["readfloat64"] = @benchmarkable perf_read!(testbuf, Float64) setup = testbuf = IOBuffer(randstring(RandUtils.SEED, 10^4))
g["readstring"] = @benchmarkable read(testbuf, String) setup = testbuf = IOBuffer(randstring(RandUtils.SEED, 10^4))

#################################
# serialization (#18633, #7893) #
#################################

g = addgroup!(SUITE, "serialization", ["buffer", "string"])

function serialized_buf(x)
    io = IOBuffer()
    serialize(io, x)
    return io
end

teststrings = [randstring(RandUtils.SEED, 32) for i=1:10^3]
teststrings_buf = serialized_buf(teststrings)

g["serialize", "Vector{String}"] = @benchmarkable serialize(io, $teststrings) setup=(io=IOBuffer())
g["deserialize", "Vector{String}"] = @benchmarkable (seek($teststrings_buf, 0); deserialize($teststrings_buf))

testdata = rand(RandUtils.SEED,1000,1000)
testdata_buf = serialized_buf(testdata)

g["serialize", "Matrix{Float64}"] = @benchmarkable serialize(io, $testdata) setup=(io=IOBuffer())
g["deserialize", "Matrix{Float64}"] = @benchmarkable (seek($testdata_buf, 0); deserialize($testdata_buf))

end # module
