module UnionBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

const SUITE = BenchmarkGroup()

###########################
# array Union{T, Nothing} #
###########################

g = addgroup!(SUITE, "array")

const VEC_LENGTH = 10000

_zero(::Type{T}) where {T} = zero(T)
_zero(::Type{Union{T, Nothing}}) where {T} = zero(T)

_abs(x) = abs(x)
_abs(::Nothing) = nothing

_mul(x, y) = x * y
_mul(::Nothing, ::Any) = nothing
_mul(::Any, ::Nothing) = nothing
_mul(::Nothing, ::Nothing) = nothing

_isnothing(x) = false
_isnothing(::Nothing) = true

function perf_sum(X::AbstractArray{T}) where T
    s = _zero(T) + _zero(T)
    @inbounds @simd for x in X
        if x !== nothing
            s += x
        end
    end
    s
end

function perf_sum2(X::AbstractArray{T}) where T
    s = _zero(T) + _zero(T)
    @inbounds @simd for x in X
        if !_isnothing(x)
            s += x
        end
    end
    s
end

function perf_sum3(X::AbstractArray{T}) where T
    s = _zero(T) + _zero(T)
    @inbounds for x in X
        if !_isnothing(x)
            s += x
        end
    end
    s
end

function perf_sum4(X::AbstractArray{T}) where T
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

function perf_simplecopy(X::AbstractArray)
    ret = similar(X)
    @inbounds for i in eachindex(X)
        ret[i] = X[i]
    end
    ret
end

function perf_binaryop(op::Function, X::AbstractArray, Y::AbstractArray)
    ret = similar(X, Union{Nothing, typeof(op(_zero(eltype(X)), _zero(eltype(Y))))})
    @inbounds for i in eachindex(X, Y)
        ret[i] = op(X[i], Y[i])
    end
    ret
end

function perf_sumskipmissing(X::AbstractArray)
    sX = skipmissing(X)
    T = eltype(sX)
    s = _zero(T) + _zero(T)
    @inbounds for i in eachindex(sX)
        s += sX[i]
    end
    s
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
    X = Vector{Union{T, Nothing}}(Vector{T}(samerand(S, VEC_LENGTH)))
    Y = Vector{Union{T, Nothing}}(Vector{T}(samerand(S, VEC_LENGTH)))
    X2 = Vector{Union{T, Nothing}}(Vector{T}(samerand(S, VEC_LENGTH)))
    Y2 = Vector{Union{T, Nothing}}(Vector{T}(samerand(S, VEC_LENGTH)))
    X2[samerand(VEC_LENGTH) .> .9] .= nothing
    Y2[samerand(VEC_LENGTH) .> .9] .= nothing

    # The arrays with missing values (M = true) are reshuffled before every evaluation: branches
    # on `nothing`/`missing` follow their random positions. See `@benchmarkable_reshuffled`.
    for (M, A) in ((false, X), (true, X2))
        g["perf_sum", T, M] = @benchmarkable_reshuffled_if M A perf_sum($A)
        g["perf_sum2", T, M] = @benchmarkable_reshuffled_if M A perf_sum2($A)
        g["perf_sum3", T, M] = @benchmarkable_reshuffled_if M A perf_sum3($A)
        g["perf_sum4", T, M] = @benchmarkable_reshuffled_if M A perf_sum4($A)

        g["perf_countnothing", T, M] = @benchmarkable_reshuffled_if M A perf_countnothing($A)

        g["perf_simplecopy", T, M] =
            @benchmarkable_reshuffled_if M A perf_simplecopy($A)
        g["map", identity, T, M] =
            @benchmarkable_reshuffled_if M A map(identity, $A)
        g["broadcast", identity, T, M] =
            @benchmarkable_reshuffled_if M A broadcast(identity, $A)
        g["collect", "all", T, M] =
            @benchmarkable_reshuffled_if M A collect($(x for x in A))
        g["collect", "filter", T, M] =
            @benchmarkable_reshuffled_if M A collect($(x for x in A if x !== 1.0))

        g["map", abs, T, M] =
            @benchmarkable_reshuffled_if M A map(_abs, $A)
        g["broadcast", abs, T, M] =
            @benchmarkable_reshuffled_if M A broadcast(_abs, $A)
    end

    for (M, A, B) in (((false, false), X, Y),
                      ((true, true), X2, Y2),
                      ((false, true), X, Y2))
        g["perf_countequals", string(T)] =
            @benchmarkable_reshuffled_if any(M) (A, B) perf_countequals($A, $B)

        g["perf_binaryop", *, T, M] =
            @benchmarkable_reshuffled_if any(M) (A, B) perf_binaryop(_mul, $A, $B)
        g["map", *, T, M] =
            @benchmarkable_reshuffled_if any(M) (A, B) map(_mul, $A, $B)
        g["broadcast", *, T, M] =
            @benchmarkable_reshuffled_if any(M) (A, B) broadcast(_mul, $A, $B)
    end

    for (M, A) in ((false, Vector{T}(X)),
                   (false, X),
                   (true, replace(X2, nothing=>missing)))
        g["skipmissing", collect, eltype(A), M] =
            @benchmarkable_reshuffled_if M A collect(skipmissing($A))

        g["skipmissing", keys, eltype(A), M] =
            @benchmarkable_reshuffled_if M A collect(keys(skipmissing($A)))

        g["skipmissing", eachindex, eltype(A), M] =
            @benchmarkable_reshuffled_if M A collect(eachindex(skipmissing($A)))

        g["skipmissing", sum, eltype(A), M] =
            @benchmarkable_reshuffled_if M A sum(skipmissing($A))

        g["skipmissing", perf_sumskipmissing, eltype(A), M] =
            @benchmarkable_reshuffled_if M A perf_sumskipmissing($A)

        if hasmethod(isless, Tuple{T, T})
            # these branch on the values, so reshuffle all inputs
            g["skipmissing", filter, eltype(A), M] =
                @benchmarkable_reshuffled A filter(>(0.5), skipmissing($A))

            g["sort", eltype(A), M] = @benchmarkable_reshuffled A sort($A)
        end
    end
end

end # module
