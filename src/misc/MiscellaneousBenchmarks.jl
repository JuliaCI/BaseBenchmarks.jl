module MiscellaneousBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat
using Compat.Dates

const SUITE = BenchmarkGroup()

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
    @assert length(k) >= 12
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

if !hasmethod(parse, Tuple{Type{DateTime}, AbstractString})
    Base.parse(::Type{DateTime}, s::AbstractString) = DateTime(s)
end

function perf_parse(result::AbstractVector{T}, strings::AbstractVector) where T
    @assert length(result) == length(strings)
    for i = 1:length(strings)
        @inbounds result[i] = parse(T, strings[i])
    end
    return result
end

g = addgroup!(SUITE, "parse", ["DateTime"])
if VERSION <= v"0.7.0-DEV.3986"
    datestr = map(string, range(DateTime("2016-02-19T12:34:56"),Dates.Millisecond(123),200))
else
    datestr = map(string, range(DateTime("2016-02-19T12:34:56"), step = Dates.Millisecond(123), length = 200))
end
g["DateTime"] = @benchmarkable perf_parse($(similar(datestr, DateTime)), $datestr)
g["Int"] = @benchmarkable perf_parse($(Vector{Int}(undef, 1000)), $(map(string, 1:1000)))
g["Float64"] = @benchmarkable perf_parse($(Vector{Float64}(undef, 1000)), $(map(string, 1:1000)))

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
include_string(@__MODULE__, nestedexpr_str)

if VERSION >= v"0.7.0-DEV.2437"
    const _parse = Meta.parse
else
    const _parse = Base.parse
end

g = addgroup!(SUITE, "julia")
g["parse", "array"] = @benchmarkable _parse($("[" * "a + b, "^100 * "]"))
g["parse", "nested"] = @benchmarkable _parse($(string(nestedexpr(100))))
g["parse", "function"] = @benchmarkable _parse($nestedexpr_str)
g["macroexpand", "evalpoly"] = @benchmarkable macroexpand(@__MODULE__, $(Expr(:macrocall, Symbol("@evalpoly"), 1:10...)))

###########################################################################

# Issue #12165

struct FloatingPointDatatype
    class::UInt8
    bitfield1::UInt8
    bitfield2::UInt8
    bitfield3::UInt8
    size::UInt32
    bitoffset::UInt16
    bitprecision::UInt16
    exponentlocation::UInt8
    exponentsize::UInt8
    mantissalocation::UInt8
    mantissasize::UInt8
    exponentbias::UInt32
end

h5type(::Type{Float16}) =
    FloatingPointDatatype(0x00, 0x20, 0x0f, 0x00, UInt32(2), 0x0000, UInt16(16), UInt8(10), 0x05, 0x00, UInt32(10), 0x0000000f)
h5type(::Type{Float32}) =
    FloatingPointDatatype(0x00, 0x20, 0x1f, 0x00, UInt32(4), 0x0000, UInt16(32), UInt8(23), 0x08, 0x00, UInt32(23), 0x0000007f)
h5type(::Type{Float64}) =
    FloatingPointDatatype(0x00, 0x20, 0x3f, 0x00, UInt32(8), 0x0000, UInt16(64), UInt8(52), 0x0b, 0x00, UInt32(52), 0x000003ff)

struct UnsupportedFeatureException <: Exception end

function jltype(dt::FloatingPointDatatype)
    if dt == h5type(Float64)
        return 64
    elseif dt == h5type(Float32)
        return 32
    elseif dt == h5type(Float16)
        return 16
    else
        throw(UnsupportedFeatureException())
    end
end

x_16 = fill(h5type(Float16), 1000000)
x_32 = fill(h5type(Float32), 1000000)
x_64 = fill(h5type(Float64), 1000000)

function perf_jltype(x)
    y = 0
    for i = 1:length(x)
        y += jltype(x[i])
    end
    y
end

g = addgroup!(SUITE, "issue 12165")
g["Float16"] = @benchmarkable perf_jltype($x_16)
g["Float32"] = @benchmarkable perf_jltype($x_32)
g["Float64"] = @benchmarkable perf_jltype($x_64)


#########################################################################
# issue #18129

function perf_cheapest_insertion_18129(distmat::Matrix{T}, initpath::Vector{Int}) where {T<:Real}
    check_square(distmat, "Distance matrix passed to cheapest_insertion must be square.")

    n = size(distmat, 1)
    path = copy(initpath)

    # collect cities to visited
    visitus = setdiff(collect(1:n), initpath)

    # helper for insertion cost
    # tour cost change for inserting node k after the node at index after in the path
    function inscost(k, after)
        return distmat[path[after], k] +
              distmat[k, path[after + 1]] -
              distmat[path[after], path[after + 1]]
    end

    counter = 0
    while !isempty(visitus)
        bestCost = Inf
        bestInsertion = (-1, -1)
        for k in visitus
            for after in 1:(length(path) - 1) # can't insert after end of path
                counter += 1
                c = inscost(k, after)
                if c < bestCost
                    bestCost = c
                    bestInsertion = (k, after)
                end
            end
        end
        # bestInsertion now holds (k, after)
        # insert into path, remove from to-do list
        k, after = bestInsertion
        insert!(path, after + 1, k)
        visitus = setdiff(visitus, k)
    end

    return (path, pathcost(distmat, path))
