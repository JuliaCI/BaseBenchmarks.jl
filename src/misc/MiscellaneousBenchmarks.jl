module MiscellaneousBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

###########################################################################
# isbits Union optimizations for type fields & array elements (issue #22441)

g = addgroup!(SUITE, "isbitsunions", ["indexing", "simd", "union"])

mutable struct UnionField
    u::Union{Int64, Void}
end

function getsetfield(A)
    for i = 1:length(A)-1
        A[i].u = A[i + 1].u
    end
end

function makeUnionFieldArray(N)
    A = [UnionField(i) for i in rand(Int64, N)]
    for i in rand(1:N, div(N, 4))
        A[i].u = nothing
    end
    return A
end

g["getsetfield"] = @benchmarkable getsetfield($(makeUnionFieldArray(10000)))

function getsetindex(A)
    for i = 1:length(A)-1
        # v = A[i + 1]
        # if v isa Void
        #     A[i] = v
        # else
        #     A[i] = v
        # end
        A[i] = A[i + 1]
    end
end

function makeIsBitsUnionArray(N)
    A = Union{Int64, Void}[i for i in rand(Int64, N)]
    for i in rand(1:N, div(N, 4))
        A[i] = nothing
    end
    return A
end

g["getsetindex"] = @benchmarkable getsetindex($(makeIsBitsUnionArray(10000)))

###########################################################################
# Splatting penalties (issue #13359)

g = addgroup!(SUITE, "splatting", ["array", "getindex"])

@noinline function perf_splatting_(A, xs...)
    A[xs...]
end
function perf_splatting(A, n, xs...)
    s = zero(eltype(A))
    for i = 1:n
        s += perf_splatting_(A, xs...)
    end
    return s
end

g[(3,3,3)] = @benchmarkable perf_splatting($(samerand(3,3,3)), 100, 1, 2, 3)

###########################################################################
# crossover from x + y + ... to afoldl (issue #13724)

function perf_afoldl(n, k)
    s = zero(eltype(k))
    assert(length(k) >= 12)
    for i = 1:n
        s += k[1] + k[2] + k[3] + k[4] + k[5] + 2 * k[6] + k[7] + k[8] + k[9] + k[10] + k[11] + k[12]
    end
    return s
end

g = addgroup!(SUITE, "afoldl", ["+", "getindex"])
g["Int"] = @benchmarkable perf_afoldl(100, $(zeros(Int, 20)))
g["Float64"] = @benchmarkable perf_afoldl(100, $(zeros(Float64, 20)))
g["Complex{Float64}"] = @benchmarkable perf_afoldl(100, $(zeros(Complex{Float64}, 20)))

###########################################################################
# repeat function (issue #15553)

g = addgroup!(SUITE, "repeat", ["array"])
g[200, 24, 1] = @benchmarkable repeat($(collect(1:200)), inner=$[24], outer=$[1])
g[200, 1, 24] = @benchmarkable repeat($(collect(1:200)), inner=$[1], outer=$[24])

###########################################################################
# bitshift operators (from #18135)

function perf_bitshift(r, n)
    s = zero(eltype(r))
    for i in r
        s += i<<n
    end
    return s
end

g = addgroup!(SUITE, "bitshift", ["range"])
g["Int", "Int"] = @benchmarkable perf_bitshift($(1:1000), Int(3))
g["Int", "UInt"] = @benchmarkable perf_bitshift($(1:1000), UInt(3))
g["UInt", "UInt"] = @benchmarkable perf_bitshift($(UInt(1):UInt(1000)), UInt(3))
g["UInt32", "UInt32"] = @benchmarkable perf_bitshift($(UInt32(1):UInt32(1000)), UInt32(3))

###########################################################################
# Integer, Float64, and Date (#18000) parsing

if !method_exists(parse, Tuple{Type{DateTime}, AbstractString})
    Base.parse(::Type{DateTime}, s::AbstractString) = DateTime(s)
end

function perf_parse{T}(result::AbstractVector{T}, strings::AbstractVector)
    assert(length(result) == length(strings))
    for i = 1:length(strings)
        @inbounds result[i] = parse(T, strings[i])
    end
    return result
end

g = addgroup!(SUITE, "parse", ["DateTime"])
datestr = map(string,range(DateTime("2016-02-19T12:34:56"),Dates.Millisecond(123),200))
g["DateTime"] = @benchmarkable perf_parse($(similar(datestr, DateTime)), $datestr)
g["Int"] = @benchmarkable perf_parse($(Vector{Int}(1000)), $(map(string, 1:1000)))
g["Float64"] = @benchmarkable perf_parse($(Vector{Float64}(1000)), $(map(string, 1:1000)))

###########################################################################
# Julia language components (parser, etc.)

# horner-like nested expression with n levels: 1*(x + 2*(x + 2*(x + 3* ...
# ... written as a string so that we can also benchmark parsing of this function.
nestedexpr_str = """
function nestedexpr(n)
    ex = :x
    for i = n:-1:1
        ex = :(\$i * (x + \$ex))
    end
    return ex
end"""
include_string(nestedexpr_str)

g = addgroup!(SUITE, "julia")
g["parse", "array"] = @benchmarkable parse($("[" * "a + b, "^100 * "]"))
g["parse", "nested"] = @benchmarkable parse($(string(nestedexpr(100))))
g["parse", "function"] = @benchmarkable parse($nestedexpr_str)
g["macroexpand", "evalpoly"] = @benchmarkable macroexpand($(Expr(:macrocall, Symbol("@evalpoly"), 1:10...)))

###########################################################################

end
