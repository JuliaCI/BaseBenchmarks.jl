module IOBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Random
using Serialization

const SUITE = BenchmarkGroup()

#################
# read (#12364) #
#################

function perf_read!(io, ::Type{T}) where T<:Number
    seekstart(io)
    x = zero(T)
    while !(eof(io))
        x += read(io, T)
    end
    return x
end

function perf_read!(io, ::Type{String})
    seekstart(io)
    read(io, String)
end

g = addgroup!(SUITE, "read", ["buffer", "stream", "string"])

testbuf = IOBuffer(randstring(RandUtils.SEED, 10^4))
g["read"] = @benchmarkable perf_read!($testbuf, UInt8)
g["readfloat64"] = @benchmarkable perf_read!($testbuf, Float64)
g["readstring"] = @benchmarkable perf_read!($testbuf, String)

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

###################################
# limited array printing (#23681) #
###################################

g = addgroup!(SUITE, "array_limit", ["array", "display"])

test_vector = rand(10^8)
test_column_matrix = reshape(test_vector, length(test_vector), 1)
test_square_matrix = reshape(test_vector, 10^4, 10^4)
disp = TextDisplay(IOContext(devnull, :limit=>true))

for A in (test_vector, test_column_matrix, test_square_matrix)
    g["display", "$(typeof(A))$(size(A))"] = @benchmarkable display($disp, $A)
end

###################################

function perf_skipchars_21109()
    mktemp() do _, file
        println(file, "G")
        flush(file)
        seek(file, 0)
        skipchars(islowercase, file)

        for i in 1:1000000
            skipchars(islowercase, file)
        end
    end
end

SUITE["skipchars"] = @benchmarkable perf_skipchars_21109()

end # module