end

###
# helpers
###

# make sure a passed distance matrix is a square
function check_square(m, msg)
    if size(m, 1) != size(m, 2)
        error(msg)
    end
end

# helper for readable one-line path costs
# optionally specify the bounds for the subpath we want the cost of
# defaults to the whole path
# but when calculating reversed path costs can help to have subpath costs
function pathcost(distmat::Matrix{T}, path::Vector{Int}, lb::Int = 1, ub::Int = length(path)) where {T<:Real}
    cost = zero(T)
    for i in lb:(ub - 1)
        @inbounds cost += distmat[path[i], path[i+1]]
    end
    return cost
end

dm = samerand(Float64, 300, 300)
SUITE["18129"] = @benchmarkable perf_cheapest_insertion_18129($dm, $([1, 1]))


###############################################################################
# issue #20517

function perf_dsum_20517(A::Matrix)
    z = zero(A[1,1])
    n = size(A,1)
    B = Vector{typeof(z)}(undef, n)

    @inbounds for j in 1:n
        @static if VERSION < v"0.7.0-beta.81"
            B[j] = mapreduce(k -> A[j,k]*A[k,j], +, z, 1:j)
        else
            B[j] = mapreduce(k -> A[j,k]*A[k,j], +, 1:j; init=z)
        end
    end
    B
end

A = samerand(127,127)
SUITE["20517"] = @benchmarkable perf_dsum_20517($A)


###############################################
# issue # 23042

struct Foo_23042{T<:Number, A<:AbstractMatrix{T}}
    data::A
end

Foo_23042(data::AbstractMatrix) = Foo_23042{eltype(data), typeof(data)}(data)


function perf_copy_23042(a, b)
    for i in 1:length(a.data)
        @inbounds a.data[i] = b.data[i]
    end
    a
end

g = addgroup!(SUITE, "23042")

for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
    b = samerand(T, 128, 128)
    a = similar(b)
    g[string(T)] = @benchmarkable perf_copy_23042($(Foo_23042(a)), $(Foo_23042(b)))
end

###############################################
# iterators

g = addgroup!(SUITE, "iterators", ["zip", "flatten"])

# zip
for N in (1,1000), M in 1:4
    X = zip(Iterators.repeated(1:N, M)...)
    g["zip($(join(fill("1:$N", M), ", ")))"] = @benchmarkable collect($X)
end

# flatten
let X = Base.Iterators.flatten(fill(rand(50), 100))
    g["sum(flatten(fill(rand(50), 100))))"] = @benchmarkable sum($X)
end
let X = Base.Iterators.flatten(collect((i,i+1) for i in 1:1000))
    g["sum(flatten(collect((i,i+1) for i in 1:1000))"] = @benchmarkable sum($X)
end

####################################################
# Allocation elision stumped by conditional #28226 #
# Note, not fixed when this benchmark was written  #
####################################################

function perf_colwise_alloc!(r, a, b)
    @inbounds for j = 1:size(a,2)
        r[j] = evaluate_cond(view(a, :, j), view(b, :, j))
    end
    r
end

@inline function evaluate_cond(a, b)
    length(a) == 0 && return 0.0 # comment out and 0.7 is super fast
    @inbounds begin
        s = 0.0
        @simd for I in eachindex(a, b)
            ai = a[I]
            bi = b[I]
            s += abs2(ai - bi)
        end
        return s
    end
end

function perf_colwise_noalloc!(r, a, b)
    @inbounds for j = 1:size(a,2)
        r[j] = evaluate_nocond(view(a, :, j), view(b, :, j))
    end
    r
end

@inline function evaluate_nocond(a, b)
    @inbounds begin
        s = 0.0
        @simd for I in eachindex(a, b)
            ai = a[I]
            bi = b[I]
            s += abs2(ai - bi)
        end
        return s
    end
end

z = zeros(41); A = rand(2, 41); B = rand(2, 41);
g = addgroup!(SUITE, "allocation elision view")
g["conditional"] = @benchmarkable perf_colwise_alloc!($z, $A, $B)
g["no conditional"] = @benchmarkable perf_colwise_noalloc!($z, $A, $B)


####################################################
# Fastmath infererence large number of args #22275 #
####################################################

function f2(a,b,c,d,e,f,g,h,j,k,l,m,n,o,p)
    aidx = eachindex(a)
    @fastmath for i in aidx
        @inbounds a[i] = b[i]+c*(d*e[i]+f*g[i]+h*j[i]+k*l[i]+m*n[i]+o*p[i])
    end
end
a = rand(10)
b = rand(10)
c = 0.1
d = 0.1
e = rand(10)
f = 0.1
g = rand(10)
h = 0.1
j = rand(10)
k = 0.1
l = rand(10)
m = 0.1
n = rand(10)
o = 0.1
p = rand(10)

SUITE["fastmath many args"] = @benchmarkable f2($a,$b,$c,$d,$e,$f,$g,$h,$j,$k,$l,$m,$n,$o,$p)

##############################################################
# Performance and typing of 6+ dimensional generators #21058 #
##############################################################
perf_g6() = sum([+(a,b,c,d,e,f) for a in 1:4, b in 1:4, c in 1:4, d in 1:4, e in 1:4, f in 1:4])

SUITE["perf highdim generator"] = @benchmarkable perf_g6()

end
