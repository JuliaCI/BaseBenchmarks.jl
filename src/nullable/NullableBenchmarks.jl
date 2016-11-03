module NullableBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

const SUITE = BenchmarkGroup()

####################
# basic operations #
####################

g = addgroup!(SUITE, "basic")

for T in (Bool, Int8, Int64, Float32, Float64, BigInt, BigFloat)
    tol = (T == BigInt || T == BigFloat) ? 0.6 : 0.3

    x = Nullable(one(T))
    g["get1", string(x)] = @benchmarkable get($x) time_tolerance=tol

    for x in (Nullable(one(T)), Nullable{T}())
        g["isnull", string(x)] = @benchmarkable isnull($x) time_tolerance=tol
        g["get2", string(x)] = @benchmarkable get($x, $(zero(T))) time_tolerance=tol

        for y in (Nullable(one(T)), Nullable(zero(T)), Nullable{T}()) time_tolerance=tol
            g["isequal", string(x), string(y)] = @benchmarkable isequal($x, $y) time_tolerance=tol
        end
    end
end

####################
# nullable array   #
####################

g = addgroup!(SUITE, "nullablearray")

immutable NullableArray{T, N} <: AbstractArray{Nullable{T}, N}
    values::Array{T, N}
    hasvalue::Array{Bool, N}
end

@inline function Base.getindex{T, N}(X::NullableArray{T, N}, I::Int...)
    if isbits(T)
        ifelse(X.hasvalue[I...], Nullable{T}(X.values[I...]), Nullable{T}())
    else
        if X.hasvalue[I...]
            Nullable{T}(X.values[I...])
        else
            Nullable{T}()
        end
    end
end

Base.size(X::NullableArray) = size(X.values)
Base.linearindexing{T<:NullableArray}(::Type{T}) = Base.LinearFast()

const VEC_LENGTH = 1000

function perf_sum{T<:Nullable}(X::AbstractArray{T})
    S = eltype(T)
    s = zero(S)+zero(S)
    @inbounds @simd for i in eachindex(X)
        s += get(X[i], zero(S))
    end
    s
end

function perf_countnulls{T<:Nullable}(X::AbstractArray{T})
    n = 0
    @inbounds for i in eachindex(X)
        n += isnull(X[i])
    end
    n
end

function perf_countequals{T<:Nullable}(X::AbstractArray{T}, Y::AbstractArray{T})
    n = 0
    @inbounds for i in eachindex(X, Y)
        n += isequal(X[i], Y[i])
    end
    n
end

for T in (Bool, Int8, Int64, Float32, Float64, BigInt, BigFloat, Complex{Float64})
    if T == BigInt
        S = Int128
    elseif T == BigFloat
        S = Float64
    else
        S = T
    end

    # 10% of missing values
    X = NullableArray(Array{T}(samerand(S, VEC_LENGTH)), Array(samerand(VEC_LENGTH) .> .9))
    Y = NullableArray(Array{T}(samerand(S, VEC_LENGTH)), Array(samerand(VEC_LENGTH) .> .9))

    for (A, X, Y) in (("NullableArray", X, Y), ("Array", collect(X), collect(Y)))
        g["perf_sum", A, string(T)] = @benchmarkable perf_sum($X)
        g["perf_countnulls", A, string(T)] = @benchmarkable perf_countnulls($X)
        g["perf_countequals", A, string(T)] = @benchmarkable perf_countequals($X, $Y)
    end
end

function perf_all(X::AbstractArray{Nullable{Bool}})
    @inbounds for i in eachindex(X)
        x = X[i]
        if isnull(x)
            return Nullable{Bool}()
        elseif !get(x)
            return Nullable(false)
        end
    end
    Nullable(true)
end

function perf_any(X::AbstractArray{Nullable{Bool}})
    allnull = true
    @inbounds for i in eachindex(X)
        x = X[i]
        if !isnull(x)
            allnull = false
            get(x) && return Nullable(true)
        end
    end
    allnull ? Nullable{Bool}() : Nullable(false)
end

# Ensure no short-circuit happens
X = NullableArray(fill(true, VEC_LENGTH), fill(true, VEC_LENGTH))
# 10% of missing values
Y = NullableArray(fill(false, VEC_LENGTH), Array(samerand(VEC_LENGTH) .> .1))

g["perf_all", "NullableArray"] = @benchmarkable perf_all($X)
g["perf_any", "NullableArray"] = @benchmarkable perf_any($Y)

g["perf_all", "Array"] = @benchmarkable perf_all($(collect(X)))
g["perf_any", "Array"] = @benchmarkable perf_any($(collect(Y)))

for b in values(g)
    b.params.time_tolerance = 0.50
end

end # module
