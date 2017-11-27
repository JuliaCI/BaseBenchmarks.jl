module NullableBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

########################
# array Union{T, Void} #
########################

g = addgroup!(SUITE, "array")

const VEC_LENGTH = 1000

_zero(::Type{T}) where {T} = zero(T)
_zero(::Type{Union{T, Void}}) where {T} = zero(T)

function perf_sum(X::AbstractArray{T}) where T
    s = _zero(T) + _zero(T)
    @inbounds @simd for x in X
        s += ifelse(x === nothing, _zero(T), x)
    end
    s
end

function perf_countnothing(X::AbstractArray)
    n = 0
    @inbounds for x in X
        n += x === nothing
    end
    n
end

function perf_countequals(X::AbstractArray, Y::AbstractArray)
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
    X = Vector{Union{T, Void}}(Vector{T}(samerand(S, VEC_LENGTH)))
    Y = Vector{Union{T, Void}}(Vector{T}(samerand(S, VEC_LENGTH)))
    X2 = Vector{Union{T, Void}}(Vector{T}(samerand(S, VEC_LENGTH)))
    Y2 = Vector{Union{T, Void}}(Vector{T}(samerand(S, VEC_LENGTH)))
    X2[samerand(VEC_LENGTH) .> .9] = nothing
    Y2[samerand(VEC_LENGTH) .> .9] = nothing    

    for A in (X, X2)
        g["perf_sum", string(typeof(A))] = @benchmarkable perf_sum($A)
        g["perf_countnothing", string(typeof(A))] = @benchmarkable perf_countnothing($A)
    end

    for (A, B) in ((X, Y), (X2, Y2), (X, Y2))
        g["perf_countequals", string(eltype(A), eltype(B))] =
            @benchmarkable perf_countequals($A, $B)
    end
end

end # module
