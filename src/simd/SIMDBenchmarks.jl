module SIMDBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

###########
# Methods #
###########

function perf_simd_axpy!(a, X, Y)
    # LLVM's auto-vectorizer typically vectorizes this loop even without @simd
    @simd for i in eachindex(X)
        @inbounds Y[i] += a*X[i]
    end
    return Y
end

function perf_simd_inner(x, y)
    s = zero(eltype(x))
    @simd for i in eachindex(x)
        @inbounds s += x[i]*y[i]
    end
    return s
end

function perf_simd_sumreduce(x, i, j)
    s = zero(eltype(x))
    @simd for k in i:j
        @inbounds s += x[k]
    end
    return s
end

##############
# Benchmarks #
##############

@track BaseBenchmarks.TRACKER begin
    @setup vectors = map(T -> BaseBenchmarks.samerand(T, 1000), (Float32, Float64))
    @benchmarks begin
        [(:simd_axpy!, string(eltype(v))) => perf_simd_axpy!(first(v), v, copy(v)) for v in vectors]
        [(:simd_inner, string(eltype(v))) => perf_simd_inner(v, v) for v in vectors]
        [(:simd_sumreduce, string(eltype(v))) => perf_simd_sumreduce(v, 500, 700) for v in vectors]
    end
    @tags "array" "simd" "inbounds" "mul" "axpy!" "inner" "sum" "reduce"
end

end # module