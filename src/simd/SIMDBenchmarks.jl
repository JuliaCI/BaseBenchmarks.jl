module SIMDBenchmarks

include(joinpath(Pkg.dir("BaseBenchmarks"), "src", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup(["array", "inbounds"])

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
    s = one(eltype(X))
    t = one(eltype(Y))
    @simd for i in 1:length(Z)
        @inbounds begin
            s += X[i]
            t += 2*Y[i]
            s += Z[i]   # Two reductions go into s
        end
    end
    return s*t
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

for s in (4095, 4096), T in (Int32, Int64, Float32, Float64)
    tstr = string(T)
    v = samerand(T, s)
    n = samerand(T)
    SUITE["axpy!", tstr, s] = @benchmarkable perf_axpy!($n, $v, $v)
    SUITE["inner", tstr, s] = @benchmarkable perf_inner($v, $v)
    SUITE["sum_reduce", tstr, s] = @benchmarkable perf_sum_reduce($v)
    SUITE["manual_example!", tstr, s] = @benchmarkable perf_manual_example!($v, $v, $v)
    SUITE["two_reductions", tstr, s] = @benchmarkable perf_two_reductions($v, $v, $v)
    SUITE["conditional_loop!", tstr, s] = @benchmarkable perf_conditional_loop!($v, $v, $v)
    SUITE["local_arrays", tstr, s] = @benchmarkable perf_local_arrays($v)
    for F in (MutableFields, ImmutableFields)
        SUITE["loop_fields!", tstr, string(F), s] = @benchmarkable perf_loop_fields!($(F)($v))
    end
end

for b in values(SUITE)
    b.params.time_tolerance = 0.20
end

end # module
