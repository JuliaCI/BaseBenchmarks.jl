module TupleBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

###############
# issue #5274 #
###############

struct TupleWrapper{N, T}
    data::NTuple{N, T}
end

Base.eltype(::TupleWrapper{N,T}) where {N,T} = T
Base.length(::TupleWrapper{N,T}) where {N,T} = N

function get_index(n::NTuple, i::Int)
    @inbounds v = n[i]
    return v
end

function get_index(n::TupleWrapper, i::Int)
    @inbounds v = n.data[i]
    return v
end

function sum_tuple(n::Union{NTuple{N, T}, TupleWrapper{N, T}}) where {N, T}
    s = zero(T)
    for i in 1:N
        s += get_index(n, i)
    end
    return s
end

const TUPLE_SUM_SIZES = (3, 8, 30, 60)
const TUPLE_SUM_TYPES = (Float32, Float64)

g = addgroup!(SUITE, "index", ["sum"])

for s in TUPLE_SUM_SIZES, T in TUPLE_SUM_TYPES
    tup = tuple(samerand(T, s)...)
    tupwrap = TupleWrapper(tup)
    g["sumelt", "NTuple", s, T] = @benchmarkable sum_tuple($tup) time_tolerance=0.40
    g["sumelt", "TupleWrapper", s, T] = @benchmarkable sum_tuple($tupwrap) time_tolerance=0.40
end

#####################
# Fixed Size Arrays #
#####################

# Short fixed size array implementation

abstract type FixedArray{T, N} <: AbstractArray{T, N} end

Base.IndexStyle(::Type{<: FixedArray}) = IndexLinear()
Base.getindex(fsa::FixedArray, i::Int) = fsa.data[i]


struct FixedVector{L, T} <: FixedArray{T, 1}
    data::NTuple{L, T}
end

Base.size(::FixedVector{L}) where {L} = (L,)
Base.size(::Type{FixedVector{L, T}}) where {L, T} = (L,)
Base.length(::FixedVector{L}) where {L} = L


struct FixedMatrix{R, C, T, RC} <: FixedArray{T, 2}
    data::NTuple{RC, T}
end

Base.size(::FixedMatrix{R, C}) where {R, C} = (R, C)
Base.size(::Type{FixedMatrix{R, C, T, RC}}) where {R, C, T, RC} = (R, C)
Base.length(::FixedMatrix{R, C, T, RC}) where {R, C, T, RC} = RC


# Reductions

@inline function perf_reduce(op, a::FixedArray)
    if length(a) == 1
        return a[1]
    else
        s = op(a[1], a[2])
        for j = 3:length(a)
            s = op(s, a[j])
        end
        return s
    end
end

perf_minimum(a::FixedArray) = perf_reduce(min, a)


@inline function perf_reduce(op, v0, a::FixedArray)
    if length(a) == 0
        return v0
    else
        s = v0
        @inbounds @simd for j = 1:length(a)
            s = op(s, a[j])
        end
        return s
    end
end

perf_sum(v::FixedArray{T}) where {T} = perf_reduce(+, zero(T), v)


@inline function perf_mapreduce(f, op, v0, a1::FixedArray)
    if length(a1) == 0
        return v0
    else
        s = op(v0, f(a1[1]))
        for j = 2:length(a1)
            s = op(s, f(a1[j]))
        end
        return s
    end
end

perf_sumabs2(a::FixedArray{T}) where {T} = perf_mapreduce(abs2, +, zero(T), a)


# Linear Algebra

@generated function perf_matvec(A::FixedMatrix{R, C, T}, b::FixedVector{C, T}) where {R, C, T}
    sA = size(A)
    sB = size(b)
    exprs = Expr(:tuple, [reduce((ex1,ex2) -> :(+($ex1,$ex2)),
                [:(A[$(sub2ind(sA, k, j))]*b[$j]) for j = 1:sA[2]]) for k = 1:sA[1]]...)
    return quote
        @inbounds return FixedVector{R, T}($exprs)
    end
end

@generated function perf_matmat(A::FixedMatrix{R1, C, T}, B::FixedMatrix{C, R2, T}) where {R1, R2, C, T}
    sA = size(A)
    sB = size(B)
    exprs =  Expr(:tuple, [reduce((ex1,ex2) -> :(+($ex1,$ex2)),
                [:(A[$(sub2ind(sA, k1, j))] * B[$(sub2ind(sB, j, k2))]) for j = 1:sA[2]]) for k1 = 1:sA[1], k2 = 1:sB[2]]...)
    result_type = FixedMatrix{R1, R2, T, (R1 * R2)}
    return quote
        @inbounds return $result_type($exprs)
    end
end

# Benchmarks #
##############
v2, v4, v8, v16 = [FixedVector((rand(i)...)) for i in (2, 4, 8, 16)]
m2x2, m4x4, m8x8, m16x16 = [FixedMatrix{i,i, Float64, i*i}((rand(i*i)...)) for i in (2, 4, 8, 16)]


# Reductions
g = addgroup!(SUITE, "reduction", ["tuple"])

for mv in (v2, v4, v8, v16, m2x2, m4x4, m8x8, m16x16)
    g["sum", size(mv)] = @benchmarkable perf_sum($mv)
    g["sumabs", size(mv)] = @benchmarkable perf_sumabs2($mv)
    g["minimum", size(mv)] = @benchmarkable perf_minimum($mv)
end

# Linear algebra

g = addgroup!(SUITE, "linear algebra", ["tuple"])

for (m, v) in zip((m2x2, m4x4, m8x8, m16x16), (v2, v4, v8, v16 ))
    g["matvec", size(m), size(v)] = @benchmarkable perf_matvec($m, $v)
    g["matmat", size(m), size(m)] = @benchmarkable perf_matmat($m, $m)
end


end # module
