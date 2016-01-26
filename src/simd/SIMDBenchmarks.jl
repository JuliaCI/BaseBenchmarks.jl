module SIMDBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..BaseBenchmarks: samerand

###########
# Methods #
###########

function perf_axpy!(a, X, Y)
    # LLVM's auto-vectorizer typically vectorizes this loop even without @simd
    @simd for i in eachindex(X)
        @inbounds Y[i] += a*X[i]
    end
    return Y
end

function perf_inner(X, Y)
    s = zero(eltype(X))
    @simd for i in eachindex(X)
        @inbounds s += X[i]*Y[i]
    end
    return s
end

function perf_sum_reduce(X)
    s = zero(eltype(X))
    i = div(length(X), 4)
    j = div(length(X), 2)
    @simd for k in i:j
        @inbounds s += X[k]
    end
    return s
end

function perf_manual_example!(X, Y, Z)
    s = zero(eltype(Z))
    n = min(length(X),length(Y),length(Z))
    @simd for i in 1:n
        @inbounds begin
            Z[i] = X[i]-Y[i]
            s += Z[i]*Z[i]
        end
    end
    return s
end

function perf_two_reductions(X, Y, Z)
    # Use non-zero initial value to make sure reduction values include it.
    (s,t) = (one(eltype(X)), one(eltype(Y)))
    @simd for i in 1:length(Z)
        @inbounds begin
            s += X[i]
            t += 2*Y[i]
            s += Z[i]   # Two reductions go into s
        end
    end
    return (s,t)
end

function perf_conditional_loop!(X, Y, Z)
    # SIMD loop with a long conditional expression
    @simd for i=1:length(X)
        @inbounds begin
            X[i] = Y[i] * (Z[i] > Y[i]) * (Z[i] < Y[i]) * (Z[i] >= Y[i]) * (Z[i] <= Y[i])
        end
    end
    return X
end

function perf_local_arrays(V)
    # SIMD loop on local arrays declared without type annotations
    T, n = eltype(V), length(V)
    X = samerand(T, n)
    Y = samerand(T, n)
    Z = samerand(T, n)
    @simd for i in eachindex(X)
        @inbounds X[i] = Y[i] * Z[i]
    end
    return X
end

immutable ImmutableFields{V<:AbstractVector}
    X::V
    Y::V
    Z::V
end

ImmutableFields{V}(X::V) = ImmutableFields{V}(X, X, X)

type MutableFields{V<:AbstractVector}
    X::V
    Y::V
    Z::V
end

MutableFields{V}(X::V) = ImmutableFields{V}(X, X, X)

function perf_loop_fields!(obj)
    # SIMD loop with field access
    @simd for i = 1:length(obj.X)
        @inbounds obj.X[i] = obj.Y[i] * obj.Z[i]
    end
    return obj
end

##############
# Benchmarks #
##############

@track BaseBenchmarks.TRACKER "simd" begin
    @setup begin
        lens = (9, 10, 255, 256, 999, 1000)
        int32_vecs = map(n -> samerand(Int32, n), lens)
        int64_vecs = map(n -> samerand(Int64, n), lens)
        float32_vecs = map(n -> samerand(Float32, n), lens)
        float64_vecs = map(n -> samerand(Float64, n), lens)
        vectors = (int32_vecs..., int64_vecs..., float32_vecs..., float64_vecs...)
    end
    @benchmarks begin
        [(:axpy!, string(eltype(v)), length(v)) => perf_axpy!(first(v), v, copy(v)) for v in vectors]
        [(:inner, string(eltype(v)), length(v)) => perf_inner(v, v) for v in vectors]
        [(:sum_reduce, string(eltype(v)), length(v)) => perf_sum_reduce(v) for v in vectors]
        [(:manual_example!, string(eltype(v)), length(v)) => perf_manual_example!(v, v, v) for v in vectors]
        [(:two_reductions, string(eltype(v)), length(v)) => perf_two_reductions(v, v, v) for v in vectors]
        [(:conditional_loop!, string(eltype(v)), length(v)) => perf_conditional_loop!(v, v, v) for v in vectors]
        [(:local_arrays, string(eltype(v)), length(v)) => perf_local_arrays(v) for v in vectors]
        [(:loop_fields!, T, string(eltype(v)), length(v)) => perf_loop_fields!(T(v)) for v in vectors, T in (MutableFields, ImmutableFields)]
    end
    @tags "array" "inbounds" "mul" "axpy!" "inner" "sum" "reduce"
end

end # module