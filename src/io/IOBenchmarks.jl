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

function perf_read!(io)
    seekstart(io)
    x = 0
    while !(eof(io))
        x += read(io, UInt8)
    end
    return x
end

g = addgroup!(SUITE, "read", ["buffer", "stream", "string"])

gettestbuf() = IOBuffer(samerandstring(10^4))

g["read"]       = @benchmarkable perf_read!(testbuf) setup=(testbuf=gettestbuf())
g["readstring"] = @benchmarkable read(testbuf, String) setup=(testbuf=gettestbuf())

#################################
# serialization (#18633, #7893) #
#################################

g = addgroup!(SUITE, "serialization", ["buffer", "string"])

function serialized_buf(x)
    io = IOBuffer()
    serialize(io, x)
    return io
end

const STR_RNG = StableRNGs.StableRNG(1)
getteststrings() = [randstring(STR_RNG, 32) for i=1:10^3]
getteststrings_buf() = serialized_buf(getteststrings())

g["serialize", "Vector{String}"] = @benchmarkable serialize(io, teststrings) setup=(io=IOBuffer(); teststrings=getteststrings())
g["deserialize", "Vector{String}"] = @benchmarkable (seek(teststrings_buf, 0); deserialize(teststrings_buf)) setup=(teststrings_buf=getteststrings_buf())

gettestdata() = samerand(1000,1000)
gettestdata_buf() = serialized_buf(gettestdata())

g["serialize", "Matrix{Float64}"] = @benchmarkable serialize(io, testdata) setup=(io=IOBuffer(); testdata=gettestdata())
g["deserialize", "Matrix{Float64}"] = @benchmarkable (seek(testdata_buf, 0); deserialize(testdata_buf)) setup=(testdata_buf=gettestdata_buf())

###################################
# limited array printing (#23681) #
###################################

g = addgroup!(SUITE, "array_limit", ["array", "display"])

gettest_vector() = samerand(10^8)
gettest_column_matrix(test_vector) = reshape(test_vector, length(test_vector), 1)
gettest_square_matrix(test_vector) = reshape(test_vector, 10^4, 10^4)
getdisp() = TextDisplay(IOContext(devnull, :limit=>true))

for getA in (identity, gettest_column_matrix, gettest_square_matrix)
    A = getA(gettest_vector())
    g["display", "$(typeof(A))$(size(A))"] = @benchmarkable display(disp, A) setup=(disp=getdisp(); A=$getA(gettest_vector()))
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
