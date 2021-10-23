module SIMDBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools

const SUITE = BenchmarkGroup(["array", "inbounds"])

###########
# Methods #
###########

function perf_axpy!(a, X, Y, f = identity)
    # LLVM's auto-vectorizer typically vectorizes this loop even without @simd
    @inbounds @simd for i in f(eachindex(X))
        Y[i] += a*X[i]
    end
    return Y
end

function perf_inner(X, Y, f = identity)
    s = zero(eltype(X))
    @inbounds @simd for i in f(eachindex(X))
        s += X[i]*Y[i]
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

function perf_manual_example!(X, Y, Z, f = identity)
    s = zero(eltype(Z))
    @inbounds @simd for i in f(eachindex(X, Y, Z))
        Z[i] = X[i]-Y[i]
        s += Z[i]*Z[i]
    end
    return s
end

function perf_two_reductions(X, Y, Z, f = identity)
    # Use non-zero initial value to make sure reduction values include it.
    s = one(eltype(X))
    t = one(eltype(Y))
    @inbounds @simd for i in f(eachindex(X, Y, Z))
        s += X[i]
        t += 2*Y[i]
        s += Z[i]   # Two reductions go into s
    end
    return s*t
end

function perf_conditional_loop!(X, Y, Z, f = identity)
    # SIMD loop with a long conditional expression
    @inbounds @simd for i = f(eachindex(X, Y, Z))
        X[i] = Y[i] * (Z[i] > Y[i]) * (Z[i] < Y[i]) * (Z[i] >= Y[i]) * (Z[i] <= Y[i])
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

### And the same methods, but without the explicit @simd annotation
function perf_auto_axpy!(a, X, Y)
    for i in eachindex(X)
        @inbounds Y[i] += a*X[i]
    end
    return Y
end

function perf_auto_inner(X, Y)
    s = zero(eltype(X))
    for i in eachindex(X)
        @inbounds s += X[i]*Y[i]
    end
    return s
end

function perf_auto_sum_reduce(X)
    s = zero(eltype(X))
    i = div(length(X), 4)
    j = div(length(X), 2)
    for k in i:j
        @inbounds s += X[k]
    end
    return s
end

function perf_auto_manual_example!(X, Y, Z)
    s = zero(eltype(Z))
    n = min(length(X),length(Y),length(Z))
    for i in 1:n
        @inbounds begin
            Z[i] = X[i]-Y[i]
            s += Z[i]*Z[i]
        end
    end
    return s
end

function perf_auto_two_reductions(X, Y, Z)
    # Use non-zero initial value to make sure reduction values include it.
    s = one(eltype(X))
    t = one(eltype(Y))
    for i in 1:length(Z)
        @inbounds begin
            s += X[i]
            t += 2*Y[i]
            s += Z[i]   # Two reductions go into s
        end
    end
    return s*t
end

function perf_auto_conditional_loop!(X, Y, Z)
    # SIMD loop with a long conditional expression
    for i=1:length(X)
        @inbounds begin
            X[i] = Y[i] * (Z[i] > Y[i]) * (Z[i] < Y[i]) * (Z[i] >= Y[i]) * (Z[i] <= Y[i])
        end
    end
    return X
end

function perf_auto_local_arrays(V)
    # SIMD loop on local arrays declared without type annotations
    T, n = eltype(V), length(V)
    X = samerand(T, n)
    Y = samerand(T, n)
    Z = samerand(T, n)
    for i in eachindex(X)
        @inbounds X[i] = Y[i] * Z[i]
    end
    return X
end


struct ImmutableFields{V<:AbstractVector}
    X::V
    Y::V
    Z::V
end

ImmutableFields(X::V) where {V} = ImmutableFields{V}(X, X, X)

mutable struct MutableFields{V<:AbstractVector}
    X::V
    Y::V
    Z::V
end

MutableFields(X::V) where {V} = ImmutableFields{V}(X, X, X)

function perf_loop_fields!(obj)
    # SIMD loop with field access
    @simd for i = 1:length(obj.X)
        @inbounds obj.X[i] = obj.Y[i] * obj.Z[i]
    end
    return obj
end

