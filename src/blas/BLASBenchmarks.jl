module BLASBenchmarks

import BaseBenchmarks
using BenchmarkTrackers

const SIZES = (2^2, 2^4, 2^6, 2^8, 2^10)

###########
# level 1 #
###########

@track BaseBenchmarks.TRACKER begin
    @setup vectors = map(rand, SIZES)
    @benchmarks "BLAS 1" begin
        [(:dot, length(v)) => dot(v, v) for v in vectors]
        [(:axpy!, length(v)) => BLAS.axpy!(BaseBenchmarks.samerand(), v, zeros(v)) for v in vectors]
    end
    @tags "array" "linalg" "blas" "mul" "level1" "dot" "axpy!"
end

###########
# level 2 #
###########

@track BaseBenchmarks.TRACKER begin
    @setup arrays = map(n -> (BaseBenchmarks.samerand(n, n), BaseBenchmarks.samerand(n)), SIZES)
    @benchmarks "BLAS 2" begin
        [(:gemv, length(x)) => *(A, x) for (A, x) in arrays]
    end
    @tags "array" "linalg" "blas" "mul" "level2" "gemv"
end

###########
# level 3 #
###########

@track BaseBenchmarks.TRACKER begin
    @setup arrays = map(n -> BaseBenchmarks.samerand(n, n), SIZES)
    @benchmarks "BLAS 3" begin
        [(:A_mul_B!, size(A, 1)) => A_mul_B!(zeros(A), A, A) for A in arrays]
    end
    @tags "array" "linalg" "blas" "mul" "level3" "matmul"
end

end # module