function perf_auto_loop_fields!(obj)
    for i = 1:length(obj.X)
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
    x = samerand(T, s)
    y = samerand(T, s)
    n = samerand(T)
    # LLVM sometimes dynamically switches to a scalar loop if the inputs alias; so test it both ways when applicable
    SUITE["Linear", "axpy!", tstr, s] = @benchmarkable perf_axpy!($n, $v, $x)
    SUITE["Linear", "inner", tstr, s] = @benchmarkable perf_inner($v, $x)
    SUITE["Linear", "sum_reduce", tstr, s] = @benchmarkable perf_sum_reduce($v)
    SUITE["Linear", "manual_example!", tstr, s] = @benchmarkable perf_manual_example!($v, $x, $y)
    SUITE["Linear", "two_reductions", tstr, s] = @benchmarkable perf_two_reductions($v, $x, $y)
    SUITE["Linear", "conditional_loop!", tstr, s] = @benchmarkable perf_conditional_loop!($v, $x, $y)
    SUITE["Linear", "local_arrays", tstr, s] = @benchmarkable perf_local_arrays($v)

    SUITE["Linear", "axpy!_aliased", tstr, s] = @benchmarkable perf_axpy!($n, $v, $v)
    SUITE["Linear", "inner_aliased", tstr, s] = @benchmarkable perf_inner($v, $v)
    SUITE["Linear", "manual_example!_aliased", tstr, s] = @benchmarkable perf_manual_example!($v, $v, $v)
    SUITE["Linear", "two_reductions_aliased", tstr, s] = @benchmarkable perf_two_reductions($v, $v, $v)
    SUITE["Linear", "conditional_loop!_aliased", tstr, s] = @benchmarkable perf_conditional_loop!($v, $v, $v)

    for F in (MutableFields, ImmutableFields)
        SUITE["Linear", "loop_fields!", tstr, string(F), s] = @benchmarkable perf_loop_fields!($(F)($v))
    end

    # Also test our ability to SIMD without explicitly requesting it
    SUITE["Linear", "auto_axpy!", tstr, s] = @benchmarkable perf_auto_axpy!($n, $v, $x)
    SUITE["Linear", "auto_conditional_loop!", tstr, s] = @benchmarkable perf_auto_conditional_loop!($v, $x, $y)
    SUITE["Linear", "auto_local_arrays", tstr, s] = @benchmarkable perf_auto_local_arrays($v)
    if T <: Integer
        # These tests can't SIMD automatically due to float associativity, so only test on integers
        SUITE["Linear", "auto_inner", tstr, s] = @benchmarkable perf_auto_inner($v, $x)
        SUITE["Linear", "auto_sum_reduce", tstr, s] = @benchmarkable perf_auto_sum_reduce($v)
        SUITE["Linear", "auto_manual_example!", tstr, s] = @benchmarkable perf_auto_manual_example!($v, $x, $y)
        SUITE["Linear", "auto_two_reductions", tstr, s] = @benchmarkable perf_auto_two_reductions($v, $x, $y)
    end
end
const nbytes = 1 << 20
_partition(iter) = @inbounds @view iter[begin+1:end-1]
for ndims in (2,3,4), dim1 in (31, 32, 63, 64), T in (Int32, Int64, Float32, Float64)
    num = nbytes ÷ sizeof(T)
    sz = (dim1, ntuple(_ -> 8, ndims - 2)..., (num>>(3ndims - 6)) ÷  dim1)
    tstr = string(T)
    _v = samerand(T, sz); v = view(_v, axes(_v)...)
    _x = samerand(T, sz); x = view(_x, axes(_x)...)
    _y = samerand(T, sz); y = view(_y, axes(_x)...)
    n = samerand(T)
    SUITE["Cartesian", "axpy!", tstr, ndims, dim1] = @benchmarkable perf_axpy!($n, $v, $x)
    SUITE["Cartesian", "inner", tstr, ndims, dim1] = @benchmarkable perf_inner($v, $x)
    SUITE["Cartesian", "manual_example!", tstr, ndims, dim1] = @benchmarkable perf_manual_example!($v, $x, $y)
    SUITE["Cartesian", "two_reductions", tstr, ndims, dim1] = @benchmarkable perf_two_reductions($v, $x, $y)
    SUITE["Cartesian", "conditional_loop!", tstr, ndims, dim1] = @benchmarkable perf_conditional_loop!($v, $x, $y)
    SUITE["CartesianPartition", "axpy!", tstr, ndims, dim1] = @benchmarkable perf_axpy!($n, $v, $x, _partition)
    SUITE["CartesianPartition", "inner", tstr, ndims, dim1] = @benchmarkable perf_inner($v, $x, _partition)
    SUITE["CartesianPartition", "manual_example!", tstr, ndims, dim1] = @benchmarkable perf_manual_example!($v, $x, $y, _partition)
    SUITE["CartesianPartition", "two_reductions", tstr, ndims, dim1] = @benchmarkable perf_two_reductions($v, $x, $y, _partition)
    SUITE["CartesianPartition", "conditional_loop!", tstr, ndims, dim1] = @benchmarkable perf_conditional_loop!($v, $x, $y, _partition)
end

for b in values(SUITE)
    b.params.time_tolerance = 0.20
end

end # module
